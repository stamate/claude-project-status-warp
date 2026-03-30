#!/bin/sh
# claude-project-status: Installer for Warp Terminal
# Adds source line to ~/.zshrc. Idempotent.
set -e

CPS_ROOT="$(cd "$(dirname "$0")" && pwd)"
MARKER="# claude-project-status"
SOURCE_LINE="source \"${CPS_ROOT}/claude-project-status.zsh\""

case "${1:-}" in
    --uninstall)
        printf 'Uninstalling claude-project-status...\n'
        for rc in "$HOME/.zshrc" "$HOME/.bashrc"; do
            if [ -f "$rc" ] && grep -qF "$MARKER" "$rc"; then
                tmp=$(mktemp)
                grep -v "$MARKER" "$rc" > "$tmp"
                mv "$tmp" "$rc"
                printf '  Removed from %s\n' "$rc"
            fi
        done
        [ -L "$HOME/.local/bin/claude-project-info" ] && rm "$HOME/.local/bin/claude-project-info" && printf '  Removed CLI symlink\n'
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

ZSHRC="$HOME/.zshrc"
[ ! -f "$ZSHRC" ] && touch "$ZSHRC"

if grep -qF "$MARKER" "$ZSHRC" 2>/dev/null; then
    printf 'Already installed in %s\n' "$ZSHRC"
else
    printf '\n%s %s\n' "$SOURCE_LINE" "$MARKER" >> "$ZSHRC"
    printf 'Added to %s\n' "$ZSHRC"
fi

chmod +x "$CPS_ROOT/bin/claude-project-info"
printf 'Done! Run: exec $SHELL\n'
