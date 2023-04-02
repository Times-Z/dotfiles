#!/bin/sh

openvpn=$(pgrep -a openvpn | head -n 1 | awk '{print $NF }' | rev | cut -d '/' -f 1 | rev)
openfortivpn=$(pgrep -a openfortivpn | head -n 1 | awk '{print $NF }' | rev | cut -d '/' -f 1 | rev)

if [ -n "$openvpn" ]; then
    echo "%{F#61C766}"
elif [ -n "$openfortivpn" ] ; then
    echo "%{F#42A5F5}"
else
    echo "%{F#66ffffff}"
fi