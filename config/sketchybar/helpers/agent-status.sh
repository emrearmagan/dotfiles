#!/usr/bin/env bash
# Report an AI agent's state to the sketchybar `agent` item.
# In tmux, status is keyed per window. Outside tmux, it falls back to
# AGENT_STATUS_ID, TERM_SESSION_ID, tty, then parent pid.
#   Usage: agent-status.sh <event|state> <agent-name>
# Writes ~/.cache/agent-status/*.status and refreshes the bar.

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
CACHE_DIR="$HOME/.cache/agent-status"
mkdir -p "$CACHE_DIR"
HOOK_JSON=""
[ -t 0 ] || HOOK_JSON="$(cat 2>/dev/null)" # hook payload on stdin

EVENT="${1:-}"
AGENT="${2:-agent}"

if [ -n "${TMUX:-}" ]; then
	# Resolve the window of the pane the hook runs in (not the focused one).
	target=()
	[ -n "${TMUX_PANE:-}" ] && target=(-t "$TMUX_PANE")
	session=$(tmux display-message -p "${target[@]}" '#{session_name}' 2>/dev/null)
	window_id=$(tmux display-message -p "${target[@]}" '#{window_id}' 2>/dev/null)
	window_name=$(tmux display-message -p "${target[@]}" '#{window_name}' 2>/dev/null)
	[ -n "$session" ] && [ -n "$window_id" ] || exit 0
	[ -n "$window_name" ] || window_name="$session"
else
	session="local"
	raw_id="${AGENT_STATUS_ID:-${TERM_SESSION_ID:-}}"
	if [ -z "$raw_id" ]; then
		raw_id=$(ps -o tty= -p "$$" 2>/dev/null | awk '{$1=$1};1')
		[ "$raw_id" = "??" ] && raw_id=""
	fi
	[ -n "$raw_id" ] || raw_id="$PPID"
	window_id=$(printf '%s:%s' "$AGENT" "$raw_id" | tr -c 'A-Za-z0-9._-' '_')
	window_name="${AGENT_STATUS_NAME:-${PWD##*/}}"
	[ -n "$window_name" ] || window_name="$AGENT"
fi

safe=$(printf '%s:%s' "$session" "$window_id" | tr -c 'A-Za-z0-9._-' '_')
file="$CACHE_DIR/$safe.status"

case "$EVENT" in
# agent exited — drop its entry
SessionEnd | session_shutdown | session_end | close | quit)
	rm -f "$file"
	sketchybar --trigger agent_status_change 2>/dev/null
	exit 0
	;;
UserPromptSubmit | PreToolUse | PostToolUse | working | \
	before_agent_start | agent_start | \
	beforeSubmitPrompt | beforeShellExecution | beforeMCPExecution | beforeReadFile)
	state=working
	;;
# Claude sends Notification for permission prompts AND idle "waiting for your
# input" pings — only the former is real attention.
Notification)
	case "$HOOK_JSON" in
	*[Ww]aiting*) state=idle ;;
	*) state=attention ;;
	esac
	;;
PermissionRequest | attention)
	state=attention
	;;
Stop | idle | done | agent_end | stop | afterAgentResponse)
	state=idle
	;;
*)
	exit 0
	;;
esac

printf '%s|%s|%s|%s|%s|%s\n' \
	"$state" "$AGENT" "$(date +%s)" "$session" "$window_id" "$window_name" >"$file"
sketchybar --trigger agent_status_change 2>/dev/null
