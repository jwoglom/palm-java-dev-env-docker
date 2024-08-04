#!/usr/bin/env bash

xhost +local:docker

# Create SD card image if not exists:
if [ ! -f sdcard.bin ]; then
    if [[ "$(uname)" == "Darwin" ]]; then
        echo "SD card image not found. Using blank image ..."
        unzip sdcard.bin.zip
        chmod 777 sdcard.bin
        chown $USER sdcard.bin
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
        echo "Mounting sdcard ..."
        hdiutil attach -imagekey diskimage-class=CRawDiskImage -readonly -mountpoint ./sdcard ./sdcard.bin
    fi
else
    mount | grep -q sdcard.bin
    if [ "$?" -ne 0 ]; then
        echo "Mounting sdcard ..."
        sudo mount -o loop ./sdcard.bin ./sdcard/
    fi
fi

# Start container if not started:
docker ps | grep -q palm-dev-env
if [ "$?" -ne 0 ]; then
    echo "Running docker compose ..."
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

