#!/usr/bin/env bash

set -u

STATUS_FILE="$HOME/.cache/cryo-htb-vpn"
JSON="$HOME/.local/share/cryo-htb/active-target.json"
INTERVAL=5

mkdir -p "$(dirname "$STATUS_FILE")"

active_file="$HOME/.config/htb/active-lab"

while true; do
  lab=""
  state="down"
  myip=""
  target=""
  ping_ms="—"

  chosen=""
  [ -s "$active_file" ] && chosen=$(cat "$active_file" 2>/dev/null || true)

  if [ -n "$chosen" ] && nmcli -t -f NAME,STATE connection show --active 2>/dev/null |
    grep -qE "^${chosen}:activated\$"; then
    lab="$chosen"
  else
    lab=$(nmcli -t -f NAME,TYPE,STATE connection show --active 2>/dev/null |
      awk -F: '$2=="vpn" && $3=="activated" {print $1; exit}')
  fi

  if [ -n "$lab" ]; then
    state="up"
    myip=$(ip -4 -o addr show tun0 2>/dev/null |
      awk '{split($4,a,"/"); print a[1]; exit}')
    myip="${myip:-pending}"

    target=$(jq -r '.ip // ""' "$JSON" 2>/dev/null || echo "")
    [ "$target" = "null" ] && target=""

    if [ -n "$target" ]; then
      # -W 1: 1-second deadline. Boxes that drop ICMP report "—".
      ping_ms=$(ping -W 1 -c 1 "$target" 2>/dev/null |
        awk -F'time=' '/time=/{split($2,a," "); printf("%.0f", a[1]); exit}')
      ping_ms="${ping_ms:-—}"
    fi
  fi

  printf 'state=%s lab=%s iface=tun0 myip=%s target=%s ping=%s\n' \
    "$state" "$lab" "$myip" "$target" "$ping_ms" >"$STATUS_FILE"

  sleep "$INTERVAL"
done
