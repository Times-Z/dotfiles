#!/bin/sh

userresources=$HOME/.Xresources
usermodmap=$HOME/.Xmodmap
sysresources=/etc/X11/xinit/.Xresources
sysmodmap=/etc/X11/xinit/.Xmodmap

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

xsetroot -cursor_name left_ptr
xrandr --dpi 96 --output DisplayPort-0 --primary --mode 3440x1440 --pos 1440x1248 --rotate normal --rate 100.00 --output DisplayPort-1 --mode 3440x1440 --pos 0x0 --rotate right --rate 100.00 --output DisplayPort-2 --off --output HDMI-A-0 --off

exec bspwm >> $HOME/.bspwn.log 2>&1
