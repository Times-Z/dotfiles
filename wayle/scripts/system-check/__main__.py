#!/usr/bin/env python3
"""The check module for the wayle bar

Bar mode prints a single JSON line where the icon shows health
the label counts pending package updates and the tooltip lists what
is wrong across systemd units services jobs clock scrubs disks and
zombies all without root

The tui flag opens the full screen dashboard with tables filtering
and journal logs while the run updates flag performs the interactive
system update through sudo pacman the AUR helper and flatpak

Update checks ride a small disk cache so the fast bar poll never
waits on the network and bar mode never imports rich or textual"""

import sys

if "--tui" in sys.argv[1:]:
    try:
        from tui import run_tui
    except ImportError:
        sys.exit("the dashboard needs rich and textual: python -m pip install textual")
    sys.exit(run_tui())
if "--run-updates" in sys.argv[1:]:
    from updates import run_updates
    sys.exit(run_updates())

from bar import main

main()
