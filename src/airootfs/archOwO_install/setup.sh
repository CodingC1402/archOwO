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
    arch-chroot /mnt /bin/bash -c "su root -c /$chroot_setup"

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
    mount "$FS_PAR" /mnt
    mount --mkdir "$EFI_PAR" /mnt/boot
    swapon "$SWAP_PAR"

    chown archowo /mnt
}

choose_and_format_disk() {
    fdisk -l

    echo "[Choose your disk, this will format it]"
    read -r disk
    echo "[Creating partitions]"
    (echo "g
    n


    +500MB
    n


    +1GB
    n
    

    
    p
    w") | fdisk "$disk"

    echo "[Creating file system, enter partition postfix]"
    read -r fsPar
    fsPar="${disk}${fsPar}"
    (echo Y) | mkfs.ext4 "$fsPar" && e2label "$fsPar" ROOT || exit 1

    echo "[Initialize swap partition, enter partion postfix]"
    read -r swapPar
    swapPar="${disk}${swapPar}"
    mkswap -L SWAP "$swapPar" || exit 1

    echo "[Creating efi system partition, enter partion postfix]"
    read -r efiPar
    efiPar="${disk}${efiPar}"
    mkfs.fat -F 32 "$efiPar" && fatlabel "$efiPar" EFI || exit 1
    
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
