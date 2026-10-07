#!/usr/bin/env bash

# Install packages from the Brewfile. Homebrew must already be installed.
#
# Usage:
#   ./setup --tag brew
#
# Examples:
#   ./setup --tag brew

brew bundle install --file="$REPO_ROOT/homebrew/Brewfile"
