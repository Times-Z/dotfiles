"""Small shared helpers for commands systemctl text ages and tooltips"""

import json
import os
import subprocess
from collections.abc import Sequence
from datetime import datetime
from pathlib import Path

from const import (
    ALT_ALERT,
    ALT_OK,
    Alt,
    COMMAND_TIMEOUT_SECONDS,
    Row,
    STATUS_CRIT,
    STATUS_OK,
    STATUS_WARN,
    Status,
)


def run(command: Sequence[str], timeout: int = COMMAND_TIMEOUT_SECONDS) -> tuple[bool, str]:
    """Run a command capturing stdout and reporting any failure as an empty result"""
    try:
        result = subprocess.run(
            command, capture_output=True, check=False, text=True, timeout=timeout,
        )
    except (OSError, subprocess.TimeoutExpired):
        return False, ""
    return result.returncode == 0, result.stdout.strip()


def read_text(path: str) -> str:
    """Read a file or an empty string since psutil cannot see mount options"""
    try:
        return Path(path).read_text()
    except OSError:
        return ""


def parse_assignments(output: str) -> dict[str, str]:
    """Collect key equals value lines into a dict ignoring the rest"""
    values: dict[str, str] = {}
    for line in output.splitlines():
        key, separator, value = line.partition("=")
        if separator:
            values[key.strip()] = value.strip()
    return values


def systemctl_show(unit: str, props: Sequence[str]) -> dict[str, str]:
    """Fetch a few properties of one unit or an empty dict when systemctl fails"""
    ok, output = run(("systemctl", "show", unit, "-p", ",".join(props)))
    return parse_assignments(output) if ok else {}


def parse_show_blocks(output: str) -> list[dict[str, str]]:
    """Split multi unit systemctl show output into one dict per unit"""
    blocks = [parse_assignments(chunk) for chunk in output.split("\n\n")]
    return [block for block in blocks if block]


def shorten(value: str, max_length: int) -> str:
    """Cut a string to a max length ending it with dots"""
    return value if len(value) <= max_length else value[: max_length - 3] + "..."


def matches(query: str, *fields: str) -> bool:
    """True when the query is empty or found in any field"""
    return not query or any(query in field.lower() for field in fields)


def timestamp_age(value: str) -> tuple[int, str] | None:
    """Days and human age like 5d ago parsed from a systemctl timestamp or None"""
    parts = value.split()
    if len(parts) < 3:
        return None
    try:
        parsed = datetime.strptime(f"{parts[1]} {parts[2]}", "%Y-%m-%d %H:%M:%S")
    except ValueError:
        return None
    now = datetime.now()
    days = max(0, (now - parsed).days)
    months = (now.year - parsed.year) * 12 + now.month - parsed.month - (now.day < parsed.day)
    if days < 1:
        return days, "today"
    if months >= 12:
        return days, f"{months // 12}y ago"
    if months >= 1:
        return days, f"{months}mo ago"
    return days, f"{days}d ago"


def age_text(seconds: float) -> str:
    """A duration as a compact age in seconds minutes or hours"""
    if seconds < 120:
        return f"{int(seconds)}s"
    if seconds < 7200:
        return f"{int(seconds // 60)}m"
    return f"{int(seconds // 3600)}h"


def format_uptime(seconds: float) -> str:
    """How long the box has been up like 3d 5h 12m"""
    days, rest = divmod(int(max(0.0, seconds)), 86400)
    hours, rest = divmod(rest, 3600)
    if days:
        return f"{days}d {hours}h {rest // 60}m"
    if hours:
        return f"{hours}h {rest // 60}m"
    return f"{rest // 60}m"


def hostname_facts() -> dict[str, str]:
    """Machine facts from hostnamectl json with architecture from uname instead"""
    ok, output = run(("hostnamectl", "--json=short"))
    if not ok:
        return {}
    try:
        raw = json.loads(output)
    except json.JSONDecodeError:
        return {}
    facts = {
        "Static hostname": raw.get("StaticHostname") or raw.get("Hostname") or "",
        "Operating System": raw.get("OperatingSystemPrettyName") or "",
        "Kernel": f"{raw.get('KernelName', '')} {raw.get('KernelRelease', '')}".strip(),
        "Architecture": os.uname().machine,
    }
    return {key: value for key, value in facts.items() if value}


def format_rows(rows: Sequence[Row]) -> str:
    """Render rows as the hover table with indented detail lines and separators"""
    label_width = max((len(label) for label, _, _ in rows if label), default=0)
    lines: list[str] = []
    for label, detail, status in rows:
        if not label and not detail and not status:
            lines.append("")
            continue
        padded = label.ljust(label_width) if label else " " * label_width
        suffix = f"  {status}" if status else ""
        lines.append(f"{padded}  {detail}{suffix}".rstrip())
    return "\n".join(lines)


def worst_of(rows: Sequence[Row]) -> Status:
    """The harshest status among the rows"""
    if any(status == STATUS_CRIT for _, _, status in rows):
        return STATUS_CRIT
    if any(status == STATUS_WARN for _, _, status in rows):
        return STATUS_WARN
    return STATUS_OK


def overall_alt(rows: Sequence[Row]) -> Alt:
    """The icon key for the bar warn or crit flips the shield to alert"""
    return ALT_ALERT if worst_of(rows) != STATUS_OK else ALT_OK
