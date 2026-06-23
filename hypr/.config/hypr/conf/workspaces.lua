-- ══════════════════════════════════════════
--   Ashen — Workspaces
-- ══════════════════════════════════════════

for i = 1, 9 do
    hl.workspace_rule({ workspace = tostring(i) })
end

-- Special Workspaces
hl.workspace_rule({ workspace = "special:music",   on_created_empty = "firefox" })
hl.workspace_rule({ workspace = "special:discord", on_created_empty = "discord" })
