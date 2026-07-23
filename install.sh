#!/usr/bin/env bash

# Cryo install script

set -e # Exit on error
set -u # error on undefined vars

# Some custom colors for status output
C_RESET='\033[0m'
C_TEAL='\033[1;36m'    # accent
C_INDIGO='\033[1;34m'  # secondary
C_RED='\033[1;31m'     # errors
C_SUBTEXT='\033[2;37m' # muted

say() { printf "${C_TEAL}==>${C_RESET} %s\n" "$*"; }
info() { printf "${C_INDIGO} ->${C_RESET} %s\n" "$*"; }
warn() { printf "${C_RED} !!${C_RESET} %s\n" "$*"; }
note() { printf "${C_SUBTEXT}    %s${C_RESET}\n" "$*"; }

# Little prompt helper
confirm() {
  local prompt="${1:-Continue?}"
  local default="${2:-N}"
  local hint reply
  if [[ "$default" =~ ^[Yy]$ ]]; then hint="[Y/n]"; else hint="[y/N]"; fi
  read -r -p "$prompt $hint " reply
  if [ -z "$reply" ]; then
    [[ "$default" =~ ^[Yy]$ ]]
  else
    [[ "$reply" =~ ^[Yy]$ ]]
  fi
}

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_DIR"

# 1. Preflight checks

say "Preflight checks"

if [ "$EUID" -eq 0]; then
  warn "Do not run install.sh as root."
  note "Stow needs \$HOME to be your user home, not /root."
  note "The script will use sudo when it needs to"
  exit 1
fi

if ! command -v pacman >/dev/null 2>&1; then
  warn "pacman not found - This script is for Arch based systems."
fi

if [ ! -f "$REPO_DIR/packages.txt" ]; then
  warn "packages.txt missing - are you running from the repo root?"
  exit 1
fi

info "Running as: $USER"
info "Repo dir: $REPO_DIR"

# 2. Parse packages.txt

say "Parsing packages.txt"

parse_section() {
  local section="$1"
  awk -v sect="[$section]" '
        $0 == sect            { in_section = 1; next }
        /^\[/                 { in_section = 0 }
        in_section && /^[^#[:space:]]/ { print $1 }
    ' "$REPO_DIR/packages.txt"
}

PACMAN_PKGS=$(parse_section pacman)
AUR_PKGS=$(parse_section aur)
PIPX_PKGS=$(parse_section pipx)

info "Pacman: $(echo "$PACMAN_PKGS" | wc -w) pkgs"
info "AUR: $(echo "$AUR_PKGS" | wc -w) pkgs"
info "pipx: $(echo "$PIPX_PKGS" | wc -w) pkgs"

# TODO: Pacman

# TODO: AUR

# TODO: PIPX

# TODO: External theme

# TODO: SDDM Deployment

# TODO: Tweaks

# TODO: Wallpaper

# TODO: Stow packages

# TODO: fontconfig

# TODO: Bluetooth

# TODO: gsettings

# TODO: zsh

# TODO: Quickshell stuff

say "HTB state files (pre-seed)"
HTB_DATA= "$HOME/.local/share/cryo-htb"
mkdir -p "$HTB_DATA/writeups" "$HOME/.config/htb" "$HOME/.cache"
chmod 700 "$HTB_DATA"

EMPTY_TGT='{"name":"","ip":"","os":"","status":"","creds":[],"ports":[],"owned_user":false,"owned_root":false,"created":"","updated":""}'
[ -f "$HTB_DATA/active-target.json" ] || echo "$EMPTY_TGT" >"$HTB_DATA/active-target.json"
[ -f "$HTB_DATA/active-notes.md" ] || : >"$HTB_DATA/active-notes.md"
[ -f "$HOME/.config/htb/active-lab" ] || : >"$HOME/.config/htb/active-lab"
[ -f "$HOME/.cache/cryo-htb-shown" ] || echo 0 >"$HOME/.cache/cryo-htb-shown"
[ -f "$HOME/.cache/cryo-htb-vpn" ] ||
  printf 'state=down lab= iface= myip= target= ping=—\n' >"$HOME/.cache/cryo-htb-vpn"
info "HTB state files present at $HTB_DATA and ~/.cache/"

# Gamemode
[ -f "$HOME/.cache/cryo-gamemode" ] || echo 0 >"$HOME/.cache/cryo-gamemode"

# Inbox drawer state + inbox.md
mkdir -p "$HOME/Documents"
[ -f "$HOME/.cache/cryo-inbox-shown" ] || echo 0 >"$HOME/.cache/cryo-inbox-shown"
touch "$HOME/Documents/obsidian/inbox.md"
info "Inbox state file present at ~/.cache/ and ~/Documents/obsidian/inbox.md"

# Pomodoro
[ -f "$HOME/.cache/cryo-pomodoro" ] || cat >"$HOME/.cache/cryo-pomodoro" <<EOF
state=idle
phase=
started_at=
duration=
cycle=1
paused_remaining=
original_duration=
EOF
info "Pomodoro state file present at ~/.cache/cryo-pomodoro"

# TODO: HTB VPN layout

say "HTB OpenVPN lab import"

HTB_LABS_DIR="$HOME/.config/htb/labs"
if ! command -v nmcli >/dev/null 2>&1; then
  warn "nmcli not found — NetworkManager not running? Skipping HTB lab import."
elif ! mkdir -p "$HTB_LABS_DIR" 2>/dev/null; then
  warn "Could not create $HTB_LABS_DIR — skipping."
elif ! ls "$HTB_LABS_DIR"/*.ovpn >/dev/null 2>&1; then
  note "No .ovpn files at $HTB_LABS_DIR/ — drop one there + re-run to import."
else
  HTB_ACTIVE_LAB="$HOME/.config/htb/active-lab"
  FIRST_IMPORTED=""
  for ovpn in "$HTB_LABS_DIR"/*.ovpn; do
    conn_name="$(basename "$ovpn" .ovpn)"
    if nmcli -t -f NAME connection show 2>/dev/null | grep -qE "^${conn_name}\$"; then
      info "NM connection already exists: $conn_name"
    else
      info "Importing $conn_name from $(basename "$ovpn")"
      if nmcli connection import type openvpn file "$ovpn"; then
        [ -z "$FIRST_IMPORTED" ] && FIRST_IMPORTED="$conn_name"
      else
        warn "Import failed for $ovpn"
      fi
    fi
  done
  if [ ! -s "$HTB_ACTIVE_LAB" ] && [ -n "$FIRST_IMPORTED" ]; then
    echo "$FIRST_IMPORTED" >"$HTB_ACTIVE_LAB"
    info "Pinned active HTB lab: $FIRST_IMPORTED"
  fi
fi

# TODO: Smoke test

# TODO: Post install notes
