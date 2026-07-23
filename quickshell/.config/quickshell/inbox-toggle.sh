#!/usr/bin/env bash

# Toggle the Quickshell inbox capture drawer using state file

STATE="$HOME/.cache/cryo-inbox-shown"
[ -f "$STATE" ] || echo "0" >"$STATE"
if [ "$(cat "$STATE")" = "1" ]; then
  echo "0" >"$STATE"
else
  echo "1" >"$STATE"
fi
