"""The nine health checks where each collector queries once and the rows paint the tooltip"""

from collections.abc import Sequence
from typing import Any, Final

import psutil

from const import (
    CRITICAL_SERVICES,
    DETAIL_MAX_LENGTH,
    DISK_FREE_CRIT_PERCENT,
    DISK_FREE_WARN_PERCENT,
    FAILED_LIST_MAX,
    GIBIB,
    LOG_TAIL_LINES,
    Record,
    Row,
    SCRUB_RUNNING,
    SCRUB_STALE_DAYS,
    SCRUB_TIMER_PREFIX,
    Section,
    STATUS_CRIT,
    STATUS_OK,
    STATUS_WARN,
    Status,
    SYSTEM_DEGRADED,
    SYSTEM_RUNNING,
    ZOMBIE_CRIT_COUNT,
    ZOMBIE_SAMPLE_MAX,
    ZOMBIE_WARN_COUNT,
)
from util import (
    hostname_facts,
    parse_assignments,
    parse_show_blocks,
    read_text,
    run,
    shorten,
    systemctl_show,
    timestamp_age,
)


def collect_system() -> Record:
    """The systemd feeling of the machine plus the hostname facts"""
    ok, state = run(("systemctl", "is-system-running"))
    return {"available": ok or bool(state), "state": state or "unknown", "facts": hostname_facts()}


def collect_units(scope: Sequence[str]) -> Record:
    """Loaded units of one scope as tuples or None when systemctl stays silent"""
    ok, output = run(
        ("systemctl", *scope, "list-units", "--all", "--no-legend", "--plain", "--no-pager")
    )
    if not ok:
        return None
    return [
        (*columns[:4], columns[4] if len(columns) > 4 else "")
        for line in output.splitlines()
        for columns in [line.split(None, 4)] if len(columns) >= 4
    ]


def collect_services() -> Record:
    """The critical services from one batched systemctl show or None"""
    if not CRITICAL_SERVICES:
        return []
    props = ("Id", "ActiveState", "SubState", "Description", "NRestarts", "ExecMainStartTimestamp")
    query = ["systemctl", "show", *(f"{name}.service" for name in CRITICAL_SERVICES)]
    for prop in props:
        query += ["-p", prop]
    ok, output = run(query)
    if not ok:
        return None
    blocks = {block.get("Id", ""): block for block in parse_show_blocks(output)}
    return [
        {"ActiveState": "unknown", **blocks.get(f"{name}.service", {}), "Name": name}
        for name in CRITICAL_SERVICES
    ]


def collect_jobs() -> Record:
    """Pending systemd jobs as raw line with columns or None"""
    ok, output = run(("systemctl", "list-jobs", "--no-legend", "--plain"))
    if not ok:
        return None
    return [(line, tuple(line.split(None, 3))) for line in output.splitlines() if line.strip()]


def collect_clock() -> Record:
    """Timedatectl facts about the wall clock or None"""
    ok, output = run(("timedatectl", "show"))
    if not ok or not output:
        return None
    return parse_assignments(output) or None


def btrfs_mounts() -> list[str]:
    """One mount point per btrfs device with the root first"""
    mounts_by_device: dict[str, str] = {}
    for part in psutil.disk_partitions(all=True):
        if part.fstype != "btrfs":
            continue
        current = mounts_by_device.get(part.device)
        if current is None or len(part.mountpoint) < len(current):
            mounts_by_device[part.device] = part.mountpoint
    return sorted(mounts_by_device.values(), key=lambda mount: (mount != "/", mount))


def systemd_instance(mount_point: str) -> str:
    """A mount point turned into its scrub instance name"""
    if mount_point == "/":
        return "-"
    return mount_point.strip("/").replace("/", "-")


def root_mount_options() -> str:
    """The mount options of root straight from the proc mounts file since psutil hides them"""
    for line in read_text("/proc/mounts").splitlines():
        columns = line.split()
        if len(columns) >= 4 and columns[1] == "/":
            return columns[3]
    return ""


def scrub_timer_units() -> dict[str, str]:
    """The existing btrfs scrub timers mapped from instance to unit"""
    ok, output = run(
        ("systemctl", "list-timers", f"{SCRUB_TIMER_PREFIX}*", "--all", "--no-legend", "--plain")
    )
    if not ok:
        return {}
    words = " ".join(output.splitlines()).split()
    found = [w for w in words if w.startswith(SCRUB_TIMER_PREFIX) and w.endswith(".timer")]
    return {w.removeprefix(SCRUB_TIMER_PREFIX).removesuffix(".timer"): w for w in found}


