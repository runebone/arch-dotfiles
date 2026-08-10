-- === ENVIRONMENT ===
hl.env("XCURSOR_SIZE", "24")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("QT_QPA_PLATFORM", "wayland")
hl.env("QT_STYLE_OVERRIDE", "kvantum")

-- === MONITOR SETUP ===
-- hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "1" })
hl.monitor({ output = "eDP-1", mode = "1920x1080@60", position = "0x0", scale = "1" })
-- hl.monitor({ output = "HDMI-A-1", mode = "preferred", position = "1920x0", scale = "1" })
hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@120", position = "auto", scale = "1", mirror = "eDP-1" })

-- === WORKSPACE BINDING ===
for i = 1, 9 do
    hl.workspace_rule({ workspace = tostring(i), monitor = "eDP-1" })
end

-- === AUTOSTART PROGRAMS ===
hl.on("hyprland.start", function()
    hl.exec_cmd("swaybg -i ~/.bg -m fill")
    hl.exec_cmd("waybar")
    hl.exec_cmd("sleep 1 && QT_QPA_PLATFORM=xcb AmneziaVPN")
    -- hl.exec_cmd("wofi --show drun")
end)

-- === APPEARANCE: NO ANIMATIONS, NO BORDERS, NO EFFECTS ===
hl.config({
    general = {
        gaps_in = 4,
        gaps_out = 8,
        border_size = 0,
        col = {
            active_border = "rgba(00000000)",
            inactive_border = "rgba(00000000)",
        },
    },

    -- https://wiki.hypr.land/Configuring/Variables/#decoration
    decoration = {
        rounding = 0,
        rounding_power = 0,

        -- Change transparency of focused and unfocused windows
        active_opacity = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled = true,
            range = 12,
            render_power = 3,
            color = "rgba(1a1a1aee)",
        },

        -- https://wiki.hypr.land/Configuring/Variables/#blur
        blur = {
            enabled = true,
            size = 3,
            passes = 1,

            vibrancy = 0.1696,
        },
    },

    animations = {
        enabled = false,
    },
})

-- Default animations, see https://wiki.hypr.land/Configuring/Animations/ for more
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}   } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}   } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}      } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1.0} } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}    } })

hl.animation({ leaf = "global",        enabled = true, speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true, speed = 1.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 1.1,  bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 0.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 0.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true, speed = 1.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })

-- See https://wiki.hypr.land/Configuring/Gestures
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- === TERMINAL ===
local term = "alacritty"

-- === KEYBINDINGS ===
-- NOTE: raw X keycodes are kept as `code:NN` so binds stay layout-independent.

hl.bind("SUPER + Z",         hl.dsp.exec_cmd("hyprlock"))
hl.bind("SUPER + SHIFT + Z", hl.dsp.exit())

-- Launchers and system tools
hl.bind("SUPER + code:36",         hl.dsp.exec_cmd(term))                                              -- RETURN
hl.bind("SUPER + SHIFT + code:27", hl.dsp.exec_cmd(term .. " -e htop"))                                -- R
hl.bind("SUPER + code:27",         hl.dsp.exec_cmd(term .. " -e yazi"))                                -- R
hl.bind("SUPER + SHIFT + code:25", hl.dsp.exec_cmd(term .. " -e nmtui"))                               -- W
hl.bind("SUPER + code:40",         hl.dsp.exec_cmd("rofi -show drun"))                                 -- D
hl.bind("SUPER + SHIFT + code:26", hl.dsp.exec_cmd("rofi -modi emoji -show emoji"))                    -- E
hl.bind("SUPER + code:33",         hl.dsp.exec_cmd("hyprpicker"))                                      -- P
hl.bind("SUPER + code:53",         hl.dsp.exec_cmd("nmcli device connect wlp3s0"))                     -- X
hl.bind("SUPER + code:32",         hl.dsp.exec_cmd("obsidian"))                                        -- O
hl.bind("SUPER + code:28",         hl.dsp.exec_cmd("Telegram"))                                        -- T
hl.bind("SUPER + code:54",         hl.dsp.exec_cmd("~/.local/bin/cursor"))                              -- C
hl.bind("SUPER + code:31",         hl.dsp.exec_cmd("sh ~/.dotfiles/scripts/hypr-switch-layout.sh"))    -- I
hl.bind("SUPER + SHIFT + code:32", hl.dsp.exec_cmd("sh ~/.dotfiles/scripts/open-last-screenshot.sh"))  -- O

-- Browsers
hl.bind("SUPER + code:25", hl.dsp.exec_cmd("firefox"))  -- W
hl.bind("SUPER + code:26", hl.dsp.exec_cmd("chromium")) -- E

