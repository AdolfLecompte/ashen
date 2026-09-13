-- ══════════════════════════════════════════
--   Ashen — Keybinds
-- ══════════════════════════════════════════

local mod = "SUPER"

-- Every combination below can be changed from Settings > Input. What is
-- written there lands in conf/userkeys.lua as a plain table of id -> keys, and
-- K() prefers it over the shipped default. Rebinding by unbinding what this
-- file just bound would leave the two disagreeing about what is bound; asking
-- BEFORE binding leaves one truth.
local keys = {}
pcall(function() keys = require("conf/userkeys") end)
local function K(id, default)
    local v = keys[id]
    if v == nil or v == "" then return default end
    return v
end

-- Shell
hl.bind(K("wallpaper", mod .. " + SHIFT + W"), hl.dsp.exec_cmd("qs ipc -c ashen call wallpaper toggle"))
hl.bind(K("notifications", mod .. " + N"),         hl.dsp.exec_cmd("qs ipc -c ashen call notifications toggle"))
hl.bind(K("settings", mod .. " + I"),         hl.dsp.exec_cmd("qs ipc -c ashen call settings toggle"))
hl.bind(K("clipboard", "SUPER + SHIFT + V"), hl.dsp.exec_cmd("sh -c 'qs ipc -c ashen call clipboard toggle'"), { locked = true })
hl.bind(K("processes", mod .. " + SHIFT + P"), hl.dsp.exec_cmd("qs ipc -c ashen call process toggle"), { locked = true })
-- Arrange the desktop widgets. Off, the desktop takes no clicks at all.
hl.bind(K("widgets", mod .. " + SHIFT + D"), hl.dsp.exec_cmd("qs ipc -c ashen call widgets edit"))
-- Flat compositor, quiet shell. By hand only -- it never turns itself on.
hl.bind(K("game", mod .. " + SHIFT + G"), hl.dsp.exec_cmd("qs ipc -c ashen call game toggle"))
-- Screen recording. The bar capsule is optional, so it cannot be the only way in.
hl.bind(K("record", mod .. " + SHIFT + R"), hl.dsp.exec_cmd("qs ipc -c ashen call record toggle"))


-- Mouse
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })


-- Apps
-- Not named outright: `ashen-app` opens what Settings was told to open, or the
-- system default, or the first one of its kind that is installed. Writing
-- "brave" here meant SUPER+W did nothing at all on a machine without it.
-- From the checkout if there is one, from PATH once installed -- the same
-- two-step autostart.lua uses. A session does not inherit the shell's PATH.
local function app(which)
    return hl.dsp.exec_cmd("sh -c 'S=\"$HOME/ashen/scripts/ashen-app\"; "
        .. "[ -x \"$S\" ] || S=ashen-app; exec \"$S\" " .. which .. "'")
end

hl.bind(K("terminal", mod .. " + T"), app("terminal"))
hl.bind(K("files",    mod .. " + E"), app("files"))
hl.bind(K("browser",  mod .. " + W"), app("browser"))
hl.bind(K("editor",   mod .. " + C"), app("editor"))
hl.bind(K("launcher", "SUPER + SUPER_L"), hl.dsp.exec_cmd("qs ipc -c ashen call launcher toggle"), { release = true })

-- Windows
hl.bind(K("close", mod .. " + Q"),       hl.dsp.window.close())
hl.bind(K("fullscreen", mod .. " + F"),       hl.dsp.window.fullscreen())
hl.bind(K("float", mod .. " + SHIFT + F"), hl.dsp.window.float({ action = "toggle" }))
hl.bind(K("pseudo", mod .. " + P"),       hl.dsp.window.pseudo())

-- Focus
hl.bind(K("focusLeft", mod .. " + left"),  hl.dsp.focus({ direction = "left"  }))
hl.bind(K("focusRight", mod .. " + right"), hl.dsp.focus({ direction = "right" }))
hl.bind(K("focusUp", mod .. " + up"),    hl.dsp.focus({ direction = "up"    }))
hl.bind(K("focusDown", mod .. " + down"),  hl.dsp.focus({ direction = "down"  }))

