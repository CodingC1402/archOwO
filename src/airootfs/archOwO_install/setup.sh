#!/bin/bash


configure_system() {
    echo "[Copying installation files over]"
    for dir in /archOwO_install/*/ ; do
        cp -r "$dir" /mnt || exit 1
    done
    cp -r /archOwO /mnt/ || exit 1

    local -r chroot_setup="setup_chroot.sh"
    cp /archOwO_install/$chroot_setup /mnt/
    cp /archOwO_install/packages /mnt/
    chmod 777 /mnt/$chroot_setup

    echo "[Setting locale]"
    genfstab -U /mnt >> /mnt/etc/fstab
    arch-chroot /mnt /bin/bash -c "su root -c /$chroot_setup" || exit 1

    # Clean up
    rm /mnt/$chroot_setup
    rm /mnt/packages
}

install_packages() {
    echo "[Installing essential packages]"

    pacman-key --init || exit 1
    local packages="base linux linux-firmware"
    pacstrap /mnt $packages || exit 1
}

mount_fs() {
    echo "[Mounting partitions]"
    mount "$FS_PAR" /mnt || exit 1
    mount --mkdir "$EFI_PAR" /mnt/boot || exit 1
    swapon "$SWAP_PAR" || exit 1

    chown archowo /mnt
    chown archowo /mnt/boot
}

choose_and_format_disk() {
    text=$(fdisk -l)
    local -r wordsArr=($text)
    local disks=()

    for word in "${wordsArr[@]}" ; do 
        if [[ "$word" =~ ^(\/dev\/).*:$ ]] ; then
            disks+=("${word::-1}")
        fi
    done

    echo "[Choose your disk, this will format it]"
    local count="0"
    for disk in "${disks[@]}" ; do
        echo "$count) $disk"
        _=$((++count))
    done
    read -r option
    
    local installDisk="${disks[option]}"
    local postfix=""
    if [[ "$installDisk" =~ (nvme)* ]] ; then
        postfix="p"
    fi
    
    # Format the disk
    echo "[Formatting]"
    (echo "g
    n
    

    
    w") | fdisk "$installDisk"
    (echo Y) || mkfs.ext4 "${installDisk}${postfix}1" || exit 1

    # Create partitions
    echo "[Creating partitions]"
    (echo "g
    n


    +500MB
    n


    +1GB
    n
    

    
    p
    w") | fdisk "$installDisk"

    local -r fsPar="${installDisk}${postfix}3"
    echo "[Creating file system in $fsPar]"
    (echo Y) | mkfs.ext4 "$fsPar" && e2label "$fsPar" ROOT || exit 1

    echo "[Initialize swap partition in $swapPar]"
    local -r swapPar="${installDisk}${postfix}2"
    mkswap -L SWAP "$swapPar" || exit 1

    echo "[Creating efi system partition in $efiPar]"
    local -r efiPar="${installDisk}${postfix}1"
    mkfs.fat -F 32 "$efiPar" && fatlabel "$efiPar" EFI || exit 1
    
    # Export for later uses
    export FS_PAR=$fsPar
    export SWAP_PAR=$swapPar
    export EFI_PAR=$efiPar
}

test_internet() {
    echo "[Testing your internet]"
    if (( $(ping -c 3 archlinux.org) != 0 )); then
        echo "Please connect to the internet first!"
        exit 1
    fi
}

set_key_layout() {
    echo "[Setting keyboard layout]"
}

set_system_clock() {
    echo "[Setting system clock]"
    timedatectl set-ntp true
}

main() {
    set_key_layout
    test_internet 
    set_system_clock
    choose_and_format_disk
    mount_fs
    install_packages
    configure_system

    umount -R /mnt
    echo "[Finish installing archOwO please reboot and remove the installation medium]"
    return 0
}

main "$0"
