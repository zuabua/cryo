#!/usr/bin/env bash
set -u

STATUS="$HOME/.cache/cryo-htb-vpn"
JSON="$HOME/.local/share/cryo-htb/active-target.json"

state="down"
lab=""
myip=""
target=""
ping="—"

if [ -f "$STATUS" ]; then
  while IFS= read -r kv; do
    case "$kv" in
    state=*) state="${kv#state=}" ;;
    lab=*) lab="${kv#lab=}" ;;
    myip=*) myip="${kv#myip=}" ;;
    target=*) target="${kv#target=}" ;;
    ping=*) ping="${kv#ping=}" ;;
    esac
  done < <(tr ' ' '\n' <"$STATUS")
fi

owned_user="false"
owned_root="false"
name=""
if [ -f "$JSON" ]; then
  owned_user=$(jq -r '.owned_user' "$JSON" 2>/dev/null || echo false)
  owned_root=$(jq -r '.owned_root' "$JSON" 2>/dev/null || echo false)
  name=$(jq -r '.name // ""' "$JSON" 2>/dev/null || echo "")
fi

# State class for CSS
class="down"
if [ "$state" = "up" ]; then
  if [ "$owned_root" = "true" ]; then
    class="root"
  elif [ "$owned_user" = "true" ]; then
    class="user"
  elif [ -n "$target" ]; then
    class="target"
  else
    class="up"
  fi
fi

if [ "$state" = "down" ]; then
  text="HTB"
elif [ -z "$target" ]; then
  text="$lab · $myip"
else
  label="${name:-$target}"
  text="$lab · $myip → $label  ${ping}ms"
fi

tooltip="lab=$lab\nmyip=$myip\ntarget=$target\nping=$ping ms"

esc() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }
printf '{"text":"%s","class":"%s","tooltip":"%s"}\n' \
  "$(esc "$text")" "$(esc "$class")" "$(esc "$tooltip")"
