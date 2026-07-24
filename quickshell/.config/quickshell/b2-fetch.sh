#!/usr/bin/env bash
# Fetch a single file from the B2 bucket to a local destination.
# usage: b2-fetch.sh <remote-path> <local-dest-dir>
# doesnt overwrite

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
DEST_DIR="${2:-}"

if [ -z "$REMOTE" ] || [ -z "$DEST_DIR" ]; then
  write_status "ERR: usage: b2-fetch.sh <remote-path> <local-dest-dir>"
  exit 1
fi

case "$REMOTE" in
*..* | *\** | *\?* | *\$* | *\`* | *\;*)
  write_status "ERR: invalid remote path"
  exit 1
  ;;
esac

if [ ! -d "$DEST_DIR" ]; then
  write_status "ERR: dest dir does not exist"
  exit 1
fi

BASENAME="$(basename "$REMOTE")"
LOCAL="${DEST_DIR%/}/${BASENAME}"

if [ -e "$LOCAL" ]; then
  write_status "ERR: would overwrite ${BASENAME}"
  exit 1
fi

write_status "Fetching ${BASENAME} ..."
if b2 file download --quiet "b2://${BUCKET}/${REMOTE}" "$LOCAL" >/dev/null 2>&1; then
  write_status "OK: fetched ${BASENAME} -> ${DEST_DIR%/}"
else
  write_status "ERR: fetch failed: ${BASENAME}"
  exit 1
fi
