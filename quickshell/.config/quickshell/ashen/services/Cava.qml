pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    property var barValues: []
    property bool isActive: false

    // Game mode reads through here rather than writing the preference: a crash
    // mid-game would otherwise leave the visualiser switched off for good.
    // The switch in Settings: the bar, the panel and the lock screen.
    readonly property bool enabled: Prefs.visualizer && !Game.on
    // Desktop widgets stay out of that switch: while one that draws the
    // sound is out, cava keeps listening for it.
    readonly property bool forWidgets: Desktop.shown("visualizer") || Desktop.shown("media")
    readonly property bool needed: !Game.on && (Prefs.visualizer || root.forWidgets)

    // Listens only while something plays. On stop it keeps reading long enough
    // for cava's own fall to reach zero, then dies and leaves nothing behind.
    readonly property bool wanted: root.needed && Media.playing
    property bool procAlive: root.wanted
    onWantedChanged: {
        if (root.wanted) {
            stopSoon.stop()
            root.procAlive = true
        } else {
            stopSoon.restart()
        }
    }
    onNeededChanged: if (!root.needed) root.isActive = false
    Timer {
        id: stopSoon
        interval: 2500
        onTriggered: {
            root.procAlive = false
            root.isActive = false
            // Paused: bars rest at zero. Switched off: nothing is drawn.
            root.barValues = root.needed ? root.barValues.map(() => 0) : []
        }
    }

    Process {
        id: cavaProcess
        command: ["sh", "-c", "exec cava -p \"$HOME/.config/cava/ashen.conf\""]
        running: root.procAlive
        stdout: SplitParser {
            onRead: data => {
                // A line still buffered when the process is told to stop lands
                // after stopSoon's zeros and froze the bars tall: ignore it.
                if (!data || !root.needed || !root.procAlive) return
                let parts = data.split(";").filter(s => s.length > 0).map(Number)
                if (parts.length === 0) return
                let maxV = Math.max.apply(null, parts)
                // Silence is published once, as true zeros, then not at all
                // until there is sound again: idle repaints cost CPU.
                const speaking = maxV > 2
                if (speaking) root.barValues = parts
                else if (root.isActive) root.barValues = parts.map(() => 0)
                root.isActive = speaking
            }
        }
        onRunningChanged: if (!running && root.procAlive) running = true
    }
}
