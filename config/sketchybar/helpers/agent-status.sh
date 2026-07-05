#!/usr/bin/env bash
# Report an AI agent's state to the sketchybar `agent` item, keyed per tmux
# window. Called from each agent's hooks.
#   Usage: agent-status.sh <event|state> <agent-name>
# Writes ~/.cache/agent-status/<session:window>.status and refreshes the bar.

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
CACHE_DIR="$HOME/.cache/agent-status"
mkdir -p "$CACHE_DIR"
HOOK_JSON=""
[ -t 0 ] || HOOK_JSON="$(cat 2>/dev/null)" # hook payload on stdin

EVENT="${1:-}"
AGENT="${2:-agent}"
[ -n "${TMUX:-}" ] || exit 0 # only track agents running inside tmux

# Resolve the window of the pane the hook runs in (not the focused one).
target=()
[ -n "${TMUX_PANE:-}" ] && target=(-t "$TMUX_PANE")
session=$(tmux display-message -p "${target[@]}" '#{session_name}' 2>/dev/null)
window_id=$(tmux display-message -p "${target[@]}" '#{window_id}' 2>/dev/null)
window_name=$(tmux display-message -p "${target[@]}" '#{window_name}' 2>/dev/null)
[ -n "$session" ] && [ -n "$window_id" ] || exit 0
[ -n "$window_name" ] || window_name="$session"

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
