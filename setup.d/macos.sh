#!/usr/bin/env bash

# Apply macOS preferences.
#
# Usage:
#   ./setup --tag macos

# Enable key repeat in WezTerm. Fully quit and reopen it afterward.
defaults write com.github.wez.wezterm ApplePressAndHoldEnabled -bool false

# OmniWM needs "Displays have separate Spaces". Takes effect after logging out.
defaults write com.apple.spaces spans-displays -bool false

# Start OmniWM at login instead of AeroSpace.
osascript -e 'tell application "System Events" to if exists login item "AeroSpace" then delete login item "AeroSpace"'
osascript -e 'tell application "System Events" to if not (exists login item "OmniWM") then make login item at end with properties {path:"/Applications/OmniWM.app", hidden:false}'

brew services start sketchybar
skhd --start-service

# Import RSS feeds; existing feeds are kept, not duplicated.
pgrep -xq eilmeldung || eilmeldung --import-opml "$REPO_ROOT/config/eilmeldung/feeds.opml"

defaults write mo.com.sleeplessmind.kindaVim appsToIgnore -string '["com.tinycast.app","net.kovidgoyal.kitty","com.mitchellh.ghostty","com.github.wez.wezterm","com.googlecode.iterm2","com.raycast-x.macos","net.kovidgoyal.kitty-quick-access"]'
