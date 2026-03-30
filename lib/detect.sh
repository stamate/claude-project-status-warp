#!/bin/sh
# claude-project-status: Core detection logic
# Walks up from $PWD to find Claude project markers (.claude/ or CLAUDE.md)
# Caches results keyed on $PWD for prompt-render speed

_CLAUDE_PS_CACHED_PWD=""
_CLAUDE_PS_ROOT=""
_CLAUDE_PS_NAME=""
_CLAUDE_PS_FLAGS=""

_claude_detect_project() {
    if [ "${CLAUDE_PROMPT_DISABLE:-0}" = "1" ]; then
        _CLAUDE_PS_CACHED_PWD=""
        _CLAUDE_PS_ROOT=""
        _CLAUDE_PS_NAME=""
        _CLAUDE_PS_FLAGS=""
        return 0
    fi

    # Cache hit
    if [ "$_CLAUDE_PS_CACHED_PWD" = "$PWD" ]; then
        return 0
    fi

    local root=""

    if [ -n "${CLAUDE_PROJECT_ROOT:-}" ]; then
        [ -d "$CLAUDE_PROJECT_ROOT" ] && root="$CLAUDE_PROJECT_ROOT"
    else
        local dir="$PWD"
        while true; do
            if [ -d "$dir/.claude" ]; then
                root="$dir"
                break
            fi
            if [ -f "$dir/CLAUDE.md" ]; then
                root="$dir"
                break
            fi
            [ "$dir" = "/" ] && break
            dir=$(dirname "$dir")
        done
    fi

    # Exclude $HOME
    [ "$root" = "$HOME" ] && root=""

    if [ -z "$root" ]; then
        _CLAUDE_PS_CACHED_PWD="$PWD"
        _CLAUDE_PS_ROOT=""
        _CLAUDE_PS_NAME=""
        _CLAUDE_PS_FLAGS=""
        return 0
    fi

    # Build flags
    local flags=""
    [ -f "$root/CLAUDE.md" ]                   && flags="md"
    [ -f "$root/.claude/settings.json" ]       && flags="${flags:+$flags,}cfg"
    [ -f "$root/.claude/settings.local.json" ] && flags="${flags:+$flags,}local"

    _CLAUDE_PS_ROOT="$root"
    _CLAUDE_PS_NAME=$(basename "$root")
    _CLAUDE_PS_FLAGS="$flags"
    _CLAUDE_PS_CACHED_PWD="$PWD"
}
