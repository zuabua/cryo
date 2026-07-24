-- Keybinds
-- See https://wiki.hypr.land/Configuring/Basics/Binds/
-- and https://wiki.hypr.land/Configuring/Basics/Dispatchers/

local vars = require("vars")

local mainMod     = vars.mainMod
local terminal    = vars.terminal
local fileManager = vars.fileManager

hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch exit"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("~/.local/bin/clip-picker"))
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("wofi --show drun"))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind(mainMod .. " + F12", hl.dsp.exec_cmd("~/.config/hypr/gamemode.sh"))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("waypaper"))
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd("~/.config/waybar/htb-toggle.sh"))
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("~/.config/quickshell/inbox-toggle.sh"))
hl.bind(mainMod .. " + period", hl.dsp.exec_cmd("bemoji -t"))
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd("~/.local/bin/pomodoro toggle"))
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("~/.config/quickshell/barctl-toggle.sh"))
hl.bind(mainMod .. " + F1", hl.dsp.exec_cmd("~/.config/quickshell/keybinds-toggle.sh"))
hl.bind("F12", hl.dsp.workspace.toggle_special("scratchpad"))
hl.bind("CTRL + ALT + L", hl.dsp.exec_cmd("pidof hyprlock || hyprlock"))

-- HTB Binds
hl.bind(mainMod .. " + I", hl.dsp.exec_cmd([[sh -c 'ip=$("$HOME/.local/bin/htb-target" ip 2>/dev/null); if [ -n "$ip" ]; then printf %s "$ip" | wl-copy; notify-send -t 1500 "Target IP" "$ip"; else notify-send -t 1500 "No active HTB target"; fi']]))
hl.bind(mainMod .. " + SHIFT + I", hl.dsp.exec_cmd([[sh -c 'ip=$(ip -4 addr show tun0 2>/dev/null | grep -oE "inet [0-9.]+" | head -n1 | cut -d" " -f2); if [ -n "$ip" ]; then printf %s "$ip" | wl-copy; notify-send -t 1500 "tun0 IP" "$ip"; else notify-send -t 1500 "tun0 down" "Bring HTB VPN up first"; fi']]))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("$HOME/.local/bin/revshell"))

hl.bind(mainMod .. " + B", hl.dsp.focus({ workspace = "previous" }))
hl.bind(mainMod .. " + G", hl.dsp.window.center())
hl.bind(mainMod .. " + SHIFT + G", hl.dsp.window.pin())

-- Some picker tools
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd([[sh -c 'hex=$(hyprpicker -f hex 2>/dev/null); if [ -n "$hex" ]; then printf %s "$hex" | wl-copy; notify-send -t 1500 "Color picked" "$hex"; fi']]))
hl.bind(mainMod .. " + SHIFT + O", hl.dsp.exec_cmd([[sh -c 'r=$(slurp 2>/dev/null) || exit 0; text=$(grim -g "$r" - | tesseract - - 2>/dev/null); if [ -n "$text" ]; then printf %s "$text" | wl-copy; notify-send -t 1800 "OCR text copied" "$(printf %s "$text" | head -c 80)"; else notify-send -t 1500 "OCR" "no text recognized"; fi']]))
hl.bind(mainMod .. " + CTRL + P", hl.dsp.exec_cmd([[sh -c 'mkdir -p "$HOME/Pictures/screenshots"; r=$(slurp 2>/dev/null) || exit 0; f="$HOME/Pictures/screenshots/$(date +%F-%H%M%S).png"; grim -g "$r" "$f" && notify-send -t 1800 "Screenshot saved" "$f"']]))

-- Session controls
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd([[sh -c 'if [ "$(dunstctl is-paused)" = "false" ]; then notify-send -t 1500 "DND on" "Notifications paused"; sleep 0.15; dunstctl set-paused true; else dunstctl set-paused false; notify-send -t 1500 "DND off" "Notifications resumed"; fi']]))
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exec_cmd("$HOME/.local/bin/power-menu"))

-- Window focus
hl.bind(mainMod .. " + h", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + j", hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + k", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + l", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + Left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + Down", hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + Up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + Right", hl.dsp.focus({ direction = "right" }))

-- Window movement
hl.bind(mainMod .. " + SHIFT + h", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + j", hl.dsp.window.move({ direction = "down" }))
hl.bind(mainMod .. " + SHIFT + k", hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + l", hl.dsp.window.move({ direction = "right" }))

-- Workspace switching / move active window to workspace
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Window resize
hl.bind(mainMod .. " + CTRL + h", hl.dsp.window.resize({ x = -40, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + l", hl.dsp.window.resize({ x = 40, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + k", hl.dsp.window.resize({ x = 0, y = -40, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + j", hl.dsp.window.resize({ x = 0, y = 40, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + Left", hl.dsp.window.resize({ x = -40, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + Right", hl.dsp.window.resize({ x = 40, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + Up", hl.dsp.window.resize({ x = 0, y = -40, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + Down", hl.dsp.window.resize({ x = 0, y = 40, relative = true }), { repeating = true })

-- Multi monitor binds
hl.bind(mainMod .. " + Tab", hl.dsp.focus({ monitor = "+1" }))
hl.bind(mainMod .. " + SHIFT + Tab", hl.dsp.window.move({ monitor = "+1" }))
hl.bind(mainMod .. " + CTRL + Tab", hl.dsp.workspace.move({ monitor = "+1" }))

-- Mouse
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Screenshots
hl.bind("Print", hl.dsp.exec_cmd("grim - | wl-copy"))
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd([[grim -g "$(slurp)" - | wl-copy]]))
