-- ══════════════════════════════════════════
--   Ashen — Autostart
-- ══════════════════════════════════════════

local function start(cmd)
    hl.on("hyprland.start", function()
        hl.exec_cmd(cmd)
    end)
end

start("awww-daemon")
-- Brings back the last wallpaper: awww for images/gif, mpvpaper for video
start("$HOME/ashen/scripts/ashen-wallpaper-restore.sh")
start("quickshell -c ashen")
start("hypridle")
start("wl-paste --type text --watch cliphist store")
start("wl-paste --type image --watch cliphist store")
