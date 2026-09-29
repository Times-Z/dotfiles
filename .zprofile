#!/bin/sh
# Fallback WM selector

if [ -z "${DISPLAY}" ] && [ "${XDG_VTNR:-0}" -eq 1 ]; then
	log_dir="${XDG_STATE_HOME:-$HOME/.local/state}/log"
	mkdir -p "${log_dir}" || log_dir="/tmp"

	ps3="Session > "
	while select sess in "Hyprland (Wayland)" "poweroff" ""; do
		case "${sess}" in
			"Hyprland (Wayland)")
				Hyprland >>"${log_dir}/hyprland.log" 2>&1 ;;
			"poweroff")
				systemctl poweroff ;;
			*)	continue ;;
		esac
		echo "Session finish, logs: ${log_dir}" >&2
	done
done
