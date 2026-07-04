-- ══════════════════════════════════════════
--   Ashen — Window Rules
-- ══════════════════════════════════════════

-- Special Workspaces
hl.window_rule({ match = { class = "youtube-music" }, workspace = "special:music"   })
hl.window_rule({ match = { class = "discord"        }, workspace = "special:discord" })

-- Floating
hl.window_rule({ match = { class = "waypaper"        }, float = true })
hl.window_rule({ match = { class = "blueman-manager" }, float = true })
hl.window_rule({ match = { class = "nwg-displays"    }, float = true })
hl.window_rule({ match = { class = "pavucontrol"     }, float = true })

-- Opacidad
hl.window_rule({ match = { class = "kitty"   }, opacity = "0.90 override 0.85 override" })
hl.window_rule({ match = { class = "nemo"}, opacity = "0.92 override 0.88 override" })
hl.window_rule({ match = { class = "codium"  }, opacity = "0.95 override 0.90 override" })

-- Tamaño floating
hl.window_rule({ match = { class = "waypaper"        }, size = "900 600", center = true })
hl.window_rule({ match = { class = "blueman-manager" }, size = "900 600", center = true })
