# Cryo — Hotkey Reference

Pure reference. No prose. For the "why" and walkthroughs, see [README.md](README.md).

---

## Hyprland — focus, swap, resize

| Bind | Action |
|------|--------|
| `Super+h/j/k/l` | Focus window left / down / up / right (vim style) |
| `Super+←/↓/↑/→` | Focus window left / down / up / right (arrow style) |
| `Super+Shift+h/j/k/l` | Swap active window with neighbour |
| `Super+Ctrl+h/j/k/l` | Resize active window −40 / +40 px (hold to repeat) |
| `Super+Ctrl+←/↓/↑/→` | Resize active window (arrow variant) |
| `Super+V` | Clipboard history picker (cliphist + wofi) |
| `Super+Shift+V` | Toggle window floating |
| `Super+F` | Toggle true fullscreen (covers waybar) |
| `Super+C` | Kill active window |
| `Super+M` | Exit Hyprland |
| `Super+G` | Center current floating window |
| `Super+Shift+G` | Pin floating window to all workspaces |
| `Super + drag` (LMB) | Move floating window |
| `Super + drag` (RMB) | Resize floating window |

---

## Hyprland — workspaces & monitors

| Bind | Action |
|------|--------|
| `Super+1` … `Super+0` | Switch to workspace 1–10 (0 = workspace 10) |
| `Super+Shift+1` … `Super+Shift+0` | Move active window to workspace 1–10 (no follow) |
| `Super+B` | Toggle back to previous workspace |
| `Super+Tab` | Focus next monitor (cycles on 3+ displays) |
| `Super+Shift+Tab` | Move active window to next monitor |
| `Super+Ctrl+Tab` | Pull active workspace onto current monitor |

---

## Hyprland — apps & launchers

| Bind | Action |
|------|--------|
| `Super+Q` | Launch terminal (kitty) |
| `Super+E` | Launch file manager (thunar) |
| `Super+R` | App launcher (wofi drun) |
| `Super+W` | Wallpaper picker (waypaper) |
| `Super+.` | Emoji picker (bemoji + wtype injects into focused window) |
| `Super+Shift+C` | Color picker (hyprpicker → hex copied to clipboard) |
| `Super+Shift+M` | Power menu (lock / suspend / logout / reboot / shutdown) |
| `Ctrl+Alt+L` | Lock screen (hyprlock) |
| `Print` | Full-screen screenshot to clipboard |
| `Super+P` | Region screenshot to clipboard |
| `Super+Ctrl+P` | Region screenshot saved to `~/Pictures/screenshots/` |
| `Super+Shift+O` | Region OCR (text from screenshot → clipboard) |

---

## Hyprland — widgets & tools

| Bind | Action |
|------|--------|
| `Super+F1` | Toggle keybinds cheatsheet drawer (this list, searchable) |
| `F12` | Toggle drop-down scratchpad terminal |
| `Super+F12` | Toggle gamemode (compositor eye-candy off) |
| `Super+T` | Toggle HTB target sticky drawer |
| `Super+Shift+T` (right-click pill) | HTB VPN up / down toggle |
| `Super+I` | Copy active HTB target IP to clipboard |
| `Super+Shift+I` | Copy tun0 IP (your VPN IP, for reverse-shell payloads) |
| `Super+Shift+S` | Reverse-shell payload picker (templated with tun0 IP) |
| `Super+Space` | Toggle universal inbox capture drawer |
| `Super+Shift+P` | Pomodoro: idle → focus / running → pause / paused → resume |
| `Super+Shift+W` | Waybar controller drawer (toggle / reorder modules) |
| `Super+N` | Toggle Do Not Disturb (dunst pause/resume) |

---

## Waybar pills — click behaviour

| Pill | Left click | Right click | Scroll |
|------|------------|-------------|--------|
| Workspaces | Activate | — | Up = next, Down = prev |
| Pomodoro | Toggle (start/pause/resume) | Reset to idle | — |
| HTB | Open drawer | VPN toggle | — |
| B2 | Open drop-zone drawer | — | — |
| Gamemode | Toggle gamemode | — | — |
| Pulseaudio | pavucontrol | Mute toggle | ±2% volume |
| Bluetooth | blueman-manager | — | — |
| Now-playing | Play / pause | Next track | Prev / next |

---

## Tmux (prefix `Ctrl-a`)

| Bind | Action |
|------|--------|
| `Prefix` | `Ctrl-a` (not `Ctrl-b`) |
| `Prefix \|` | Split pane vertically (keep cwd) |
| `Prefix -` | Split pane horizontally (keep cwd) |
| `Prefix c` | New window (keep cwd) |
| `Prefix h/j/k/l` | Select pane left / down / up / right |
| `Prefix r` | Reload `~/.tmux.conf` |
| `Prefix [` | Enter copy mode |

