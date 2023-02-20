#!/bin/bash

LOW_BAT=20           # lesser than this is considered low battery
ICON_PATH="/usr/share/icons/Tela-circle-black-dark/symbolic/status/battery-empty-symbolic.svg"
ALREADY_NOTIFY=false

# If BAT0 doesn't work for you, check available devices with command below
#
#   $ ls -1 /sys/class/power_supply/
#
BAT_PATH=/sys/class/power_supply/BAT0

while true
do
	BAT_LEVEL=$(cat "$BAT_PATH/capacity")

	if [ $BAT_LEVEL -lt $LOW_BAT ]
	then
		if [ $ALREADY_NOTIFY = false ]
		then
			ALREADY_NOTIFY=true
			dunstify --appname="battery" "Battery low" --urgency="critical" -i $ICON_PATH
			paplay $NOTIFICATION_SOUND 
		fi
	else
		if [ $ALREADY_NOTIFY = true ]
		then
			ALREADY_NOTIFY=false
		fi
	fi
done
