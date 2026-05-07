#!/usr/bin/env bash
# Claude Code status line — compact single-line output.
# Receives JSON on stdin from Claude Code.

input="$(cat)"

# --- model ---
model="$(printf '%s' "$input" | jq -r '.model.display_name // empty')"

# --- directory: shorten relative to $HOME, keep at most 3 segments ---
cwd="$(printf '%s' "$input" | jq -r '.workspace.current_dir // .cwd // empty')"
home="${HOME:-/Users/horiaradu}"
# Strip $HOME prefix
short="${cwd#"$home/"}"
# If nothing was stripped it's an absolute path outside $HOME — use as-is
if [[ "$short" == "$cwd" ]]; then
  short="$cwd"
fi
# Keep only the last 3 path components
short="$(printf '%s' "$short" | awk -F'/' '{ n=NF; if(n>3){ printf "..."; for(i=n-2;i<=n;i++) printf "/"$i } else print $0 }')"

# --- git branch (from the workspace cwd, skip optional locks) ---
branch=""
if [[ -n "$cwd" && -d "$cwd" ]]; then
  branch="$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null \
    || GIT_OPTIONAL_LOCKS=0 git -C "$cwd" rev-parse --short HEAD 2>/dev/null)"
fi

# --- context usage ---
used_pct="$(printf '%s' "$input" | jq -r '.context_window.used_percentage // empty')"

# --- assemble ---
# Color codes: only used for the Opus warning; everything else is plain text
# so the line reads fine in monochrome panes.
RESET='\033[0m'
BOLD='\033[1m'
YELLOW='\033[33m'

parts=()

# Model — highlight Opus so it stands out
if [[ "$model" == *"Opus"* ]]; then
  model_str="$(printf "${BOLD}${YELLOW}%s${RESET}" "$model")"
else
  model_str="$model"
fi
[[ -n "$model_str" ]] && parts+=("$model_str")

# Directory
[[ -n "$short" ]] && parts+=("$short")

# Branch
[[ -n "$branch" ]] && parts+=("($branch)")

# Context — only show when ≥10% used so it's not noisy on fresh sessions
if [[ -n "$used_pct" ]]; then
  used_int="$(printf '%.0f' "$used_pct")"
  if (( used_int >= 10 )); then
    parts+=("ctx:${used_int}%")
  fi
fi

# Join with " | "
line=""
for part in "${parts[@]}"; do
  if [[ -z "$line" ]]; then
    line="$part"
  else
    line="$line | $part"
  fi
done

printf '%b' "$line"
