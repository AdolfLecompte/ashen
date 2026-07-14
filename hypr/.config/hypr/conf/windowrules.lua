-- ══════════════════════════════════════════
--   Ashen — Window Rules
-- ══════════════════════════════════════════

-- Special Workspaces
hl.window_rule({ match = { class = "brave-cinhimbnkkaeohfgghhklpknlkffjgod-Default" }, workspace = "special:music"   })
hl.window_rule({ match = { class = "discord"        }, workspace = "special:discord" })

-- Floating
hl.window_rule({ match = { class = "nwg-displays"    }, float = true })
hl.window_rule({ match = { class = "pavucontrol"     }, float = true })

-- Opacity: no per-class overrides. Every window (terminal, browser,
-- discord, steam, editor...) uses the global active/inactive_opacity from
-- decoration.lua, so the frosted glass stays uniform.

-- Bar blur
hl.layer_rule({ match = { namespace = "quickshell:.*" }, blur = true })
hl.layer_rule({ match = { namespace = "quickshell:.*" }, ignore_alpha = 0.05 })
