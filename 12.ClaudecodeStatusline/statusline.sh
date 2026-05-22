#!/bin/sh
input=$(cat)

cwd=$(echo "$input" | jq -r '.cwd')
model=$(echo "$input" | jq -r '.model.display_name')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# Git branch (skip optional locks)
branch=""
if git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git -C "$cwd" -c core.hooksPath=/dev/null symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
fi

short_dir=$(basename "$cwd")

# ── OAuth token ─────────────────────────────────────────
get_oauth_token() {
  if [ -n "$CLAUDE_CODE_OAUTH_TOKEN" ]; then
    echo "$CLAUDE_CODE_OAUTH_TOKEN"; return 0
  fi
  if command -v security >/dev/null 2>&1; then
    blob=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null)
    if [ -n "$blob" ]; then
      token=$(echo "$blob" | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null)
      [ -n "$token" ] && [ "$token" != "null" ] && echo "$token" && return 0
    fi
  fi
  creds="$HOME/.claude/.credentials.json"
  if [ -f "$creds" ]; then
    token=$(jq -r '.claudeAiOauth.accessToken // empty' "$creds" 2>/dev/null)
    [ -n "$token" ] && [ "$token" != "null" ] && echo "$token" && return 0
  fi
  echo ""
}

# ── Fetch usage (cached 60s) ────────────────────────────
cache_file="/tmp/claude/statusline-usage-cache.json"
mkdir -p /tmp/claude

usage_data=""
needs_refresh=true

if [ -f "$cache_file" ]; then
  cache_mtime=$(stat -f %m "$cache_file" 2>/dev/null || stat -c %Y "$cache_file" 2>/dev/null)
  now=$(date +%s)
  cache_age=$(( now - cache_mtime ))
  [ "$cache_age" -lt 60 ] && needs_refresh=false && usage_data=$(cat "$cache_file" 2>/dev/null)
fi

if $needs_refresh; then
  token=$(get_oauth_token)
  if [ -n "$token" ] && [ "$token" != "null" ]; then
    response=$(curl -s --max-time 5 \
      -H "Accept: application/json" \
      -H "Authorization: Bearer $token" \
      -H "anthropic-beta: oauth-2025-04-20" \
      -H "User-Agent: claude-code/2.1.34" \
      "https://api.anthropic.com/api/oauth/usage" 2>/dev/null)
    if [ -n "$response" ] && echo "$response" | jq -e '.five_hour' >/dev/null 2>&1; then
      usage_data="$response"
      echo "$response" > "$cache_file"
    fi
  fi
  [ -z "$usage_data" ] && [ -f "$cache_file" ] && usage_data=$(cat "$cache_file" 2>/dev/null)
fi

# ── Nerd Font icons (UTF-8 byte sequences for /bin/sh) ───
IC_FOLDER=$(printf '\xef\x81\xbb')   # U+F07B nf-fa-folder
IC_BRANCH=$(printf '\xee\x82\xa0')   # U+E0A0 nf-pl-branch
IC_ROBOT=$(printf '\xee\xa9\xb7')    # U+EA77 nf-md-robot
IC_BOLT=$(printf '\xef\x83\xa7')     # U+F0E7 nf-fa-bolt
IC_CLOCK=$(printf '\xef\x80\x97')    # U+F017 nf-fa-clock_o
IC_CAL=$(printf '\xef\x81\xb3')      # U+F073 nf-fa-calendar
IC_RESET=$(printf '\xef\x80\xa1')    # U+F021 nf-fa-refresh

# ── Build status parts ──────────────────────────────────
ESC=$(printf '\033')

git_part=""
if [ -n "$branch" ]; then
  git_part=" ${ESC}[0;35m${IC_BRANCH} $branch${ESC}[0m"
fi

ctx_part=""
if [ -n "$used_pct" ]; then
  ctx_part=" ${ESC}[0;33m${IC_BOLT} ${used_pct}%${ESC}[0m"
fi

current_part=""
weekly_part=""
reset_part=""
if [ -n "$usage_data" ] && echo "$usage_data" | jq -e . >/dev/null 2>&1; then
  five_pct=$(echo "$usage_data" | jq -r '.five_hour.utilization // 0' | awk '{printf "%.0f", $1}')
  seven_pct=$(echo "$usage_data" | jq -r '.seven_day.utilization // 0' | awk '{printf "%.0f", $1}')

  current_part=" ${ESC}[0;32m${IC_CLOCK} ${five_pct}%${ESC}[0m"
  weekly_part=" ${ESC}[0;36m${IC_CAL} ${seven_pct}%${ESC}[0m"

  # ── Session end time ──────────────────────────────────
  reset_ts=$(echo "$usage_data" | jq -r '.five_hour.resets_at // empty' 2>/dev/null)
  if [ -n "$reset_ts" ]; then
    if echo "$reset_ts" | grep -qE '^[0-9]+$'; then
      reset_fmt=$(TZ="Asia/Kolkata" date -r "$reset_ts" +"%I:%M %p" 2>/dev/null || TZ="Asia/Kolkata" date -d "@$reset_ts" +"%I:%M %p" 2>/dev/null)
    else
      # Normalize: strip fractional seconds and replace +00:00 with Z
      clean_ts=$(echo "$reset_ts" | sed 's/\.[0-9]*//' | sed 's/+00:00$/Z/')
      epoch=$(TZ=UTC date -j -f "%Y-%m-%dT%H:%M:%SZ" "$clean_ts" +%s 2>/dev/null \
              || TZ=UTC date -d "$reset_ts" +%s 2>/dev/null)
      [ -n "$epoch" ] && reset_fmt=$(TZ="Asia/Kolkata" date -r "$epoch" +"%I:%M %p" 2>/dev/null || TZ="Asia/Kolkata" date -d "@$epoch" +"%I:%M %p" 2>/dev/null)
    fi
    [ -n "$reset_fmt" ] && reset_part=" ${ESC}[0;31m${IC_RESET} $reset_fmt${ESC}[0m"
  fi
fi

printf "${ESC}[0;34m${IC_FOLDER} %s${ESC}[0m%s ${ESC}[0;36m${IC_ROBOT} %s${ESC}[0m%s%s%s%s" \
  "$short_dir" "$git_part " "$model" "$ctx_part " "$current_part " "$weekly_part " "$reset_part"