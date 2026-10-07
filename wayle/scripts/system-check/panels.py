"""The dashboard look with the Dracula palette table builders and rich panels that only the tui imports"""

from collections.abc import Callable, Sequence
from datetime import datetime
from typing import Any, Final
import os

import psutil
from rich.console import Group
from rich.panel import Panel
from rich.table import Table
from rich.text import Text

from checks import SECTIONS, disk_usage, scrub_judge
from const import (
    GIBIB,
    Record,
    STATUS_CRIT,
    STATUS_OK,
    STATUS_WARN,
    Status,
    TUI_ROW_LIMIT,
    ZOMBIE_CRIT_COUNT,
    Section,
)
from updates import collect_updates
from util import (
    age_text,
    format_uptime,
    matches,
    shorten,
    timestamp_age,
)

# Dracula palette shared by the Textual CSS and the rich renderables
DRACULA: Final[dict[str, str]] = {
    "bg": "#282a36", "current": "#44475a", "fg": "#f8f8f2", "comment": "#6272a4",
    "cyan": "#8be9fd", "green": "#50fa7b", "orange": "#ffb86c", "pink": "#ff79c6",
    "purple": "#bd93f9", "red": "#ff5555", "yellow": "#f1fa8c",
}

# icon and color per row status in the section list and panels
STATUS_GLYPHS: Final[dict[Status, tuple[str, str]]] = {
    STATUS_OK: ("✓", DRACULA["green"]),
    STATUS_WARN: ("!", DRACULA["yellow"]),
    STATUS_CRIT: ("✗", DRACULA["red"]),
    "": ("·", DRACULA["comment"]),
}


def units_ordered(data: list[tuple[str, ...]]) -> list[tuple[str, ...]]:
    """Units sorted failed first then active then the rest each group alphabetical"""
    return sorted(data, key=lambda unit: ({"failed": 0, "active": 1}.get(unit[2], 2), unit[0]))


def units_table(data: Record, query: str = "") -> list[Any]:
    """Table rows for every loaded unit with the query filter applied"""
    if not isinstance(data, list):
        return []
    return [
        (shorten(uid, 32), shorten(load, 6), shorten(active, 10), shorten(sub, 10), shorten(desc, 40))
        if active != "failed"
        else (
            Text(shorten(uid, 32), style=DRACULA["red"]),
            shorten(load, 6), shorten(active, 10), shorten(sub, 10), shorten(desc, 40),
        )
        for uid, load, active, sub, desc in units_ordered(data)
        if matches(query, uid, desc)
    ]


def services_table(data: Record, query: str = "") -> list[Any]:
    """Table rows for the critical services with the query filter applied"""
    if not isinstance(data, list):
        return []
    rows: list[Any] = []
    for service in data:
        if not matches(query, service["Name"], service.get("Description", "")):
            continue
        up = service["ActiveState"] == "active"
        started = timestamp_age(service.get("ExecMainStartTimestamp", ""))
        rows.append((
            service["Name"],
            Text("✓" if up else "✗", style=DRACULA["green"] if up else DRACULA["red"]),
            service["ActiveState"], service.get("SubState", ""), service.get("NRestarts", ""),
            started[1] if started else "-",
            shorten(service.get("Description", ""), 42),
        ))
    return rows


def updates_table(data: Record, query: str = "") -> list[Any]:
    """Table rows for pending packages with the query filter applied"""
    if not isinstance(data, dict):
        return []
    color_by_manager = {"PACMAN": DRACULA["cyan"], "AUR": DRACULA["purple"]}
    rows: list[Any] = []
    for record in data["records"]:
        desc = record.get("desc", "")
        if not matches(query, record["package"], record["manager"], desc):
            continue
        rows.append((
            Text(record["manager"], style=color_by_manager[record["manager"]]),
            shorten(record["package"], UPDATES_WIDTHS[1]),
            Text(shorten(record["from"], UPDATES_WIDTHS[2]), style=DRACULA["comment"]),
            Text(shorten(record["to"], UPDATES_WIDTHS[3]), style=DRACULA["green"]),
            desc if desc else Text("·", style=DRACULA["comment"]),
        ))
    return rows


# fixed widths of the first updates columns and the description takes all the rest
UPDATES_WIDTHS: Final[tuple[int, int, int, int]] = (7, 26, 16, 16)

# drillable sections with headers and a row builder for their tables
TABLE_SPECS: Final[dict[str, tuple[tuple[str, ...], Callable[..., list[Any]]]]] = {
    "UNITS": (("UNIT", "LOAD", "ACTIVE", "SUB", "DESCRIPTION"), units_table),
    "USER UNITS": (("UNIT", "LOAD", "ACTIVE", "SUB", "DESCRIPTION"), units_table),
    "SERVICES": (("SERVICE", "", "ACTIVE", "SUB", "RESTARTS", "UP", "DESCRIPTION"), services_table),
    "UPDATES": (("MANAGER", "PACKAGE", "OLD", "NEW", "DESCRIPTION"), updates_table),
}

