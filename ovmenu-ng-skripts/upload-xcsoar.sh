#!/bin/bash

UPLOAD_PATH=${HOME}/XCSoarData
. usb_stick.sh
USB_PATH=${USB_STICK}/XCSoarData

if [ -d ${USB_PATH} ]; then
    rsync -a --verbose ${USB_PATH}/ ${UPLOAD_PATH}/
else
    echo "No ${USB_PATH} found."
fi

echo "Umount Stick ..."
umount ${USB_STICK}
echo "Done."
