-- ══════════════════════════════════════════
--   Ashen — Windows and layouts
-- ══════════════════════════════════════════
-- Snapping, tab groups, per-workspace layouts, and the helpers keybinds.lua binds.

local M = {}

hl.config({
    general = {
        snap = { enabled = true, respect_gaps = true, window_gap = 10, monitor_gap = 10 },
    },
    scrolling = {
        column_width = 0.5,
        explicit_column_widths = "0.333, 0.5, 0.667, 1.0",
    },
})

-- ── Tab groups, painted with the wallpaper's accent ──────────────────────
local function accent()
    local f = io.open(os.getenv("HOME") .. "/.cache/ashen_accent.json")
    local s = f and f:read("a") or ""
    if f then f:close() end
    local function get(k, def) return s:match('"' .. k .. '"%s*:%s*"#(%x+)"') or def end
    return { accent = get("accent", "ffb4ac"), on = get("onAccent", "5f1412"), surface = get("surface", "281e11") }
end

-- Re-read by scripts/ashen-apply-border.sh after every recolor.
function M.paintGroups()
    local c = accent()
    hl.config({
        group = {
            col = {
                border_active = { colors = { "rgba(" .. c.accent .. "ff)" } },
                border_inactive = { colors = { "rgba(" .. c.surface .. "00)" } },
                border_locked_active = { colors = { "rgba(" .. c.accent .. "ff)" } },
                border_locked_inactive = { colors = { "rgba(" .. c.surface .. "00)" } },
            },
            groupbar = {
                enabled = true,
                font_family = "JetBrainsMono NF",
                font_size = 11,
                height = 22,
                gradients = true,
                rounding = 8,
                gradient_rounding = 8,
                indicator_height = 0,
                gaps_in = 4,
                gaps_out = 4,
                keep_upper_gap = false,
                text_color = "rgba(" .. c.on .. "ff)",
                text_color_inactive = "rgba(" .. c.accent .. "cc)",
                col = {
                    active = { colors = { "rgba(" .. c.accent .. "ff)" } },
                    inactive = { colors = { "rgba(" .. c.surface .. "cc)" } },
                    locked_active = { colors = { "rgba(" .. c.accent .. "ff)" } },
                    locked_inactive = { colors = { "rgba(" .. c.surface .. "cc)" } },
                },
            },
        },
    })
end
M.paintGroups()

-- ── Helpers ──────────────────────────────────────────────────────────────
-- Free area of the active monitor, in logical px.
local function usable()
    local m = hl.get_active_monitor()
    local r = m.reserved
    return (m.width / m.scale) - r.left - r.right, (m.height / m.scale) - r.top - r.bottom
end

local function place(fw, fh, addr)
    local w, h = usable()
    local target = "address:" .. addr
    hl.dispatch(hl.dsp.window.resize({ x = math.floor(w * fw), y = math.floor(h * fh), relative = false, window = target }))
    hl.dispatch(hl.dsp.window.center({ window = target }))
end

-- A maximized or fullscreen window can be neither floated nor pinned.
local function unmax(win)
    if win.fullscreen == 0 then return end
    hl.dispatch(hl.dsp.window.fullscreen({ mode = win.fullscreen == 2 and "fullscreen" or "maximized", action = "unset" }))
end

-- Floating opens centred at 60% x 70%; tiling it again restores its tile.
function M.float()
    local win = hl.get_active_window()
    if not win then return end
    -- `win` is live: read its state before changing it.
    local tiled, addr = not win.floating, win.address
    unmax(win)
    hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
    if tiled then place(0.6, 0.7, addr) end
end

-- Pinning needs a float: a tiled window is floated first.
function M.pin()
    local win = hl.get_active_window()
    if not win then return end
    if not win.floating then M.float() end
    hl.dispatch(hl.dsp.window.pin({ action = "toggle" }))
end

-- Dwindle ↔ scrolling for the active workspace, until the next reload.
function M.toggleLayout()
    local ws = hl.get_active_workspace()
    if not ws then return end
    local next = ws.tiled_layout == "scrolling" and "dwindle" or "scrolling"
    hl.workspace_rule({ workspace = tostring(ws.id), layout = next })
end

-- Steps 1/3 → 1/2 → 2/3: the split in dwindle, the column in scrolling, the width of a float.
local steps = { 0.333, 0.5, 0.667 }
local stepOf = {}
function M.cycleSize()
    local win = hl.get_active_window()
    local ws = hl.get_active_workspace()
    if not win or not ws then return end
    if not win.floating and ws.tiled_layout == "scrolling" then
        hl.dispatch(hl.dsp.layout("colresize +conf"))
        return
    end
    local key = tostring(win.address)
    stepOf[key] = (stepOf[key] or 2) % #steps + 1
    local f = steps[stepOf[key]]
    if win.floating then
        place(f, 0.7, win.address)
    else
        hl.dispatch(hl.dsp.layout("splitratio " .. (f * 2) .. " exact"))
    end
end

return M
