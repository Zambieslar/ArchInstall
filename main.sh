#!/bin/bash

source ./pkgs.sh
source ./fndefinitions.sh
source ./create_lvm.sh
source ./wrapper.sh
source ./encrypt.sh

NETSTATUS=$(ping archlinlux.org)

case "$?" in
        1)
                printf "No connection currently available"
                ;;
        0)
                printf "Connection established. Continuing with installation"
                ;;
esac

if [[ "$NTPSTATUS" = "inactive" ]]; then
        printf "NTP currently inactive. This is not ideal in some situations as it will prevent package installations and system updtes. Fixing for your dumbass..."
        sed -Ee 's/#NTP=//g' -e 's/(#FallbackNTP=)(.*)/NTP=\2/' /etc/systemd/timesyncd.conf
        timedatectl set-ntp true
fi

printf "Create LVM or static partition?\n\n (LVM || Static)\n\n>>> "
read -r DRIVE_TYPE
printf "Would you like to encrypt your drive?\n\n (Yes || No)\n\n>>> "
read -r ENCRYPT

case $DRIVE_TYPE in
        "LVM"|"Lvm"|"lvm"|1)
                clear
                printf "First, we need to partition at least two partitions on a drive.\n\nIf you choose to encrypt your LV's, the boot volume can't be encrypted or the bootloader won't be able to load our linux kernel on boot.\n\nCreate one boot partition and one partition to wrap your LV's"
                DRIVE=getDrives
                partitionDrive $DRIVE # Passing block device in /dev/block_dev format
                if [[ $ENCRYPT == "Yes" ]] || [[ $ENCRYPT == "yes" ]] || [[ $ENCRYPT == "1" ]]; then
                            encryptDrive $DRIVE
                fi
        ;;
        "Static"|"static"|2)
                partitionDrive
        ;;
esac