def collect_scrubs() -> Record:
    """One scrub record per mounted filesystem and per orphan timer with raw systemctl strings"""
    def query(mount: str | None, instance: str, timer_unit: str = "") -> dict[str, Any]:
        if not timer_unit:
            return {"mount": mount, "instance": instance, "timer": "", "state": "", "last": "",
                    "next": "", "active": "", "result": "", "exit": ""}
        timer = systemctl_show(timer_unit, ("UnitFileState", "LastTriggerUSec", "NextElapseUSecRealtime"))
        service = systemctl_show(
            timer_unit.removesuffix(".timer") + ".service", ("ActiveState", "Result", "ExecMainStatus")
        )
        return {
            "mount": mount, "instance": instance, "timer": timer_unit,
            "state": timer.get("UnitFileState", ""), "last": timer.get("LastTriggerUSec", ""),
            "next": timer.get("NextElapseUSecRealtime", ""), "active": service.get("ActiveState", ""),
            "result": service.get("Result", ""), "exit": service.get("ExecMainStatus", ""),
        }

    timers = scrub_timer_units()
    records: list[dict[str, Any]] = []
    seen: set[str] = set()
    for mount_point in btrfs_mounts():
        instance = systemd_instance(mount_point)
        seen.add(instance)
        records.append(query(mount_point, instance, timers.get(instance, "")))
    for instance, timer_unit in sorted(timers.items()):
        if instance not in seen:
            records.append(query(None, instance, timer_unit))
    return records


def collect_disks() -> Record:
    """Usage per btrfs filesystem and the options of root with a negative total when unreadable"""
    wanted = set(btrfs_mounts())
    devices = {p.mountpoint: p.device for p in psutil.disk_partitions(all=True) if p.mountpoint in wanted}
    disks: list[dict[str, Any]] = []
    for mount_point in sorted(wanted, key=lambda mount: (mount != "/", mount)):
        try:
            usage = psutil.disk_usage(mount_point)
            disks.append({"mount": mount_point, "device": devices.get(mount_point, "?"),
                          "total": usage.total, "free": usage.free})
        except OSError:
            disks.append({"mount": mount_point, "device": devices.get(mount_point, "?"), "total": -1, "free": -1})
    return disks, root_mount_options()


def collect_zombies() -> Record:
    """Zombie processes with their pid name and parent"""
    found: list[dict[str, str]] = []
    for process in psutil.process_iter(["pid", "name", "status", "ppid"]):
        info = process.info
        if info["status"] != psutil.STATUS_ZOMBIE:
            continue
        try:
            parent = psutil.Process(info["ppid"]).name() or "?"
        except psutil.Error:
            parent = "?"
        found.append({"pid": str(info["pid"]), "name": info["name"] or "?",
                      "ppid": str(info["ppid"]), "parent": parent})
    return found


def collect_logs(unit: str, user: bool) -> list[str]:
    """The last journal lines of one unit and failures come back as lines not exceptions"""
    command = ["journalctl", *(("--user",) if user else ()), "-u", unit,
               "-n", str(LOG_TAIL_LINES), "--no-pager"]
    ok, output = run(command)
    lines = output.splitlines()
    if ok:
        return lines or [f"no journal lines for {unit}"]
    return lines or [f"journalctl failed for {unit}"]


def system_rows(data: Record) -> list[Row]:
    """One line saying running is fine degraded is crit and anything else warns"""
    state = data["state"]
    if not data["available"] and state == "unknown":
        return [("SYSTEM", "unavailable", STATUS_WARN)]
    status: Status = STATUS_OK if state == SYSTEM_RUNNING else STATUS_CRIT if state == SYSTEM_DEGRADED else STATUS_WARN
    return [("SYSTEM", state, status)]


def units_rows(data: Record, label: str) -> list[Row]:
    """The failed count and their names as capped indented lines"""
    if data is None:
        return [(label, "unavailable", STATUS_WARN)]
    failed = [unit for unit in data if unit[2] == "failed"]
    rows: list[Row] = [(label, f"{len(failed)} failed", STATUS_OK if not failed else STATUS_CRIT)]
    rows += [
        ("", shorten(f"{uid}  {desc}".strip(), DETAIL_MAX_LENGTH), "")
        for uid, _, _, _, desc in failed[:FAILED_LIST_MAX]
    ]
    if len(failed) > FAILED_LIST_MAX:
        rows.append(("", f"... {len(failed) - FAILED_LIST_MAX} more", ""))
    return rows


def services_rows(data: Record) -> list[Row]:
    """The critical services count and each one that is down since dead services can hide from the failed list"""
    if not CRITICAL_SERVICES:
        return []
    if data is None:
        return [("SERVICES", "unavailable", STATUS_WARN)]
    down = [service for service in data if service["ActiveState"] != "active"]
    rows: list[Row] = [
        ("SERVICES", f"{len(data) - len(down)}/{len(data)} active", STATUS_OK if not down else STATUS_CRIT)
    ]
    rows += [
        ("", shorten(f"{service['Name']}.service: {service['ActiveState']}", DETAIL_MAX_LENGTH), "")
        for service in down
    ]
    return rows


def jobs_rows(data: Record) -> list[Row]:
    """The pending count with a line per job because a stuck queue means a stuck unit"""
    if data is None:
        return [("JOBS", "unavailable", STATUS_WARN)]
    rows: list[Row] = [("JOBS", f"{len(data)} pending", STATUS_OK if not data else STATUS_WARN)]
    rows += [
        ("", shorten(f"{columns[1]} {columns[3]}" if len(columns) > 3 else raw, DETAIL_MAX_LENGTH), "")
        for raw, columns in data[:FAILED_LIST_MAX]
    ]
    return rows


