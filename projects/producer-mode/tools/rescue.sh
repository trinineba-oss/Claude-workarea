#!/bin/sh
# Bootloop recovery: disables ALL Magisk modules as soon as adb comes up.
echo "Waiting for device..."
adb wait-for-device shell su -c 'magisk --remove-modules'
