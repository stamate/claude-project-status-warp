#!/bin/sh
set -e
exec "$(cd "$(dirname "$0")" && pwd)/install.sh" --uninstall
