#!/bin/bash
# Restore the personalized system configs mirrored under ./etc/
#
# Intended for a FRESH install/rebuild. On an already-running machine, the file copies will OVERWRITE /etc — diff first if unsure
set -euo pipefail
cd "$(dirname "$(realpath "$0")")"

echo "[INFO] Copying etc/ mirror to / ..."
find etc -type f | while read -r f; do
    dst="/${f#etc/}"
    sudo mkdir -p "$(dirname "$dst")"
    sudo cp -f "$f" "$dst"
done

echo "[INFO] Reloading systemd and udev ..."
sudo systemctl daemon-reload
sudo udevadm control --reload

echo "[INFO] Enabling system services/timers ..."
for u in \
    NetworkManager.service avahi-daemon.service bluetooth.service \
    bluetooth-autoconnect.service cups.service earlyoom.service \
    epp-performance.service rngd.service seatd.service smartd.service \
    ufw.service reflector.timer fstrim.timer
do
    systemctl is-enabled "$u" &>/dev/null || sudo systemctl enable "$u"
    sudo systemctl start "$u" 2>/dev/null || echo "[WARN] $u start failed"
done

echo
echo "[INFO] Done. Manual follow-ups (fresh install):"
echo "  # bootloader/ly/mkinitcpio/grub steps are deliberately not scripted"
echo "  sudo pacman -S grub-btrfs snapper"
echo "  sudo systemctl enable --now grub-btrfsd snapper-timeline.timer snapper-cleanup.timer"
echo "  # + capture snapper configs back into etc/snapper/ once created"
