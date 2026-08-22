#!/usr/bin/env python3
import subprocess
import re
import json

# Matches: ● Name (type, wpid=xxxx, battery=N% status (state))
DEVICE_RE = re.compile(
    r"●\s+(.+?)\s+\(\w+,\s*wpid=[0-9a-f]+,\s*battery=(\d+)%\s+(\w+)\s+\((\w+)\)"
)


def main() -> None:
    try:
        proc = subprocess.run(
            ["openlogi", "list"],
            capture_output=True, text=True, timeout=10,
        )
        output = proc.stdout
    except (FileNotFoundError, subprocess.TimeoutExpired):
        print(json.dumps({"text": "?", "percentage": 0, "tooltip": "openlogi unavailable"}))
        return

    devices = []
    for m in DEVICE_RE.finditer(output):
        name, pct_str, status, state = m.groups()
        devices.append({
            "name": name,
            "pct": int(pct_str),
            "status": status,
            "state": state,
        })

    if not devices:
        print(json.dumps({"text": "–", "percentage": 0, "tooltip": "No devices found"}))
        return

    weakest = min(devices, key=lambda d: d["pct"])
    tooltip = "\n".join(
        f"{d['name']}: {d['pct']}% {d['status']} ({d['state']})" for d in devices
    )

    print(json.dumps({
        "text": f"{weakest['pct']}%",
        "percentage": weakest["pct"],
        "tooltip": tooltip,
    }))


if __name__ == "__main__":
    main()
