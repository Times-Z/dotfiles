#!/bin/bash

declare -A PACKAGES_MANAGER
declare -A OS_PACKAGES
declare -A SHELL_FILE

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
USER=$(whoami)

SHELL_FILE=(
  [zsh]=$HOME/.zshrc
  [bash]=$HOME/.bashrc
)
OS_PACKAGES=(
  [arch]="bspwm curl dunst exa feh gpicview git kitty neofetch neovim picom polybar ranger rofi sxhkd yad zsh"
  [debian]="bspwm curl dunst exa feh fuse gpicview git kitty neofetch polybar ranger rofi sxhkd yad zsh"
)
PACKAGES_MANAGER=(
  [arch]="/etc/arch-release;pacman -Syy"
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
)

function install_path {
  mkdir -p ~/{.local,.local/bin,.local/share,.local/share/fonts}
  PATH=$PATH:~/.local/bin
  file=${SHELL_FILE[$(echo $SHELL | rev | cut -d'/' -f1 | rev)]}
  export PATH
  echo 'PATH="${PATH}:~/.local/bin"; export PATH;' >> $file
}

function get_package_manager {
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

function config {
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

function install_node_packages {
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

function install_python_packages {
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

function install_os_packages {
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
  current_path=$(pwd)
  cd ~ && RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
  

  if [ "$(cat /etc/os-release | grep deb)" != "" ]
  then
    # force install neovim 0.9 on debian based distro
    curl -LO https://github.com/neovim/neovim/releases/download/v0.9.0/nvim.appimage
    chmod u+x nvim.appimage
    sudo mv nvim.appimage /usr/bin/nvim

    # picom install latest version from sources
    sudo $PACKAGE_MANAGER_INSTALL_PHRASE autoconf \
      gcc \
      make \
      pkg-config \
      libxext-dev \
      libxcb1-dev \
      libxcb-damage0-dev \
      libxcb-dpms0-dev \
      libxcb-xfixes0-dev \
      libxcb-shape0-dev \
      libxcb-render-util0-dev \
      libxcb-render0-dev \
      libxcb-randr0-dev \
      libxcb-composite0-dev \
      libxcb-image0-dev \
      libxcb-present-dev \
      libxcb-glx0-dev \
      libpixman-1-dev \
      libdbus-1-dev \
      libconfig-dev \
      libgl-dev \
      libegl-dev \
      libpcre2-dev \
      libevdev-dev \
      uthash-dev \
      libev-dev \
      libx11-xcb-dev \
      libpam0g-dev \
      libcairo2-dev \
      libfontconfig1-dev \
      libxcb-xkb-dev \
      libxcb-xinerama0-dev \
      libxcb-util-dev \
      libxcb-xrm-dev \
      libxkbcommon-dev \
      libxkbcommon-x11-dev \
      libjpeg-dev \
      meson

    cd /tmp
    git clone https://github.com/yshui/picom.git
    cd picom
    git submodule update --init --recursive
    meson setup --buildtype=release . build
    ninja -C build
    sudo ninja -C build install

    # install pokemon color script
    cd /tmp
    git clone https://gitlab.com/phoneybadger/pokemon-colorscripts.git
    cd pokemon-colorscripts
    sudo ./install.sh

    # Install betterlockscreen & i3lock color
    cd /tmp
    wget https://github.com/betterlockscreen/betterlockscreen/archive/refs/heads/main.zip
    unzip main.zip
    cd betterlockscreen-main/
    chmod u+x betterlockscreen
    sudo cp betterlockscreen /usr/local/bin/
    sudo cp system/betterlockscreen@.service /usr/lib/systemd/system/
    systemctl enable betterlockscreen@$USER

    cd /tmp
    git clone https://github.com/Raymo111/i3lock-color.git
    cd i3lock-color
    ./install-i3lock-color.sh

    cd /tmp
    wget https://github.com/erebe/greenclip/releases/download/v4.2/greenclip
    chmod +x greenclip
    sudo mv greenclip /usr/bin/greenclip

  else
    sudo $PACKAGE_MANAGER_INSTALL_PHRASE --needed git base-devel 
    cd /tmp
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si

    yay -S betterlockscreen \
      pokemon-colorscripts-git \
      rofi-greenclip
  fi

  cd $current_path
  echo
}

function install_fonts {
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

function install_config_files {
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
  config --dir pipewire ~/.config/pipewire

  config --file .zshrc ~/.zshrc
  config --file .xinitrc ~/.xinitrc
  config --file .zprofile ~/.zprofile
  config --file betterlockscreenrc ~/.config/betterlockscreenrc
  config --file greenclip.toml ~/.config/greenclip.toml

  cp $SCRIPT_DIR/scripts/* ~/.local/bin
  cp $SCRIPT_DIR/fonts/* ~/.local/share/fonts
}

install_path
install_os_packages
install_node_packages
install_python_packages
install_fonts
install_config_files

curl -Lo ~/Pictures/wallpaper.png https://lh3.googleusercontent.com/u/0/drive-viewer/AFGJ81pkL30f1wyCsEgmk6G9dGUQ9xyIIu5W_hhfQQhNOufbZMtoELupCCuzEhwvasKuKemvS8qDnHPoTt5DTqU-SZ_OelaE=w1835-h1275
cd ~/Pictures && wallpaper wallpaper.png
betterlockscreen -u ~/Pictures/wallpaper.png

echo
echo
echo
read -p "Do you want to reboot ? [y/n] " -n 1 -r
echo
if [[ "$REPLY" =~ ^([Yy]| )$ ]]
then
  reboot
fi