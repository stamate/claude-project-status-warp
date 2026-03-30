#!/bin/sh
# Path encoding for ~/.claude/projects/ lookups
# Convention: replace / . _ with -

_claude_encode_path() {
    printf '%s' "$1" | tr '/._' '---'
}

_claude_count_sessions() {
    local project_root="$1"
    local claude_home="${CLAUDE_HOME:-$HOME/.claude}"
    local encoded
    encoded=$(_claude_encode_path "$project_root")
    local projects_dir="${claude_home}/projects/${encoded}"

    if [ ! -d "$projects_dir" ]; then
        printf '0'
        return 0
    fi

    local count=0
    for f in "$projects_dir"/*.jsonl; do
        [ -f "$f" ] && count=$((count + 1))
    done
    printf '%d' "$count"
}
