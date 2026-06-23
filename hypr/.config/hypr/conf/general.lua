-- ══════════════════════════════════════════
--   Ashen — General
-- ══════════════════════════════════════════
hl.config({
    general = {
        gaps_in = 4,
        gaps_out = 8,
        border_size = 2,
        col = {
            active_border = { colors = {"rgba(6272a4ff)"} },
            inactive_border = "rgba(16161bff)",
        },
        resize_on_border = true,
        layout = "dwindle",
    },
    dwindle = {
        preserve_split = true,
    },
})
