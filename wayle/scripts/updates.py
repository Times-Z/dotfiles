#!/usr/bin/env python3

import json
import subprocess
from collections.abc import Sequence


COMMAND_TIMEOUT_SECONDS = 30
PACMAN_COMMAND = ("checkupdates",)
AUR_COMMAND = ("yay", "-Qua")
PACKAGE_MAX_LENGTH = 20
VERSION_MAX_LENGTH = 24


def run(command: Sequence[str]) -> str:
    try:
        result = subprocess.run(
            command,
            capture_output=True,
            check=False,
            text=True,
            timeout=COMMAND_TIMEOUT_SECONDS,
        )
    except (OSError, subprocess.TimeoutExpired):
        return ""
    return result.stdout.strip()


def count_lines(text: str) -> int:
    return sum(1 for line in text.splitlines() if line.strip())


def parse_rows(manager: str, data: str) -> list[tuple[str, str, str, str]]:
    packages: list[tuple[str, str, str, str]] = []
    for line in data.splitlines():
        if not line.strip():
            continue

        previous, separator, current = line.partition(" -> ")
        left = previous.split()
        pkg = left[0] if left else "?"
        oldv = left[-1] if len(left) > 1 else "?"
        newv = current.strip() if separator else "?"
        packages.append((manager, pkg, oldv, newv))
    return packages


def shorten(value: str, max_length: int) -> str:
    if max_length < 4:
        raise ValueError("max_length must be at least 4")
    if len(value) <= max_length:
        return value
    return value[: max_length - 3] + "..."


def format_table(
    pacman_data: str,
    aur_data: str,
    pacman_count: int,
    aur_count: int,
    total_count: int,
) -> str:
    source_rows = parse_rows("PACMAN", pacman_data) + parse_rows("AUR", aur_data)
    rows = [
        (
            manager,
            shorten(package, PACKAGE_MAX_LENGTH),
            shorten(f"{oldv} -> {newv}", VERSION_MAX_LENGTH),
        )
        for manager, package, oldv, newv in source_rows
    ]
    if not rows:
        rows = [("-", "No updates", "-")]

    headers = ("MANAGER", "PACKAGE", "VERSION")
    widths = [
        max(len(headers[index]), *(len(row[index]) for row in rows))
        for index in range(len(headers))
    ]
    separator = "-+-".join("-" * width for width in widths)

    lines = [
        " | ".join(header.ljust(width) for header, width in zip(headers, widths)),
        separator,
    ]
    lines.extend(" | ".join(value.ljust(width) for value, width in zip(row, widths)) for row in rows)
    lines.append(separator)
    lines.extend(
        [
            "",
            f"PACMAN: {pacman_count}",
            f"AUR: {aur_count}",
            f"TOTAL: {total_count}",
        ]
    )
    return "\n".join(lines)


def main() -> None:
    pacman_updates = run(PACMAN_COMMAND)
    aur_updates = run(AUR_COMMAND)

    pacman_count = count_lines(pacman_updates)
    aur_count = count_lines(aur_updates)
    total_count = pacman_count + aur_count

    tooltip = format_table(
        pacman_updates,
        aur_updates,
        pacman_count,
        aur_count,
        total_count,
    )

    print(json.dumps({"text": str(total_count), "tooltip": tooltip}))


if __name__ == "__main__":
    main()
