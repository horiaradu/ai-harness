# ai-instructions

Version-controlled config for Claude Code (and Copilot, sharing the same instructions file).

## Layout

```
.
├── copilot-instructions.md   # shared Copilot + Claude global instructions (~/.claude/CLAUDE.md)
├── claude/
│   ├── settings.json         # ~/.claude/settings.json
│   ├── statusline.sh         # ~/.claude/statusline.sh
│   ├── agents/               # ~/.claude/agents/
│   └── hooks/                # ~/.claude/hooks/
└── install.sh                # creates the symlinks above
```

Everything else under `~/.claude/` (sessions, cache, history, plans, plugins, etc.) is runtime data and is intentionally not tracked.

## Setup on a new machine

```bash
git clone <repo-url> ~/dev/ai-instructions
cd ~/dev/ai-instructions
./install.sh
```

`install.sh` is idempotent. If a real file already exists at the target, it's moved to `*.bak.<timestamp>` before the symlink is created.

## Adding new agents or hooks

Just drop the file into `claude/agents/` or `claude/hooks/` and commit. The directories themselves are symlinked, so no install step is needed after the first run.
