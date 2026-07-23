#!/usr/bin/env bash
# b2 uploader.
# usage b2-upload.sh <category> <path>
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

CATEGORY="${1:-}"
SRC="${2:-}"

if [ -z "$CATEGORY" ] || [ -z "$SRC" ]; then
  write_status "ERR: usage: b2-upload.sh <category> <path>"
  exit 1
fi
if [ ! -e "$SRC" ]; then
  write_status "ERR: not found: $SRC"
  exit 1
fi

BASENAME="$(basename "$SRC")"

if [ -f "$SRC" ]; then
  REMOTE="${CATEGORY}/${BASENAME}"
  write_status "Uploading $BASENAME -> $REMOTE ..."
  if b2 file upload --quiet "$BUCKET" "$SRC" "$REMOTE" >/dev/null 2>&1; then
    write_status "OK: $BASENAME -> $CATEGORY/"
  else
    write_status "ERR: upload failed: $BASENAME"
    exit 1
  fi

elif [ -d "$SRC" ]; then
  REMOTE="${CATEGORY}/${BASENAME}"
  write_status "Syncing $BASENAME -> $REMOTE/ ..."
  if b2 sync \
    --no-progress \
    --keep-days 0 \
    --skip-newer \
    "$SRC" "b2://${BUCKET}/${REMOTE}" >/dev/null 2>&1; then
    write_status "OK: $BASENAME/ -> $CATEGORY/"
  else
    if b2 sync --noProgress --keepDays 0 --skipNewer \
      "$SRC" "b2://${BUCKET}/${REMOTE}" >/dev/null 2>&1; then
      write_status "OK: $BASENAME/ -> $CATEGORY/"
    else
      write_status "ERR: sync failed: $BASENAME/"
      exit 1
    fi
  fi

else
  write_status "ERR: not a file or dir: $SRC"
  exit 1
fi
