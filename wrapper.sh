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

BOOTMODE=$(cat /sys/firmware/efi/fw_platform_size)
NTPSTATUS=$(timedatectl | grep -oP "(NTP service: )\K.*")
export "${DRIVES?}" "${BOOTMODE?}" "${NTPSTATUS?}"
