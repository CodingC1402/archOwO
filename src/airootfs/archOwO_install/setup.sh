#!/bin/bash


configure_system() {
    genfstab -U /mnt >> /mnt/etc/fstab
    arch-chroot /mnt
    ln -sf /usr/share/zoneinfo/Asia/Ho_Chi_Minh /etc/localtime
    hwclock --systohc

    locale-gen
    echo "[Uncomment the locales you want]"
    read -r
    vim /etc/locale.gen

    touch /etc/locale.conf
    read -r lang
    echo "LANG=${lang}" >> /etc/locale.conf

    systemctl enable sddm
    systemctl enable initial_setups
    systemctl enable NetworkManager

    # Set executable permission
    local -r mount_root="/mnt/archOwO"
    chmod +x "$mount_root/initial_setups.sh"
    chmod +x "$mount_root/set_gnome_theme.sh"

    passwd
}

install_packages() {
    echo "[Installing packages]"

    local packages="base grub linux linux-firmware vim"
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

    pacstrap /mnt "$packages"

    echo "[Copying installation files over]"
    cp -a /archOwO_install/. /mnt/
    cp -r /archOwO /mnt/
}

setup_chaotic_aur() {
    echo "[Installing chaotic aur]"
    
    pacman-key --init
    pacman-key --recv-key FBA220DFC880C036 --keyserver keyserver.ubuntu.com
    pacman-key --lsign-key FBA220DFC880C036
    pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
    
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
    mkfs.ext4 "$fsPar"

    echo "[Initialize swap partition, enter partion postfix]"
    read -r swapPar
    swapPar="${disk}${swapPar}"
    mkswap "$swapPar"

    echo "[Creating efi system partition, enter partion postfix]"
    read -r efiPar
    efiPar="${disk}${efiPar}"
    mkfs.fat -F 32 "$efiPar"
    
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
    configure_system

    return 0
}

main "$0"
