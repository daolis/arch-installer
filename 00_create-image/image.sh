#!/usr/bin/bash

set -euxo pipefail

# Pick todays archlinux version
version=$(date +'%Y.%m.%d')

# Download and verify image
curl -C - "https://www.archlinux.org/iso/${version}/archlinux-${version}-x86_64.iso.sig" -o "archlinux-${version}-x86_64.iso.sig"
curl -C - "http://mirror.rackspace.com/archlinux/iso/${version}/archlinux-${version}-x86_64.iso" -o "archlinux-${version}-x86_64.iso"
gpg --keyserver-options auto-key-retrieve --verify "archlinux-${version}-x86_64.iso.sig"

# Show available drives and ask for target
lsblk
read -p "Target Device [/dev/sdb]: " device
device=${device:-/dev/sdb}

# Copy image to the USB drive
sudo dd bs=4M if="archlinux-${version}-x86_64.iso" of="$device" status=progress oflag=sync
