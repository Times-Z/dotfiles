#!/bin/sh

items=(1 "BSPWM"
       2 "Hyprland"
       3 "poweroff"
     )

if [ -z "${DISPLAY}" ] && [ "${XDG_VTNR}" -eq 1 ]; then
  while choice=$(dialog --title "$TITLE" --no-cancel \
                 --menu "Please select a WM" 10 40 3 "${items[@]}" \
                 2>&1 >/dev/tty)
  do
    case $choice in
      1) startx >> /var/log/xorg.log ;;
      2) Hyprland >> /var/log/Hyprland.log ;;
      3) poweroff ;;
      *) ;;
    esac
  done
fi
