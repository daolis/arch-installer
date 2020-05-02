# This script is not meant to be executed directly

set -euxo pipefail

ask_continue () {
    read -p "Continue? "
}

config_clock () {
    ln -s /usr/share/zoneinfo/Europe/Vienna /etc/localtime
    hwclock --systohc
}

config_keymap () {
    echo "KEYMAP=de-latin1" > /etc/vconsole.conf
}

config_locales () {
    sed -i "s/#\(en_US\.UTF-8.*$\)/\1/" /etc/locale.gen
    locale-gen
    echo <<EOF > /etc/locale.conf
LANG=en_US.UTF-8
LANGUAGE=en_US
LC_ALL=C
EOF
}

ask_hostname () {
    read -p "Hostname [porkypig]: " NET_HOSTNAME
    NET_HOSTNAME=${NET_HOSTNAME:-porkypig}
}

config_hostname () {
    echo "${NET_HOSTNAME}" > /etc/hostname
    echo <<EOF > /etc/hosts
127.0.0.1      localhost
::1            localhost
127.0.1.1      ${NET_HOSTNAME}.localdomain ${NET_HOSTNAME}
EOF
}

config_root () {
    passwd
}

config_user() {
    useradd -m -g users -G wheel -s /bin/zsh cr
    passwd cr
}

config_mkinitcpio () {
    sed -i 's/^MODULES.*/MODULES=(ext4)/' /etc/mkinitcpio.conf
    sed -i 's/^HOOKS.*/HOOKS=(base udev autodetect modconf block encrypt lvm2 filesystems keyboard fsck)/' /etc/mkinitcpio.conf
    mkinitcpio -p linux
}

config_bootloader () {
    bootctl install

    mkdir -p /boot/loader
    echo <<EOF > /boot/loader/loader.conf
default arch
timeout 1
EOF

    cryptdevice=$(blkid | grep "${DISK_LUKS}" | grep -o ' UUID="[^"]*"' | cut -c8- | rev | cut -c2- | rev)
    mkdir -p /boot/loader/entries
    echo <<EOF > /boot/loader/entries/arch.conf
title Archlinux
linux /vmlinuz-linux
initrd /initramfs-linux.img
options cryptdevice=UUID=${cryptdevice}:cryptlvm root=/dev/vg0/root rw loglevel=3
EOF
}

ask_continue
config_clock

ask_continue
config_keymap

ask_continue
config_locales

ask_hostname
config_hostname

ask_continue
config_root

ask_continue
config_user

ask_continue
config_mkinitcpio

ask_continue
config_bootloader