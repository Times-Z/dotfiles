#!/bin/sh

readonly CMD=$1

readonly VPN_PATH=~/Documents/scripts/.vpn
readonly COLOR_OFF="%{F#66ffffff}"
readonly ICON_OFF=""
readonly COLOR_ON="%{F#61C766}"
readonly ICON_ON=""

function show_icon() {
    openvpn=$(pgrep -a openvpn | head -n 1 | awk '{print $NF }' | rev | cut -d '/' -f 1 | rev)
    openfortivpn=$(pgrep -a openfortivpn | head -n 1 | awk '{print $NF }' | rev | cut -d '/' -f 1 | rev)
    
    if [ -n "$openvpn" ]; then
        echo $COLOR_ON$ICON_ON $openvpn
    elif [ -n "$openfortivpn" ] ; then
        echo $COLOR_ON$ICON_ON
    else
        echo $COLOR_OFF$ICON_OFF
    fi
}

function kill_vpn_gui {
    cmd=(
        yad
        --undecorated --fixed --close-on-unfocus --borders=0
        --button="Kill VPN"
        --posx="2030" --posy="35"
    )
    "${cmd[@]}"
    exval=$?
}

function toggle() {

    openvpn=$(pgrep -a openvpn)
    openfortivpn=$(pgrep -a openfortivpn)

    if [ -n "$openvpn" ] ; then

        kill_vpn_gui
        case $exval in
            0) pgrep openvpn | pkexec xargs kill;;
        esac

    elif [ -n "$openfortivpn" ] ; then

        kill_vpn_gui
        case $exval in
            0) pgrep openfortivpn | pkexec xargs kill;;
        esac

    else

        file=$(cd $VPN_PATH && yad --file)
        extension="${file##*.}"

        case $extension in
            "ovpn")
                options="$file"
                if [ "$file" == "$VPN_PATH/perso/home.ovpn" ]
                then
                    options="--askpass $VPN_PATH/perso/.home.cred --config $file"
                fi
                pkexec openvpn $options
            ;;
            "conf")
                pkexec openfortivpn -c $file
            ;;
        esac
    fi

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
        echo "--toggle                   Toggle vpn on/off"
        echo "--show                     Show icons"
        exit 0
    ;;
    
esac