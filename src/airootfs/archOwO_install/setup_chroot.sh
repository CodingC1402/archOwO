#!/bin/bash

apply_settings() {
    ln -sf /usr/share/zoneinfo/Asia/Ho_Chi_Minh /etc/localtime
    hwclock --systohc

    locale-gen || exit 1
    touch /etc/locale.conf || exit 1

    local lang="en_US.UTF-8"
    echo "[Enter your prefered lang default is ($lang)]"
    read -r option
    if [[ -n $option ]] ; then 
        lang="$option"
    fi
    echo "LANG=${lang}" >> /etc/locale.conf

    # Enable services
    echo "[Enabling services]"
    systemctl enable sddm
    systemctl enable initial_setups
    systemctl enable NetworkManager
    systemctl enable reflector

    # Set executable permission
    local -r mount_root="/archOwO"
    for file in "$mount_root"/*.sh ; do
        chmod 755 "$file"
    done

    local -r profile="/etc/profile.d"
    for file in "$profile"/*.sh ; do
        chmod 755 "$file"
    done

    chmod 755 /etc/X11/xinit/xinitrc

    # Create auto login
    local -r auto_log_path="/etc/systemd/system/getty@tty7.service.d"
    mkdir -p "$auto_log_path"
    touch "$auto_log_path"/autologin.conf
    echo "[Service]
ExecStart=
ExecStart=-/sbin/agetty -o '-p -f -- \\u' --noclear --autologin $USERNAME %I \$TERM" >> "$auto_log_path"/autologin.conf

    # I don't know what this does :P
    mkinitcpio -P || exit 1

    # Install grub
    grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --removable || exit 1

    # Update grub configs
    grub-mkconfig -o /boot/grub/grub.cfg || exit 1
}

install_graphic_driver() {
    echo "[Installing graphic driver]"
    local -r dir="/home/$USERNAME/Downloads/temp"

    # Run build not as root
    sudo -u "$USERNAME" bash -c "\\
        mkdir -p $dir
        cd $dir
        git clone https://aur.archlinux.org/nvidia-vulkan.git
        cd ./nvidia-vulkan
        makepkg -sc || exit 1
        exit 0
    "

    if (($? != 0)) ; then
        exit 1
    fi

    cd "$dir"/nvidia-vulkan || exit 1
    local packages=""
    for package in *pkg.tar.zst ; do
        if [[ ! $package =~ (lib32|dkms)+ ]] ; then
            packages="$packages $package"
        fi
    done

    pacman -U --needed --noconfirm $packages

    # This is important, remember this for the future
    cd /

    rm -r "$dir"
}

install_packages() {
    echo "[Installing essential packages]"

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
    done < <(grep -v '^#\|^$' /packages)

    pacman -Syu --needed --noconfirm $packages || exit 1
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

create_user() {
    echo "[Enter your username]"
    read -r username
    
    # Set password
    useradd -m "$username"
    gpasswd -a "$username" wheel

    echo "[Password for $username]"
    passwd "$username"
    echo "[Password for root]"
    passwd root

    export USERNAME=$username
}

main() {
    create_user
    setup_chaotic_aur
    install_packages
    install_graphic_driver
    apply_settings
}

main "$0"