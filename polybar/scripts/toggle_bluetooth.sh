#!/bin/sh
if [ $(bluetoothctl show | grep "Powered: yes" | wc -c) -eq 0 ]
then
    bluetoothctl power on
    state=on
else
    bluetoothctl power off
    state=off
fi

dunstify --appname="bluetoothctl" "Bluetooth powered $state" -i /usr/share/icons/Tela-dark/scalable@3x/devices/bluetooth.svg