# the dashboard nav with the nine health sections plus pending updates
# which no health tooltip shows and the app refetches in background
# while its rows stay empty for the table builders
TUI_SECTIONS: Final[list[Section]] = [*SECTIONS, Section("UPDATES", collect_updates, lambda data: [])]


def table_caption(name: str, data: Record) -> str:
    """The counts a drillable table title is worth"""
    if name == "UPDATES":
        if not isinstance(data, dict):
            return "pending updates · checking"
        managers = [record["manager"] for record in data["records"]]
        age = age_text((datetime.now() - data["checked"]).total_seconds())
        note = f" · missing {' + '.join(data['missing'])}" if data.get("missing") else ""
        return (f"pending updates · {managers.count('PACMAN')} pacman · "
                f"{managers.count('AUR')} aur{note} · checked {age} ago")
    if not isinstance(data, list):
        return f"{name.lower()} unavailable"
    if name == "SERVICES":
        up = sum(1 for service in data if service["ActiveState"] == "active")
        return f"critical services · {up}/{len(data)} up"
    failed = sum(1 for unit in data if unit[2] == "failed")
    active = sum(1 for unit in data if unit[2] == "active")
    label = "user units" if name == "USER UNITS" else "system units"
    return f"{label} · {len(data)} loaded · {active} active · {failed} failed"


def drill_items(name: str, data: Record, query: str = "") -> list[str]:
    """Unit names behind table rows in the very order and filter of the table so enter opens the right journal"""
    if name in ("UNITS", "USER UNITS") and isinstance(data, list):
        return [unit[0] for unit in units_ordered(data) if matches(query, unit[0], unit[4])]
    if name == "SERVICES" and isinstance(data, list):
        return [
            f"{service['Name']}.service"
            for service in data
            if matches(query, service["Name"], service.get("Description", ""))
        ]
    return []


def facts_table() -> Any:
    """The dim two column style shared by the fact panels"""
    table = Table(box=None, show_header=False, pad_edge=False, collapse_padding=True)
    table.add_column(style=DRACULA["comment"], no_wrap=True)
    table.add_column()
    return table


def table_panel(title: str, headers: Sequence[str], rows: Sequence[Sequence[Any]],
                border: str = "", extra: Any = None) -> Any:
    """A framed rich table optionally followed by one line"""
    table = Table()
    for header in headers:
        table.add_column(header)
    for row in rows:
        table.add_row(*row)
    body: Any = table if extra is None else Group(table, extra)
    return Panel(body, title=title, border_style=border or DRACULA["comment"])


def system_panel(data: Any) -> Any:
    """Machine facts plus live load and memory figures"""
    if not isinstance(data, dict):
        return Panel(Text("systemctl is not answering", style=DRACULA["red"]), title="system")
    table = facts_table()
    for key in ("Static hostname", "Operating System", "Kernel", "Architecture"):
        if key in data["facts"]:
            table.add_row(f"{key}:", data["facts"][key])
    table.add_row("Uptime:", format_uptime(datetime.now().timestamp() - psutil.boot_time()))
    try:
        load = os.getloadavg()
        table.add_row("Load:", f"{load[0]:.2f} {load[1]:.2f} {load[2]:.2f} on {os.cpu_count()} cpus")
    except OSError:
        pass
    memory = psutil.virtual_memory()
    if memory.total:
        table.add_row("RAM:", f"{(memory.total - memory.available) / GIBIB:.1f} / {memory.total / GIBIB:.1f} GiB used")
    swap = psutil.swap_memory()
    if swap.total:
        table.add_row("Swap:", f"{(swap.total - swap.free) / GIBIB:.1f} / {swap.total / GIBIB:.1f} GiB used")
    return Panel(table, title="system", border_style=DRACULA["comment"])


def jobs_panel(data: Any) -> Any:
    """The jobs still waiting in the queue"""
    if data is None:
        return Panel(Text("systemctl is not answering", style=DRACULA["red"]), title="jobs")
    if not data:
        return Panel(Text("no pending jobs", style=DRACULA["green"]), title="jobs")
    rows = [
        list(columns) if len(columns) == 4 else (shorten(raw, 60), "", "", "")
        for raw, columns in data[:TUI_ROW_LIMIT]
    ]
    if len(data) > TUI_ROW_LIMIT:
        rows.append((f"... {len(data) - TUI_ROW_LIMIT} more", "", "", ""))
    return table_panel(f"jobs · {len(data)} pending", ("JOB", "UNIT", "TYPE", "STATE"), rows, border=DRACULA["yellow"])


