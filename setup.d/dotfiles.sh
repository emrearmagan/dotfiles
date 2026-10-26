#!/usr/bin/env bash

# Link configs into your home directory.
# Existing files and links are backed up in ~/.dotfiles_backup/.
#
# Usage:
#   ./setup --tag dotfiles
#
# Add links as:
#   link "path in this repo" "path in your home directory"
#
# Examples:
#   ./setup --tag dotfiles

link "homebrew/Brewfile" "Brewfile"
link "config/zsh/.zshrc" ".zshrc"
link "config/zsh/.zprofile" ".zprofile"
link "config/system/alias" ".config/alias"
link "config/system/scripts" ".config/scripts"
link "config/git/.gitconfig" ".gitconfig"
link "config/git/.gitignore_global" ".gitignore_global"

link "config/wezterm" ".config/wezterm"
link "config/kitty" ".config/kitty"
link "config/ghostty" ".config/ghostty"
link "config/tmux" ".config/tmux"
link "config/nvim" ".config/nvim"
link "config/vim/vimrc" ".vimrc"
link "config/bat" ".config/bat"
link "config/lazygit" ".config/lazygit"
link "config/starship/starship.toml" ".config/starship.toml"
link "config/aerospace" ".config/aerospace"
link "config/omniwm" ".config/omniwm"
link "config/skhd" ".config/skhd"
link "config/sketchybar" ".config/sketchybar"
link "config/borders" ".config/borders"

link "config/opencode" ".config/opencode"
link "config/pi" ".pi/agent"
link "config/mcp/mcp.json" ".pi/agent/mcp.json"
link "config/claude/settings.json" ".claude/settings.json"
link "config/cursor/hooks.json" ".cursor/hooks.json"
link "config/codex/hooks.json" ".codex/hooks.json"

link "config/agents" ".agents"
link "config/agents/AGENTS.md" ".codex/AGENTS.md"
link "config/agents/AGENTS.md" ".claude/CLAUDE.md"
# Claude Code only reads ~/.claude/skills and keeps its own synced skills there, so link each skill.
for skill in "$REPO_ROOT"/config/agents/skills/*/; do
	skill=$(basename "$skill")
	link "config/agents/skills/$skill" ".claude/skills/$skill"
done
link "config/mcp/mcp.json" ".config/mcp/mcp.json"

link "config/btop" ".config/btop"
link "config/ripgrep" ".config/ripgrep"
link "config/worktrunk" ".config/worktrunk"
link "config/tealdeer" ".config/tealdeer"
link "config/eilmeldung" ".config/eilmeldung"
link "config/matcha" ".config/matcha"
link "config/maki" ".config/maki"
