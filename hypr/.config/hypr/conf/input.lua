-- ══════════════════════════════════════════
--   Ashen — Input
-- ══════════════════════════════════════════

hl.config({
    input = {
        kb_layout = "latam",
        kb_variant = "",
        kb_model = "",
        kb_options = "",
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = {
            natural_scroll = true,
            disable_while_typing = true,
            tap_to_click = true,
            scroll_factor = 0.5,
        },
    },
})

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
