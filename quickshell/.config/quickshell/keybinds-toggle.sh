#!/usr/bin/env bash
set -e -u

SELF="$(readlink -f "$0")"
REPO_ROOT="$(cd "$(dirname "$SELF")/../../.." && pwd)"
SRC="$REPO_ROOT/KEYBINDS.md"
[ -f "$SRC" ] && ln -sf "$SRC" "$HOME/.cache/cryo-keybinds.md"

STATE="$HOME/.cache/cryo-keybinds-shown"
[ -f "$STATE" ] || echo "0" >"$STATE"
if [ "$(cat "$STATE")" = "1" ]; then
  echo "0" >"$STATE"
else
  echo "1" >"$STATE"
fi
