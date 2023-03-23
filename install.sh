#!/bin/bash

declare -A PACKAGES_MANAGER
declare -A OS_PACKAGES
declare -A SHELL_FILE

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
USER=$(whoami)

SHELL_FILE=(
  [zsh]=~/.zshrc
  [bash]=~/.bashrc
)
OS_PACKAGES=(
  [pacman]="bspwm dunst gpicview git kitty neofetch neovim picom polybar ranger rofi sxhkd zsh"
  [debian]="bspwm dunst gpicview git kitty neofetch neovim picom polybar ranger rofi sxhkd zsh"
)
PACKAGES_MANAGER=(
  [pacman]="/etc/arch-release;pacman -Syy"
  [debian]="/etc/debian_version;apt-get install -y"
)
NVIM_LSP_YARN_PACKAGES=(
  "ansible-language-server"
  "awk-language-server"
  "bash-language-server"
  "cssmodules-language-server"
  "@cucumber/language-server"
  "dockerfile-language-server-nodejs"
  "emmet-ls"
  "intelephense"
  "yaml-language-server"
  "vscode-langservers-extracted" 
)
NVIM_LSP_PYTHON_PACKAGES=(
  "python-lsp-server"
  "pyright"
  "pyre-check"
)
FONTS=(
  "https://github.com/adam7/delugia-code/releases/download/v2111.01.2/delugia-complete.zip"
  "https://github.com/googlefonts/noto-emoji/archive/refs/tags/v2.038.zip"
  "https://github.com/FortAwesome/Font-Awesome/releases/download/6.3.0/fontawesome-free-6.3.0-web.zip"
  "https://github.com/zavoloklom/material-design-iconic-font/releases/download/2.2.0/material-design-iconic-font.zip"
  "https://github.com/ryanoasis/nerd-fonts/releases/download/v2.3.3/Hack.zip"
)

function install_path(){
  mkdir -p ~/{.local,.local/bin}
  PATH=$PATH:~/.local/bin
  file=${SHELL_FILE[$(echo $SHELL | rev | cut -d'/' -f1 | rev)]}
  echo 'PATH="${PATH}:~/.local/bin"; export PATH;' >> $file
}

function get_package_manager(){
  for os in ${!PACKAGES_MANAGER[@]}
  do
    if [[ -f $(echo ${PACKAGES_MANAGER[$os]} | cut -d ";" -f1) ]]
    then
      OS=$os
      PACKAGE_MANAGER_INSTALL_PHRASE=$(echo ${PACKAGES_MANAGER[$os]} | cut -d ";" -f2)
      return 0
    fi
  done
}

function config() {
  if [ -d $3 ]
  then
    cp -R $3 $3.bck
  fi

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
}

function install_node_packages() {
  packages=${NVIM_LSP_YARN_PACKAGES[@]}
  get_package_manager

  read -p "Do you want to insall ($packages) with yarn ? [y/n] " -n 1 -r
  echo
  if [[ ! "$REPLY" =~ ^([Yy]| )$ ]]
  then
    [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1 
  fi

  if [[ -z $(which yarn) ]]
  then

    if [ $OS == "debian" ]
    then
      if [[ -z $(which nodejs) ]]
      then
        curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
        sudo $PACKAGE_MANAGER_INSTALL_PHRASE nodejs
        sudo npm install -g yarn
      fi
    else
      sudo $PACKAGE_MANAGER_INSTALL_PHRASE yarn
    fi

    echo
  fi

  echo
  yarn global add node-gyp
  echo
  yarn global add $packages
  echo
}

function install_python_packages() {
  packages=${NVIM_LSP_PYTHON_PACKAGES[@]}
  get_package_manager

  read -p "Do you want to install ($packages) with pip ? [y/n]" -n 1 -r
  echo
  if [[ ! "$REPLY" =~ ^([Yy]| )$ ]]
  then
    [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1 
  fi

  if [[ -z $(which pip) ]]
  then
    if [ $OS == "debian" ]
    then
      pip_package="python3-pip"
    else
      pip_package="python-pip"
    fi

    sudo $PACKAGE_MANAGER_INSTALL_PHRASE $pip_package
    echo
  fi

  python3 -m pip install $packages
  echo
}

function install_os_packages() {
  get_package_manager
  packages=${OS_PACKAGES[$OS]}

  read -p "Do you want to insall ($packages) ? [y/n] " -n 1 -r
  echo
  if [[ ! "$REPLY" =~ ^([Yy]| )$ ]]
  then
    [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1 
  fi

  sudo $PACKAGE_MANAGER_INSTALL_PHRASE curl make gcc g++ 
  sudo $PACKAGE_MANAGER_INSTALL_PHRASE $packages
  RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  echo
}

function install_fonts() {
  mkdir /tmp/ttf
  mkdir -p ~/.local/share/fonts

  for font_url in ${FONTS[@]}
  do
    archive_name=$(echo $font_url | rev | cut -d"/" -f1 | rev)
    echo $font_url
    curl -L -o /tmp/$archive_name $font_url
    unzip /tmp/$archive_name "*.ttf" -d /tmp/ttf
  done

  curl -o /tmp/ttf/icomoon-feather.ttf https://github.com/khanhas/dotfiles/raw/master/polybar/fonts/icomoon-feather.ttf

  cp -R /tmp/ttf ~/.local/share/fonts
  rm -r /tmp/ttf
  rm /tmp/*.zip
  fc-cache -f -v
}

function install_config_files() {
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

  cp $SCRIPT_DIR/scripts/* ~/.local/bin
}

install_path
install_config_files
install_os_packages
install_node_packages
install_python_packages
install_fonts

