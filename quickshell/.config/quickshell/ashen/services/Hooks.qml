pragma Singleton
import Quickshell
import QtQuick

// Your own commands on the shell's events: an executable at
// ~/.config/ashen/hooks/<event> runs with the event's details as arguments.
// No file, nothing runs. Changes while the shell starts up do not count.
Singleton {
    id: root

    readonly property string dir: Paths.config + "/hooks"
    readonly property var events: ["startup", "wallpaper", "lock", "unlock", "theme",
                                   "power", "battery-low", "usb", "game"]

    property bool armed: false
    function arm() { settle.restart() }
    Timer { id: settle; interval: 3000; onTriggered: { root.armed = true; root.fire("startup") } }

    function fire(event, ...args) {
        if (!root.armed) return
        Quickshell.execDetached(["sh", "-c", 'h="$1"; shift; [ -x "$h" ] && exec "$h" "$@"',
                                 "_", root.dir + "/" + event].concat(args.map(String)))
    }

    Connections {
        target: Wallpaper
        function onPathChanged() { if (Wallpaper.path !== "") root.fire("wallpaper", Wallpaper.path) }
    }
    Connections {
        target: AppState
        function onSessionLockedChanged() { root.fire(AppState.sessionLocked ? "lock" : "unlock") }
    }
    Connections {
        target: Prefs
        function onThemeModeChanged() { root.fire("theme", Prefs.themeMode) }
    }
    Connections {
        target: Battery
        function onChargingChanged() { root.fire("power", Battery.charging ? "ac" : "battery") }
        function onLowWarnedChanged() { if (Battery.lowWarned) root.fire("battery-low", Battery.level) }
    }
    Connections {
        target: Game
        function onOnChanged() { root.fire("game", Game.on ? "on" : "off") }
    }

    // USB drives by name, compared with the last look.
    property var knownDrives: []
    Connections {
        target: USB
        function onDrivesChanged() {
            const now = USB.drives.map(d => d.name)
            if (root.armed) {
                for (const n of now) if (root.knownDrives.indexOf(n) < 0) root.fire("usb", "added", n)
                for (const n of root.knownDrives) if (now.indexOf(n) < 0) root.fire("usb", "removed", n)
            }
            root.knownDrives = now
        }
    }
}
