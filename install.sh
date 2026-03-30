#!/bin/sh
# claude-project-status: Installer for Warp Terminal (via Starship)
# Sets up Starship with a Claude project custom module.
set -e

CPS_ROOT="$(cd "$(dirname "$0")" && pwd)"
MARKER="# claude-project-status"
ZSHRC="$HOME/.zshrc"
STARSHIP_CONFIG="$HOME/.config/starship.toml"

case "${1:-}" in
    --uninstall)
        printf 'Uninstalling claude-project-status...\n'

        # Remove our line from .zshrc
        for rc in "$ZSHRC" "$HOME/.bashrc"; do
            if [ -f "$rc" ] && grep -qF "$MARKER" "$rc"; then
                tmp=$(mktemp)
                grep -v "$MARKER" "$rc" > "$tmp"
                mv "$tmp" "$rc"
                printf '  Removed from %s\n' "$rc"
            fi
        done

        # Remove claude module from starship.toml
        if [ -f "$STARSHIP_CONFIG" ] && grep -q 'custom.claude' "$STARSHIP_CONFIG"; then
            tmp=$(mktemp)
            awk '
                /^\[custom\.claude\]/ { skip=1; next }
                /^\[/ && skip { skip=0 }
                !skip { print }
            ' "$STARSHIP_CONFIG" | sed '/^# Claude project status$/d' > "$tmp"
            mv "$tmp" "$STARSHIP_CONFIG"
            printf '  Removed Claude module from %s\n' "$STARSHIP_CONFIG"
        fi

        # Remove starship.toml entirely if we created it and it has no user content left
        if [ -f "$STARSHIP_CONFIG" ]; then
            # Check if only our boilerplate remains (no custom sections besides ours)
            remaining=$(grep -c '^\[' "$STARSHIP_CONFIG" 2>/dev/null || true)
            if [ "$remaining" -eq 0 ]; then
                rm "$STARSHIP_CONFIG"
                printf '  Removed empty %s\n' "$STARSHIP_CONFIG"
            fi
        fi

        # Remove CLI symlink
        if [ -L "$HOME/.local/bin/claude-project-info" ]; then
            rm "$HOME/.local/bin/claude-project-info"
            printf '  Removed CLI symlink\n'
        fi

        # Remove the cloned repo directory
        if [ -d "$CPS_ROOT" ] && [ -f "$CPS_ROOT/claude-project-status.zsh" ]; then
            printf '  Removing %s\n' "$CPS_ROOT"
            # Can't rm ourselves while running — schedule removal after script exits
            trap "rm -rf '$CPS_ROOT'" EXIT
        fi

        printf 'Done. Run: exec $SHELL\n'
        exit 0 ;;
    --link)
        mkdir -p "$HOME/.local/bin"
        ln -sf "$CPS_ROOT/bin/claude-project-info" "$HOME/.local/bin/claude-project-info"
        printf 'Symlinked claude-project-info to ~/.local/bin/\n'
        exit 0 ;;
    -h|--help)
        printf 'Usage: ./install.sh [--uninstall] [--link] [-h]\n'
        exit 0 ;;
esac

# --- Check prerequisites ---
if ! command -v starship >/dev/null 2>&1; then
    printf 'Starship is required but not installed.\n'
    printf 'Install it with: brew install starship\n'
    printf 'Then re-run this installer.\n'
    exit 1
fi

# --- Make CLI executable ---
chmod +x "$CPS_ROOT/bin/claude-project-info"

# --- Add starship init to .zshrc ---
[ ! -f "$ZSHRC" ] && touch "$ZSHRC"

if grep -qF "$MARKER" "$ZSHRC" 2>/dev/null; then
    printf 'Already installed in %s\n' "$ZSHRC"
else
    printf '\neval "$(starship init zsh)" %s\n' "$MARKER" >> "$ZSHRC"
    printf 'Added starship init to %s\n' "$ZSHRC"
    # Warp users: enable Settings → Appearance → Prompt → "Shell prompt (PS1)"
    if [ "$TERM_PROGRAM" = "WarpTerminal" ]; then
        printf '\n  NOTE: In Warp, go to Settings → Appearance → Prompt → select "Shell prompt (PS1)"\n'
        printf '  This makes Starship (with Claude info) appear in all tabs.\n'
    fi
fi

# --- Create or update starship.toml ---
mkdir -p "$(dirname "$STARSHIP_CONFIG")"

if [ -f "$STARSHIP_CONFIG" ]; then
    # Config exists — add claude module if not present
    if grep -q 'custom.claude' "$STARSHIP_CONFIG"; then
        printf 'Claude module already in %s\n' "$STARSHIP_CONFIG"
    else
        printf '\n# Claude project status\n' >> "$STARSHIP_CONFIG"
        cat >> "$STARSHIP_CONFIG" << MODULEEOF

[custom.claude]
command = "${CPS_ROOT}/bin/claude-project-info --format '%n %f' 2>/dev/null"
when = "${CPS_ROOT}/bin/claude-project-info --quiet 2>/dev/null"
format = "[⚡\$output](\$style) "
style = "bold purple"
shell = ["sh"]
description = "Claude project status"
MODULEEOF
        printf 'Added Claude module to %s\n' "$STARSHIP_CONFIG"
    fi
else
    # No config — create one with good defaults + claude module
    cat > "$STARSHIP_CONFIG" << CONFIGEOF
format = """\
\$directory\
\$git_branch\
\$git_status\
\$custom\
\$cmd_duration\
\$line_break\
\$character"""

[directory]
style = "bold cyan"
truncation_length = 3

[git_branch]
format = "[\$symbol\$branch](\$style) "
symbol = " "
style = "bold green"

[git_status]
format = "[\$all_status\$ahead_behind](\$style) "
style = "bold yellow"

[custom.claude]
command = "${CPS_ROOT}/bin/claude-project-info --format '%n %f' 2>/dev/null"
when = "${CPS_ROOT}/bin/claude-project-info --quiet 2>/dev/null"
format = "[⚡\$output](\$style) "
style = "bold purple"
shell = ["sh"]
description = "Claude project status"

[cmd_duration]
min_time = 2000
format = "[\$duration](\$style) "
style = "bold yellow"

[character]
success_symbol = "[❯](bold green)"
error_symbol = "[❯](bold red)"
CONFIGEOF
    printf 'Created %s\n' "$STARSHIP_CONFIG"
fi

printf '\nDone! Run: exec $SHELL\n'
