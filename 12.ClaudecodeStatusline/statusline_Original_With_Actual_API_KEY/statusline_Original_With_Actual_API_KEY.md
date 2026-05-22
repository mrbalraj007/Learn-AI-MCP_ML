# Custom Claude Code Status Line — Setup Guide

## Overview

Claude Code has a built-in status line that appears at the bottom of the terminal during interactive sessions. This guide documents a **custom enhanced status line** that shows:

| Segment | Icon | Description | Color |
|---------|------|-------------|-------|
| Directory |  | Current working directory (basename) | Blue |
| Git branch |  | Active git branch or short commit SHA | Purple |
| Model |  | Current AI model name (e.g., Opus 4.7) | Cyan |
| Context |  | Context window usage percentage | Yellow |
| 5-hour usage |  | API usage in the current 5-hour window | Green |
| 7-day usage |  | API usage in the current 7-day window | Cyan |
| Reset time |  | When the 5-hour usage window resets (IST) | Red |

The usage data (5-hour, 7-day, reset time) is fetched live from `api.anthropic.com/api/oauth/usage` and cached for 60 seconds.

---

## Prerequisites (Windows VM / Git Bash)

Run these commands in **Git Bash** (MINGW64) as Administrator:

### 1. Install jq (JSON processor)

```bash
# Option A: via winget (recommended)
winget install jqlang.jq --accept-package-agreements

# Option B: via Chocolatey
choco install jq -y

# Verify installation (restart terminal first)
jq --version
```

### 2. Install curl (usually pre-installed with Git Bash)

```bash
# Verify
curl --version
```

### 3. Ensure Git is installed

```bash
git --version
```

### 4. Install a Nerd Font (for icons)

Without a Nerd Font, the status line icons will show as boxes (`□`) or blank characters.

1. Go to https://www.nerdfonts.com/font-downloads
2. Download **Caskaydia Cove Nerd Font** or **FiraCode Nerd Font**
3. Extract the `.zip` and install all `.ttf` files (right-click → **Install** on Windows)
4. Open your terminal settings (Ctrl+, in Windows Terminal)
5. Under **Appearance**, set **Font face** to the installed Nerd Font
6. Restart Claude Code

### 5. Verify `jq` is reachable from your shell startup

In Git Bash:

```bash
which jq
# Should print: /c/Users/Administrator/AppData/Local/Microsoft/WinGet/Links/jq
```

### 6. Claude Code authenticated

The script reads your OAuth token from one of these sources (checked in order):
1. `$CLAUDE_CODE_OAUTH_TOKEN` environment variable
2. macOS keychain (`security find-generic-password`) — macOS only
3. `~/.claude/.credentials.json` — created automatically when you log into Claude Code

Run `claude login` if you haven't already.

---

## Files Created

### File 1: `~/.claude/statusline.sh` (the script)

**Path:** `C:\Users\Administrator\.claude\statusline.sh`

```sh
#!/bin/sh
# Ensure jq and curl are in PATH (winget / MSYS2 / choco locations)
for p in \
  "$HOME/AppData/Local/Microsoft/WinGet/Links" \
  "/c/Users/Administrator/AppData/Local/Microsoft/WinGet/Links" \
  "/mingw64/bin" \
  "/usr/bin" \
  "/c/ProgramData/chocolatey/bin" \
  "/c/Program Files/Git/usr/bin" \
  "/c/Program Files/Git/mingw64/bin"; do
  case ":$PATH:" in *":$p:"*) ;; *) [ -d "$p" ] && PATH="$p:$PATH" ;; esac
done
export PATH

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
```

### File 2: `~/.claude/settings.json` (the configuration)

**Path:** `C:\Users\Administrator\.claude\settings.json`

```json
{
  "autoUpdatesChannel": "latest",
  "theme": "dark",
  "statusLine": {
    "type": "command",
    "command": "bash \"$HOME/.claude/statusline.sh\""
  }
}
```

### File 3: Usage cache (auto-created at runtime)

**Path:** `/tmp/claude/statusline-usage-cache.json`

This is created automatically by the script. It caches the Anthropic API usage response for 60 seconds to avoid rate-limiting the OAuth endpoint. No manual setup needed.

---

## How It Works

