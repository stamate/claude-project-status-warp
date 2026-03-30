#!/bin/sh
# Full uninstall: removes source line, starship module, CLI symlink, and this directory
set -e
"$(cd "$(dirname "$0")" && pwd)/install.sh" --uninstall
