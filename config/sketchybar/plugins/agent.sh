#!/bin/bash
# Renders the agent chips + popup from ~/.cache/agent-status/*.status.
# Priority: attention (red) > working (yellow) > idle (blue). Chips show up to 3
# agents, then "+N more". A new attention triggers a subtle bounce + optional sound.

source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"

# Mouse events (from any chip) just drive chip.1's popup.
case "$SENDER" in
mouse.clicked)
	sketchybar --set agent.chip.1 popup.drawing=toggle
	exit 0
	;;
mouse.exited | mouse.exited.global | front_app_switched)
	sketchybar --set agent.chip.1 popup.drawing=off
	exit 0
	;;
esac
[ "$NAME" = "agent.chip.1" ] || exit 0 # only the controller recomputes

SOUND_ON=1 # 1 = play a sound on attention, 0 = silent (bounce still happens)
ATTENTION_SOUND="/System/Library/Sounds/Tink.aiff"
CACHE_DIR="$HOME/.cache/agent-status"
ATTN_SEEN="$CACHE_DIR/.attention-seen"
NOW=$(date +%s)
STALE=1800 # drop a "working" entry older than 30 min (agent likely died)

LIVE_WINDOWS="$(tmux list-windows -a -F '#{session_name}:#{window_id}' 2>/dev/null)"
attention=()
working=()
idle=()
attn_keys="" # session:window_id of agents currently needing attention

if [ -d "$CACHE_DIR" ]; then
	for f in "$CACHE_DIR"/*.status; do
		[ -f "$f" ] || continue
		IFS='|' read -r state agent epoch session window_id window_name <"$f" 2>/dev/null
		[ -n "$state" ] || continue
		# prune entries whose tmux window is gone
		if ! printf '%s\n' "$LIVE_WINDOWS" | grep -qxF "$session:$window_id"; then
			rm -f "$f"
			continue
		fi
		[ -n "$window_name" ] || window_name="$session"
		case "$state" in
		working)
			[ $((NOW - ${epoch:-0})) -gt "$STALE" ] && {
				rm -f "$f"
				continue
			}
			working+=("$window_name|$agent")
			;;
		attention)
			attention+=("$window_name|$agent")
			attn_keys="$attn_keys $session:$window_id"
			;;
		idle | done) idle+=("$window_name|$agent") ;;
		esac
	done
fi

# priority order: attention, working, idle
ordered=()
for e in "${attention[@]}"; do ordered+=("$e|attention"); done
for e in "${working[@]}"; do ordered+=("$e|working"); done
for e in "${idle[@]}"; do ordered+=("$e|idle"); done
count=${#ordered[@]}

icon_for() { case "$1" in attention) printf '%s' "$AGENT_WAIT" ;; working) printf '%s' "$AGENT_WORKING" ;; idle) printf '%s' "$AGENT_IDLE" ;; esac; }
color_for() { case "$1" in attention) printf '%s' "$RED" ;; working) printf '%s' "$YELLOW" ;; idle) printf '%s' "$BLUE" ;; esac; }
agent_icon() { case "$1" in claude) printf '%s' "$AGENT_ICON_CLAUDE" ;; cursor) printf '%s' "$AGENT_ICON_CURSOR" ;; codex) printf '%s' "$AGENT_ICON_CODEX" ;; pi) printf '%s' "$AGENT_ICON_PI" ;; *) printf '%s' ":default:" ;; esac; }
agent_font() { case "$1" in pi) printf '%s' "SF Pro:Semibold:$ICON_SIZE" ;; *) printf '%s' "sketchybar-app-font:Regular:$ICON_SIZE" ;; esac; }
# chip label: always the window name (all states)
set_chip() { sketchybar --set "agent.chip.$1" drawing=on icon="$2" icon.color="$3" label="$4" label.color="$3"; }
hide_chip() { sketchybar --set "agent.chip.$1" drawing=off; }

# ---- chip: only the highest-priority agent (attention > working > idle); +N for the rest ----
if [ "$count" -eq 0 ]; then
	hide_chip 1
else
	IFS='|' read -r name agent state <<<"${ordered[0]}"
	label="$name"
	[ "$count" -gt 1 ] && label="$name +$((count - 1))"
	set_chip 1 "$(icon_for "$state")" "$(color_for "$state")" "$label"
fi

# ---- popup: full list with provider logos ----
idx=1
for e in "${ordered[@]}"; do
	[ "$idx" -gt 8 ] && break
	IFS='|' read -r name agent state <<<"$e"
	case "$state" in attention) human="needs you" ;; working) human="working" ;; idle) human="idle" ;; esac
	sketchybar --set agent.row.$idx drawing=on \
		icon="$(agent_icon "$agent")" icon.font="$(agent_font "$agent")" icon.color="$(color_for "$state")" \
		label="$name · $human" label.color=$LABEL_COLOR
	idx=$((idx + 1))
done
while [ "$idx" -le 8 ]; do
	sketchybar --set agent.row.$idx drawing=off
	idx=$((idx + 1))
done

# ---- attention cue: fire once when an agent newly needs you ----
prev_attn="$(cat "$ATTN_SEEN" 2>/dev/null)"
new_attention=0
for k in $attn_keys; do
	case " $prev_attn " in *" $k "*) ;; *) new_attention=1 ;; esac
done
printf '%s' "$attn_keys" >"$ATTN_SEEN"
if [ "$new_attention" -eq 1 ]; then
	sketchybar --animate tanh 20 --set agent.chip.1 y_offset=6 y_offset=0 >/dev/null 2>&1
	if [ "$SOUND_ON" -eq 1 ] && [ -f "$ATTENTION_SOUND" ]; then
		/usr/bin/afplay "$ATTENTION_SOUND" >/dev/null 2>&1 &
	fi
fi
