#!/usr/bin/env bash

# Add this script to your wm startup file.

DIR="$HOME/.config/polybar"

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 0.1; done

# Launch the bar
polybar -q main -c "$DIR"/config.ini &

sleep 1

if pgrep -x "polybar" >/dev/null
then
    dunstify --appname="polybar" --urgency="LOW" "loaded at $(date +'%T')" -i /usr/share/icons/Tela-dark/scalable@3x/apps/starred.svg
else
    dunstify --appname="polybar" --urgency="CRITICAL" "Polybar not loaded" -i /usr/share/icons/Tela-dark/scalable@3x/apps/starred.svg
fi
