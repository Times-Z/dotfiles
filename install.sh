#!/bin/bash

set -e

REPO_URL="https://github.com/Times-Z/dotfiles.git"
REPO_NAME="dotfiles"

if [ ! -f "install.sh" ]; then
    if ! command -v git &> /dev/null; then
        echo "[INFO] git not found, installing..."
        sudo pacman -S git
    fi
    echo "[INFO] Launching installation script from remote repository..."
    TMPDIR=$(mktemp -d)
    git clone --depth=1 "$REPO_URL" "$TMPDIR/$REPO_NAME"
    cd "$TMPDIR/$REPO_NAME"
    exec bash install.sh "$@"
    exit 0
fi

if ! command -v yay &> /dev/null; then
    echo "[INFO] yay not found, installing..."
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    (cd /tmp/yay && makepkg -si)
fi

if [ -f pacman.txt ]; then
    echo "[INFO] Installing pacman packages from pacman.txt..."
    sudo pacman -Syu --needed $(grep -vE '^[ \t]*#' pacman.txt | xargs)
else
    echo "[WARN] pacman.txt not found, skipping pacman packages."
fi

if [ -f yay.txt ]; then
    echo "[INFO] Installing AUR packages from yay.txt..."
    yay -S --needed $(grep -vE '^[ \t]*#' yay.txt | xargs)
else
    echo "[WARN] yay.txt not found, skipping AUR packages."
fi

echo "[INFO] All packages installed."

echo "[INFO] Copying configuration files..."

cp -r dunst ~/.config/
cp -r fonts/* ~/.local/share/fonts/ && fc-cache -fv
cp -r gpicview ~/.config/
cp -r kitty ~/.config/
cp -r nvim ~/.config/neovim
sudo cp pipewire.conf.d/samplerate.conf /etc/pipewire/pipewire.conf.d
cp -r ranger ~/.config/
cp -r rofi ~/.config/
cp -r waybar ~/.config/
cp .zshrc ~/.zshrc
cp greenclip.toml ~/.config/greenclip.toml

echo "[INFO] Done!"