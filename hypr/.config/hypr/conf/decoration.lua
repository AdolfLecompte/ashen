-- ══════════════════════════════════════════
--   Ashen — Decoration
-- ══════════════════════════════════════════
hl.config({
    decoration = {
        rounding = 10,
        -- Frosted glass: fairly transparent, but the strong blur below
        -- turns it milky instead of showing a sharp background.
        active_opacity = 0.60,
        inactive_opacity = 0.50,
        shadow = {
            enabled = true,
            range = 20,
            render_power = 3,
            color = 0xaa000000,
        },
        blur = {
            enabled = true,
            size = 10,
            passes = 4,
            vibrancy = 0.2,
            vibrancy_darkness = 0.5,
            noise = 0.03,
            contrast = 1.1,
            brightness = 0.85,
            popups = true,
            special = true,
            new_optimizations = true,
            xray = false,
        },
    },
})
