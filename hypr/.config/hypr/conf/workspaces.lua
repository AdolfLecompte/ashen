-- ══════════════════════════════════════════
--   Ashen — Workspaces
-- ══════════════════════════════════════════

for i = 1, 9 do
    hl.workspace_rule({ workspace = tostring(i) })
end

-- Special Workspaces
-- Through /usr/bin/brave, not /opt/brave-bin/brave: only the wrapper reads
-- ~/.config/brave-flags.conf, which is what routes notifications to D-Bus
-- What opens when a special workspace is created empty. A workspace.created
-- handler, not on_created_empty: Hyprland 0.57 deprecated that rule.
local onEmpty = {
    ["special:music"]   = "/usr/bin/brave --profile-directory=Default --app-id=cinhimbnkkaeohfgghhklpknlkffjgod",
    ["special:discord"] = "discord",
    ["special:notes"]   = "obsidian",
}
hl.on("workspace.created", function(ws)
    local cmd = onEmpty[ws.name] or onEmpty["special:" .. tostring(ws.name)]
    if cmd and ws.is_empty then hl.exec_cmd(cmd) end
end)
