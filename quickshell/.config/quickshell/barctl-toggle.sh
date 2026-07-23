#!/usr/bin/env bash
STATE="$HOME/.cache/voidglow-barctl-shown"
[ -f "$STATE" ] || echo "0" >"$STATE"
if [ "$(cat "$STATE")" = "1" ]; then
  echo "0" >"$STATE"
else
  echo "1" >"$STATE"
fi
