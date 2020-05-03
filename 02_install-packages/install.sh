#!/usr/bin/bash

set -euxo pipefail

#pacman -Syu
pacman -S --needed - < packages.txt

systemctl enable gdm.service
systemctl enable ufw.service
systemctl enable docker.service
