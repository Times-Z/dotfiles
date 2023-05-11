#!/bin/bash

readonly CMD=$1

readonly COLOR_OFF="%{F#66ffffff}"
readonly ICON_OFF=""
readonly COLOR_ON="%{F#d4a1dd}"
readonly ICON_ON=""
readonly COLOR_CONNECTED="%{F#883696}"
readonly ICON_CONNECTED=""

function show_icon {
    if [ $(bluetoothctl show | grep "Powered: yes" | wc -c) -eq 0 ]
    then
        echo $COLOR_OFF$ICON_OFF
    else
        if [ $(echo info | bluetoothctl | grep 'Device' | wc -c) -eq 0 ]
        then
            echo $COLOR_ON$ICON_ON
        else
            echo $COLOR_CONNECTED$ICON_CONNECTED
        fi
    fi
}

function toggle {
    if [ $(bluetoothctl show | grep "Powered: yes" | wc -c) -eq 0 ]
    then
        bluetoothctl power on
        state=on
    else
        bluetoothctl power off
        state=off
    fi
    
    dunstify --appname="bluetoothctl" "Bluetooth powered $state"
}

case $CMD in
    
    "--show")
        show_icon
    ;;
    
    "--toggle")
        toggle
    ;;
    
    *)
        echo "Invalid command"
        echo ""
        echo "Available commands :"
        echo "--toggle                   Toggle bluetooth state"
        echo "--show                     Show icons"
        exit 0
    ;;
    
esac
