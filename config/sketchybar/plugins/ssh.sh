#!/usr/bin/env bash
# Detects outgoing SSH sessions and shows the host(s). Skips `-W` ProxyJump
# helpers and extracts the host from each ssh client's command line.

source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"

case "$SENDER" in
mouse.clicked)
	sketchybar --set ssh popup.drawing=toggle
	exit 0
	;;
mouse.exited | mouse.exited.global | front_app_switched)
	sketchybar --set ssh popup.drawing=off
	exit 0
	;;
esac

hosts=()
while IFS= read -r cmd; do
	[ -n "$cmd" ] || continue
	case " $cmd " in *" -W "*) continue ;; esac # skip ProxyJump helper
	# host = first non-option token (options in `oa` take a following argument)
	host=$(printf '%s\n' "$cmd" | awk '{
		oa="bcDEeFIiJLlmOopQRSWw"
		for (i=2; i<=NF; i++) { t=$i
			if (t ~ /^-/) { if (length(t)==2 && index(oa, substr(t,2,1))>0) i++; continue }
			print t; exit }
	}')
	[ -n "$host" ] && hosts+=("$host")
done < <(ps -axo command | awk '$1=="ssh" || $1 ~ /\/ssh$/')

n=${#hosts[@]}
if [ "$n" -eq 0 ]; then
	sketchybar --set ssh drawing=off
	for i in $(seq 1 8); do sketchybar --set ssh.row.$i drawing=off; done
	exit 0
fi

# Icon only on the bar; host names live in the popup.
sketchybar --set ssh drawing=on icon=$SSH_ICON icon.color=$TEAL label=""

idx=1
for h in "${hosts[@]}"; do
	[ "$idx" -gt 8 ] && break
	sketchybar --set ssh.row.$idx drawing=on label="$h"
	idx=$((idx + 1))
done
while [ "$idx" -le 8 ]; do
	sketchybar --set ssh.row.$idx drawing=off
	idx=$((idx + 1))
done
