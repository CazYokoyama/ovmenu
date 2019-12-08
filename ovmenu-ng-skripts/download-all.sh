#!/bin/bash

DOWNLOAD_PATH="${HOME}/.xcsoar"
. usb_stick.sh
USB_PATH=${USB_STICK}/download/xcsoar

if [ ! -d "$USB_PATH" ]; then
	mkdir -p "$USB_PATH"
fi
if [ -z "$(ls $DOWNLOAD_PATH/* 2>/dev/null)" ]; then
        echo "No files found !!!"
else
        for downloadfile in $(find $DOWNLOAD_PATH -type f); do
                echo $downloadfile
                cp $downloadfile $USB_PATH
        done
fi

echo "Umount Stick ..."
umount ${USB_STICK}
echo "Done !!"

