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

getUUID(){
        declare -A DRIVES
        X=1
        RESULT=$(lsblk -Po NAME,UUID | sed 's/NAME=\"\(.*\)\"\sUUID=\"\(.*\)\"/\1 | \2/')
        KEY=$(sed -n "$X"p <<< $RESULT | sed 's/\(.*\)\s|\s\(.*\)/\1/')
        while [[ -n $KEY ]]
        do
        	KEY=$(sed -n "$X"p <<< $RESULT | sed 's/\(.*\)\s|\s\(.*\)/\1/')
        	VALUE=$(sed -n "$X"p <<< $RESULT | sed 's/\(.*\)\s|\s\(.*\)/\2/')
        	if [[ -z $VALUE ]]; then
        		((X++))
        		continue
        	elif [[ -z $KEY ]]; then
        		break
        	else
        		DRIVES["$KEY"]="$VALUE"
        		((X++))
        	fi
        done
        return $DRIVES
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
calcSwap() {
        TOTAL_MEM=$(lsmem -no SIZE | grep -oP "(?<=Total online memory:)\d\d|\d\d.\d")
        TARGET_SIZE=$(bc -l <<< "$TOTAL_MEM * 1.5")
        return "$TARGET_SIZE"
}
# $1: Boot partition
# $2: Root partition

fsPrepare() {
        mkfs.fat -F 32 "$1"
        mkfs.ext4 "$2"
        mount $2 /mnt
        if [[ -d /mnt/boot ]]; then
                mount $1 /mnt/boot
        fi
        mkdir /mnt/boot
        mount $1 /mnt/boot
        printf "Would you like to use swap?\n\n>>> "
        read -r SWAP
        case $SWAP in
                "Yes"|"yes"|1)
                        printf "Would you like to use a swap file or swap partition?\n\n>>> "
                        read -r RESULT
                        case "$RESULT" in
                        "yes"|"Yes"|1)
                                TARGET_SIZE=calcSwap
                                mkswap -U clear --size "$TARGET_SIZE"G --file /mnt/swap
                        ;;
                        "no"|"No"|2)
                        ;;
                esac
                ;;
                "No"|"no"|2)
                ;;
        esac
}
