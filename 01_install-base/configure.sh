#!/usr/bin/bash

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
    cat <<EOF > /etc/locale.conf
LANG=en_US.UTF-8
EOF
}

ask_hostname () {
    read -p "Hostname [porkypig]: " NET_HOSTNAME
    NET_HOSTNAME=${NET_HOSTNAME:-porkypig}
}

config_hostname () {
    echo "${NET_HOSTNAME}" > /etc/hostname
    cat <<EOF > /etc/hosts
127.0.0.1      localhost
::1            localhost
127.0.1.1      ${NET_HOSTNAME}.localdomain ${NET_HOSTNAME}
EOF
}

config_root () {
    passwd
    chsh -s /usr/bin/zsh root
}

config_user() {
    useradd -m -g users -G wheel -s /bin/zsh cr
    passwd cr
    chsh -s /usr/bin/zsh cr
}

config_mkinitcpio () {
    sed -i 's/^MODULES.*/MODULES=(ext4)/' /etc/mkinitcpio.conf
    sed -i 's/^HOOKS.*/HOOKS=(base udev autodetect modconf block encrypt lvm2 filesystems keyboard fsck)/' /etc/mkinitcpio.conf
    mkinitcpio -p linux
}

config_bootloader () {
    bootctl install

    mkdir -p /boot/loader
    cat <<EOF > /boot/loader/loader.conf
default arch
timeout 1
EOF

    cryptdevice=$(blkid | grep "crypto_LUKS" | grep -o ' UUID="[^"]*"' | cut -c8- | rev | cut -c2- | rev)
    mkdir -p /boot/loader/entries
    cat <<EOF > /boot/loader/entries/arch.conf
title Archlinux
linux /vmlinuz-linux
initrd /initramfs-linux.img
options cryptdevice=UUID=${cryptdevice}:cryptlvm root=/dev/vg0/root rw loglevel=3
EOF
}

config_enable_services () {
    systemctl enable NetworkManager.service

    systemctl enable systemd-resolved.service
    rm -f /etc/resolv.conf
    ln -s /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
}

ask_hostname

config_clock
config_keymap
config_locales
config_hostname
config_root
config_user
config_enable_networkmanager

ask_continue
config_mkinitcpio

ask_continue
config_bootloader
