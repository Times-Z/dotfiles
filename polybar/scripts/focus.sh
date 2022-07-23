#!/usr/bin/bash
#
# Script to toggle brightness of a screen to 0 or 1
#
# Author : https://github.com/Crash-Zeus


readonly command=$1
readonly SCREEN="DisplayPort-1"

function get_current_brightness {
    current_brightness=$(xrandr --verbose |grep $SCREEN -A 5 | awk '/Brightness/ { print $2 }')
}

function toggle_brightness {
    get_current_brightness
    
    if [ "$current_brightness" == "0.0" ] ; then
        value="1"
    elif [ "$current_brightness" == "1.0" ] ; then
        value="0"
    else
        value="1"
    fi
    
    xrandr --output $SCREEN --brightness $value
}

case $command in
    
    "--toggle")
        toggle_brightness
    ;;
    
    "--get-current")
        get_current_brightness

        if [ "$current_brightness" == "0.0" ] ; then
            icon="%{F#4DD0E1}"
        elif [ "$current_brightness" == "1.0" ] ; then
            icon="%{F#4DD0E1}"
        else
            icon="%{F#4DD0E1}"
        fi
        echo $icon
    ;;
    
    *)
        echo "No command specified."
        echo ""
        echo "Available commands :"
        echo "--toggle                   Toggle brightness from 1 to 0 or from 0 to 1"
        echo "--get-current              Get current brightness of the screen and set an icon"
        exit 0
    ;;
esac

