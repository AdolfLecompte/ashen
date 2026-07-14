-- ══════════════════════════════════════════
--   Ashen — Workspaces
-- ══════════════════════════════════════════

for i = 1, 9 do
    hl.workspace_rule({ workspace = tostring(i) })
end

-- Special Workspaces
-- Through /usr/bin/brave, not /opt/brave-bin/brave: only the wrapper reads
-- ~/.config/brave-flags.conf, which is what routes notifications to D-Bus
hl.workspace_rule({ workspace = "special:music",   on_created_empty = "/usr/bin/brave --profile-directory=Default --app-id=cinhimbnkkaeohfgghhklpknlkffjgod" })
hl.workspace_rule({ workspace = "special:discord", on_created_empty = "discord" })
