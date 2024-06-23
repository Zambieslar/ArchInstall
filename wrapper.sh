# Get devices and create an array containing each device #

# Each returned device starts with /dev/* (not meant to be displayed only for deserialization)#
for f in /dev/*
do
        case $(grep -oP "(?<=/dev/).+?(?=$)" <<< "$f") in
                nvme?n?)
                        DRIVES+=("$f")
                        ;;
                sd?)
                        DRIVES+=("$f")
                        ;;
                *)
                        continue
                        ;;
        esac
done

#Get timezone information
clear
for z in /usr/share/zoneinfo/*
do
        REGION="$(grep -oP "[A-Z]{1}\w{0,20}$" <<< "$z")"
        if [[ -z $REGION ]]; then
                continue
        fi
        REGIONS+=("$(grep -oP "[A-Z]{1}\w{0,20}$" <<< "$z")")

        #ZONE="$(ls $z | grep -oP "[A-Z]{0,1}\w{0,20}$")"
done


X=0
for i in /usr/share/zoneinfo/"${REGIONS[$REGION]}"/*
do
        ZONE=$(grep -oP "[A-Z]{1}\w{0,20}$" <<< "$i")
        if [[ -z $ZONE ]]; then
                continue
        fi
        ZONES+=("$(grep -oP "[A-Z]{1}\w{0,20}$" <<< "$i")")
done

KERNELS=(linux-lts linux linux-hardened linux-rt linux-rt-lts linux-zen)
BOOTMODE=$(cat /sys/firmware/efi/fw_platform_size)
NTPSTATUS=$(timedatectl | grep -oP "(NTP service: )\K.*")
MOD_NVIDIA=(nvidia nvidia_modeset nvidia_drm nvidia_uvm)
ENCRYPT_HOOKS=(base udev autodetect microcode modconf keyboard keymap consolefont block lvm2 encrypt filesystems fsck)
BOOT_LOADERS=(GRUB Systemd-Boot)
export "${DRIVES?}" "${BOOTMODE?}" "${NTPSTATUS?}" "${KERNELS?}" "${ZONES?}" "${REGIONS?}" "${MOD_NVIDIA?}" "${ENCRYPT_HOOKS?}" "${BOOT_LOADERS?}"
