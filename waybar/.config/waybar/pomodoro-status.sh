#!/usr/bin/env bash
set -u

STATE="$HOME/.cache/cryo-pomodoro"

state="idle"
phase=""
started_at=""
duration=""
cycle="1"
paused_remaining=""
original_duration=""
if [ -f "$STATE" ]; then
  while IFS='=' read -r k v; do
    case "$k" in
    state) state="$v" ;;
    phase) phase="$v" ;;
    started_at) started_at="$v" ;;
    duration) duration="$v" ;;
    cycle) cycle="$v" ;;
    paused_remaining) paused_remaining="$v" ;;
    original_duration) original_duration="$v" ;;
    esac
  done <"$STATE"
fi

if [ "$state" = "idle" ] || [ -z "$state" ]; then
  printf '{"text":"🍅","class":"idle","tooltip":"Pomodoro idle — click to start"}\n'
  exit 0
fi

now=$(date +%s)

if [ "$state" = "paused" ]; then
  remaining="${paused_remaining:-0}"
else
  remaining=$((started_at + duration - now))
fi

if [ "$state" = "running" ] && [ "$remaining" -le 0 ]; then
  ~/.local/bin/pomodoro _advance_internal >/dev/null 2>&1 || true
  state="idle"
  phase=""
  started_at=""
  duration=""
  if [ -f "$STATE" ]; then
    while IFS='=' read -r k v; do
      case "$k" in
      state) state="$v" ;;
      phase) phase="$v" ;;
      started_at) started_at="$v" ;;
      duration) duration="$v" ;;
      cycle) cycle="$v" ;;
      esac
    done <"$STATE"
  fi
  if [ "$state" = "idle" ]; then
    printf '{"text":"🍅","class":"idle","tooltip":"Pomodoro idle — click to start"}\n'
    exit 0
  fi
  remaining=$((started_at + duration - now))
fi

[ "$remaining" -lt 0 ] && remaining=0

mins=$((remaining / 60))
secs=$((remaining % 60))
time_str=$(printf "%02d:%02d" "$mins" "$secs")

total="${original_duration:-${duration:-1}}"
elapsed=$((total - remaining))
[ "$elapsed" -lt 0 ] && elapsed=0
[ "$elapsed" -gt "$total" ] && elapsed="$total"
fill=$((elapsed * 8 / total))
[ "$fill" -gt 8 ] && fill=8
bar=""
for i in $(seq 1 8); do
  if [ "$i" -le "$fill" ]; then bar="${bar}█"; else bar="${bar}░"; fi
done

case "$phase" in
focus)
  icon="🍅"
  class="focus"
  ;;
short_break)
  icon="☕"
  class="short_break"
  ;;
long_break)
  icon="🌳"
  class="long_break"
  ;;
*)
  icon="•"
  class="idle"
  ;;
esac

if [ "$state" = "paused" ]; then
  icon="⏸"
  class="paused"
  text="$icon $bar $time_str"
else
  text="$icon $bar $time_str"
fi

tooltip="phase=$phase cycle=$cycle remaining=${mins}m${secs}s"

esc() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }
printf '{"text":"%s","class":"%s","tooltip":"%s"}\n' \
  "$(esc "$text")" "$(esc "$class")" "$(esc "$tooltip")"
