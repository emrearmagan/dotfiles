#!/usr/bin/env bash

set -euo pipefail

# Shared color utility (Catppuccin Mocha).
#
# Available names:
# - text
# - subtext0
# - subtext1
# - overlay0
# - overlay1
# - overlay2
# - rosewater
# - flamingo
# - pink
# - mauve
# - red
# - maroon
# - peach
# - yellow
# - green
# - teal
# - sky
# - sapphire
# - blue
# - lavender
#
# Usage:
#   source "$(dirname "$0")/colors.sh"
#   printf '%s\n' "$(colorize mauve '== Header ==')"
#   printf '%b' "$(getColor red)"
#   ./colors.sh red "hello"
#   echo "hello" | ./colors.sh red

if [[ -n "${FORCE_COLOR:-}" && -z "${NO_COLOR:-}" ]]; then
  COLOR_ENABLED=1
elif [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  COLOR_ENABLED=1
else
  COLOR_ENABLED=0
fi

colorize() {
  local name="${1:-}"
  shift || true
  local text="$*"
  local prefix
  prefix=$(getColor "$name")
  [[ -n "$prefix" ]] || { printf '%s' "$text"; return; }

  if [[ "$COLOR_ENABLED" == "1" ]]; then
    printf '%b%s\033[0m' "$prefix" "$text"
  else
    printf '%s' "$text"
  fi
}

isKnownColor() {
  local name="${1:-}"
  case "$name" in
    text|subtext0|subtext1|overlay0|overlay1|overlay2|rosewater|flamingo|pink|mauve|red|maroon|peach|yellow|green|teal|sky|sapphire|blue|lavender)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

# Returns ANSI prefix for Catppuccin color names.
# Unknown names return empty.
getColor() {
  local name="${1:-}"
  local code=""

  [[ "$COLOR_ENABLED" == "1" ]] || { printf ''; return; }

  case "$name" in
    text) code="38;2;205;214;244" ;;
    subtext0) code="38;2;166;173;200" ;;
    subtext1) code="38;2;186;194;222" ;;
    overlay0) code="38;2;108;112;134" ;;
    overlay1) code="38;2;127;132;156" ;;
    overlay2) code="38;2;147;153;178" ;;
    rosewater) code="38;2;245;224;220" ;;
    flamingo) code="38;2;242;205;205" ;;
    pink) code="38;2;245;194;231" ;;
    mauve) code="38;2;203;166;247" ;;
    red) code="38;2;243;139;168" ;;
    maroon) code="38;2;235;160;172" ;;
    peach) code="38;2;250;179;135" ;;
    yellow) code="38;2;249;226;175" ;;
    green) code="38;2;166;227;161" ;;
    teal) code="38;2;148;226;213" ;;
    sky) code="38;2;137;220;235" ;;
    sapphire) code="38;2;116;199;236" ;;
    blue) code="38;2;137;180;250" ;;
    lavender) code="38;2;180;190;254" ;;
    *) printf ''; return ;;
  esac

  printf '\033[%sm' "$code"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  script_name="$(basename "$0")"

  color_name="${1:-}"
  if [[ -z "$color_name" && "$script_name" == colors.* ]]; then
    color_name="${script_name#colors.}"
  fi

  if [[ -z "$color_name" ]]; then
    printf 'usage: %s <color> [text]\n' "$script_name" >&2
    exit 1
  fi

  if ! isKnownColor "$color_name"; then
    printf 'unknown color: %s\n' "$color_name" >&2
    exit 1
  fi

  if [[ $# -gt 1 ]]; then
    shift
    printf '%s\n' "$(colorize "$color_name" "$*")"
  elif [ -p /dev/stdin ]; then
    input="$(cat)"
    printf '%s' "$(colorize "$color_name" "$input")"
  else
    printf '%b\n' "$(getColor "$color_name")"
  fi
fi
