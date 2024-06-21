# Get drives and print them out in a serialized way for the user to select. 
getDrives() {
        while :
        do
                X=0
                printf "Which drive would you like to use?\n\n"
                for d in "${DRIVES[@]}"
                do
                        printf "   $((X++))) %s\n" "$(grep -oP "(?<=/dev/).+?(?=$)" <<< "$d")"
                done
                printf "\n>>> "
                read -r DEVICE
                if [[ $((DEVICE + 1)) -gt "${#DRIVES[@]}" ]];
                then
                        clear
                        printf "ERROR --> Device not found\n\n"
                else
                        break
                fi
        done
        # Return the block device in format /dev/block_dev
        return "${DRIVES[$DEVICE]}"
}

# Enumerate partitions for the user to select
# Return the selected partition in /dev/block_dev_part format
getParts() {
        for f in /dev/*
        do
                case $(grep -P "(?<=nvme\dn\dp\d)|(?<=sd\w\d)|(?<=xvd\w\d)" <<< "$f") in
                        /dev/nvme?n?p?)
                                DRIVES+=("$f")
                        ;;
                        /dev/sd??)
                                DRIVES+=("$f")
                        ;;
                        *)
                                continue
                        ;;
                esac
        done
        while :
        do
                X=0
                printf "Which partition would you like to use?\n\n"
                for d in "${DRIVES[@]}"
                do
                        printf "   $((X++))) %s\n" "$(grep -oP "(?<=/dev/).*" <<< "$d")"
                done
                printf "\n>>> "
                read -r DEVICE
                if [[ $((DEVICE + 1)) -gt "${#DRIVES[@]}" ]];
                then
                        clear
                        printf "ERROR --> Device not found\n\n"
                else
                        break
                fi
        done
        # Return the block device in format /dev/block_dev_part
        return "${DRIVES[$DEVICE]}"
}

# Allow user to get the existing block devices and launch cfdisk to partition them interactively.
# Script waits for the user to finish before continuing.
partitionDrive() {
        while :
        do
                clear
                RESULT=0
                cfdisk "$1" ; wait $(pidof cfdisk)
                clear
                printf "Would you like to partition additional drives?\n\n>>> "
                read -r RESULT
                clear
                case "$RESULT" in
                        "yes"|"Yes"|1)
                                continue
                        ;;
                        "no"|"No"|2)
                                break
                        ;;
                        *)
                                printf "I'm sorry, I don't understand. Please reiterate stupid?\n\n"
                        ;;
                esac
        done
}

# $1: Boot partition
# $2: Root partition

fsPrepare() {
        mkfs.fat -F 32 "$1"
        mkfs.ext4 "$2"
        printf "Would you like to use swap?\n\n>>> "
        read -r SWAP
        case $SWAP in
                "Yes"|"yes"|1)
                        printf "Would you like to use a swap file or swap partition?"
                        ;;
                "No"|"no"|2)
                        ;;
        esac
}
