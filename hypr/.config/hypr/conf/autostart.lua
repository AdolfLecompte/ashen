-- ══════════════════════════════════════════
--   Ashen — Autostart
-- ══════════════════════════════════════════

local function start(cmd)
    hl.on("hyprland.start", function()
        hl.exec_cmd(cmd)
    end)
end

start("swww-daemon")
start("quickshell -c ~/.config/ashen")
start("swayosd-server")
start("hypridle")
start("wl-paste --type text --watch cliphist store")
start("wl-paste --type image --watch cliphist store")
start("nm-applet --indicator")
start("blueman-applet")
start("/usr/lib/plasma-browser-integration/plasma-browser-integration-host")
