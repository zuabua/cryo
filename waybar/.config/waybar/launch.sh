#!/usr/bin/env bash

# Waybar launcher
# Hyprlands exec-once points here instead of waybar directly.
# This is to ensure the config-live.jsonc exists on first login.
# Even if install.sh hasnt run since stowing.
#
# Essentially:
# * If config-live.jsonc is missing, regenerate it from the stowed skeleton
# * exec waybar with the live config.

set -u

export PATH="$HOME/.local/bin:$PATH"

LIVE="$HOME/.config/waybar/config-live.jsonc"
SKELETON="$HOME/.config/waybar/config.jsonc"

if [ ! -f "$LIVE" ]; then
  if command -v waybar-layout >/dev/null 2>&1; then
    waybar-layout apply >/dev/null 2>&1 || true
  fi

  if [ ! -f "$LIVE" ] && [ -f "$SKELETON" ]; then
    cp "$SKELETON" "$LIVE"
  fi
fi

exec waybar -c "$LIVE"
