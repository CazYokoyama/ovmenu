#!/bin/bash

DOWNLOAD_PATH=${HOME}/XCSoarData
. usb_stick.sh
USB_PATH=${USB_STICK}/XCSoarData

[ -d ${USB_PATH} ] || mkdir -p ${USB_PATH}

if [ -d ${DOWNLOAD_PATH} ]; then
    rsync -a --verbose ${DOWNLOAD_PATH}/ ${USB_PATH}/
else
    echo "No ${DOWNLOAD_PATH}."
fi

echo "Umount Stick ..."
umount ${USB_STICK}
echo "Done."

