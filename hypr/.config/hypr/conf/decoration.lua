-- ══════════════════════════════════════════
--   Ashen — Decoration
-- ══════════════════════════════════════════
hl.config({
    decoration = {
        rounding = 10,
        active_opacity = 0.85,
        inactive_opacity = 0.75,
        shadow = {
            enabled = true,
            range = 20,
            render_power = 3,
            color = 0xaa000000,
        },
        blur = {
            enabled = true,
            size = 12,
            passes = 4,
            vibrancy = 0.2,
            new_optimizations = true,
            xray = false,
        },
    },
})
