#!/usr/bin/env python3
import json
import dbus


UPower_DEVICE = "org.freedesktop.UPower.Device"
DBUS_PROPERTIES = "org.freedesktop.DBus.Properties"
DEVICE_TYPE_MOUSE = 5
DEVICE_STATES = {
    1: "charging",
    2: "discharging",
    3: "empty",
    4: "fully charged",
    5: "pending charge",
    6: "pending discharge",
}


def get_devices():
    bus = dbus.SystemBus()
    upower = bus.get_object("org.freedesktop.UPower", "/org/freedesktop/UPower")
    paths = upower.EnumerateDevices(
        dbus_interface="org.freedesktop.UPower"
    )

    devices = []
    for path in paths:
        device = bus.get_object("org.freedesktop.UPower", path)
        properties = device.GetAll(
            UPower_DEVICE,
            dbus_interface=DBUS_PROPERTIES,
        )
        if int(properties.get("Type", 0)) != DEVICE_TYPE_MOUSE:
            continue
        if not bool(properties.get("IsPresent", True)):
            continue

        devices.append({
            "name": str(properties.get("Model", "Unknown mouse")),
            "pct": round(float(properties.get("Percentage", 0))),
            "state": DEVICE_STATES.get(int(properties.get("State", 0)), "unknown"),
        })
    return devices


def main() -> None:
    try:
        devices = get_devices()
    except dbus.DBusException:
        print(json.dumps({"text": "?", "percentage": 0, "tooltip": "UPower unavailable"}))
        return

    if not devices:
        print(json.dumps({"text": "-", "percentage": 0, "tooltip": "No devices found"}))
        return

    weakest = min(devices, key=lambda d: d["pct"])
    tooltip = "\n".join(
        f"{d['name']}: {d['pct']}% ({d['state']})" for d in devices
    )

    print(json.dumps({
        "text": f"{weakest['pct']}%",
        "percentage": weakest["pct"],
        "tooltip": tooltip
    }))


if __name__ == "__main__":
    main()
