#!/bin/sh
IS_ON=$(bluetoothctl show | grep "Powered: yes" | wc -l)

if [ "$IS_ON" = "1" ]; then
    bluetoothctl power off
else
    rfkill unblock bluetooth
    sleep 0.3
    bluetoothctl power on
fi
