#!/bin/bash

IGC_PATH="${HOME}/.xcsoar/logs"
. usb_stick.sh
USB_PATH=${USB_STICK}/igc
mkdir -p ${USB_PATH} # if not exist

if [ -z "$(ls $IGC_PATH/*.igc 2>/dev/null)" ]; then
        echo "No files found !!!"
else
        for igcfile in $(find $IGC_PATH -name '*.igc'); do
                echo $igcfile
                cp $igcfile $USB_PATH
        done
fi

umount ${USB_STICK}
