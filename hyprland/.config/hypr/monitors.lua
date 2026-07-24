-- Monitor setup
-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- Real output names: hyprctl monitors all

hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = 1,
})

-- Example setup
-- hl.monitor({ output = "HDMI-A-1", mode = "3840x2160@60",  position = "0x0",    scale = 1.5 })
-- hl.monitor({ output = "DP-2",     mode = "2560x1440@240", position = "2560x0", scale = 1   })
