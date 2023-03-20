#!/bin/bash
declare -A PACKAGES_MANAGER

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
USER=$(whoami)
PACKAGES=(
  "bspwm"
  "dunst"
  "gpicview"
  "kitty"
  "neofetch"
  "neovim"
  "picom"
  "polybar"
  "ranger"
  "rofi"
  "sxhkd"
)
PACKAGES_MANAGER=(
  [yum]="/etc/redhat-release;yum install"
  [pacman]="/etc/arch-release;pacman -Syy"
  [debian]="/etc/debian_version;apt install"
)

function backup_config() {
  echo "=> Backup $1 configuration"
  cp -R $1 $1.bck
}

function get_package_manager(){
  for os in ${!PACKAGES_MANAGER[@]}
  do
    if [[ -f $(echo ${PACKAGES_MANAGER[$os]} | cut -d ";" -f1) ]]
    then
      PACKAGE_MANAGER=$os
      PACKAGE_MANAGER_INSTALL_PHRASE=$(echo ${PACKAGES_MANAGER[$os]} | cut -d ";" -f2)
      return 0
    fi
  done
}

function config() {
    backup_config $3
    echo " => Installing $2 configuration"
    case $1 in       
      "--dir")
        mkdir -p $3
        cp -R $SCRIPT_DIR/$2/* $3/
      ;;
      "--file")
        cp $SCRIPT_DIR/$2 $3
      ;;
      *)
        echo "Bad option"
        exit 1
      ;;
    esac
  chown -R $USER $2
  echo " => Done"
}

function install_package() {
  packages=${PACKAGES[@]}
  get_package_manager
  read -p "Do you want to insall ($packages) with $PACKAGE_MANAGER ? [y/n] " -n 1 -r
  echo
  if [[ ! "$REPLY" =~ ^([Yy]| )$ ]]
  then
    [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1 
  fi
  $(sudo $PACKAGE_MANAGER_INSTALL_PHRASE $packages)
}

function install_configuration() {
  echo "----------------------"
  echo "Starting configuration"
  config --dir bspwm ~/.config/bspwm
  config --dir dunst ~/.config/dunst
  config --dir gpicview ~/.config/gpicview
  config --dir kitty ~/.config/kitty
  config --dir neofetch ~/.config/neofetch
  config --dir nvim ~/.config/nvim
  config --dir picom ~/.config/picom
  config --dir polybar ~/.config/polybar
  config --dir ranger ~/.config/ranger
  config --dir rofi ~/.config/rofi
  config --dir spotify-tui ~/.config/spotify-tui
  config --dir spotifyd ~/.config/spotifyd
  config --dir sxhkd ~/.config/sxhkd

  config --file .zshrc ~/.zshrc
  config --file .xinitrc ~/.xinitrc
  config --file .zprofile ~/.zprofile
  config --file betterlockscreenrc ~/.config/betterlockscreenrc

  echo "All done"
  echo "----------------------"
}

install_configuration
install_package