-- Audio
hl.bind("SUPER + code:58",         hl.dsp.exec_cmd("pactl set-source-mute @DEFAULT_SOURCE@ toggle")) -- M
hl.bind("code:156",                hl.dsp.exec_cmd("pactl set-source-mute @DEFAULT_SOURCE@ toggle")) -- M
hl.bind("SUPER + SHIFT + code:58", hl.dsp.exec_cmd("pamixer -t"))                                    -- M
hl.bind("code:121",                hl.dsp.exec_cmd("pamixer -t"))                                    -- M
hl.bind("SUPER + code:20", hl.dsp.exec_cmd("pamixer -d 5"), { locked = true, repeating = true }) -- MINUS
hl.bind("code:122",        hl.dsp.exec_cmd("pamixer -d 5"), { locked = true, repeating = true }) -- MINUS
hl.bind("SUPER + code:21", hl.dsp.exec_cmd("pamixer -i 5"), { locked = true, repeating = true }) -- EQUAL
hl.bind("code:123",        hl.dsp.exec_cmd("pamixer -i 5"), { locked = true, repeating = true }) -- EQUAL

-- Brightness
hl.bind("SUPER + SHIFT + code:111", hl.dsp.exec_cmd("brightnessctl set +1%"), { locked = true, repeating = true }) -- UP
hl.bind("code:233",                 hl.dsp.exec_cmd("brightnessctl set +5%"), { locked = true, repeating = true }) -- UP
hl.bind("SUPER + SHIFT + code:116", hl.dsp.exec_cmd("brightnessctl set 1%-"), { locked = true, repeating = true }) -- DOWN
hl.bind("code:232",                 hl.dsp.exec_cmd("brightnessctl set 5%-"), { locked = true, repeating = true }) -- DOWN

-- Screenshot full
hl.bind("SUPER + code:39", hl.dsp.exec_cmd("sh ~/.dotfiles/scripts/screenshot-full")) -- S
hl.bind("code:107",        hl.dsp.exec_cmd("sh ~/.dotfiles/scripts/screenshot-full")) -- S
-- Screenshot selection
hl.bind("SUPER + SHIFT + code:39", hl.dsp.exec_cmd("sh ~/.dotfiles/scripts/screenshot-sel")) -- S

-- Workspaces
for i = 1, 9 do
    hl.bind("SUPER + code:" .. (9 + i),         hl.dsp.focus({ workspace = i }))       -- 1..9
    hl.bind("SUPER + SHIFT + code:" .. (9 + i), hl.dsp.window.move({ workspace = i })) -- 1..9
end

-- Focus move
hl.bind("SUPER + code:43", hl.dsp.focus({ direction = "left" }))  -- H
hl.bind("SUPER + code:44", hl.dsp.focus({ direction = "down" }))  -- J
hl.bind("SUPER + code:45", hl.dsp.focus({ direction = "up" }))    -- K
hl.bind("SUPER + code:46", hl.dsp.focus({ direction = "right" })) -- L

-- Move window
hl.bind("SUPER + SHIFT + code:43", hl.dsp.window.swap({ direction = "left" }))  -- H
hl.bind("SUPER + SHIFT + code:44", hl.dsp.window.swap({ direction = "down" }))  -- J
hl.bind("SUPER + SHIFT + code:45", hl.dsp.window.swap({ direction = "up" }))    -- K
hl.bind("SUPER + SHIFT + code:46", hl.dsp.window.swap({ direction = "right" })) -- L

-- Resize window
hl.bind("SUPER + code:34", hl.dsp.window.resize({ x = -120, y = 0, relative = true }), { locked = true, repeating = true }) -- bracketleft
hl.bind("SUPER + code:35", hl.dsp.window.resize({ x = 120, y = 0, relative = true }),  { locked = true, repeating = true }) -- bracketright

-- Window mode toggles
hl.bind("SUPER + code:41",         hl.dsp.window.fullscreen())                 -- F
hl.bind("SUPER + SHIFT + code:41", hl.dsp.window.float({ action = "toggle" })) -- F
-- hl.bind("SUPER + code:28",      hl.dsp.group.toggle())                      -- T
hl.bind("SUPER + code:24",         hl.dsp.window.close())                      -- Q
hl.bind("SUPER + SHIFT + code:24", hl.dsp.exec_cmd("systemctl suspend"))       -- Q
hl.bind("SUPER + SHIFT + code:33", hl.dsp.window.pin())                        -- P

hl.bind("SUPER + SHIFT + code:56", hl.dsp.exec_cmd("sh ~/.dotfiles/scripts/keylogger-toggle.sh")) -- B

hl.bind("SUPER + code:73", hl.dsp.exec_cmd("obs-cmd recording toggle-pause")) -- F7
hl.bind("SUPER + code:74", hl.dsp.exec_cmd("obs-cmd recording toggle"))       -- F8

-- === Mouse: Move and resize windows ===
hl.bind("SUPER + mouse:272", hl.dsp.window.drag())
hl.bind("SUPER + mouse:273", hl.dsp.window.resize())

require("xkb")

hl.config({
    input = {
        repeat_rate = 70,
        repeat_delay = 290,
    },

    misc = {
        force_default_wallpaper = 0,   -- Set to 0 or 1 to disable the anime mascot wallpapers
        disable_hyprland_logo = true,  -- If true disables the random hyprland logo / anime girl background. :(
    },
})
