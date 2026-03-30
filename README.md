# claude-project-status (Warp Edition)

Claude project detection for [Warp Terminal](https://www.warp.dev/). Shows the current Claude project in Warp's **tab title** — zero interference with Warp's prompt rendering.

```
┌─ metale [claude md,local] ─────────────────────────┐
│ $ ls                                                │
│ src/  CLAUDE.md  .claude/                           │
└─────────────────────────────────────────────────────┘
  ↑ project info in Warp's tab/session title
```

## Why a Warp-specific version?

Warp renders its own prompt and ignores the shell's `PROMPT`/`RPROMPT`/`PS1` by default. Standard shell prompt integrations either don't show up or break Warp's UI.

This version uses **OSC title escape sequences** (`\e]0;...\a`) which Warp natively renders in tab titles and block headers. No PROMPT or RPROMPT is touched.

## Install

```sh
git clone https://github.com/stamate/claude-project-status-warp.git ~/.claude-project-status
~/.claude-project-status/install.sh
exec $SHELL
```

### Manual

Add to `~/.zshrc`:

```zsh
source ~/.claude-project-status/claude-project-status.zsh
```

### Uninstall

```sh
~/.claude-project-status/uninstall.sh
rm -rf ~/.claude-project-status
exec $SHELL
```

## What It Does

When you `cd` into a Claude project, the Warp tab title updates to:

```
metale [claude md,local]
```

When you `cd` out, the title resets to the current directory name.

## What It Detects

| Marker | Flag | Meaning |
|--------|------|---------|
| `.claude/` | — | Claude configuration directory |
| `CLAUDE.md` | `md` | Project instructions |
| `.claude/settings.json` | `cfg` | Project settings |
| `.claude/settings.local.json` | `local` | Local permission overrides |

Detection walks up from `$PWD` to `/`, stopping at the first match. Home directory is excluded.

## CLI Tool

```sh
$ claude-project-info
Claude Project: metale
Root:           /Users/c/lab/metale
Flags:          md,local

$ claude-project-info --json
{"is_project": true, "root": "...", "name": "metale", ...}

$ claude-project-info --quiet && echo "yes"
yes
```

Make it globally available:

```sh
./install.sh --link
```

## Configuration

| Variable | Purpose |
|----------|---------|
| `CLAUDE_PROMPT_DISABLE=1` | Disable the integration |
| `CLAUDE_PROJECT_ROOT=/path` | Override detected root |

## Performance

| Scenario | Time |
|----------|------|
| Cache hit (same dir) | ~0ms |
| Cache miss (dir changed) | ~2ms |

Pure POSIX shell — no dependencies.

## Files

```
claude-project-status.zsh    # Warp integration (precmd → tab title)
bin/claude-project-info      # CLI tool
lib/detect.sh                # Walk-up detection + caching
lib/encode.sh                # Path encoding for session lookups
install.sh                   # Installer
uninstall.sh                 # Uninstaller
test/run_tests.sh            # Test suite
```

## License

MIT
