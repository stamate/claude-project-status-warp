#!/bin/sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CPS_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

. "$CPS_ROOT/lib/detect.sh"
. "$CPS_ROOT/lib/encode.sh"

PASS=0; FAIL=0; TOTAL=0

check() {
    TOTAL=$((TOTAL + 1))
    if [ "$2" = "$3" ]; then
        printf '  PASS: %s\n' "$1"; PASS=$((PASS + 1))
    else
        printf '  FAIL: %s\n    expected: [%s]\n    actual:   [%s]\n' "$1" "$2" "$3"; FAIL=$((FAIL + 1))
    fi
}

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# Setup test projects
mkdir -p "$TMPDIR/full/.claude"
printf '{}' > "$TMPDIR/full/.claude/settings.json"
printf '{}' > "$TMPDIR/full/.claude/settings.local.json"
printf '#' > "$TMPDIR/full/CLAUDE.md"
mkdir -p "$TMPDIR/full/src/deep"
mkdir -p "$TMPDIR/mdonly/src"
printf '#' > "$TMPDIR/mdonly/CLAUDE.md"
mkdir -p "$TMPDIR/bare/.claude"
mkdir -p "$TMPDIR/nothing/src"

printf '\n=== Detection ===\n'

_CLAUDE_PS_CACHED_PWD=""; PWD="$TMPDIR/full"
_claude_detect_project
check "full project: root" "$TMPDIR/full" "$_CLAUDE_PS_ROOT"
check "full project: name" "full" "$_CLAUDE_PS_NAME"
check "full project: flags" "md,cfg,local" "$_CLAUDE_PS_FLAGS"

_CLAUDE_PS_CACHED_PWD=""; PWD="$TMPDIR/full/src/deep"
_claude_detect_project
check "nested: finds root" "$TMPDIR/full" "$_CLAUDE_PS_ROOT"

_CLAUDE_PS_CACHED_PWD=""; PWD="$TMPDIR/mdonly"
_claude_detect_project
check "md-only: root" "$TMPDIR/mdonly" "$_CLAUDE_PS_ROOT"
check "md-only: flags" "md" "$_CLAUDE_PS_FLAGS"

_CLAUDE_PS_CACHED_PWD=""; PWD="$TMPDIR/mdonly/src"
_claude_detect_project
check "md-only nested: walks up" "$TMPDIR/mdonly" "$_CLAUDE_PS_ROOT"

_CLAUDE_PS_CACHED_PWD=""; PWD="$TMPDIR/bare"
_claude_detect_project
check "bare .claude/: detected" "$TMPDIR/bare" "$_CLAUDE_PS_ROOT"
check "bare .claude/: no flags" "" "$_CLAUDE_PS_FLAGS"

_CLAUDE_PS_CACHED_PWD=""; PWD="$TMPDIR/nothing/src"
_claude_detect_project
check "non-project: no root" "" "$_CLAUDE_PS_ROOT"

# Cache
_CLAUDE_PS_CACHED_PWD="$TMPDIR/full"; _CLAUDE_PS_NAME="full"; _CLAUDE_PS_FLAGS="test_cached"
PWD="$TMPDIR/full"
_claude_detect_project
check "cache hit: preserved" "test_cached" "$_CLAUDE_PS_FLAGS"

# Disable/re-enable
_CLAUDE_PS_CACHED_PWD=""; PWD="$TMPDIR/full"
_claude_detect_project
check "pre-disable: detected" "full" "$_CLAUDE_PS_NAME"
CLAUDE_PROMPT_DISABLE=1; _claude_detect_project
check "disabled: cleared" "" "$_CLAUDE_PS_NAME"
unset CLAUDE_PROMPT_DISABLE; _claude_detect_project
check "re-enabled: detected" "full" "$_CLAUDE_PS_NAME"

# HOME exclusion
FAKE_HOME="$TMPDIR/fakehome"; mkdir -p "$FAKE_HOME/.claude"
OLD_HOME="$HOME"; HOME="$FAKE_HOME"
_CLAUDE_PS_CACHED_PWD=""; PWD="$FAKE_HOME"
_claude_detect_project
check "HOME excluded" "" "$_CLAUDE_PS_ROOT"
HOME="$OLD_HOME"

# Override
_CLAUDE_PS_CACHED_PWD=""; CLAUDE_PROJECT_ROOT="$TMPDIR/mdonly"; PWD="$TMPDIR/nothing"
_claude_detect_project
check "override root" "$TMPDIR/mdonly" "$_CLAUDE_PS_ROOT"
unset CLAUDE_PROJECT_ROOT

printf '\n=== Encoding ===\n'

check "encode basic" "-Users-c-lab" "$(_claude_encode_path "/Users/c/lab")"
check "encode dots" "-Users-c--ssh" "$(_claude_encode_path "/Users/c/.ssh")"
check "encode underscores" "-Users-c-lab-my-proj" "$(_claude_encode_path "/Users/c/lab/my_proj")"

printf '\n=== Results: %d/%d passed ===\n' "$PASS" "$TOTAL"
[ "$FAIL" -eq 0 ] || exit 1
printf 'All tests passed!\n'
