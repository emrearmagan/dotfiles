#!/usr/bin/env bash
set -euo pipefail

# ---- core helpers ----

USE_COLOR=0
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  USE_COLOR=1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROGRESSBAR_BIN="$SCRIPT_DIR/progressbar"

ansi() {
  local code="$1"
  shift
  if [[ "$USE_COLOR" == "1" ]]; then
    printf '\033[%sm%s\033[0m' "$code" "$*"
  else
    printf '%s' "$*"
  fi
}

label() { ansi "1;96" "$1"; }
dim() { ansi "90" "$1"; }
ok() { ansi "32" "$1"; }
warn() { ansi "33" "$1"; }
bad() { ansi "31" "$1"; }

color_by_used() {
  local used="$1"
  if [[ ! "$used" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    printf '37'
    return
  fi
  if (( $(jq -nr --argjson u "$used" 'if $u < 50 then 1 else 0 end') )); then
    printf '32'
  elif (( $(jq -nr --argjson u "$used" 'if $u < 80 then 1 else 0 end') )); then
    printf '33'
  else
    printf '31'
  fi
}

need() { command -v "$1" >/dev/null 2>&1 || { echo "missing: $1" >&2; exit 1; }; }
need curl
need jq

line() { printf "%-10s %s\n" "$(label "$1")" "$2"; }
sep() { printf '%s\n' "$(dim '------------------------------------------------------------')"; }
section() { printf '\n%s\n' "$(ansi '1;95' "== $1 ==")"; }

bar() {
  local used="$1"
  [[ "$used" =~ ^[0-9]+([.][0-9]+)?$ ]] || { printf '░░░░░░░░░░░░░░░░░░░░'; return; }

  local pct raw
  pct=$(jq -nr --argjson u "$used" '($u | floor)')

  if [[ -x "$PROGRESSBAR_BIN" ]]; then
    raw=$("$PROGRESSBAR_BIN" "$pct%" -s 20 -w "█" 2>/dev/null || true)
    raw=${raw#|}
    raw=${raw%|}
    raw=${raw// /░}
    [[ -n "$raw" ]] || raw='░░░░░░░░░░░░░░░░░░░░'
    ansi "$(color_by_used "$used")" "$raw"
    return
  fi

  printf '░░░░░░░░░░░░░░░░░░░░'
}

eta() {
  local sec="${1:-}"
  [[ "$sec" =~ ^[0-9]+$ ]] || { printf 'n/a'; return; }
  (( sec <= 0 )) && { printf 'now'; return; }
  local d h m
  d=$((sec / 86400))
  h=$(((sec % 86400) / 3600))
  m=$(((sec % 3600) / 60))
  if (( d > 0 )); then
    printf '%dd %dh' "$d" "$h"
  elif (( h > 0 )); then
    printf '%dh %dm' "$h" "$m"
  else
    printf '%dm' "$m"
  fi
}

usd() {
  local n="${1:-}"
  [[ "$n" =~ ^-?[0-9]+([.][0-9]+)?$ ]] || { printf '%s' "$n"; return; }
  jq -nr --argjson n "$n" '"$" + (($n * 100 | round) / 100 | tostring)'
}

# ---- GitHub Copilot ----

copilot() {
  local reset_epoch
  section "GitHub Copilot"
  local apps="$HOME/.config/github-copilot/apps.json"
  [[ -f "$apps" ]] || { line status "apps.json missing"; return; }

  local token
  token=$(sed '1s/^\xEF\xBB\xBF//' "$apps" | jq -r 'to_entries[]?.value.oauth_token' | head -n1)
  [[ -n "$token" && "$token" != "null" ]] || { line status "token missing"; return; }

  local r
  r=$(curl -fsS -H "Authorization: Bearer $token" https://api.github.com/copilot_internal/user) || { line status "request failed"; return; }

  local used left total reset login plan sku left_pct used_pct
  total=$(jq -r '.quota_snapshots.premium_interactions.entitlement // 0' <<<"$r")
  left=$(jq -r '.quota_snapshots.premium_interactions.remaining // 0' <<<"$r")
  used=$(jq -r '(.quota_snapshots.premium_interactions.entitlement // 0) - (.quota_snapshots.premium_interactions.remaining // 0)' <<<"$r")
  reset=$(jq -r '.quota_reset_date // .quota_reset_date_utc // "n/a"' <<<"$r")
  login=$(jq -r '.login // empty' <<<"$r")
  plan=$(jq -r '.copilot_plan // empty' <<<"$r")
  sku=$(jq -r '.access_type_sku // empty' <<<"$r")

  if [[ "$total" =~ ^[0-9]+([.][0-9]+)?$ ]] && [[ "$left" =~ ^[0-9]+([.][0-9]+)?$ ]] && [[ "$total" != "0" ]]; then
    left_pct=$(jq -nr --argjson l "$left" --argjson t "$total" '($l * 100 / $t)')
    used_pct=$(jq -nr --argjson u "$used" --argjson t "$total" '($u * 100 / $t)')
  else
    left_pct=$(jq -r '.quota_snapshots.premium_interactions.percent_remaining // empty' <<<"$r")
    used_pct=$(jq -nr --argjson l "${left_pct:-0}" '100 - $l' 2>/dev/null || echo "0")
  fi

  printf '%s: %s/%s left %s\n' "$(label 'Premium')" "$left" "$total" "$(bar "$used_pct")"
  if [[ "$reset" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
    reset_epoch=$(date -j -f '%Y-%m-%d %H:%M:%S' "$reset 00:00:00" '+%s' 2>/dev/null || true)
    if [[ -n "${reset_epoch:-}" ]]; then
      local now rem
      now=$(date '+%s')
      rem=$((reset_epoch - now))
      if (( rem > 0 )); then
        printf '%s %s\n' "$(dim 'Resets in')" "$(eta "$rem")"
      else
        printf '%s %s\n' "$(dim 'Resets on')" "$reset"
      fi
    else
      printf '%s %s\n' "$(dim 'Resets on')" "$reset"
    fi
  else
    printf '%s %s\n' "$(dim 'Resets on')" "$reset"
  fi
  local plan_pretty
  plan_pretty=""
  [[ -n "$plan" ]] && plan_pretty="$(tr '[:lower:]' '[:upper:]' <<<"${plan:0:1}")${plan:1}"
  if [[ -n "$login" && -n "$plan_pretty" && -n "$sku" ]]; then
    printf '%s: %s (%s - %s)\n' "$(label 'Account')" "$login" "$plan_pretty" "$sku"
  elif [[ -n "$login" && -n "$plan_pretty" ]]; then
    printf '%s: %s (%s)\n' "$(label 'Account')" "$login" "$plan_pretty"
  elif [[ -n "$login" ]]; then
    printf '%s: %s\n' "$(label 'Account')" "$login"
  elif [[ -n "$plan_pretty" ]]; then
    printf '%s: %s\n' "$(label 'Plan')" "$plan_pretty"
  fi
}

# ---- OpenRouter ----

openrouter() {
  section "OpenRouter"
  [[ -n "${OPENROUTER_API_KEY:-}" ]] || { line status "OPENROUTER_API_KEY missing"; return; }

  local r
  r=$(curl -fsS https://openrouter.ai/api/v1/key -H "Authorization: Bearer $OPENROUTER_API_KEY") || { line status "request failed"; return; }

  local label_key used limit left used_pct reset expires tier
  local usage_daily usage_weekly usage_monthly
  label_key=$(jq -r '.data.label // empty' <<<"$r")
  used=$(jq -r '.data.usage // "n/a"' <<<"$r")
  limit=$(jq -r '.data.limit // "n/a"' <<<"$r")
  left=$(jq -r '.data.limit_remaining // empty' <<<"$r")
  reset=$(jq -r '.data.limit_reset // empty' <<<"$r")
  expires=$(jq -r '.data.expires_at // empty' <<<"$r")
  tier=$(jq -r '.data.is_free_tier // false' <<<"$r")
  usage_daily=$(jq -r '.data.usage_daily // empty' <<<"$r")
  usage_weekly=$(jq -r '.data.usage_weekly // empty' <<<"$r")
  usage_monthly=$(jq -r '.data.usage_monthly // empty' <<<"$r")

  if [[ -z "$left" ]] && jq -e '.data.usage != null and .data.limit != null' >/dev/null 2>&1 <<<"$r"; then
    left=$(jq -r '(.data.limit - .data.usage)' <<<"$r")
  fi

  if [[ "$used" =~ ^[0-9]+([.][0-9]+)?$ ]] && [[ "$limit" =~ ^[0-9]+([.][0-9]+)?$ ]] && [[ "$limit" != "0" ]]; then
    used_pct=$(jq -nr --argjson u "$used" --argjson l "$limit" '($u * 100 / $l)')
  else
    used_pct=""
  fi

  printf '%s: %s/%s left %s\n' "$(label 'Credits')" "$(usd "$left")" "$(usd "$limit")" "$(bar "$used_pct")"
  [[ -n "$usage_daily" ]] && printf '%s: %s\n' "$(label 'Daily')" "$(usd "$usage_daily")"
  [[ -n "$usage_weekly" ]] && printf '%s: %s\n' "$(label 'Weekly')" "$(usd "$usage_weekly")"
  [[ -n "$usage_monthly" ]] && printf '%s: %s\n' "$(label 'Monthly')" "$(usd "$usage_monthly")"

  if [[ -n "$reset" && "$reset" != "null" ]]; then
    printf '%s %s\n' "$(dim 'Resets on')" "$reset"
  elif [[ -n "$expires" && "$expires" != "null" ]]; then
    printf '%s %s\n' "$(dim 'Expires on')" "$expires"
  else
    printf '%s %s\n' "$(dim 'Resets')" "n/a"
  fi

  if [[ -n "$label_key" ]]; then
    if [[ "$tier" == "true" ]]; then
      printf '%s: %s (%s)\n' "$(label 'Account')" "$label_key" "Free tier"
    else
      printf '%s: %s\n' "$(label 'Account')" "$label_key"
    fi
  fi
}

# ---- generic command-backed providers (Cursor, etc.) ----

provider_from_cmd() {
  local name="$1"
  local cmd="$2"
  section "$name"
  [[ -n "$cmd" ]] || { line status "cmd not set"; return; }
  if out=$(eval "$cmd" 2>&1); then
    printf "%s\n" "$out"
  else
    line status "command failed"
    printf "%s\n" "$out"
  fi
}

# ---- Codex ----

codex() {
  local version
  version=$(jq -r '.latest_version // empty' "$HOME/.codex/version.json" 2>/dev/null || true)
  [[ -n "$version" ]] || version="unknown"
  printf '%s\n' "$(ansi '1;94' "== Codex $version (codex-cli) ==")"

  local auth="$HOME/.codex/auth.json"
  [[ -f "$auth" ]] || { line status "~/.codex/auth.json missing"; return; }

  local token r
  token=$(jq -r '.tokens.access_token // empty' "$auth")
  [[ -n "$token" ]] || { line status "access token missing"; return; }

  r=$(curl --connect-timeout 4 --max-time 10 -fsS "https://chatgpt.com/backend-api/wham/usage" -H "Authorization: Bearer $token" -H "Accept: application/json") || {
    line status "usage request failed"
    return
  }

  local p_used s_used p_left s_left p_reset_after s_reset_after
  local email plan credits p_window s_window
  p_used=$(jq -r '.rate_limit.primary_window.used_percent // .primary.used_percent // .rate_limits.primary.used_percent // .usage.primary.usedPercent // empty' <<<"$r")
  s_used=$(jq -r '.rate_limit.secondary_window.used_percent // .secondary.used_percent // .rate_limits.secondary.used_percent // .usage.secondary.usedPercent // empty' <<<"$r")
  p_reset_after=$(jq -r '.rate_limit.primary_window.reset_after_seconds // empty' <<<"$r")
  s_reset_after=$(jq -r '.rate_limit.secondary_window.reset_after_seconds // empty' <<<"$r")
  p_window=$(jq -r '.rate_limit.primary_window.limit_window_seconds // 18000' <<<"$r")
  s_window=$(jq -r '.rate_limit.secondary_window.limit_window_seconds // 604800' <<<"$r")
  email=$(jq -r '.email // empty' <<<"$r")
  plan=$(jq -r '.plan_type // empty' <<<"$r")
  credits=$(jq -r '.credits.balance // "n/a"' <<<"$r")

  [[ "$p_used" =~ ^[0-9]+([.][0-9]+)?$ ]] && p_left=$(jq -nr "100 - ($p_used)") || p_left="n/a"
  [[ "$s_used" =~ ^[0-9]+([.][0-9]+)?$ ]] && s_left=$(jq -nr "100 - ($s_used)") || s_left="n/a"

  local p_left_i s_left_i
  p_left_i=$(jq -nr --argjson n "$p_left" '($n|round)' 2>/dev/null || echo "n/a")
  s_left_i=$(jq -nr --argjson n "$s_left" '($n|round)' 2>/dev/null || echo "n/a")

  local p_reset_txt s_reset_txt
  p_reset_txt=$(eta "$p_reset_after")
  s_reset_txt=$(eta "$s_reset_after")

  printf '%s: %s%% left %s %s\n' "$(label 'Session')" "$p_left_i" "$(bar "$p_used")" "$(dim "(resets in $p_reset_txt)")"
  printf '%s: %s%% left %s %s\n' "$(label 'Weekly')" "$s_left_i" "$(bar "$s_used")" "$(dim "(resets in $s_reset_txt)")"

  local pace_line
  pace_line=""
  if [[ "$s_used" =~ ^[0-9]+$ && "$s_reset_after" =~ ^[0-9]+$ && "$s_window" =~ ^[0-9]+$ ]]; then
    local elapsed expected delta projected eta_to_100
    elapsed=$((s_window - s_reset_after))
    if (( elapsed > 0 )); then
      expected=$((elapsed * 100 / s_window))
      if (( s_used >= expected )); then
        delta=$((s_used - expected))
        pace_line="Pace: ${delta}% in deficit | Expected ${expected}% used"
      else
        delta=$((expected - s_used))
        pace_line="Pace: ${delta}% in reserve | Expected ${expected}% used"
      fi

      if (( s_used > 0 )); then
        projected=$((s_used * s_window / elapsed))
        if (( projected <= 100 )); then
          pace_line+=" | Lasts until reset"
        else
          eta_to_100=$(((100 - s_used) * elapsed / s_used))
          pace_line+=" | Runs out in $(eta "$eta_to_100")"
        fi
      fi
    fi
  fi
  [[ -n "$pace_line" ]] && printf '%s\n' "$(warn "$pace_line")"

  printf '%s: %s left\n' "$(label 'Credits')" "$credits"
  local plan_pretty
  plan_pretty=""
  [[ -n "$plan" ]] && plan_pretty="$(tr '[:lower:]' '[:upper:]' <<<"${plan:0:1}")${plan:1}"
  if [[ -n "$email" && -n "$plan_pretty" ]]; then
    printf '%s: %s (%s)\n' "$(label 'Account')" "$email" "$plan_pretty"
  elif [[ -n "$email" ]]; then
    printf '%s: %s\n' "$(label 'Account')" "$email"
  elif [[ -n "$plan_pretty" ]]; then
    printf '%s: %s\n' "$(label 'Plan')" "$plan_pretty"
  fi
}

# ---- main ----

main() {
  copilot
  sep
  openrouter
  sep
  provider_from_cmd "Cursor" "${CURSOR_USAGE_CMD:-}"
  sep
  codex
  printf '\n'
}

main "$@"
