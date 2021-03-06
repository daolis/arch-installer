#!/usr/bin/bash

set -euxo pipefail

ask_continue () {
    read -p "Continue? "
}

ask_disk_device () {
    lsblk
    read -p "Target Device [sdb]: " DISK_NAME
    DISK_NAME=${DISK_NAME:-sdb}
    DISK_DEVICE="/dev/${DISK_NAME}"
}

disk_print_partitions () {
    sgdisk -p "$DISK_DEVICE"
}

disk_create_partitions () {
    sgdisk --zap-all --clear "$DISK_DEVICE"
    sgdisk -o "$DISK_DEVICE"

    sgdisk -n 1:0:+512M "$DISK_DEVICE"
    sgdisk -t 1:ef00 "$DISK_DEVICE"
    sgdisk -c 1:"UEFI Boot" "$DISK_DEVICE"

    sgdisk -n 2:0:0 "$DISK_DEVICE"
    sgdisk -t 2:8300 "$DISK_DEVICE"
    sgdisk -c 2:"LUKS" "$DISK_DEVICE"

    partprobe "$DISK_DEVICE"
    sleep 5
}

disk_detect_partitons () {
    DISK_UEFI=/dev/`lsblk -l -o NAME | grep -v "${DISK_NAME}$" | grep "${DISK_NAME}" | grep "1$"`
    DISK_LUKS=/dev/`lsblk -l -o NAME | grep -v "${DISK_NAME}$" | grep "${DISK_NAME}" | grep "2$"`
}

disk_setup_uefi () {
    mkfs.vfat -F32 "${DISK_UEFI}"
}

disk_setup_luks () {
    cryptsetup -c aes-xts-plain64 -y --use-random luksFormat "${DISK_LUKS}"
    cryptsetup luksOpen "${DISK_LUKS}" luks

    pvcreate /dev/mapper/luks
    vgcreate vg0 /dev/mapper/luks
    lvcreate -L 8G vg0 --name swap
    lvcreate -L 30G vg0 --name root
    lvcreate -l100%FREE vg0 --name home

    mkfs.ext4 /dev/mapper/vg0-root
    mkfs.ext4 /dev/mapper/vg0-home
    mkswap /dev/mapper/vg0-swap
}

disk_mount () {
    mount /dev/mapper/vg0-root /mnt
    mkdir /mnt/home
    mount /dev/mapper/vg0-home /mnt/home
    swapon /dev/mapper/vg0-swap
    mkdir /mnt/boot
    mount "${DISK_UEFI}" /mnt/boot
}

bootstrap () {
    pacstrap /mnt base linux linux-firmware base-devel lvm2 zsh grml-zsh-config vim git dialog wpa_supplicant networkmanager
    genfstab -pU /mnt >> /mnt/etc/fstab
    cat <<EOF >> /mnt/etc/fstab

# Use a ramdisk for the /tmp directory
tmpfs			/tmp		tmpfs		defaults,noatime,mode=1777	0 0
EOF
}

configure () {
    cp configure.sh /mnt/configure.sh
    arch-chroot /mnt /bin/bash -c "/configure.sh"
    rm /mnt/configure.sh
}

cleanup () {
    umount -R /mnt
    swapoff -a
}

ask_disk_device
disk_print_partitions

ask_continue
disk_create_partitions
disk_detect_partitons
disk_setup_uefi
disk_setup_luks
disk_mount
bootstrap

ask_continue
configure

ask_continue
cleanup