-- Workspaces and moving windows
for i = 1, 9 do
    hl.bind(mod .. " + " .. i,           hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + ALT + " .. i,     hl.dsp.window.move({ workspace = i }))
end
hl.bind(mod .. " + 0",       hl.dsp.focus({ workspace = 10 }))
hl.bind(mod .. " + ALT + 0", hl.dsp.window.move({ workspace = 10 }))
hl.bind(K("wsNext", mod .. " + CTRL + right"), hl.dsp.focus({ workspace = "e+1" }))
hl.bind(K("wsPrev", mod .. " + CTRL + left"),  hl.dsp.focus({ workspace = "e-1" }))
hl.bind(K("moveWsPrev", mod .. " + ALT + left"),  hl.dsp.window.move({ workspace = "e-1" }))
hl.bind(K("moveWsNext", mod .. " + ALT + right"), hl.dsp.window.move({ workspace = "e+1" }))

-- Special Workspaces
hl.bind(K("spMusic", mod .. " + M"), hl.dsp.workspace.toggle_special("music"))
hl.bind(K("spDiscord", mod .. " + D"), hl.dsp.workspace.toggle_special("discord"))
hl.bind(K("spNotes", mod .. " + O"), hl.dsp.workspace.toggle_special("notes"))
hl.bind(K("spFav", mod .. " + X"), hl.dsp.workspace.toggle_special("fav"))

-- Send to a special workspace
-- ALT sends, the way it does for the numbered workspaces. Silent: the window
-- goes away and you stay where you are; its key brings it back.
hl.bind(K("toMusic", mod .. " + ALT + M"),   hl.dsp.window.move({ workspace = "special:music",   silent = true }))
hl.bind(K("toDiscord", mod .. " + ALT + D"), hl.dsp.window.move({ workspace = "special:discord", silent = true }))
hl.bind(K("toNotes", mod .. " + ALT + O"),   hl.dsp.window.move({ workspace = "special:notes",   silent = true }))
hl.bind(K("toFav", mod .. " + ALT + X"),     hl.dsp.window.move({ workspace = "special:fav",     silent = true }))

-- Window switcher: the same call opens it and steps through it
hl.bind(K("switcherNext", "ALT + Tab"),         hl.dsp.exec_cmd("qs ipc -c ashen call switcher next"), { repeating = true })
hl.bind(K("switcherPrev", "ALT + SHIFT + Tab"), hl.dsp.exec_cmd("qs ipc -c ashen call switcher prev"), { repeating = true })

-- System
-- slurp draws the selection, and it was drawing NOTHING: `-w 0` is a border of
-- zero and `-b 00000000` a transparent screen, so you were dragging an
-- invisible rectangle. Now: the screen dims (-b), the selection stays clear so
-- you see what you are taking (-s), its edge is the shell's own accent (-c -w)
-- and -d prints the size while you drag.
hl.bind(K("screenshot", mod .. " + SHIFT + S"), hl.dsp.exec_cmd("sh -c 'DEFAULT_TARGET_DIR=\"$HOME/Pictures/Screenshots\" SLURP_ARGS=\"-b 12121a99 -s 00000000 -c 6e6e7aff -w 2 -d\" grimblast copysave area && qs ipc -c ashen call notifications screenshot'"))
hl.bind(K("lock", mod .. " + L"),         hl.dsp.exec_cmd("qs ipc -c ashen call lockscreen lock"))
hl.bind(K("power", mod .. " + Escape"),    hl.dsp.exec_cmd("qs ipc -c ashen call power toggle"))
-- Closing the lid locks right away; logind still owns the suspend itself.
-- Belt to hypridle's before_sleep_cmd: this fires even if the daemon is down.
hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd("qs ipc -c ashen call lockscreen lock"), { locked = true })

-- Audio and brightness
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("sh -c 'wpctl set-mute @DEFAULT_AUDIO_SINK@ 0 && wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ -l 1.0 && qs ipc -c ashen call osd volume'"),  { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("sh -c 'wpctl set-mute @DEFAULT_AUDIO_SINK@ 0 && wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- && qs ipc -c ashen call osd volume'"),  { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("sh -c 'wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle && qs ipc -c ashen call osd volume'"), { locked = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("sh -c 'brightnessctl set 5%+ && qs ipc -c ashen call osd brightness'"),     { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("sh -c 'brightnessctl set 5%- && qs ipc -c ashen call osd brightness'"),     { locked = true, repeating = true })

-- Media
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("sh -c 'qs ipc -c ashen call media next || playerctl next'"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("sh -c 'qs ipc -c ashen call media prev || playerctl previous'"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("sh -c 'qs ipc -c ashen call media playPause || playerctl play-pause'"), { locked = true })

-- ── Capturing a shortcut in Settings ─────────────────────────────────────
-- Hyprland runs its own binds BEFORE handing the key to the client, so a chip
-- waiting for SUPER+T never saw it: the compositor opened a terminal instead.
-- While Settings is listening, the session moves into this submap, where
-- nothing is bound and every key falls through to Quickshell. Escape is the
-- one way out that does not depend on the shell being alive to send it.
hl.define_submap("ashen-capture", function()
    hl.bind("escape", hl.dsp.submap("reset"))
end)