def clock_panel(data: Any) -> Any:
    """What timedatectl knows about the wall clock"""
    if not data:
        return Panel(Text("timedatectl is not answering", style=DRACULA["red"]), title="clock")
    table = facts_table()
    table.add_row("Local time:", data.get("TimeUSec", "?"))
    table.add_row("Time zone:", data.get("Timezone", "?"))
    synced = data.get("NTPSynchronized", "?")
    table.add_row("NTP synchronized:", Text(synced, style=DRACULA["green"] if synced == "yes" else DRACULA["yellow"]))
    rtc = data.get("LocalRTC", "?")
    table.add_row("RTC holds local time:", Text(rtc, style=DRACULA["green"] if rtc == "no" else DRACULA["yellow"]))
    return Panel(table, title="clock", border_style=DRACULA["comment"])


def scrub_panel(data: Any) -> Any:
    """One line per scrub timer mounted or not"""
    records = sorted((info for info in (data or []) if info["timer"]), key=lambda info: info["instance"])
    if not records:
        return Panel(Text("no btrfs scrub timers found", style=DRACULA["yellow"]), title="scrub")
    rows: list[Sequence[Any]] = []
    for info in records:
        age = timestamp_age(info["last"])
        next_bits = info["next"].split()
        next_text = f"{next_bits[1]} {next_bits[2][:5]}" if len(next_bits) > 2 else "-"
        glyph, color = STATUS_GLYPHS[scrub_judge(info)[2] if info["mount"] else ""]
        rows.append((
            info["mount"] or f"({info['instance']})", info["instance"], info["state"],
            age[1] if age else "never", next_text, info["result"], info["exit"],
            Text(glyph, style=color),
        ))
    return table_panel(
        "btrfs scrubs", ("FILESYSTEM", "TIMER", "ENABLED", "LAST", "NEXT", "RESULT", "EXIT", ""), rows
    )


def disk_panel(data: Any) -> Any:
    """Size free space and a usage bar per btrfs filesystem"""
    disks, root_options = data
    rows: list[Sequence[Any]] = []
    for disk in disks:
        if disk["total"] < 0:
            rows.append((disk["mount"], disk["device"], "unavailable", "", Text("!", style=DRACULA["yellow"])))
            continue
        if disk["total"] <= 0:
            continue
        used_percent, status = disk_usage(disk)
        color = STATUS_GLYPHS[status][1]
        filled = round(used_percent / 100 * 14)
        bar = Text("█" * filled, style=color) + Text("░" * (14 - filled), style=DRACULA["current"])
        bar.append(f" {used_percent:.0f}%")
        rows.append((disk["mount"], disk["device"], f"{disk['total'] / GIBIB:.0f} GiB",
                     f"{disk['free'] / GIBIB:.0f} GiB", bar))
    options = root_options.split(",")
    if "ro" in options and "rw" not in options:
        extra: Any = Text("root filesystem is mounted READ-ONLY", style=f"bold {DRACULA['red']}")
    else:
        extra = Text(f"root mount: {shorten(root_options, 60)}", style=DRACULA["comment"])
    return table_panel("disks", ("FILESYSTEM", "DEVICE", "SIZE", "FREE", "USE"), rows, extra=extra)


def zombie_panel(data: Any) -> Any:
    """Defunct processes and the parents that never reaped them"""
    zombies = data or []
    if not zombies:
        return Panel(Text("no zombies, parents behave", style=DRACULA["green"]), title="zombies",
                     border_style=DRACULA["comment"])
    rows = [(zombie["pid"], zombie["name"], zombie["ppid"], zombie["parent"]) for zombie in zombies[:TUI_ROW_LIMIT]]
    if len(zombies) > TUI_ROW_LIMIT:
        rows.append(("", f"... {len(zombies) - TUI_ROW_LIMIT} more", "", ""))
    border = DRACULA["red"] if len(zombies) >= ZOMBIE_CRIT_COUNT else DRACULA["yellow"]
    return table_panel(f"{len(zombies)} defunct", ("PID", "COMMAND", "PARENT PID", "PARENT"), rows, border=border)


# flat sections rendered as rich panels and drillable ones use the specs
FLAT_PANELS: Final[dict[str, Callable[[Record], Any]]] = {
    "SYSTEM": system_panel, "JOBS": jobs_panel, "CLOCK": clock_panel,
    "SCRUB": scrub_panel, "DISK": disk_panel, "ZOMBIES": zombie_panel,
}
