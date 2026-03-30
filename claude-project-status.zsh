#!/usr/bin/env zsh
# claude-project-status: Warp-native integration
#
# Sets the Warp tab/session title to include Claude project info.
# Does NOT touch PROMPT or RPROMPT — zero interference with Warp's rendering.
#
# Usage: Add to ~/.zshrc:
#   source /path/to/claude-project-status-warp/claude-project-status.zsh
#
# What you see in Warp's tab bar:
#   Inside a project:  "metale [claude md,local]"
#   Outside a project: normal Warp title behavior

# Guard against double-sourcing
if (( ${+functions[_claude_warp_precmd]} )); then
    return 0
fi

# Resolve script directory
local _cps_dir="${0:A:h}"

# Source detection library
source "${_cps_dir}/lib/detect.sh"

# Save Warp's default title behavior
typeset -g _CLAUDE_WARP_ORIG_TITLE=""
typeset -g _CLAUDE_WARP_ACTIVE=0

# Set terminal title via OSC escape sequence
# Works in Warp, iTerm2, Terminal.app, and most modern terminals
_claude_set_title() {
    printf '\e]0;%s\a' "$1"
}

# precmd hook: update title on every prompt render
_claude_warp_precmd() {
    _claude_detect_project

    if [[ -n "$_CLAUDE_PS_NAME" ]]; then
        local title="${_CLAUDE_PS_NAME}"
        if [[ -n "$_CLAUDE_PS_FLAGS" ]]; then
            title="${title} [claude ${_CLAUDE_PS_FLAGS}]"
        else
            title="${title} [claude]"
        fi
        _claude_set_title "$title"
        _CLAUDE_WARP_ACTIVE=1
    elif (( _CLAUDE_WARP_ACTIVE )); then
        # Left a project — reset title to current directory name
        _claude_set_title "${PWD##*/}"
        _CLAUDE_WARP_ACTIVE=0
    fi
}

autoload -U add-zsh-hook
add-zsh-hook precmd _claude_warp_precmd
