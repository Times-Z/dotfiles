#!/usr/bin/env python3

import json
import subprocess


def run(cmd: str) -> str:
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=30)
        return result.stdout.strip()
    except subprocess.TimeoutExpired:
        return ""


def count_lines(text: str) -> int:
    return sum(1 for line in text.splitlines() if line.strip())


def format_rows(section_name: str, data: str) -> str:
    lines = [section_name]
    rows = [l for l in data.splitlines() if l.strip()]

    if not rows:
        lines.append("none\n")
        return "\n".join(lines)

    for row in rows:
        parts = row.split(" -> ", 1)
        left = parts[0].split()
        pkg = left[0] if left else "?"
        oldv = left[-1] if len(left) > 1 else "?"
        newv = parts[1].strip() if len(parts) > 1 else "?"
        lines.append(f"{pkg} {oldv} to {newv}")

    lines.append("")
    return "\n".join(lines)


def main() -> None:
    pacman_updates = run("checkupdates 2>/dev/null || true")
    aur_updates = run("yay -Qua 2>/dev/null || true")

    pacman_count = count_lines(pacman_updates)
    aur_count = count_lines(aur_updates)
    total_count = pacman_count + aur_count

    pacman_rows = format_rows("PACMAN", pacman_updates)
    aur_rows = format_rows("AUR", aur_updates)

    tooltip = (
        f"Pacman : {pacman_count} | Aur : {aur_count}\n\n"
        f"{pacman_rows}\n"
        "----------------\n"
        f"{aur_rows}"
    )

    print(json.dumps({"text": str(total_count), "tooltip": tooltip}))


if __name__ == "__main__":
    main()
