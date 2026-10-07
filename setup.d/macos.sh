#!/usr/bin/env bash

# Apply macOS preferences.
#
# Usage:
#   ./setup --tag macos

# Enable key repeat in WezTerm. Fully quit and reopen it afterward.
defaults write com.github.wez.wezterm ApplePressAndHoldEnabled -bool false
