#!/usr/bin/env bash

# Install JetBrains Mono Nerd Font, SF Pro, and both SketchyBar app fonts.
# SketchyBar's status icons use SF Symbols from SF Pro.
#
# Usage:
#   ./setup --tag fonts
#
# Examples:
#   ./setup --tag fonts

for font_cask in font-jetbrains-mono-nerd-font font-sf-pro font-sketchybar-app-font; do
	if brew list --cask "$font_cask" >/dev/null 2>&1; then
		printf '%s (already installed)\n' "$font_cask"
	else
		# Adopt identical font files from installations outside Homebrew.
		brew install --cask --adopt "$font_cask"
	fi
done

# The background icon variant is not available as a Homebrew cask.
background_font="$HOME/Library/Fonts/sketchybar-app-font-bg.ttf"
if [[ -s "$background_font" ]]; then
	printf '%s (already installed)\n' "sketchybar-app-font-bg"
else
	mkdir -p "$HOME/Library/Fonts"
	curl --fail --location --show-error \
		"https://soichiroyamane.github.io/sketchybar-app-font-bg/dist/sketchybar-app-font-bg.ttf" \
		--output "$background_font.download"
	mv "$background_font.download" "$background_font"
fi
