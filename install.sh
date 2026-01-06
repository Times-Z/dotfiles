#!/bin/bash
set -e

pacman_safe() {
    set +e
    sudo pacman "$@"
    local status=$?
    set -e
    return $status
}

yay_safe() {
    set +e
    yay "$@"
    local status=$?
    set -e
    return $status
}

REPO_URL="https://github.com/Times-Z/dotfiles.git"
REPO_NAME="dotfiles"

if [[ "${BASH_SOURCE[0]}" != "$0" || ! -f "$(dirname "${BASH_SOURCE[0]}")/pacman.txt" ]]; then
    echo "[INFO] Bootstrapping from remote..."
    
    TMPDIR=$(mktemp -d)
    
    if ! command -v git &> /dev/null; then
        sudo pacman -S --needed git
    fi
    
    git clone --depth=1 "$REPO_URL" "$TMPDIR/$REPO_NAME"
    exec bash "$TMPDIR/$REPO_NAME/install.sh" "$@"
    exit 0
fi

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

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
    echo "[INFO] Installing pacman packages..."
    
    PKGS=$(grep -vE '^[ \t]*#' pacman.txt | xargs)
    
    pacman_safe -Sy --needed --noconfirm $PKGS || {
        echo
        echo "[WARN] Conflicts detected. Switching to interactive mode..."
        pacman_safe -Syu --needed $PKGS
    }
else
    echo "[WARN] pacman.txt not found."
fi

if [ -f yay.txt ]; then
    echo "[INFO] Installing AUR packages..."
    
    YAY_PKGS=$(grep -vE '^[ \t]*#' yay.txt | xargs)
    
    yay_safe -Sy --needed --noconfirm $YAY_PKGS || {
        echo
        echo "[WARN] AUR conflicts detected. Switching to interactive mode..."
        yay_safe -S --needed $YAY_PKGS
    }
else
    echo "[WARN] yay.txt not found."
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