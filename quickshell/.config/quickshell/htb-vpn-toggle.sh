#!/usr/bin/env bash
set -u

active_file="$HOME/.config/htb/active-lab"
lab=""
[ -s "$active_file" ] && lab=$(cat "$active_file" 2>/dev/null || true)

# Verify the chosen lab still exists in NM; if not, fall through to fallback
if [ -n "$lab" ] && ! nmcli -t -f NAME connection show 2>/dev/null |
  grep -qE "^${lab}\$"; then
  lab=""
fi

if [ -z "$lab" ]; then
  lab=$(nmcli -t -f NAME,TYPE connection show 2>/dev/null |
    awk -F: '$2=="vpn"{print $1; exit}')
fi

if [ -z "$lab" ]; then
  notify-send "HTB VPN" "No OpenVPN connection in NetworkManager. Use the drawer's lab picker or drop a .ovpn into ~/.config/htb/labs/ and re-run install.sh." 2>/dev/null ||
    echo "no openvpn connection — pick a .ovpn from the drawer or run install.sh after dropping one into ~/.config/htb/labs/" >&2
  exit 1
fi

if nmcli -t -f NAME,STATE connection show --active 2>/dev/null |
  grep -qE "^${lab}:activated\$"; then
  nmcli con down "$lab"
else
  nmcli con up "$lab"
fi
