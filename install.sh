#!/usr/bin/env bash
# Symlink tracked AI config from this repo into ~/.claude/.
# Idempotent: safe to re-run. Existing real files are backed up to *.bak.<timestamp>.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

mkdir -p "$CLAUDE_DIR"

link() {
  local src="$1"
  local dst="$2"

  if [[ ! -e "$src" ]]; then
    echo "skip: $src missing in repo"
    return
  fi

  if [[ -L "$dst" ]]; then
    if [[ "$(readlink "$dst")" == "$src" ]]; then
      echo "ok:      $dst"
      return
    fi
    echo "replace: $dst (was $(readlink "$dst"))"
    rm "$dst"
  elif [[ -e "$dst" ]]; then
    local backup="$dst.bak.$(date +%Y%m%d-%H%M%S)"
    echo "backup:  $dst -> $backup"
    mv "$dst" "$backup"
  fi

  ln -s "$src" "$dst"
  echo "linked:  $dst -> $src"
}

link "$REPO_DIR/copilot-instructions.md" "$CLAUDE_DIR/CLAUDE.md"
link "$REPO_DIR/claude/settings.json"    "$CLAUDE_DIR/settings.json"
link "$REPO_DIR/claude/statusline.sh"    "$CLAUDE_DIR/statusline.sh"
link "$REPO_DIR/claude/agents"           "$CLAUDE_DIR/agents"
link "$REPO_DIR/claude/hooks"            "$CLAUDE_DIR/hooks"

echo "done."
