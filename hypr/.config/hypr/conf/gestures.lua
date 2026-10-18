-- ══════════════════════════════════════════
--   Ashen — Touchpad gestures
-- ══════════════════════════════════════════

-- Not in input.lua: that file belongs to the installer and to Settings, which
-- rewrite its keyboard layout. Settings > Input reads this file for its
-- Gestures card, so a gesture added here shows up there by itself.

-- Workspaces
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- Launcher
hl.gesture({
    fingers = 3,
    direction = "up",
    action = function() hl.exec_cmd("qs ipc -c ashen call launcher toggle") end
})

-- Scratchpad
hl.gesture({
    fingers = 3,
    direction = "down",
    action = function() hl.dispatch(hl.dsp.workspace.toggle_special("scratch")) end
})

-- Move the active window
hl.gesture({ fingers = 4, direction = "swipe", action = "move" })
