#!/usr/bin/bash

# Add this script to your wm startup file.

DIR="$HOME/.config/polybar"

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 0.1; done

if [ ! -z "$LAPTOP" ] ;
then
    polybar -q main-laptop -c "$DIR/config.ini" &
else
    polybar -q main -c "$DIR/config.ini" &
fi

sleep 1

if pgrep -x "polybar" >/dev/null
then
    dunstify --appname="polybar" --urgency="LOW" "Polybar loaded at $(date +'%T')"
else
    dunstify --appname="polybar" --urgency="CRITICAL" "Polybar not loaded"
fi
