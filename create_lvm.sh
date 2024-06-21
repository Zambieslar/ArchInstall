#!/bin/bash

# $1: Are we encrypting the Logical Volume?
# $2: LV to encrypt.

# Partitioning block devices called from main.

createLvm() {
        case $1 in
                "Yes"|"yes"|1)
                        clear
                        pvcreate "$2"
                        vgcreate arch-lv "$2"
                        lvcreate -l 100%FREE arch-lv -n root
                        lvreduce -L -256M arch-lv/root
                ;;
                "No"|"no"|2)
                        clear
                        LVM_DISK=$(lvmdiskscan | grep -oP "(?<=/dev/).+?(?=\s)")
                        printf "Please choose a device to create your physical volume.\n\nThis volume will wrap your Logical Volumes.\n\n"
                        while [[ $d -lt $(wc -l <<< "$LVM_DISK") ]]
                        do
                        	LVM_TARGETS+=($(lvmdiskscan | grep -oP "/.+?(?=\s)"))
                        	printf "   %s\n" "$((d++))) $(sed -n "$d"p <<< "${LVM_DISK[@]}")"
                        done
                        printf "\n>>> "
                        read -r LVM_TARGET
                        pvcreate "${LVM_TARGETS[$LVM_TARGET]}"
                        vgcreate arch-lv "${LVM_TARGETS[$LVM_TARGET]}"
                        lvcreate -l 100%FREE arch-lv -n root
                        lvreduce -L -256M arch-lv/root
                ;;
        esac
}
