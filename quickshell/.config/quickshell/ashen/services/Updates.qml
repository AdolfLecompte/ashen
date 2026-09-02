pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// What this machine could install: pacman's own list plus whatever the AUR
// helper knows about. Nothing here installs anything -- a desktop widget that
// can start a transaction behind a wallpaper is a trap, not a feature.
Singleton {
    id: root

    // { name, from, to } per package, repos first, AUR after.
    property var list: []
    readonly property int count: root.list.length
    property bool checking: false
    // Epoch ms of the last answer, 0 until the first one lands.
    property double checkedAt: 0

    // Only asked while something is looking: checkupdates syncs a database of
    // its own, and doing that for a widget nobody can see is rude.
    property int watchers: 0
    function watch(on) {
        root.watchers = Math.max(0, root.watchers + (on ? 1 : -1))
        if (root.watchers > 0 && root.checkedAt === 0) root.refresh()
    }

    function refresh() {
        if (root.checking) return
        root.checking = true
        proc.running = true
    }

    Timer {
        running: root.watchers > 0
        interval: 30 * 60000
        repeat: true
        onTriggered: root.refresh()
    }

    Process {
        id: proc
        running: false
        // checkupdates never touches the real sync database; the helper is
        // asked only if it is installed, and neither one failing may take the
        // other's answer with it.
        command: ["sh", "-c",
            "{ checkupdates 2>/dev/null; " +
            "for h in paru yay; do command -v $h >/dev/null 2>&1 && { $h -Qua 2>/dev/null; break; }; done; } | sort -u"]
        stdout: StdioCollector {
            onStreamFinished: {
                let out = []
                for (const line of text.split("\n")) {
                    const l = line.trim()
                    if (l === "") continue
                    // "name 1.2.3-1 -> 1.2.4-1"
                    const m = l.match(/^(\S+)\s+(\S+)\s+->\s+(\S+)$/)
                    if (m) out.push({ name: m[1], from: m[2], to: m[3] })
                    else out.push({ name: l.split(/\s+/)[0], from: "", to: "" })
                }
                root.list = out
                root.checking = false
                root.checkedAt = Date.now()
            }
        }
    }
}
