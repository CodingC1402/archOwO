#!/usr/bin/env bash
# shellcheck disable=SC2034

iso_name="archOwO"
iso_label="ARCH_$(date +%Y%m)"
iso_publisher="Arch Linux <https://archlinux.org>"
iso_application="Arch Linux baseline"
iso_version="$(date +%Y.%m.%d)"
install_dir="arch"
buildmodes=('iso')
bootmodes=('bios.syslinux.mbr' 'bios.syslinux.eltorito'
           'uefi-ia32.grub.esp' 'uefi-x64.grub.esp'
           'uefi-ia32.grub.eltorito' 'uefi-x64.grub.eltorito')
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="erofs"
airootfs_image_tool_options=('-zlz4hc,12' -E ztailpacking)
file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/etc/gshadow"]="0:0:0400"
  ["/etc/sudoers"]="0:0:0400"
  ["/etc/X11/xinit/xinitrc"]="0:0:0755"
  ["/archOwO/initial-setups.sh"]="0:0:0755"
  ["/archOwO/set_gnome_theme.sh"]="0:0:0755"
  ["/archOwO_install/setup.sh"]="0:0:0755"
  ["/archOwO_install/injectOwO.sh"]="0:0:0755"
  ["/etc/profile.d/startx.sh"]="0:0:0755"
  ["/etc/profile.d/mark_executable.sh"]="0:0:0755"
)
