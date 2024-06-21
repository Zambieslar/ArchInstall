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
declare -A ZONES
for z in /usr/share/zoneinfo/*
do
        REGION="$(grep -oP "[A-Z]{0,1}\w{0,20}$" <<< "$z")"
        for i in "$z"/*
        do
                ZONE="$(grep -oP "[A-Z]{0,1}\w{0,20}$" <<< "$i")"
                if [[ -z $ZONE ]]; then
                        continue
                fi
                ZONES[$REGION]="${ZONES[$REGION]}${ZONES[$REGION]:+ }$ZONE"
        done
        #ZONE="$(ls $z | grep -oP "[A-Z]{0,1}\w{0,20}$")"
        REGIONS+="$z"
done





KERNELS=(linux-lts linux linux-hardened linux-rt linux-rt-lts linux-zen)
BOOTMODE=$(cat /sys/firmware/efi/fw_platform_size)
NTPSTATUS=$(timedatectl | grep -oP "(NTP service: )\K.*")
export "${DRIVES?}" "${BOOTMODE?}" "${NTPSTATUS?}" "${KERNELS?}" "${ZONES?}" "${REGIONS?}"
