#!/usr/bin/env bash
# LLM Cursor Plugin Auto-Installer

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing llm-cursor plugin..."

if ! command -v llm &> /dev/null; then
    echo "Error: 'llm' command not found. Install with: brew install llm"
    exit 1
fi

if ! command -v cursor-agent &> /dev/null; then
    echo "Warning: 'cursor-agent' not found. Plugin will work once cursor-agent is installed."
fi

llm install -e "$SCRIPT_DIR"

echo "Done. Usage: llm -m cursor/auto 'your prompt'"
