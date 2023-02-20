#!/bin/sh

userresources=$HOME/.Xresources
usermodmap=$HOME/.Xmodmap
sysresources=/etc/X11/xinit/.Xresources
sysmodmap=/etc/X11/xinit/.Xmodmap
LAPTOP=false

# merge in defaults and keymaps

if [ -f $sysresources ]; then
    xrdb -merge $sysresources
fi

if [ -f $sysmodmap ]; then
    xmodmap $sysmodmap
fi

if [ -f "$userresources" ]; then
    xrdb -merge "$userresources"
fi

if [ -f "$usermodmap" ]; then
    xmodmap "$usermodmap"
fi

# start some nice programs

if [ -d /etc/X11/xinit/xinitrc.d ]; then
    for f in /etc/X11/xinit/xinitrc.d/*; do
        [ -x "$f" ] && . "$f"
    done
    unset f
fi

if [ ! -z "$(upower -d | grep BAT)" ]
then
    LAPTOP=true
fi

export NOTIFICATION_SOUND="$HOME/.config/dunst/notif.mp3"
export LAPTOP=$LAPTOP

xsetroot -cursor_name left_ptr
setxkbmap fr
sxhkd &
slimbookbattery --minimize &
xhost +local:root

exec bspwm >> $HOME/.bspwn.log 2>&1
