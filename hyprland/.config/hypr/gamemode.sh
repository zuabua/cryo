#!/usr/bin/env bash

STATE="$HOME/.cache/cryo-gamemode"
[ -f "$STATE" ] || echo "0" >"$STATE"
CURRENT="$(cat "$STATE")"

if [ "$CURRENT" = "1" ]; then
  hyprctl --batch "\
    keyword animations:enabled 1 ;\
    keyword decoration:blur:enabled 1 ;\
    keyword decoration:shadow:enabnled 1 ;\
    keyword decoration:rounding 12 ;\
    keyword misc:vfr 1 ;\
    keyword misc:vrr 2" >/dev/null
  echo "0" >"$STATE"
  notify-send -t 1500 "Cryo" "Gamemode OFF" 2>/dev/null || true
else
  hyprctl --batch "\
    keyword animations:enabled 0 ;\
    keyword decoration:blur:enabled 0 ;\
    keyword decoration:shadow:enabled 0 ;\
    keyword decoration:rounding 0 ;\
    keyword misc:vfr 0 ;\
    keyword misc:vrr 1" >/dev/null
  echo "1" >"$STATE"
  notify-send -t 1500 "Cryo" "Gamemode ON" 2>/dev/null || true
fi
