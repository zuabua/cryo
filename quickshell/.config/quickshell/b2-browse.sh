#!/usr/bin/env bash
# Fuzzy find a b2 using wofi
# usage: b2-browse.sh fetch|delete

export PATH="$HOME/.local/bin:$PATH"
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
CACHE="$HOME/.cache/cryo-b2-list"
STATUS="$HOME/.cache/cryo-b2-status"

write_status() { echo "$1" >"$STATUS"; }

ACTION="${1:-}"
case "$ACTION" in
fetch | delete) ;;
*)
  write_status "ERR: usage: b2-browse.sh fetch|delete"
  exit 1
  ;;
esac

if [ ! -s "$CACHE" ]; then
  write_status "ERR: no cached list (try refresh)"
  exit 1
fi

PROMPT="B2 $ACTION"
PICK="$(wofi --dmenu --prompt "$PROMPT" --insensitive <"$CACHE")" || exit 0
[ -n "$PICK" ] || exit 0

case "$ACTION" in
fetch)
  DEST="$(zenity --file-selection --directory --title='Save to which directory?')" || exit 0
  "$HERE/b2-fetch.sh" "$PICK" "$DEST"
  ;;
delete)
  zenity --question --title='Delete from B2?' \
    --text="Delete: $PICK"$'\n\n'"This cannot be undone." || exit 0
  "$HERE/b2-delete.sh" "$PICK" && "$HERE/b2-list.sh"
  ;;
esac
