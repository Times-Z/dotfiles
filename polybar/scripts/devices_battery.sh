#!/bin/bash

readonly COMMAND=$1
readonly DEVICE=$2
readonly ICON=$3

readonly HIGH_POWER=51
readonly MID_POWER=50
readonly LOW_POWER=20

function show_icon() {
    POWER=$(upower -d | awk "/${1}/" RS= | grep percentage | cut -d':' -f2 | xargs | cut -d'%' -f1)

    if [ $POWER -ge $HIGH_POWER ] ;
    then
        echo "%{F#00cc44}${2}"
    elif [ $POWER -le $MID_POWER ] && [ $POWER -gt $LOW_POWER ] ;
    then
        echo "%{F#ff9933}${2}"
    elif [ $POWER -le $LOW_POWER ] ;
    then
        echo "%{F#ff1a1a}${2}"
    fi
}

function is_device_connected() {
    upower -d | awk "/${1}/" | grep .
}

case $COMMAND in
    
    "--is_device_connected")
        is_device_connected $DEVICE
    ;;
    
    "--show_icon")
        show_icon $DEVICE $ICON
    ;;
    
    *)
        echo "No command specified."
        echo "Commands availaible"
        echo "--is_device_connected : return an exit code 0 if device connected or 1 if not"
        echo "--show_icon           : show the icon"
        exit 1
    ;;
esac