def clock_rows(data: Record) -> list[Row]:
    """NTP synchronized status since every timestamp here trusts the clock"""
    value = (data or {}).get("NTPSynchronized", "")
    if value == "yes":
        return [("CLOCK", "NTP synchronized", STATUS_OK)]
    if value == "no":
        return [("CLOCK", "NTP desynchronized", STATUS_WARN)]
    return [("CLOCK", "unavailable", STATUS_WARN)]


def scrub_judge(info: dict[str, Any]) -> Row:
    """Verdict of one scrub where running or recent success is ok disabled or stale warns and a failed run is crit"""
    label = f"SCRUB {info['mount']}"
    if not info["timer"]:
        return (label, "no scrub timer", STATUS_WARN)
    age = timestamp_age(info["last"])
    if info["active"] in SCRUB_RUNNING:
        return (label, "running now", STATUS_OK)
    if info["state"] != "enabled":
        return (label, "timer not enabled", STATUS_WARN)
    if age is None:
        return (label, "never scrubbed", STATUS_WARN)
    age_days, age_str = age
    detail = f"ran {age_str}"
    if info["result"] and info["result"] != "success":
        return (label, f"{detail}  result={info['result']} exit={info['exit']}", STATUS_CRIT)
    if info["exit"] and info["exit"] != "0":
        return (label, f"{detail}  exit={info['exit']}", STATUS_CRIT)
    if age_days > SCRUB_STALE_DAYS:
        return (label, f"{detail}  stale", STATUS_WARN)
    return (label, f"{detail}  result=success", STATUS_OK)


def scrub_rows(data: Record) -> list[Row]:
    """Scrub status per mounted filesystem with orphan timers listed harmlessly"""
    rows: list[Row] = []
    for info in data:
        if info["mount"] is None:
            age = timestamp_age(info["last"])
            ran = age[1] if age else "never"
            rows.append((f"SCRUB ({info['instance']})", f"not mounted, ran {ran}", ""))
        else:
            rows.append(scrub_judge(info))
    if not rows:
        rows.append(("SCRUB", "no btrfs filesystems", ""))
    return rows


def disk_usage(disk: dict[str, Any]) -> tuple[float, Status]:
    """Percent used and its threshold status"""
    free_percent = disk["free"] / disk["total"] * 100
    if free_percent < DISK_FREE_CRIT_PERCENT:
        status: Status = STATUS_CRIT
    elif free_percent < DISK_FREE_WARN_PERCENT:
        status = STATUS_WARN
    else:
        status = STATUS_OK
    return 100 - free_percent, status


def disk_rows(data: Record) -> list[Row]:
    """Usage per filesystem plus the read only root canary that only appears after a filesystem error"""
    disks, root_options = data
    rows: list[Row] = []
    for disk in disks:
        if disk["total"] < 0:
            rows.append((f"DISK {disk['mount']}", "unavailable", STATUS_WARN))
            continue
        if disk["total"] <= 0:
            continue
        used_percent, status = disk_usage(disk)
        rows.append((
            f"DISK {disk['mount']}",
            f"{used_percent:.0f}% used ({disk['free'] / GIBIB:.0f} GiB free)",
            status,
        ))
    options = root_options.split(",")
    if "ro" in options and "rw" not in options:
        rows.append(("ROOTFS", "mounted read-only", STATUS_CRIT))
    return rows


def zombie_rows(data: Record) -> list[Row]:
    """Zombie count that stays quiet at first then warns and finally crits with a few names"""
    count = len(data)
    if count == 0:
        return [("ZOMBIES", "none", STATUS_OK)]
    status: Status = (
        STATUS_CRIT if count >= ZOMBIE_CRIT_COUNT
        else STATUS_WARN if count >= ZOMBIE_WARN_COUNT else ""
    )
    rows: list[Row] = [("ZOMBIES", f"{count} defunct", status)]
    rows += [
        ("", shorten(f"{zombie['pid']} ({zombie['name']})", DETAIL_MAX_LENGTH), "")
        for zombie in data[:ZOMBIE_SAMPLE_MAX]
    ]
    return rows


def safe_rows(section: Section) -> list[Row]:
    """One section can never break the module since any crash becomes one warn row"""
    try:
        return section.rows(section.collect())
    except Exception as exc:  # last resort fallback so the module never breaks
        return [("CHECK", shorten(f"error: {exc}", DETAIL_MAX_LENGTH), STATUS_WARN)]


SECTIONS: Final[list[Section]] = [
    Section("SYSTEM", collect_system, system_rows),
    Section("UNITS", lambda: collect_units(()), lambda data: units_rows(data, "UNITS")),
    Section("USER UNITS", lambda: collect_units(("--user",)), lambda data: units_rows(data, "USER UNITS")),
    Section("SERVICES", collect_services, services_rows),
    Section("JOBS", collect_jobs, jobs_rows),
    Section("CLOCK", collect_clock, clock_rows),
    Section("SCRUB", collect_scrubs, scrub_rows),
    Section("DISK", collect_disks, disk_rows),
    Section("ZOMBIES", collect_zombies, zombie_rows),
]