```
Claude Code
    │
    │  Every render tick, Claude Code sends JSON to stdin:
    │  { "cwd": "/path/to/project",
    │    "model": { "display_name": "Opus 4.7" },
    │    "context_window": { "used_percentage": 42 } }
    │
    ▼
statusline.sh
    │
    ├─ 1. Fixes PATH to find jq and curl (multiple fallback locations)
    ├─ 2. Parses JSON from stdin: cwd, model, context %
    ├─ 3. Checks git branch (with hooks disabled for speed)
    ├─ 4. Reads OAuth token from:
    │      a) $CLAUDE_CODE_OAUTH_TOKEN env var
    │      b) macOS keychain
    │      c) ~/.claude/.credentials.json
    ├─ 5. Fetches usage from api.anthropic.com (cached 60s)
    ├─ 6. Renders color-coded segments with Nerd Font icons
    │
    ▼
ANSI-escaped status line printed to stdout
    │
    ▼
Claude Code displays it in the bottom bar
```

---

## Troubleshooting

### Status line is blank or shows `bash: jq: command not found`

`jq` is not in PATH when Claude Code spawns the shell. The script already includes a PATH-fixing block at the top, but if it still fails:

```bash
# Find where jq lives
where jq   # Windows CMD
which jq   # Git Bash

# Add that directory to the `for p in` list at the top of statusline.sh
```

### Icons show as boxes (□) or question marks

Your terminal font doesn't include Nerd Font glyphs. Install a Nerd Font (see Prerequisites step 4).

### Usage stats always show 0% or don't appear

Check your OAuth token is valid:

```bash
cat ~/.claude/.credentials.json | jq '.claudeAiOauth.accessToken'
```

If the file doesn't exist or the token is missing, run:

```bash
claude login
```

### Wrong timezone for reset time

The script uses `Asia/Kolkata` timezone. To change it, search for `TZ="Asia/Kolkata"` in `statusline.sh` (appears 4 times) and replace with your timezone (e.g., `America/New_York`, `Europe/London`, `Asia/Tokyo`).

### Slow status line rendering

The `curl` call has a 5-second timeout. If the API is unreachable, the script falls back to cached data. First render after cache expiry will block for up to 5 seconds — subsequent renders use the cache.

---

## Customization

### Change icons

Replace the hex sequences in the `IC_*` variables (lines 81-87). Find Nerd Font codepoints at https://www.nerdfonts.com/cheat-sheet.

### Change colors

Colors use ANSI escape codes in the format `ESC[<style>;<color>m`:
- `[0;34m` = blue (directory)
- `[0;35m` = purple (branch)
- `[0;36m` = cyan (model, weekly)
- `[0;33m` = yellow (context)
- `[0;32m` = green (5-hour)
- `[0;31m` = red (reset time)

Change the number after `[0;` — valid values: 30-37 (standard colors), 90-97 (bright colors).

### Remove segments

Delete or comment out the `*_part` variable and its corresponding `%s` in the final `printf` line. Each `%s` corresponds to one segment in order: `$git_part`, `$ctx_part`, `$current_part`, `$weekly_part`, `$reset_part`.



===========================================
<!-- 
----------------------

Here's what each part means:

  ┌────────────┬─────────────────────────────┬────────┐
  │    Icon    │        What it shows        │ Color  │
  ├────────────┼─────────────────────────────┼────────┤
  │  Folder   │ Current directory name      │ Blue   │
  ├────────────┼─────────────────────────────┼────────┤
  │  Branch   │ Git branch (if in a repo)   │ Purple │
  ├────────────┼─────────────────────────────┼────────┤
  │  Robot    │ Model name (Opus 4.7)       │ Cyan   │
  ├────────────┼─────────────────────────────┼────────┤
  │  Bolt     │ Context window usage %      │ Yellow │
  ├────────────┼─────────────────────────────┼────────┤
  │  Clock    │ 5-hour API usage %          │ Green  │
  ├────────────┼─────────────────────────────┼────────┤
  │  Calendar │ 7-day API usage %           │ Cyan   │
  ├────────────┼─────────────────────────────┼────────┤
  │  Reset    │ Next usage reset time (IST) │ Red    │
  └────────────┴─────────────────────────────┴────────┘


  I cann't see the following while others are working fine. Would you please fix it as well.
  
  Clock    │ 5-hour API usage %          │ Green  │
  ├────────────┼─────────────────────────────┼────────┤
  │  Calendar │ 7-day API usage %           │ Cyan   │
  ├────────────┼─────────────────────────────┼────────┤
  │  Reset    │ Next usage reset time (IST) │ Red   -->