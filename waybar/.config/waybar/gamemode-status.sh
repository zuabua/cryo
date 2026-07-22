#!/usr/bin/env bash
# Experimental gamemode i plan on changing in the future

set -u

STATE="$HOME/.cache/voidglow-gamemode"

val="0"
if [ -f "$STATE" ]; then
  val=$(tr -d '[:space:]' <"$STATE" 2>/dev/null || true)
  [ -z "$val" ] && val="0"
fi

if [ "$val" = "1" ]; then
  printf '%s\n' '{"text":"\uf11b","class":"on","tooltip":"Gamemode ON"}'
else
  printf '%s\n' '{"text":"\uf11b","class":"off","tooltip":"Gamemode OFF"}'
fi
