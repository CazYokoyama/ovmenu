#!/bin/bash

MOUNT_ROOT="/media/pi"

USB_LABEL=`ls ${MOUNT_ROOT} | cut -d" " -f1`
if [ -z "${USB_LABEL}" ]; then
    echo No USB flash memory attached.
    exit 0
fi

USB_STICK=${MOUNT_ROOT}/${USB_LABEL}
