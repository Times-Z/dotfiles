#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
USER=$(whoami)

function backup_config() {
    echo "=> Backup $1 configuration"
    cp -R $1 $1.bck
}

function install() {
    backup_config $3
    echo " => Installing $2 configuration"
    case $1 in
        
        "--dir")
            cp -R $SCRIPT_DIR/$2/* $3
            echo "dir mode"
        ;;
        
        "--file")
            cp $SCRIPT_DIR/$2 $3
            echo "file mode"
        ;;
        
        *)
            echo "Bad option"
            exit 1
        ;;
    esac
    
    chown -R $USER $2
    echo " => Done"
}


echo "----------------------"
echo "Starting configuration"

install --dir bspwm ~/.config/bspwm
install --dir dunst ~/.config/dunst
install --dir gpicview ~/.config/gpicview
install --dir kitty ~/.config/kitty
install --dir neofetch ~/.config/neofetch
install --dir nvim ~/.config/nvim/lua/custom
install --dir picom ~/.config/picom
install --dir polybar ~/.config/polybar
install --dir ranger ~/.config/ranger
install --dir rofi ~/.config/rofi
install --dir spotify-tui ~/.config/spotify-tui
install --dir spotifyd ~/.config/spotifyd
install --dir sxhkd ~/.config/sxhkd

install --file .zshrc ~/.zshrc
install --file .xinitrc ~/.xinitrc
install --file .zprofile ~/.zprofile
install --file betterlockscreenrc ~/.config/betterlockscreenrc

echo "All done"
echo "----------------------"
