#!/usr/bin/env bash

# Install Neovim's Xcode tools and physical-device support.
# Install and select the full Xcode app separately.
#
# Usage:
#   ./setup --tag xcode
#
# Examples:
#   ./setup --tag xcode

brew install xcp xcode-build-server xcbeautify pipx rg jq coreutils
pipx install pymobiledevice3
