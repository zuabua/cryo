#!/usr/bin/env bash
# Refresh the B2 bucket listing
# usage: b2-list.sh

export PATH="$HOME/.local/bin:$PATH"
set -u
CACHE="$HOME/.cache/cryo-b2-list"
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

write_status "Listing bucket..."

TMP="$(mktemp "${CACHE}.XXXXXX")"
if b2 ls --recursive "b2://${BUCKET}" >"$TMP" 2>/dev/null; then
  mv "$TMP" "$CACHE"
  COUNT=$(wc -l <"$CACHE")
  write_status "OK: listed ${COUNT} items"
else
  rm -f "$TMP"
  write_status "ERR: listing failed"
  exit 1
fi
