#!/bin/bash

source ./fndefinitions.sh

# $1: Block device in /dev/block_dev format

prepare() {
        cryptsetup open --type plain -d /dev/urandom --sector-size 4096 "$1" pre_crypt
        shred --random-source=/dev/urandom --zero /dev/mapper/precrypt
        cryptsetup close /dev/mapper/pre_crypt
        cryptsetup luksFormat "$1"
        cryptsetup open "$1" cryptlvm
        case "$2" in
                        /dev/nvme?n?)
                                BOOT_PART=$(printf "$2%s" "p1")
                        ;;
                        /dev/sd?)
                                BOOT_PART=$(printf "$2%s" "1")
                        ;;
        esac
        fsPrepare "$BOOT_PART" "/dev/arch-lv/root"
}

encryptDrive() {
        printf "Let's get your drive prepared.\n\nWARNING --> THIS WILL SECURELY WIPE YOUR DRIVE. ANY DATA WILL BE IRRECOVERABLE.\n\n"
        printf "Continue?\n\n>>> "
        read -r RESULT
        clear
        printf "Please choose a Physical Volume to prepare"
        PART=getParts
        if [[ $RESULT = "Yes" || $RESULT = "yes" || $RESULT = 1  ]]; then
                prepare "$PART" $1
        fi

}
