#!/usr/bin/env bash
# PostToolUse hook: auto-format the edited file with the project's prettier config.
# Silent on every failure mode — hooks must never interrupt the conversation.
#
# Triggers: Edit, Write, MultiEdit
# Skips when:
#   - input has no file_path
#   - file no longer exists
#   - no enclosing package.json above the file
#   - no prettier config anywhere in the directory tree above the file
#     (matches VS Code's prettier.requireConfig: true — never format with defaults)

set -uo pipefail

input="$(cat)"

file_path="$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)"
[[ -z "$file_path" || ! -f "$file_path" ]] && exit 0

# Walk up from the file looking for ANY prettier config.
# Prettier itself walks up to discover the config — we mirror that to decide whether
# to invoke it at all (so projects without configs aren't reformatted with defaults).
has_prettier_config() {
  local dir="$1"
  shopt -s nullglob
  while [[ "$dir" != "/" && "$dir" != "." ]]; do
    local matches=("$dir"/.prettierrc*)
    if [[ ${#matches[@]} -gt 0 ]] \
      || [[ -f "$dir/prettier.config.js" ]] \
      || [[ -f "$dir/prettier.config.cjs" ]] \
      || [[ -f "$dir/prettier.config.mjs" ]] \
      || { [[ -f "$dir/package.json" ]] && jq -e '.prettier' "$dir/package.json" >/dev/null 2>&1; }; then
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  return 1
}

# Walk up to nearest package.json — that's where prettier is installed (node_modules).
nearest_package_dir() {
  local dir="$1"
  while [[ "$dir" != "/" && "$dir" != "." ]]; do
    [[ -f "$dir/package.json" ]] && { printf '%s' "$dir"; return; }
    dir="$(dirname "$dir")"
  done
}

file_dir="$(dirname "$file_path")"

has_prettier_config "$file_dir" || exit 0

work_dir="$(nearest_package_dir "$file_dir")"
[[ -z "$work_dir" ]] && exit 0

# Find the project's local prettier binary by walking up from work_dir.
# Skip if prettier isn't installed locally — don't auto-install via npx.
prettier_bin=""
search="$work_dir"
while [[ "$search" != "/" && "$search" != "." ]]; do
  if [[ -x "$search/node_modules/.bin/prettier" ]]; then
    prettier_bin="$search/node_modules/.bin/prettier"
    break
  fi
  search="$(dirname "$search")"
done
[[ -z "$prettier_bin" ]] && exit 0

cd "$work_dir" || exit 0
"$prettier_bin" --write --log-level=warn "$file_path" >/dev/null 2>&1 || true
exit 0
