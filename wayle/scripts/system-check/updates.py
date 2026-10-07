"""Package updates fetched and cached on disk plus the interactive updater all in stdlib only"""

import json
import os
import shutil
import subprocess
import sys
import termios
import tty
from collections.abc import Sequence
from datetime import datetime

from const import (
    AUR_HELPERS,
    Record,
    UPDATE_SOURCES,
    UPDATE_TIMEOUT_SECONDS,
    UPDATES_CACHE_FILE,
    UPDATES_CACHE_SECONDS,
)
from util import read_text, run


def parse_updates(manager: str, output: str) -> list[dict[str, str]]:
    """Parse the old versus new version lines into update records"""
    records: list[dict[str, str]] = []
    for line in output.splitlines():
        old_part, arrow, new_part = line.partition(" -> ")
        parts = old_part.split()
        if not arrow or len(parts) < 2:
            continue
        records.append({"manager": manager, "package": parts[0], "from": parts[-1], "to": new_part.strip()})
    return records


def _description_map(flags: str, names: Sequence[str]) -> dict[str, str]:
    """Grab Name and Description from one batched local pacman query leaving empty when it fails"""
    if not names:
        return {}
    ok, output = run(["pacman", flags, *names])
    if not ok:
        return {}
    descs: dict[str, str] = {}
    name = field = ""
    for line in output.splitlines():
        if line[:1].isspace():
            if field == "Description" and name:
                descs[name] = (descs[name] + " " + line.strip()).strip()
            continue
        key, sep, value = line.partition(":")
        if not sep:
            continue
        field = key.strip()
        if field == "Name":
            name = value.strip()
        elif field == "Description":
            descs[name] = value.strip()
    return descs


def attach_descriptions(records: list[dict[str, str]]) -> None:
    """Fill every record with what its package is for using only local databases"""
    pacman = sorted({r["package"] for r in records if r["manager"] == "PACMAN"})
    aur = sorted({r["package"] for r in records if r["manager"] == "AUR"})
    descs = _description_map("-Si", pacman) | _description_map("-Qi", aur)
    for record in records:
        record["desc"] = descs.get(record["package"], "")


def collect_updates() -> Record:
    """Pending updates with the fetch time while dead sources are listed as missing"""
    records: list[dict[str, str]] = []
    missing: list[str] = []
    for manager, command in UPDATE_SOURCES:
        ok, output = run(command, UPDATE_TIMEOUT_SECONDS)
        if ok:
            records.extend(parse_updates(manager, output))
        else:
            missing.append(manager)
    if records:
        attach_descriptions(records)
    return {"records": records, "missing": missing, "checked": datetime.now()}


def load_updates_cache() -> Record:
    """The cached update picture or None when the file is broken or absent"""
    try:
        raw = json.loads(read_text(str(UPDATES_CACHE_FILE)))
        return {
            "records": raw["records"],
            "missing": raw.get("missing", []),
            "checked": datetime.fromisoformat(raw["checked"]),
        }
    except (OSError, ValueError, KeyError, TypeError):
        return None


def save_updates_cache(data: Record) -> None:
    """Cache written through a temp file rename so readers never see a half write"""
    try:
        UPDATES_CACHE_FILE.parent.mkdir(parents=True, exist_ok=True)
        tmp = UPDATES_CACHE_FILE.with_suffix(".tmp")
        tmp.write_text(json.dumps({
            "records": data["records"], "missing": data["missing"],
            "checked": data["checked"].isoformat(),
        }))
        os.replace(tmp, UPDATES_CACHE_FILE)
    except OSError:
        pass


def freshen_updates() -> Record:
    """Cache while fresh and refetch when the age passes but a total wipeout is never cached"""
    cached = load_updates_cache()
    if cached is not None and (datetime.now() - cached["checked"]).total_seconds() < UPDATES_CACHE_SECONDS:
        return cached
    updates = collect_updates()
    if len(updates["missing"]) < len(UPDATE_SOURCES):
        save_updates_cache(updates)
    return updates


def run_interactive(command: Sequence[str]) -> None:
    """Run a command with the live terminal so sudo and pacman can prompt"""
    try:
        subprocess.run(command)
    except OSError as exc:
        print(f"{command[0]}: {exc}")


def wait_keypress() -> None:
    """Wait for a single raw keypress like the old shell pause"""
    try:
        fd = sys.stdin.fileno()
        saved = termios.tcgetattr(fd)
    except OSError:
        return
    try:
        tty.setraw(fd)
        sys.stdin.read(1)
    except OSError:
        pass
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, saved)


def run_updates() -> int:
    """The interactive updater running pacman through sudo then the AUR helper and flatpak needing a terminal"""
    if not (sys.stdin.isatty() and sys.stdout.isatty()):
        print("the updater needs a terminal (try it from kitty)", file=sys.stderr)
        return 1
    print("Updating Arch Linux system...")
    run_interactive(("sudo", "pacman", "-Syu"))
    helper = next((name for name in AUR_HELPERS if shutil.which(name)), "")
    if helper:
        print(f"Updating AUR packages... ({helper})")
        run_interactive((helper, "-Syu"))
    else:
        print("Missing AUR Helper. Try installing yay or paru")
    if shutil.which("flatpak"):
        print("Updating Flatpak packages...")
        run_interactive(("flatpak", "update", "-y"))
    print("Done with Arch & AUR updates. Press any key to continue...")
    wait_keypress()
    return 0
