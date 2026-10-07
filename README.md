# Dotfiles

Personal configuration for my Arch Linux environment.

## Install

### Get the archinstall json pre-configuration
```bash
curl -o /tmp/user_configuration.json https://raw.githubusercontent.com/Times-Z/dotfiles/refs/heads/main/user_configuration.json
```

### Use arch install pre-configuration json
Just user and disk to configure

```bash
archinstall --config /tmp/user_configuration.json
```

### Install dotfiles
```bash
curl -fsSL https://raw.githubusercontent.com/Times-Z/dotfiles/main/install.sh | bash -s --
```

## System Overview

- **OS:** Arch Linux
- **WM:** Hyprland (Wayland)
- **Shell:** zsh
- **Terminal:** kitty

## Screenshots

### Terminal
![Terminal](.assets/terminal.png)

### Fuzzel
![fuzzel](.assets/fuzzel.png)

### Wayle (with notifications)
![wayle bar](.assets/bar.jpg)

![Notifications](.assets/notifications.jpg)

![Notifications](.assets/notifications_panel.jpg)

#### Wayle system check custom module
![sys check](.assets/system_check_module.png)
![sys check](.assets/sys_check1.png)
![sys check](.assets/sys_check2.png)
![sys check](.assets/sys_check3.png)
![sys check](.assets/sys_check4.png)

### Clipboard
![Clipboard](.assets/clipboard.jpg)

### Lockscreen
![Lockscreen](.assets/lockscreen.jpg)

## System configs (etc/)

Personalized system files are mirrored under [`etc/`](etc/) and restored with `sudo ./install_system.sh` (fresh-install oriented — overwrites `/etc`)