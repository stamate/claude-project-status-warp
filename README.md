# claude-project-status (Warp Edition)

Claude project detection for [Warp Terminal](https://www.warp.dev/). Shows the current Claude project **in Warp's prompt bar** — right next to the git branch, using [Starship](https://starship.rs/).

```
~/lab/metale   main  ⚡metale md,local
                              └──────────────────┘
                              appears in Claude projects
```

## Why a Warp-specific version?

Warp renders its own prompt bar and ignores the shell's `PROMPT`/`PS1`. Standard prompt integrations don't show up or break Warp's UI.

This version uses **Starship** (which Warp natively supports) to add a Claude project segment directly in the prompt bar, alongside directory and git info.

## Prerequisites

- [Warp Terminal](https://www.warp.dev/)
- [Starship](https://starship.rs/) — install with `brew install starship`

## Install

```sh
git clone https://github.com/stamate/claude-project-status-warp.git ~/.claude-project-status
~/.claude-project-status/install.sh
exec $SHELL
```

Then in Warp: **Settings → Appearance → Prompt → select "Shell prompt (PS1)"**

This tells Warp to use Starship's prompt (with Claude info) instead of its native prompt bar. Without this setting, Warp ignores custom prompts.

The installer will:
1. Add Starship init to your `~/.zshrc`
2. Create `~/.config/starship.toml` with git + Claude project modules (or add the Claude module to your existing config)

### Uninstall

```sh
~/.claude-project-status/uninstall.sh
rm -rf ~/.claude-project-status
exec $SHELL
```

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

| Flag | Description |
|------|-------------|
| `-j, --json` | JSON output |
| `-q, --quiet` | Exit code only (0 = project, 1 = not) |
| `-r, --root` | Print project root path |
| `-n, --name` | Print project name |
| `-f, --flags` | Print flags |
| `-s, --sessions` | Include session count |
| `--format STR` | Custom format (`%n` = name, `%f` = flags, `%r` = root) |

## Configuration

| Variable | Purpose |
|----------|---------|
| `CLAUDE_PROMPT_DISABLE=1` | Disable the integration |
| `CLAUDE_PROJECT_ROOT=/path` | Override detected root |

### Customizing the Starship segment

Edit `~/.config/starship.toml`:

```toml
[custom.claude]
format = "[⚡$output]($style) "   # change icon/format
style = "bold purple"              # change color
```

## Performance

| Scenario | Time |
|----------|------|
| Cache hit (same dir) | ~0ms |
| Cache miss (dir changed) | ~2ms |

Pure POSIX shell — no dependencies beyond Starship.

## License

MIT
