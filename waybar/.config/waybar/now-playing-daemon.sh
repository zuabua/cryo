#!/usr/bin/env bash

set -u
export PATH="$HOME/.local/bin:$PATH"

MAX_LEN=42

esc() {
  printf '%s' "$1" |
    sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/\t/ /g' -e 's/\r//g' |
    tr -d '\000-\037'
}

# Truncate to MAX_LEN with a trailing ellipsis.
trunc() {
  local s="$1"
  if [ "${#s}" -gt "$MAX_LEN" ]; then
    printf '%s…' "${s:0:$((MAX_LEN - 1))}"
  else
    printf '%s' "$s"
  fi
}

emit() {
  local text="$1" cls="$2" full="$3"
  printf '{"text":"%s","class":"%s","tooltip":"%s"}\n' \
    "$(esc "$text")" "$(esc "$cls")" "$(esc "$full")"
}

while true; do
  emit "" "idle" ""
  playerctl metadata --follow \
    --format '{{status}}␞{{artist}}␞{{title}}' 2>/dev/null |
    while IFS='␞' read -r status artist title; do
      if [ -z "${status:-}" ]; then
        emit "" "idle" ""
        continue
      fi
      case "$status" in
      Playing) icon="▶" cls="playing" ;;
      Paused) icon="⏸" cls="paused" ;;
      Stopped)
        emit "" "idle" ""
        continue
        ;;
      *) icon="•" cls="$status" ;;
      esac
      if [ -n "$artist" ] && [ -n "$title" ]; then
        full="$artist · $title"
      elif [ -n "$title" ]; then
        full="$title"
      else
        full="$status"
      fi
      emit "$icon $(trunc "$full")" "$cls" "$full"
    done
  sleep 5
done
