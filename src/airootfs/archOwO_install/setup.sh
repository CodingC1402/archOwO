#!/bin/bash


configure_system() {
    echo "[Copying installation files over]"
    for dir in /archOwO_install/*/ ; do
        cp -r "$dir" /mnt || exit 1
    done
    cp -r /archOwO /mnt/ || exit 1

    local -r chroot_setup="setup_chroot.sh"
    cp /archOwO_install/$chroot_setup /mnt/
    chmod 777 /mnt/$chroot_setup

    echo "[Setting locale]"
    genfstab -U /mnt >> /mnt/etc/fstab
    arch-chroot /mnt /bin/bash -c "su root -c /$chroot_setup"
    rm /mnt/$chroot_setup
}

install_graphic_driver() {
    echo "[Installing graphic driver]"
    
    # Run build not as root
    sudo -u archowo bash -c '\
        mkdir -p /mnt/archOwO/temp
        cd /mnt/archOwO/temp
        git clone https://aur.archlinux.org/nvidia-vulkan.git
        cd ./nvidia-vulkan
        makepkg -sc || exit 1
        exit 0
    '

    if (($? != 0)) ; then
        exit 1
    fi

    cd /mnt/archOwO/temp/nvidia-vulkan || exit 1
    local packages=""
    for package in *pkg.tar.zst ; do
        if [[ ${package:0:18} != "nvidia-vulkan-dkms" ]] ; then
            packages="$packages $package"
        fi
    done

    pacstrap -U /mnt $packages
} 

install_packages() {
    echo "[Installing packages]"

    local packages=""
    echo "[Is your cpu amd or intel]"
    echo "1) AMD"
    echo "2) Intel"
    read -r option

    local ucode=""
    case "${option}" in
        1)
            ucode="amd-ucode"
        ;;
        2)
            ucode="intel-ucode"
        ;;
        *)
            echo "Error"
            exit 1
        ;;
    esac
    packages="$packages $ucode"

    while read -r package ; do
        packages="${packages} ${package}"
    done < <(grep -v '^#\|^$' /archOwO_install/packages)

    pacstrap /mnt $packages || exit 1
}

setup_chaotic_aur() {
    echo "[Installing chaotic aur]"
    
    pacman-key --init || exit 1
    pacman-key --recv-key FBA220DFC880C036 --keyserver keyserver.ubuntu.com || exit 1
    pacman-key --lsign-key FBA220DFC880C036 || exit 1
    (echo "Y") | pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' || exit 1
    
    echo "
    [chaotic-aur]
    Include = /etc/pacman.d/chaotic-mirrorlist
    " >> /etc/pacman.conf
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
    (echo Y) | mkfs.ext4 "$fsPar" || exit 1

    echo "[Initialize swap partition, enter partion postfix]"
    read -r swapPar
    swapPar="${disk}${swapPar}"
    mkswap "$swapPar" || exit 1

    echo "[Creating efi system partition, enter partion postfix]"
    read -r efiPar
    efiPar="${disk}${efiPar}"
    mkfs.fat -F 32 "$efiPar" || exit 1
    
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
    setup_chaotic_aur
    mount_fs
    install_packages
    install_graphic_driver
    configure_system

    umount  -R /mnt
    echo "[Finish installing archOwO please reboot and remove the installation medium]"
    return 0
}

main "$0"
