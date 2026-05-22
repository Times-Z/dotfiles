hl.on("hyprland.start", function()
    -- Environment setup
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP SSH_AUTH_SOCK")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP SSH_AUTH_SOCK")
    hl.exec_cmd("~/.config/hypr/scripts/reset-portals")

    -- Authentication & Security
    hl.exec_cmd("sh -lc 'eval $(/usr/bin/gnome-keyring-daemon --start --components=secrets,ssh); export SSH_AUTH_SOCK'")
    hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")

    -- Core services
    hl.exec_cmd("wayle panel start")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("clipse -listen")

    -- Hardware & Display
    hl.exec_cmd("dispwin -I ~/Documents/samsung_g9_oled.icm")
    hl.exec_cmd("streamcontroller -b")
    hl.exec_cmd("/usr/bin/openrgb -p totally_off --server --startminimized")
end)
