#!/usr/bin/env bash
# Delete a single file from the b2 bucket.
# usage: b2-delete <remote-path>

export PATH="$HOME/.local/bin:$PATH"
set -u
STATUS="$HOME/.cache/cryo-b2-status"
CREDS="$HOME/.config/b2/credentials"

write_status() { echo "$1" >"$STATUS"; }

if [ ! -r "$CREDS" ]; then
  write_status "ERR: missing $CREDS"
  exit 1
fi
# shellcheck disable=SC1090
source "$CREDS"
BUCKET="${B2_BUCKET:-backup}"
b2 account authorize "$B2_KEY_ID" "$B2_APP_KEY" >/dev/null 2>&1 || {
  write_status "ERR: b2 authorize failed"
  exit 1
}

REMOTE="${1:-}"
if [ -z "$REMOTE" ]; then
  write_status "ERR: usage: b2-delete.sh <remote-path>"
  exit 1
fi

case "$REMOTE" in
*..* | *\** | *\?* | *\$* | *\`* | *\;*)
  write_status "ERR: invalid path"
  exit 1
  ;;
esac

write_status "Deleting ${REMOTE} ..."
if b2 rm --quiet "b2://${BUCKET}/${REMOTE}" >/dev/null 2>&1; then
  write_status "OK: deleted ${REMOTE}"
else
  write_status "ERR: delete failed: ${REMOTE}"
  exit 1
fi