---

## Zsh — command line editing

| Bind | Action |
|------|--------|
| `Ctrl+←/→` | Jump word back / forward |
| `Ctrl+⌫` | Delete word backward |
| `Ctrl+Delete` | Delete word forward |
| `Shift+←/→` | Extend selection by character |
| `Shift+⇑/⇓` | Extend selection by line |
| `Shift+Home/End` | Extend selection to start / end of line |
| `Shift+Ctrl+←/→` | Extend selection by word |
| Type a character (with selection) | Replaces selection |
| `Backspace` (with selection) | Deletes selection |

---

## Zsh — productivity trio

| Bind | Action | Tool |
|------|--------|------|
| `Ctrl+R` | Fuzzy-search every command you've ever run | atuin |
| `Ctrl+Up` | Atuin search UI (what bare Up arrow used to do) | atuin |
| `Up` | Plain shell-history previous (atuin disabled here) | zsh |
| `Ctrl+T` | Fuzzy file picker, pastes path on cmdline | fzf |
| `Alt+C` | Fuzzy directory picker, `cd`s into selection | fzf |
| `z <fragment>` | Jump to most-visited dir matching fragment | zoxide |
| `zi` | Interactive zoxide picker | zoxide |

---

## Neovim — Cryo additions

LazyVim base; only Cryo-specific binds listed.

| Bind | Action |
|------|--------|
| `<leader>on` | Obsidian: new note |
| `<leader>os` | Obsidian: search |
| `<leader>od` | Obsidian: open today's daily note |
| `<leader>ob` | Obsidian: show backlinks |

LazyVim defaults (full list: `:Telescope keymaps`): `<leader>ff` find file, `<leader>fg` grep, `<leader>e` toggle file tree, `<leader>l` Lazy package manager, `<leader>w` window operations, `<leader>x` diagnostics.

---

## Kitty — terminal

| Bind | Action |
|------|--------|
| `Ctrl+Shift+C` | Copy selection |
| `Ctrl+Shift+V` | Paste from clipboard |
| `Ctrl+Shift+Plus` / `Minus` / `0` | Font size up / down / reset |
| `Ctrl+Shift+T` | New tab |
| `Ctrl+Shift+Q` | Close window |
| `Ctrl+Shift+W` | Close tab |
| `Ctrl+Shift+Left/Right` | Previous / next tab |
| `Ctrl+Shift+Enter` | New window (split) |
| `Ctrl+Shift+F` | Open scrollback in pager |

---

## Yazi — file manager

| Bind | Action |
|------|--------|
| `h/j/k/l` | Navigate (vim) |
| `Enter` | Enter directory / open file |
| `Backspace` | Go up one level |
| `Space` | Toggle selection |
| `v` | Visual selection mode |
| `y` | Yank (copy) |
| `x` | Cut |
| `p` | Paste |
| `d` | Delete (to trash) |
| `D` | Delete permanently |
| `a` | Create file / directory |
| `r` | Rename |
| `/` | Search in current directory |
| `n` / `N` | Next / previous search hit |
| `gh` | Go home |
| `q` | Quit |
| `:` | Command mode |

---

## CLI tools (not keyboard chords — terminal commands)

| Command | What it does |
|---------|--------------|
| `inbox '<text>'` | Append timestamped line to `~/Documents/inbox.md` |
| `inbox` | Open inbox in `$EDITOR` |
| `inbox --tail 20` | Show last 20 entries |
| `htb-target set <name> <ip>` | Pin HTB box; populates JSON + opens notes template |
| `htb-target ip` / `htb-target name` | Print current target's IP / name (pipe-friendly) |
| `htb-target help` | All HTB-target subcommands |
| `pomodoro start [tag]` | Start a focus block; tag is optional |
| `pomodoro toggle` / `pause` / `resume` / `reset` | Manual control |
| `pomodoro status` | Print current state JSON |
| `bar-mood on` / `off` / `status` | Toggle ambient bar accent shifting |
| `waybar-layout list` / `apply` / `set <zone> <a,b,c>` / `reset` | Reorder bar modules |
| `clip-picker` | Open clipboard history picker (also: `Super+V`) |
| `clip-picker clear` | Wipe cliphist database (asks first) |
| `atuin import auto` | One-time: import existing zsh history into atuin's DB |
| `chwd -li` | List installed hardware-driver profiles (CachyOS) |
