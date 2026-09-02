pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    property var barValues: []
    property bool isActive: false

    readonly property bool enabled: Prefs.visualizer

    // Off, it goes deaf first and dies after, so the wave fades the way it does
    // when the music stops. Killing it outright froze the last frame on screen.
    property bool procAlive: Prefs.visualizer
    onEnabledChanged: {
        if (root.enabled) {
            stopSoon.stop()
            root.procAlive = true
        } else {
            root.isActive = false
            stopSoon.restart()
        }
    }
    Timer {
        id: stopSoon
        interval: 1200
        onTriggered: {
            root.procAlive = false
            root.barValues = []
        }
    }

    Process {
        id: cavaProcess
        command: ["sh", "-c", "exec cava -p \"$HOME/.config/cava/ashen.conf\""]
        running: root.procAlive
        stdout: SplitParser {
            onRead: data => {
                if (!data || !root.enabled) return
                let parts = data.split(";").filter(s => s.length > 0).map(Number)
                if (parts.length === 0) return
                root.barValues = parts
                let maxV = Math.max.apply(null, parts)
                root.isActive = maxV > 2
            }
        }
        onRunningChanged: if (!running && root.procAlive) running = true
    }
}
