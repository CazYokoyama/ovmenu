#!/bin/bash

UPLOAD_PATH="${HOME}/.xcsoar"
. usb_stick.sh
USB_PATH="${USB_STICK}/upload"
if [ -z "$(ls $USB_PATH/* 2>/dev/null)" ]; then
        echo "No files found !!!"
else
        for uploadfile in $(find $USB_PATH -type f); do
                echo $uploadfile
                cp $uploadfile $UPLOAD_PATH
        done
fi

umount ${USB_STICK}
