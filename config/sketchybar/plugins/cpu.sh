#!/usr/bin/env bash
# Collapsed: "cpu% · mem%". Popup: CPU / RAM / SSD / Top process.

source "$HOME/.config/sketchybar/colors.sh"

top_process() {
	ps -A -r -o %cpu=,comm= 2>/dev/null | head -1
}

top_memory_process() {
	ps -A -m -o %mem=,comm= 2>/dev/null | head -1
}

update_summary() {
	read -r user sys <<<"$(top -l 1 -n 0 2>/dev/null | awk '/CPU usage/{u=$3;s=$5} END{gsub(/%/,"",u);gsub(/%/,"",s);print u, s}')"
	cpu=$(awk "BEGIN{printf \"%.0f\", ${user:-0}+${sys:-0}}")

	free=$(memory_pressure 2>/dev/null | awk '/free percentage/{gsub(/%/,"",$NF);print $NF}')
	mem=$((100 - ${free:-0}))

	if [ "$cpu" -ge 80 ]; then col=$RED; elif [ "$cpu" -ge 50 ]; then col=$YELLOW; else col=$GREEN; fi

	cpu_label="${cpu}%"
	if [ "$cpu" -gt 50 ]; then
		top_name=$(top_process | awk '{$1=""; sub(/^ /,""); sub(/.*\//,""); sub(/com\.apple\./,""); printf "%s", $0}')
		[ -z "$top_name" ] || cpu_label="$cpu_label $top_name"
	fi

	mem_label="${mem}%"
	if [ "$mem" -gt 80 ]; then
		top_mem_name=$(top_memory_process | awk '{$1=""; sub(/^ /,""); sub(/.*\//,""); sub(/com\.apple\./,""); printf "%s", $0}')
		[ -z "$top_mem_name" ] || mem_label="$mem_label $top_mem_name"
	fi

	sketchybar --set cpu icon.color="$col" label="$cpu_label · $mem_label" \
		--set cpu.row.1 label="CPU   ${cpu}%" \
		--set cpu.row.2 label="RAM   ${mem}%"
}

update_details() {
	davail=$(df -h / | awk 'NR==2 {print $4}')
	davail=${davail%i}

	top_proc=$(top_process |
		awk '{c=$1; $1=""; sub(/^ /,""); sub(/.*\//,""); sub(/com\.apple\./,""); printf "%s %.0f%%", $0, c}')

	sketchybar --set cpu.row.3 label="SSD   ${davail} free" \
		--set cpu.row.4 label="TOP   ${top_proc}"
}

case "$SENDER" in
mouse.clicked)
	update_details
	sketchybar --set cpu popup.drawing=toggle
	;;
mouse.exited | mouse.exited.global | front_app_switched)
	sketchybar --set cpu popup.drawing=off
	;;
*)
	update_summary
	;;
esac
