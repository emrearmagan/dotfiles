#!/usr/bin/env bash

# Apply macOS preferences.
#
# Usage:
#   ./setup --tag macos

# Enable key repeat in WezTerm. Fully quit and reopen it afterward.
defaults write com.github.wez.wezterm ApplePressAndHoldEnabled -bool false

defaults write mo.com.sleeplessmind.kindaVim appsToIgnore -string '["com.tinycast.app","net.kovidgoyal.kitty","com.mitchellh.ghostty","com.github.wez.wezterm","com.googlecode.iterm2","com.raycast-x.macos","net.kovidgoyal.kitty-quick-access"]'
