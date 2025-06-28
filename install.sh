#!/bin/bash

set -e

if ! command -v yay &> /dev/null; then
    echo "yay not found, installing..."
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    (cd /tmp/yay && makepkg -si)
fi

if [ -f pacman.txt ]; then
    echo "[INFO] Installing pacman packages from pacman.txt..."
    sudo pacman -Syu --needed $(grep -vE '^\s*#' pacman.txt | xargs)
else
    echo "[WARN] pacman.txt not found, skipping pacman packages."
fi

if [ -f yay.txt ]; then
    echo "[INFO] Installing AUR packages from yay.txt..."
    yay -S --needed $(grep -vE '^\s*#' yay.txt | xargs)
else
    echo "[WARN] yay.txt not found, skipping AUR packages."
fi

echo "[INFO] All packages installed."

echo "[INFO] Copying configuration files..."

cp -r dunst ~/.config/
cp -r fonts/* ~/.local/share/fonts/ && fc-cache -fv
cp -r gpicview ~/.config/
cp -r kitty ~/.config/
cp -r neovim ~/.config/
sudo cp pipewire.conf.d/samplerate.conf /etc/pipewire/pipewire.conf.d
cp -r ranger ~/.config/
cp -r rofi ~/.config/
cp -r waybar ~/.config/
cp .zshrc ~/.zshrc
cp greenclip.toml ~/.config/greenclip.toml

echo "[INFO] Done!"