"""All the tunable knobs and the shared types of the whole app"""

from dataclasses import dataclass
from pathlib import Path
from typing import Any, Final, Literal
import os

COMMAND_TIMEOUT_SECONDS: Final[int] = 10
SYSTEM_RUNNING: Final[str] = "running"
SYSTEM_DEGRADED: Final[str] = "degraded"
SCRUB_TIMER_PREFIX: Final[str] = "btrfs-scrub@"
SCRUB_STALE_DAYS: Final[int] = 30
FAILED_LIST_MAX: Final[int] = 8
DETAIL_MAX_LENGTH: Final[int] = 70
LOG_TAIL_LINES: Final[int] = 200
TUI_ROW_LIMIT: Final[int] = 40

# services that must always run on this machine
CRITICAL_SERVICES: Final[tuple[str, ...]] = (
    "ly",
    "seatd",
    "NetworkManager",
    "earlyoom",
    "grub-btrfsd",
    "smartd",
    "systemd-timesyncd",
)

GIBIB: Final[int] = 1024**3

DISK_FREE_WARN_PERCENT: Final[int] = 10
DISK_FREE_CRIT_PERCENT: Final[int] = 5
ZOMBIE_WARN_COUNT: Final[int] = 5
ZOMBIE_CRIT_COUNT: Final[int] = 25
ZOMBIE_SAMPLE_MAX: Final[int] = 3
TUI_REFRESH_SECONDS: Final[float] = 5.0

# update sources for the bar label and the dashboard section
# a missing helper just reports nothing
UPDATE_SOURCES: Final[tuple[tuple[str, tuple[str, ...]], ...]] = (
    ("PACMAN", ("checkupdates",)),
    ("AUR", ("yay", "-Qua")),
)
# AUR helpers tried by the updater in order of preference
AUR_HELPERS: Final[tuple[str, ...]] = ("paru", "yay")
UPDATE_TIMEOUT_SECONDS: Final[int] = 30
UPDATES_CACHE_SECONDS: Final[float] = 600.0
# where the update picture rides between the quick bar polls and the
# dashboard as one small JSON file replaced atomically
UPDATES_CACHE_FILE: Final[Path] = Path(
    os.environ.get("XDG_CACHE_HOME") or Path.home() / ".cache"
) / "system-check-updates.json"

# service states meaning a scrub is running right now
SCRUB_RUNNING: Final[tuple[str, ...]] = ("active", "activating", "reloading")

Status = Literal["", "ok", "warn", "crit"]
Alt = Literal["ok", "alert"]

STATUS_OK: Final[Status] = "ok"
STATUS_WARN: Final[Status] = "warn"
STATUS_CRIT: Final[Status] = "crit"

ALT_OK: Final[Alt] = "ok"
ALT_ALERT: Final[Alt] = "alert"

# one tooltip line label detail status an empty status hides the column
# and a fully empty row renders as a blank separator line
Row = tuple[str, str, Status]

BLANK_ROW: Final[Row] = ("", "", "")

# whatever a collector hands over plain dicts and tuples shaped per
# category and described where they are built
Record = Any


@dataclass(frozen=True)
class Section:
    """One dashboard category with its collector and its tooltip renderer"""

    name: str
    collect: Any
    rows: Any
