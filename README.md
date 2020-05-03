# Arch Installer

A very simple shell script to automate the archlinux installation
across my devices.

This is probably only useful to me, because it is very biased to what
I need.

If you want to install archlinux yourself, please refer to the
installation guide.

https://wiki.archlinux.org/index.php/installation_guide

## Prepare Installer Image

To download and prepare a USB install medium run:

``` bash
cd 00_create-image
./image.sh
```

## Installation Procedure

Boot the machine from the USB drive.

Afterwards clone this repository to run the install script.

``` bash
loadkeys de
wifi-menu
pacman -Sy git
git clone https://github.com/kautsig/arch-installer.git
cd arch-installer/01_install-base
./install.sh
```

This is an interactive script, it will ask for disk, hostname,
etc. After every step it waits for confirmation before continuing, so
each step can be verfied for correctness.

## Boot the system

After you have booted into the system, you can use the package list to
get to a usable environment:

``` bash
nmcli device wifi connect <SSID> password <password>
cd arch-installer/02_install-packages
./install.sh
```

This will also enable needed services to start on next boot.

## Troubleshooting

### Cannot boot from USB

Remind that for doing so, "secure boot" must be disabled in the BIOS.

### Disk not visible

In case the disk is not visible in the `lsblk` command try changing
the SATA controller mode from RST to AHCI in BIOS setup.
