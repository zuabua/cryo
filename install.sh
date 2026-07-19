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
