-- ══════════════════════════════════════════
--   Ashen — Hyprland Config
--   github.com/AdolfLecompte/ashen
-- ══════════════════════════════════════════

-- Core
require("conf/monitors")
require("conf/env")
require("conf/general")

-- Appearance
require("conf/decoration")
require("conf/animations")
require("conf/windows")

-- Input
require("conf/input")
require("conf/gestures")
require("conf/keybinds")

-- Rules & Workspaces
require("conf/windowrules")
require("conf/workspaces")

-- Autostart
require("conf/autostart")

-- This machine's own, outside the checkout so an update never meets them, and
-- last so they win: layout.lua and border.lua are written by Settings and the
-- theme, user.lua is yours.
local own = os.getenv("HOME") .. "/.config/ashen/hypr/"
for _, f in ipairs({ "layout.lua", "border.lua", "user.lua" }) do
    local fh = io.open(own .. f)
    if fh then fh:close(); dofile(own .. f) end
end
