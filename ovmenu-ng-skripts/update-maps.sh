#!/bin/bash
XCSOAR_MAP_PATH="${HOME}/.xcsoar"
. usb_stick.sh
MAP_PATH="${USB_STICK}/maps"

if [ -z "$(ls $MAP_PATH/xcsoar-maps*.ipk 2>/dev/null)" ]; then
        echo "No files for update found !!!"
else
        for mapfile in $(find $MAP_PATH -name 'xcsoar-maps*.ipk'); do
                echo $mapfile
                opkg install $mapfile
        done
fi

if [ -z "$(ls $MAP_PATH/*.xcm 2>/dev/null)" ]; then
        echo "No files for update found !!!"
else
        for mapfile in $(find $MAP_PATH -name '*.xcm'); do
                echo $mapfile
                cp $mapfile $XCSOAR_MAP_PATH
        done
fi


umount ${USB_STICK}
