#!/usr/bin/env bash

xhost +local:docker

# Create SD card image if not exists:
if [ ! -f sdcard.bin ]; then
    if [[ "$(uname)" == "Darwin" ]]; then
        echo "SD card image not found. Using blank image ..."
        unzip sdcard.bin.zip
    else
        echo "SD card image not found. Creating new image ..."
        fallocate -l 50M sdcard.bin
        sudo mkfs.fat ./sdcard.bin
    fi
fi

# Mount SD card image if not mounted:

if [[ "$(uname)" == "Darwin" ]]; then
    mount | grep -q "$(pwd)"
    if [ "$?" -ne 0 ]; then
        MOUNTED_DISK=$(hdiutil attach -imagekey diskimage-class=CRawDiskImage -nomount ./sdcard.bin)
        mount -t msdos $MOUNTED_DISK ./sdcard
    fi
else
    mount | grep -q sdcard.bin
    if [ "$?" -ne 0 ]; then
        sudo mount -o loop ./sdcard.bin ./sdcard/
    fi
fi

# Start container if not started:
docker ps | grep -q palm-dev-env
if [ "$?" -ne 0 ]; then
    docker compose up --detach
fi

echo
echo    "*******************************************************************"
echo    "Aliases:"
echo -e "\temulator\tRun emulator with mounted SD card"
echo
echo    "Installed programming tools:"
echo -e "\tjava"
echo -e "\tjavac"
echo -e "\tktoolbar"
echo -e "\tjar2prc"
echo -e "\teclipse"
echo    "*******************************************************************"
echo

# Go to container
docker exec -it palm-dev-env /bin/bash

