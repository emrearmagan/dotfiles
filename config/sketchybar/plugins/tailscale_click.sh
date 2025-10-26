#!/bin/bash

# Toggle Tailscale on click
if tailscale status &>/dev/null; then
	# osascript -e 'display notification "Disconnecting Tailscale…" with title "Tailscale"'
	tailscale down
else
	# Disconnected → connect
	# osascript -e 'display notification "Connecting Tailscale…" with title "Tailscale"'
	tailscale up
fi

sketchybar --trigger tailscale_update
