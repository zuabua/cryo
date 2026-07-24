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

# Pacman

say "Installing pacman packages"

sudo pacman -Sy
sudo pacman -S --needed --noconfirm $PACMAN_PKGS

# AUR

say "AUR packages"

AUR_HELPER=""
if command -v paru >/dev/null 2>&1; then
  AUR_HELPER="paru"
elif command -v yay >/dev/null 2>&1; then
  AUR_HELPER="yay"
fi

if [ -z "$AUR_HELPER" ]; then
  warn "No AUR helper found (paru or yay)."
  note "Tokyonight-GTK requires gtk-engine-murrine (AUR-only as of Nov 2025)."
  note "Icons (Tela-circle) also live on AUR."
  if confirm "Skip AUR section (you can install gtk-engine-murrine + tela-circle-icon-theme later)?"; then
    info "Skipping AUR; remember to install $AUR_PKGS later."
  else
    warn "Aborting — install paru or yay first, then re-run."
    exit 1
  fi
else
  info "Using $AUR_HELPER"
  AUR_FAILED=()
  for pkg in $AUR_PKGS; do
    info "$AUR_HELPER -S $pkg"
    if ! $AUR_HELPER -S --needed --noconfirm "$pkg"; then
      warn "AUR install failed: $pkg"
      AUR_FAILED+=("$pkg")
    fi
  done
  if [ ${#AUR_FAILED[@]} -gt 0 ]; then
    warn "Some AUR packages failed: ${AUR_FAILED[*]}"
    note "Common causes: upstream source 404, build deps missing, mirror flake."
    note "Retry manually after the install finishes:"
    for pkg in "${AUR_FAILED[@]}"; do
      note "  $AUR_HELPER -S $pkg"
    done
    if printf '%s\n' "${AUR_FAILED[@]}" | grep -qx gtk-engine-murrine; then
      warn "gtk-engine-murrine is required by Tokyonight-GTK (step 6)."
      note "Workaround options:"
      note "  1. Retry: $AUR_HELPER -S gtk-engine-murrine   (the source mirror"
      note "     intermittently 404s; a retry often succeeds)"
      note "  2. Build manually: git clone https://aur.archlinux.org/gtk-engine-murrine.git"
      note "     cd gtk-engine-murrine && makepkg -si"
      note "  3. Skip the GTK theme: re-run install.sh and answer 'n' if prompted,"
      note "     or comment out step 6 (Tokyonight-GTK) in install.sh — the rest"
      note "     of the rice will work, you'll just keep the default GTK theme."
      if ! confirm "Continue install without gtk-engine-murrine (Tokyonight-GTK will be skipped)?"; then
        warn "Aborting. Fix gtk-engine-murrine then re-run ./install.sh."
        exit 1
      fi
      # Mark so step 6 knows to skip itself.
      SKIP_TOKYONIGHT=1
    fi
  fi
fi

# PIPX

say "pipx packages"

if ! command -v pipx >/dev/null 2>&1; then
  info "Installing pipx via pacman"
  sudo pacman -S --needed --noconfirm python-pipx
fi
pipx ensurepath >/dev/null

for pkg in $PIPX_PKGS; do
  if pipx list 2>/dev/null | grep -q "package $pkg "; then
    info "pipx: $pkg already installed"
  else
    info "pipx install $pkg"
    pipx install "$pkg"
  fi
done

# External theme

say "Tokyonight-GTK theme"

if [ "${SKIP_TOKYONIGHT:-0}" = "1" ]; then
  warn "Skipping Tokyonight-GTK (gtk-engine-murrine missing)."
  note "Install gtk-engine-murrine + re-run ./install.sh to apply the theme."
elif [ -d "$HOME/.themes/Tokyonight-Dark" ]; then
  info "Tokyonight-Dark already installed at ~/.themes/"
else
  SCRATCH="$HOME/.cache/cryo-install-scratch"
  mkdir -p "$SCRATCH"
  if [ ! -d "$SCRATCH/Tokyo-Night-GTK-Theme" ]; then
    info "Cloning Tokyonight-GTK upstream"
    git clone --depth 1 https://github.com/Fausto-Korpsvart/Tokyo-Night-GTK-Theme.git \
      "$SCRATCH/Tokyo-Night-GTK-Theme"
  fi
  info "Running upstream install.sh (-c dark -t default --tweaks black -l)"
  (cd "$SCRATCH/Tokyo-Night-GTK-Theme/themes" &&
    ./install.sh -c dark -t default --tweaks black -l)
fi

# SDDM Deployment

say "SDDM Cryo theme"

SDDM_SRC="$REPO_DIR/system/sddm/cryo"
SDDM_DST="/usr/share/sddm/themes/cryo"

if [ ! -d "$SDDM_SRC" ]; then
  warn "$SDDM_SRC missing — skipping SDDM theme."
else
  if command -v magick >/dev/null 2>&1; then
    info "Regenerating SDDM background from palette"
    CRYO_PALETTE="$REPO_DIR/theme/.config/theme/colors.sh" \
      bash "$SDDM_SRC/generate-background.sh" ||
      warn "background regen failed; keeping existing PNG"
  else
    note "imagemagick (magick) not installed — using committed background.png"
  fi

  info "Copying theme to $SDDM_DST"
  sudo rm -rf "$SDDM_DST"
  sudo cp -r "$SDDM_SRC" "$SDDM_DST"
  sudo chmod -R 755 "$SDDM_DST"

  info "Activating theme via /etc/sddm.conf.d/zz-cryo.conf"
  sudo mkdir -p /etc/sddm.conf.d

  SDDM_DROPIN=/etc/sddm.conf.d/zz-cryo.conf
  sddm_write_dropin() {
    sudo tee "$SDDM_DROPIN" >/dev/null <<'EOF'
# Managed by cryo install.sh — selects the SDDM greeter theme.
# This file's `zz-` prefix makes it sort last among /etc/sddm.conf.d/*.conf,
# so it overrides any [Theme] Current= set by other drop-ins.
[Theme]
Current=cryo
EOF
  }
  sddm_dropin_ok() {
    [ -s "$SDDM_DROPIN" ] &&
      sudo grep -q '^Current=cryo' "$SDDM_DROPIN" 2>/dev/null
  }

  for attempt in 1 2 3; do
    sddm_write_dropin
    if sddm_dropin_ok; then
      info "Drop-in written (attempt $attempt)"
      break
    fi
    warn "Drop-in write attempt $attempt didn't stick — retrying"
    sleep 1
  done

  if ! sddm_dropin_ok; then
    warn "Failed to persist $SDDM_DROPIN after 3 tries."
    note "Run this by hand to repair, then \`sudo systemctl restart sddm\`:"
    note "    echo -e '[Theme]\\nCurrent=cryo' | sudo tee $SDDM_DROPIN"
  fi

  SDDM_EFFECTIVE_THEME=$(
    for f in /usr/lib/sddm/sddm.conf.d/*.conf \
      /etc/sddm.conf.d/*.conf \
      /etc/sddm.conf; do
      [ -f "$f" ] || continue
      awk -F= '/^\[Theme\]/{f=1; next} /^\[/{f=0} f && /^Current=/{print $2}' "$f"
    done | tail -n 1
  )
  if [ "$SDDM_EFFECTIVE_THEME" = "cryo" ]; then
    info "Verified: SDDM will load 'cryo'"
  else
    warn "Effective SDDM theme is '$SDDM_EFFECTIVE_THEME', not 'cryo'."
    note "Some other config under /etc/sddm.conf or /etc/sddm.conf.d/ is"
    note "overriding our drop-in. Check with: grep -rn '^Current=' /etc/sddm.conf*"
  fi

  note "New greeter shows up on next SDDM start (reboot or 'sudo systemctl restart sddm')."
  note "WARNING: restarting sddm kills the current graphical session."
  note "If the drop-in vanishes again after a snapper rollback, re-run"
  note "this script — it's idempotent; the smoke test phase at the end"
  note "will flag any missing pieces loudly."
fi

# Tweaks

say "NVIDIA Hyprland tweaks"

NVCONF="$HOME/.config/hypr/nvidia.conf"
mkdir -p "$(dirname "$NVCONF")"

NVIDIA_DETECTED=0
if lspci 2>/dev/null | grep -iE 'vga|3d|display' | grep -qi 'nvidia'; then
  NVIDIA_DETECTED=1
  info "lspci reports an NVIDIA GPU"
fi

case "${CRYO_NVIDIA:-}" in
1 | yes | on)
  WANT_NVIDIA=1
  info "CRYO_NVIDIA=$CRYO_NVIDIA — applying NVIDIA tweaks"
  ;;
0 | no | off)
  WANT_NVIDIA=0
  info "CRYO_NVIDIA=$CRYO_NVIDIA — skipping NVIDIA tweaks"
  ;;
*)
  if [ "$NVIDIA_DETECTED" = "1" ]; then
    if confirm "Apply NVIDIA-specific Hyprland env vars + cursor tweaks?" Y; then
      WANT_NVIDIA=1
    else
      WANT_NVIDIA=0
    fi
  else
    note "No NVIDIA GPU detected — skipping (force with CRYO_NVIDIA=1)"
    WANT_NVIDIA=0
  fi
  ;;
esac

if [ "$WANT_NVIDIA" = "1" ]; then
  info "Writing $NVCONF"
  cat >"$NVCONF" <<'EOF'
# CRYO NVIDIA-specific Hyprland tweaks (generated by install.sh).
# Re-run install.sh to regenerate, or set CRYO_NVIDIA=0 to disable.
#
# LIBVA  — VA-API video decode routes through nvidia
# GBM    — buffer management backend (nvidia-drm required for Wayland)
# GLX    — GLX vendor library preference (Electron / older GL clients)
# NVD    — direct rendering for the nvidia decode backend
# ELECTRON_OZONE_PLATFORM_HINT — pushes vscode/discord/slack onto
#          native Wayland instead of XWayland (lower latency, better DPI)
# no_hardware_cursors — pre-555 NVIDIA loses the cursor sprite during
#          workspace switches. Software cursors avoid the bug. Harmless
#          on driver 555+ with explicit sync.

env = LIBVA_DRIVER_NAME,nvidia
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
env = GBM_BACKEND,nvidia-drm
env = NVD_BACKEND,direct
env = ELECTRON_OZONE_PLATFORM_HINT,auto

cursor {
    no_hardware_cursors = true
}
EOF
  note "Re-run install.sh with CRYO_NVIDIA=0 to disable later."
  note "Bare-metal also wants \`nvidia_drm.modeset=1\` as a kernel param —"
  note "check /etc/default/grub or /etc/cmdline.d/ if you ever see flickering."

  case "${CRYO_HDR:-}" in
  1 | yes | on) WANT_HDR=1 ;;
  0 | no | off) WANT_HDR=0 ;;
  *)
    if confirm "Install vk-hdr-layer for HDR-capable Steam/Proton games?" Y; then
      WANT_HDR=1
    else
      WANT_HDR=0
    fi
    ;;
  esac

  if [ "$WANT_HDR" = "1" ]; then
    if [ -n "${AUR_HELPER:-}" ]; then
      info "$AUR_HELPER -S vk-hdr-layer-kwin6-git"
      if $AUR_HELPER -S --needed --noconfirm vk-hdr-layer-kwin6-git; then
        info "vk-hdr-layer-kwin6-git installed"
      else
        warn "Failed to install vk-hdr-layer-kwin6-git — retry manually:"
        note "    $AUR_HELPER -S vk-hdr-layer-kwin6-git"
      fi
    else
      warn "No AUR helper detected — install vk-hdr-layer-kwin6-git manually:"
      note "    paru -S vk-hdr-layer-kwin6-git   # or yay"
    fi
    note "Per-game launch options (Steam: right-click → Properties → Launch options):"
    note "    PROTON_ENABLE_WAYLAND=1 PROTON_ENABLE_HDR=1 ENABLE_HDR_WSI=1 %command%"
    note "Monitor must be HDR-capable AND HDR-enabled in Hyprland's monitor config."
  fi
else
  cat >"$NVCONF" <<'EOF'
# Cryo NVIDIA tweaks disabled (no NVIDIA GPU detected or user
# opted out). This stub keeps hyprland.conf's `source` line valid.
# Re-run install.sh on an NVIDIA machine, or `CRYO_NVIDIA=1 ./install.sh`,
# to opt in.
EOF
fi

# Wallpaper

say "Bundled wallpaper"

WP_SRC="$REPO_DIR/system/wallpaper/cryo-default.jpg"
WP_DIR="$HOME/Pictures/wallpapers"
WP_DST="$WP_DIR/dark/cryo-default.jpg"

mkdir -p "$WP_DIR"/{dark,gaming,minimal}

if [ ! -f "$WP_SRC" ]; then
  warn "Bundled wallpaper missing at $WP_SRC — skipping"
elif [ -f "$WP_DST" ]; then
  info "Wallpaper already at $WP_DST (not overwriting your copy)"
else
  info "Copying bundled wallpaper to $WP_DST"
  cp "$WP_SRC" "$WP_DST"
fi

WP_TEMPLATE="$REPO_DIR/system/waypaper/config.ini.template"
WP_CONF="$HOME/.config/waypaper/config.ini"

if [ ! -f "$WP_TEMPLATE" ]; then
  warn "$WP_TEMPLATE missing — skipping waypaper config seed"
  note "waypaper will fall back to its own defaults (wrong folder + backend)."
else
  mkdir -p "$(dirname "$WP_CONF")"
  if [ -L "$WP_CONF" ]; then
    info "Removing symlinked $WP_CONF (config is a seeded file now)"
    rm -f "$WP_CONF"
  fi
  if [ -f "$WP_CONF" ]; then
    info "waypaper config already present — leaving your settings alone"
    note "Delete $WP_CONF and re-run to reseed from the repo defaults."
  else
    info "Seeding $WP_CONF for $USER"
    sed "s|@HOME@|$HOME|g" "$WP_TEMPLATE" >"$WP_CONF"
  fi
fi

if [ -f "$WP_DST" ] &&
  [ -n "${WAYLAND_DISPLAY:-}" ] &&
  command -v waypaper >/dev/null 2>&1; then
  if waypaper --wallpaper "$WP_DST" >/dev/null 2>&1; then
    info "Applied $WP_DST via waypaper (state seeded)"
  else
    note "waypaper --wallpaper failed — wallpaper-restore will apply on next login"
  fi
else
  note "No Wayland session detected — wallpaper applies on next Hyprland login via wallpaper-restore"
fi

# Stow packages

say "Stowing packages"

STOW_PKGS=(
  theme
  hyprland
  waybar
  wofi
  kitty
  zsh
  nvim
  yazi
  tmux
  quickshell
  wallpaper
  dunst
  gtk
  htb
  inbox
  pomodoro
)

# Backup directory — timestamped so re-runs don't collide.
BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"
BACKUP_USED=0

backup_conflicting_targets() {
  local pkg="$1"
  local src_root="$REPO_DIR/$pkg"
  [ -d "$src_root" ] || return 0

  while IFS= read -r -d '' src_file; do
    local rel="${src_file#"$src_root"/}"
    local target="$HOME/$rel"

    # No target = no conflict.
    if [ ! -e "$target" ] && [ ! -L "$target" ]; then
      continue
    fi

    # Already our symlink = no conflict.
    if [ -L "$target" ]; then
      local link_dest
      link_dest="$(readlink -f "$target" 2>/dev/null || true)"
      case "$link_dest" in
      "$REPO_DIR"/*) continue ;;
      esac
    fi

    # Real conflict: move it.
    local backup_target="$BACKUP_DIR/$rel"
    mkdir -p "$(dirname "$backup_target")"
    mv "$target" "$backup_target"
    BACKUP_USED=1
    note "backup: $target -> $backup_target"
  done < <(find "$src_root" -type f -print0)
}

# Pre-flight: back up everything that would conflict, across all packages.
for pkg in "${STOW_PKGS[@]}"; do
  [ -d "$REPO_DIR/$pkg" ] && backup_conflicting_targets "$pkg"
done

if [ "$BACKUP_USED" = "1" ]; then
  info "Pre-existing configs moved to: $BACKUP_DIR"
  note "If anything's wrong, originals are recoverable from there."
fi

# Now stow cleanly.
for pkg in "${STOW_PKGS[@]}"; do
  if [ ! -d "$REPO_DIR/$pkg" ]; then
    info "skip: $pkg (not in repo)"
    continue
  fi
  info "stow: $pkg"
  stow --restow --no-folding -d "$REPO_DIR" -t "$HOME" "$pkg"
done

# fontconfig

say "Refreshing fontconfig cache"
if command -v fc-cache >/dev/null 2>&1; then
  fc-cache -f >/dev/null 2>&1 && info "fc-cache refreshed (user)"
  if fc-match 'JetBrainsMono Nerd Font' 2>/dev/null | grep -q -i 'nerd'; then
    info "Verified: JetBrainsMono Nerd Font is available"
  else
    warn "JetBrainsMono Nerd Font not resolving — waybar icons may render as boxes."
    note "Check ttf-jetbrains-mono-nerd is installed: pacman -Qi ttf-jetbrains-mono-nerd"
  fi
else
  warn "fc-cache not found — skipping font cache refresh"
fi

# Bluetooth
say "Bluetooth service"
if systemctl list-unit-files bluetooth.service >/dev/null 2>&1; then
  if systemctl is-enabled bluetooth.service >/dev/null 2>&1; then
    info "bluetooth.service already enabled"
  else
    if sudo systemctl enable --now bluetooth.service; then
      info "bluetooth.service enabled + started"
    else
      warn "Failed to enable bluetooth.service — check 'systemctl status bluetooth'"
    fi
  fi
else
  note "bluetooth.service not installed — skipping (bluez removed?)"
fi

# gsettings

say "Applying gsettings overrides"

if [ -x "$REPO_DIR/gtk/apply-gsettings.sh" ]; then
  "$REPO_DIR/gtk/apply-gsettings.sh"
else
  warn "gtk/apply-gsettings.sh missing or not executable — skipping."
fi

# zsh
say "Default shell"

CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7)"
ZSH_PATH="$(command -v zsh)"

if [ "$CURRENT_SHELL" = "$ZSH_PATH" ]; then
  info "Already zsh ($ZSH_PATH)"
elif [ -z "$ZSH_PATH" ]; then
  warn "zsh not found — somehow it didn't install. Skipping."
else
  info "Current shell: $CURRENT_SHELL"
  info "Proposed:      $ZSH_PATH"
  if confirm "Change default shell to zsh?"; then
    chsh -s "$ZSH_PATH"
    note "Takes effect on next login."
  else
    info "Keeping current shell."
  fi
fi

# Quickshell stuff

say "HTB state files (pre-seed)"
HTB_DATA="$HOME/.local/share/cryo-htb"
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
mkdir -p "$HOME/obsidian/Documents"
[ -f "$HOME/.cache/cryo-inbox-shown" ] || echo 0 >"$HOME/.cache/cryo-inbox-shown"
touch "$HOME/Documents/obsidian/inbox.md"
info "Inbox state file present at ~/.cache/ and ~/Documents/obsidian/inbox.md"

# Waybar controller
[ -f "$HOME/.cache/cryo-barctl-shown" ] || echo 0 >"$HOME/.cache/cryo-barctl-shown"

# Bar mood
mkdir -p "$HOME/.config/waybar"
info "accent.css.live stowed; bar mood disabled by default — run \`bar-mood on\` to enable"

# Waybar layout
WAYBAR_LAYOUT="$HOME/.local/bin/waybar-layout"
WAYBAR_LIVE="$HOME/.config/waybar/config-live.jsonc"
WAYBAR_SKEL="$HOME/.config/waybar/config.jsonc"
if [ -x "$WAYBAR_LAYOUT" ]; then
  info "Regenerating $WAYBAR_LIVE"
  if ! "$WAYBAR_LAYOUT" apply >/dev/null; then
    warn "waybar-layout apply failed — see stderr above"
  fi
else
  warn "$WAYBAR_LAYOUT not present after stow — skipping apply"
fi

# Verify Result
if [ ! -s "$WAYBAR_LIVE" ]; then
  warn "$WAYBAR_LIVE is missing or empty after apply"
  if [ -f "$WAYBAR_SKEL" ]; then
    note "Falling back to a verbatim copy of the skeleton."
    cp "$WAYBAR_SKEL" "$WAYBAR_LIVE"
  else
    warn "Skeleton $WAYBAR_SKEL also missing — waybar will fail to start."
    warn "Check that the 'waybar' stow package linked correctly."
  fi
fi

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

# HTB VPN layout

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

# Smoke test

say "Smoke test"
SMOKE_FAILS=0
smoke_ok() { info "    [ok]   $1"; }
smoke_fail() {
  warn "    [FAIL] $1"
  SMOKE_FAILS=$((SMOKE_FAILS + 1))
}
smoke_section() { printf "\n  ${C_TEAL}== %s ==${C_RESET}\n" "$1"; }

# ── [SDDM] ────────────────────────────────────────────────────────────
smoke_section "SDDM (login greeter)"

SDDM_DST="/usr/share/sddm/themes/cryo"
if [ -d "$SDDM_DST" ]; then
  smoke_ok "theme deployed at $SDDM_DST"
  for f in Main.qml metadata.desktop theme.conf background.png; do
    if [ -f "$SDDM_DST/$f" ]; then
      smoke_ok "  $f present"
    else
      smoke_fail "  $f missing from theme — greeter will fall back to default"
    fi
  done
else
  smoke_fail "theme directory $SDDM_DST missing — was step 7 skipped?"
fi

if [ -f /etc/sddm.conf.d/zz-cryo.conf ]; then
  smoke_ok "activation drop-in /etc/sddm.conf.d/zz-cryo.conf present"
else
  smoke_fail "activation drop-in missing — greeter will use distro default"
fi

SDDM_EFF=$(
  for f in /usr/lib/sddm/sddm.conf.d/*.conf \
    /etc/sddm.conf.d/*.conf \
    /etc/sddm.conf; do
    [ -f "$f" ] || continue
    awk -F= '/^\[Theme\]/{f=1; next} /^\[/{f=0} f && /^Current=/{print $2}' "$f"
  done | tail -n 1
)
if [ "$SDDM_EFF" = "cryo" ]; then
  smoke_ok "effective SDDM theme resolves to 'cryo'"
else
  smoke_fail "effective SDDM theme is '$SDDM_EFF', not 'cryo'"
fi

# ── [Waybar] ──────────────────────────────────────────────────────────
smoke_section "Waybar (bar + icons + scripts)"

WB_LIVE="$HOME/.config/waybar/config-live.jsonc"
WB_STYLE="$HOME/.config/waybar/style.css"
WB_ACCENT="$HOME/.config/waybar/accent.css.live"
WB_LAUNCH="$HOME/.config/waybar/launch.sh"

if [ ! -f "$WB_LIVE" ]; then
  smoke_fail "config-live.jsonc missing — launch.sh's bootstrap fallback should still cover it, but verify"
elif sed -E 's:^[[:space:]]*//.*$::' <"$WB_LIVE" | jq -e . >/dev/null 2>&1; then
  smoke_ok "config-live.jsonc is valid JSON"
else
  smoke_fail "config-live.jsonc is not valid JSON — re-run \`waybar-layout apply\`"
fi

if [ -f "$WB_LIVE" ]; then
  PUA_COUNT=$(python3 -c "
text = open('$WB_LIVE').read()
print(sum(1 for c in text if 0xE000 <= ord(c) <= 0xF8FF))
" 2>/dev/null || echo 0)
  if [ "$PUA_COUNT" -ge 6 ]; then
    smoke_ok "config-live.jsonc has $PUA_COUNT Nerd Font icons"
  else
    smoke_fail "config-live.jsonc has only $PUA_COUNT Nerd Font icons (expected ≥6) — skeleton lost them"
  fi
fi

if [ ! -f "$WB_STYLE" ]; then
  smoke_fail "style.css missing"
else
  if awk 'BEGIN{c=0} {
            for(i=1;i<=length($0);i++) {
                ch=substr($0,i,1)
                if(ch=="{") c++
                else if(ch=="}") c--
            }
        } END { exit (c==0?0:1) }' "$WB_STYLE"; then
    smoke_ok "style.css braces balanced"
  else
    smoke_fail "style.css has unbalanced braces"
  fi

  CSS_BAD=$(grep -nE '^[[:space:]]*[0-9]+%[[:space:]]*,' "$WB_STYLE" 2>/dev/null || true)
  if [ -n "$CSS_BAD" ]; then
    smoke_fail "style.css has comma-shorthand keyframe selectors (GTK CSS rejects them):"
    printf '%s\n' "$CSS_BAD" | sed 's/^/             /'
  else
    smoke_ok "style.css free of comma-shorthand keyframes"
  fi
fi

# accent.css.live must exist (style.css imports it unconditionally).
if [ -f "$WB_ACCENT" ] || [ -L "$WB_ACCENT" ]; then
  smoke_ok "accent.css.live present (style.css's @import resolves)"
else
  smoke_fail "accent.css.live missing — style.css @import will warn on every reload"
fi

# launch.sh exists + is executable (Hyprland's exec-once points at it)
if [ -x "$WB_LAUNCH" ]; then
  smoke_ok "launch.sh present + executable"
else
  smoke_fail "launch.sh missing or not executable — Hyprland exec-once will silently fail"
fi

# Every script referenced inside config-live.jsonc (exec / on-click / on-click-right)
# must resolve to an existing executable. Catches "I deleted a script but
# the skeleton still references it" — the pill silently dies otherwise.
if [ -f "$WB_LIVE" ] && command -v jq >/dev/null 2>&1; then
  WB_BAD=0
  # Walk all values that look like a path (start with ~/ or /).
  while IFS= read -r path; do
    [ -z "$path" ] && continue
    # Just take the first word — strip flags/args.
    bin=$(printf '%s' "$path" | awk '{print $1}')
    expanded="${bin/#\~/$HOME}"
    # Skip shell builtins / inlined `cat … | awk …` exec strings.
    case "$expanded" in
    cat | /usr/bin/cat | sh | bash) continue ;;
    esac
    if [ ! -e "$expanded" ]; then
      warn "             missing script: $bin"
      WB_BAD=$((WB_BAD + 1))
    elif [ ! -x "$expanded" ]; then
      warn "             not executable: $bin"
      WB_BAD=$((WB_BAD + 1))
    fi
  done < <(
    sed -E 's:^[[:space:]]*//.*$::' <"$WB_LIVE" |
      jq -r '..|strings | select(test("^(~|/)") and (test("\\.sh$|/bin/")))' 2>/dev/null |
      sort -u
  )
  if [ "$WB_BAD" -eq 0 ]; then
    smoke_ok "all module-referenced scripts resolve to executables"
  else
    smoke_fail "$WB_BAD waybar-referenced script(s) broken"
  fi
fi

# ── [Hyprland] ────────────────────────────────────────────────────────
smoke_section "Hyprland (config + exec-once + binds)"

HYP_DIR="$HOME/.config/hypr"
for f in hyprland.conf monitors.conf workspaces.conf; do
  if [ -f "$HYP_DIR/$f" ]; then
    smoke_ok "$f present"
  else
    smoke_fail "$f missing — Hyprland will fail to start or fall back to defaults"
  fi
done

HYP_CONF="$HYP_DIR/hyprland.conf"
if [ -f "$HYP_CONF" ]; then
  if grep -qE '^\$mainMod[[:space:]]*=' "$HYP_CONF"; then
    smoke_ok "\$mainMod is defined"
  else
    smoke_fail "\$mainMod not defined — every bind in this config will be invalid"
  fi

  # exec-once + bind script paths must resolve.
  HYP_BAD=0
  while IFS= read -r path; do
    [ -z "$path" ] && continue
    expanded="${path/#\~/$HOME}"
    if [ ! -e "$expanded" ]; then
      warn "             missing: $path"
      HYP_BAD=$((HYP_BAD + 1))
    elif [ ! -x "$expanded" ]; then
      warn "             not executable: $path"
      HYP_BAD=$((HYP_BAD + 1))
    fi
  done < <(
    # shellcheck disable=SC2088
    grep -E '^(exec-once|bind)' "$HYP_CONF" |
      grep -oE '~/[^ ,;)]+' |
      sort -u
  )
  if [ "$HYP_BAD" -eq 0 ]; then
    smoke_ok "all exec-once + bind script paths resolve"
  else
    smoke_fail "$HYP_BAD Hyprland script path(s) broken"
  fi

  SRC_BAD=0
  while IFS= read -r path; do
    [ -z "$path" ] && continue
    expanded="${path/#\~/$HOME}"
    if [ ! -f "$expanded" ]; then
      warn "             missing source: $path"
      SRC_BAD=$((SRC_BAD + 1))
    fi
  done < <(
    # shellcheck disable=SC2088
    grep -E '^source[[:space:]]*=' "$HYP_CONF" |
      grep -oE '~/[^ ,;)]+' |
      sort -u
  )
  if [ "$SRC_BAD" -eq 0 ]; then
    smoke_ok "all Hyprland source paths resolve"
  else
    smoke_fail "$SRC_BAD Hyprland source path(s) missing"
  fi

  if grep -qE '^bind.*workspace,[[:space:]]*[0-9]+' "$HYP_CONF"; then
    smoke_ok "workspace binds present (Super+1..0 should work)"
  else
    smoke_fail "no workspace binds found — config may be truncated"
  fi
fi

# ── [Services & cache] ───────────────────────────────────────────────
smoke_section "Services & cache"

# Cache files seeded for every waybar custom module that reads one
CACHE_MISS=()
for f in cryo-gamemode cryo-pomodoro cryo-htb-vpn \
  cryo-htb-shown cryo-inbox-shown cryo-barctl-shown; do
  [ -f "$HOME/.cache/$f" ] || CACHE_MISS+=("$f")
done
if [ ${#CACHE_MISS[@]} -eq 0 ]; then
  smoke_ok "all waybar cache files seeded"
else
  smoke_fail "missing cache files: ${CACHE_MISS[*]}"
fi

if [ -f "$HOME/Pictures/wallpapers/dark/cryo-default.jpg" ]; then
  smoke_ok "bundled wallpaper present at ~/Pictures/wallpapers/dark/"
else
  smoke_fail "bundled wallpaper missing — wallpaper-restore fallback will fail"
fi

# waypaper config must be a real file (not a repo symlink) and must not carry
# a home directory belonging to somebody else.
SMOKE_WP_CONF="$HOME/.config/waypaper/config.ini"
if [ -L "$SMOKE_WP_CONF" ]; then
  smoke_fail "waypaper config.ini is a symlink — waypaper will write into the repo"
elif [ ! -s "$SMOKE_WP_CONF" ]; then
  smoke_fail "waypaper config.ini missing — picker falls back to waypaper defaults"
else
  FOREIGN_HOME=$(grep -oE '/home/[^/[:space:]]+' "$SMOKE_WP_CONF" |
    sort -u | grep -vxF "$HOME" || true)
  if [ -n "$FOREIGN_HOME" ]; then
    smoke_fail "waypaper config.ini references another user's home: $FOREIGN_HOME"
  elif grep -q '@HOME@' "$SMOKE_WP_CONF"; then
    smoke_fail "waypaper config.ini still has an unsubstituted @HOME@ placeholder"
  else
    smoke_ok "waypaper config.ini seeded for $USER (no hardcoded paths)"
  fi
fi

# bluetooth.service enabled (skip if bluez not installed)
if systemctl list-unit-files bluetooth.service >/dev/null 2>&1; then
  if systemctl is-enabled --quiet bluetooth.service 2>/dev/null; then
    smoke_ok "bluetooth.service enabled"
  else
    smoke_fail "bluetooth.service not enabled — pill will show 'no controller'"
  fi
fi

# JetBrainsMono Nerd Font resolves
if fc-match 'JetBrainsMono Nerd Font' 2>/dev/null | grep -qi 'nerd'; then
  smoke_ok "JetBrainsMono Nerd Font resolves"
else
  smoke_fail "JetBrainsMono Nerd Font doesn't resolve — bar icons will be tofu boxes"
fi

# Soft binary check — pacman says package is installed but binary is gone
BIN_MISSING=()
for b in waybar hyprctl jq stow fc-match playerctl cliphist blueman-manager wofi; do
  pacman -Qq "$b" >/dev/null 2>&1 || pacman -Qq "${b//-manager/}" >/dev/null 2>&1 || continue
  command -v "$b" >/dev/null 2>&1 || BIN_MISSING+=("$b")
done
if [ ${#BIN_MISSING[@]} -eq 0 ]; then
  smoke_ok "all installed-package binaries on PATH"
else
  smoke_fail "installed but not on PATH: ${BIN_MISSING[*]}"
fi

# ── Summary ───────────────────────────────────────────────────────────
printf "\n"
if [ "$SMOKE_FAILS" -eq 0 ]; then
  info "Smoke test: ${C_TEAL}all checks passed${C_RESET} — safe to log out and into the rice."
else
  warn "Smoke test: ${SMOKE_FAILS} failure(s) above. The rice will probably *mostly*"
  warn "            work but something specific is broken. Fix what's flagged, then"
  warn "            re-run \`./install.sh\` (this whole script is idempotent)."
fi

# Post install notes

say "Done — post-install items"

cat <<EOF

The repo is deployed. A few items still need your hands:

  ${C_TEAL}1. B2 credentials${C_RESET}
     mkdir -p ~/.config/b2
     cp $REPO_DIR/quickshell/.config/quickshell/b2-credentials.example \\
        ~/.config/b2/credentials
     chmod 600 ~/.config/b2/credentials
     # Then edit and paste your real B2_KEY_ID + B2_APP_KEY.
     # Set B2_BUCKET to your bucket name (defaults to "backup" if unset).

  ${C_TEAL}2. Monitor config (bare metal)${C_RESET}
     Edit  ~/.config/hypr/monitors.conf
     Comment the VM block, uncomment the bare-metal block.
     Verify real names: hyprctl monitors all

  ${C_TEAL}3. Workspace pinning (bare metal)${C_RESET}
     Edit  ~/.config/hypr/workspaces.conf
     Same VM/bare-metal toggle pattern.

  ${C_TEAL}4. Obsidian vault path${C_RESET}
     Edit  ~/.config/nvim/lua/plugins/obsidian.lua
     Repoint to your real vault.

  ${C_TEAL}5. Wallpapers${C_RESET}
     A palette-matched default is already installed at
       ~/Pictures/wallpapers/dark/cryo-default.jpg
     Drop your own additions into:
       ~/Pictures/wallpapers/{dark,gaming,minimal}/
     Super+W opens the waypaper picker; whatever you pick survives
     reboots via wallpaper-restore (Hyprland exec-once).

  ${C_TEAL}6. HTB lab .ovpn${C_RESET}
     mkdir -p ~/.config/htb/labs
     mv ~/Downloads/Machines.ovpn ~/.config/htb/labs/
     # Re-run ./install.sh; it imports each .ovpn as an NM connection
     # named after the filename. Toggle via the Waybar HTB pill
     # (left = drawer, right = VPN up/down) or \`Super+T\`.
     # Custom notes template (optional): ~/.config/htb/notes-template.md
     # CLI from any terminal: \`htb-target set Lame 10.10.10.3\`,
     # \`htb-target ip\`, \`htb-target help\`.

  ${C_TEAL}7. Shell productivity trio — first-time setup${C_RESET}
     atuin import auto      # one-time: import existing zsh history into atuin's DB
     # Optional cross-machine sync (skip if you only use one machine):
     #   atuin register -u <username> -e <email>
     #   atuin sync
     # Then on the next machine: atuin login + atuin sync
     #
     # Keys to learn:
     #   Ctrl+R    fuzzy history search (atuin)
     #   Ctrl+T    fuzzy file picker, pastes path on cmdline (fzf)
     #   Alt+C     fuzzy directory picker, cd's into selection (fzf)
     #   z <frag>  jump to most-visited matching dir (zoxide)
     #   zi        interactive zoxide picker

  ${C_TEAL}8. Universal inbox${C_RESET}
     Super+Space opens the capture drawer; Enter saves a timestamped
     line to ~/Documents/inbox.md, Esc cancels.
     CLI: \`inbox 'note text'\` from any terminal,
          \`inbox\` (no args) opens the file in \$EDITOR,
          \`inbox --tail 20\` shows recent entries.

  ${C_TEAL}9. Reload / re-login${C_RESET}
     hyprctl reload                       # picks up most config changes
     Log out + back in                    # triggers exec-once
     sudo systemctl restart sddm          # see the new greeter immediately
                                          # (kills your session — log back in)

  ${C_TEAL}10. Backed-up configs${C_RESET}
     If install.sh moved any pre-existing files aside, they're saved at:
       ~/.config-backup-<timestamp>/
     Safe to delete once you've confirmed everything works.

${C_SUBTEXT}For the full keybind reference + bare-metal flag list, see README.md.${C_RESET}

EOF
