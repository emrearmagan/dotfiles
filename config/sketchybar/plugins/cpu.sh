#!/usr/bin/env bash
# Collapsed: "cpu% · mem%". Popup: CPU / RAM / SSD / Net / Top process.

source "$HOME/.config/sketchybar/colors.sh"

case "$SENDER" in
mouse.clicked)
	sketchybar --set cpu popup.drawing=toggle
	exit 0
	;;
mouse.exited | mouse.exited.global | front_app_switched)
	sketchybar --set cpu popup.drawing=off
	exit 0
	;;
esac

INTERVAL=5

read -r user sys <<<"$(top -l 2 -n 0 2>/dev/null | awk '/CPU usage/{u=$3;s=$5} END{gsub(/%/,"",u);gsub(/%/,"",s);print u, s}')"
cpu=$(awk "BEGIN{printf \"%.0f\", ${user:-0}+${sys:-0}}")

free=$(memory_pressure 2>/dev/null | awk '/free percentage/{gsub(/%/,"",$NF);print $NF}')
mem=$((100 - ${free:-0}))

read -r dused davail <<<"$(df -h / | awk 'NR==2 {gsub(/%/,"",$5); print $5, $4}')"
davail=${davail%i}

top_proc=$(ps -A -r -o %cpu=,comm= 2>/dev/null | head -1 |
	awk '{c=$1; $1=""; sub(/^ /,""); sub(/.*\//,""); sub(/com\.apple\./,""); printf "%s %.0f%%", $0, c}')

# network throughput (delta since last run)
iface=$(route -n get default 2>/dev/null | awk '/interface:/{print $2}')
read -r crx ctx <<<"$(netstat -ib -I "$iface" 2>/dev/null | awk '/Link/{print $7, $10; exit}')"
statef="$HOME/.cache/sketchybar_net"
prx=0 ptx=0
[ -f "$statef" ] && read -r prx ptx <"$statef"
printf '%s %s\n' "${crx:-0}" "${ctx:-0}" >"$statef"
drx=$(((${crx:-0} - prx) / INTERVAL / 1024)); [ "$drx" -lt 0 ] && drx=0
dtx=$(((${ctx:-0} - ptx) / INTERVAL / 1024)); [ "$dtx" -lt 0 ] && dtx=0

if [ "$cpu" -ge 80 ]; then col=$RED; elif [ "$cpu" -ge 50 ]; then col=$YELLOW; else col=$GREEN; fi

sketchybar --set cpu icon.color="$col" label="${cpu}% · ${mem}%" \
	--set cpu.row.1 label="CPU   ${cpu}%" \
	--set cpu.row.2 label="RAM   ${mem}%" \
	--set cpu.row.3 label="SSD   ${davail} free" \
	--set cpu.row.4 label="NET   ↓${drx}  ↑${dtx} KB/s" \
	--set cpu.row.5 label="TOP   ${top_proc}"
