#!/bin/bash

source ./pkgs.sh
source ./fndefinitions.sh
source ./create_lvm.sh
source ./wrapper.sh
source ./encrypt.sh

NETSTATUS=$(ping archlinlux.org)
case "$?" in
        1)
                printf "No connection currently available. Please connect the device to the internet before continuing with the installation."
                exit 1
                ;;
        0)
                printf "Connection established. Continuing with installation."
                ;;
esac

if [[ "$NTPSTATUS" = "inactive" ]]; then
        printf "NTP currently inactive. This is not ideal in some situations as it will prevent package installations and system updates. Fixing for your dumbass..."
        sed -i -Ee 's/#NTP=//g' -e 's/(#FallbackNTP=)(.*)/NTP=\2/' /etc/systemd/timesyncd.conf
        timedatectl set-ntp true
fi

printf "Create LVM or static partition?\n\n (LVM || Static)\n\n>>> "
read -r DRIVE_TYPE
printf "Would you like to encrypt your drive?\n\n (Yes || No)\n\n>>> "
read -r ENCRYPT

case $DRIVE_TYPE in
        "LVM"|"Lvm"|"lvm"|1)
                clear
                printf "First, we need to create at least two partitions on a drive.\n\nIf you choose to encrypt your LV's, the boot volume can't be encrypted or the bootloader won't be able to load our the kernel on boot.\n\nCreate one boot partition and one root partition to wrap your Logical Volumes."
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

printf "Please select a kernel"
X=0
for i in "${KERNELS[@]}"
do
        printf "%s\n" "$X) $i"
        ((X++))
done
printf "\n(0-5) >>> "

printf "Installing the base system"
pacstrap -K /mnt "${PKGS[@]}" "$KERNEL"
printf "Generating fstab to match partition layout"
genfstab -U /mnt >> /mnt/etc/fstab
printf "Please select a region\n\n"
X=0
for i in "${REGIONS[@]}"
do
        printf "%s\n" "   $X) $i"
        ((X++))
done
printf "\n>>> "
read -r REGION
clear
X=0
printf "Please select a zone\n\n"
for i in "${ZONES[@]}"
do
        printf "%s\n" "   $X) $i"
        ((X++))
done
printf "\n>>> "
read -r ZONE

printf "%s" "Setting timezone to ${REGIONS[$REGION]} - ${ZONES[$ZONE]}"

arch-chroot /mnt ln -sf /usr/share/zoneinfo/${REGIONS[$REGION]}/${ZONES[$ZONE]} /etc/localtime

printf "Default locale is en_US.UTF-8 UTF-8. Would you like to change the locale or continue with default settings?\n\n>>> "
read -r RESULT

case $RESULT in
        "Continue"|"continue"|"Yes"|"yes"|1)
                arch-chroot /mnt sed -i 's/#\(en_US.UTF-8 UTF-8\)/\1/g' locale.gen
                arch-chroot /mnt locale-gen
        ;;
        "Update"|"update"|"Change"|"change"|"No"|"no"|2)
        ;;
esac

printf "Please enter a hostname for your device.\n\n>>> "
read -r HOSTNAME

echo $HOSTNAME >> /mnt/etc/hostname

printf "Please select a boot loader for your installation.\n\n"
X=0
for i in ${BOOT_LOADERS[@]}
do
        printf "\t%s\n" "$X) $i"
        ((X++))
done
printf "\n\n>>> "
read BOOT_LOADER

DRIVE_UUID=$(lsblk -Po NAME,UUID /dev/$DRIVE | sed 's/NAME=\"\(.*\)\"\sUUID=\"\(.*\)\"/\2/'

case $BOOT_LOADER in
        "GRUB"|"grub"|1)
                grub-install --target-x86_64-efi --efi-directory /mnt/boot --bootloader-id=ArchLinux
                grub-mkconfig -o /mnt/boot/grub/grub.cfg
        ;;
        "Systemd-Boot"|"systemd-boot"|2)
                arch-chroot /mnt bootctl install --esp-path=/boot
        ;;
esac

case $ENCRYPT in
        "Yes"|"yes"|1)
                printf "Update mkinitcpio.conf and GRUB to support disk encryption and preload GFX drivers."
                sed -i "s/MODULES=()/$MOD_NVIDIA/g" /mnt/etc/mkinitcpio.conf
                sed -i "s/HOOKS=(.*)/$ENCRYPT_HOOKS/g" /mnt/etc/mkinitcpio.conf
                sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=\".*\"/GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 quiet nvidia_drm.modeset=1 cryptdevice=UUID=$DRIVE_UUID:cryptlvm root=/dev/arch-lv/root nvidia_drm.modeset=1\"/g"
                arch-chroot /mnt mkinitcpio -P
        ;;
        "No"|"no"|2)
        ;;
esac

while :
do  
        printf "Finally, please enter a password for your root account.\n\n>>> "
        read -r -s PASSWD
        clear
        printf "Please confirm password.\n\n>>> "
        read -r -s CONFPASSWD
        if [[ $PASSWD == $CONFPASSWD ]]; then
                arch-chroot /mnt passwd "$PASSWD"
                break
        else
                printf "Passwords do not match. Please try again."
                sleep 5
                clear
                continue
        fi
done
