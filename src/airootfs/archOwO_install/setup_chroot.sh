#!/bin/bash

main() {
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

    # Set executable permission
    local -r mount_root="/archOwO"
    chmod +x "$mount_root/initial-setups.sh"
    chmod +x "$mount_root/set_gnome_theme.sh"
    
    echo "[Enter your username]"
    read -r username
    
    # Set password
    useradd -m "$username"
    gpasswd -a "$username" wheel

    echo "[Password for $username]"
    passwd "$username"
    echo "[Password for root]"
    passwd root

    # Install grub
    grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB

    # Update grub configs
    grub-mkconfig -o /boot/grub/grub.cfg
}

main "$0"