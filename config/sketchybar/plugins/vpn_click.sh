#!/bin/bash
# Toggle Tailscale on click (OpenVPN Connect can't be toggled from the CLI).

if tailscale status &>/dev/null; then
	tailscale down
else
	tailscale up
fi

sketchybar --trigger vpn_update
