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

if ! pacman -Qi base-devel &>/dev/null; then
    echo "[INFO] Installing base-devel (required for yay and AUR builds)..."
    sudo pacman -S --needed --noconfirm base-devel
fi

if ! command -v yay &> /dev/null; then
    echo "[INFO] yay not found, installing..."
    sudo pacman -S go
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    (cd /tmp/yay && makepkg -si --noconfirm)
fi

if [ -f pacman.txt ]; then
    echo "[INFO] Installing pacman packages from pacman.txt..."
    sudo pacman -Syu --noconfirm --needed $(grep -vE '^[ \t]*#' pacman.txt | xargs)
else
    echo "[WARN] pacman.txt not found, skipping pacman packages."
fi

if [ -f yay.txt ]; then
    echo "[INFO] Installing AUR packages from yay.txt..."
    yay -S --needed --noconfirm $(grep -vE '^[ \t]*#' yay.txt | xargs)
else
    echo "[WARN] yay.txt not found, skipping AUR packages."
fi

echo "[INFO] All packages installed."

echo "[INFO] Copying configuration files..."

copy_config() {
    local src=$1
    local dest=$2

    rm -rf "$dest"
    cp -rf "$src" "$dest"
    echo "[INFO] Copy $src to $dest"
}

CONFIG_DIRS=(
    clipse
    MangoHud
    gpicview
    hypr
    hyprpanel
    kitty
    lsfg-vk
    nvim
    ranger
    rofi
    systemd
    waybar
    wireplumber
    xdg-desktop-portal
)

for dir in "${CONFIG_DIRS[@]}"; do
    copy_config "$dir" "$HOME/.config/$dir"
done

mkdir -p "$HOME/.local/share/fonts"
cp -rf fonts/* "$HOME/.local/share/fonts/"
fc-cache -fv

sudo cp -f pipewire.conf.d/samplerate.conf /etc/pipewire/pipewire.conf.d

cp -f .zshrc "$HOME/.zshrc"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

echo "[INFO] Done!"