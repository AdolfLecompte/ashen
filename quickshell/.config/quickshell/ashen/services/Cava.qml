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
    readonly property bool enabled: Prefs.visualizer && !Game.on

    // Off, it goes deaf first and dies after, so the wave fades the way it does
    // when the music stops. Killing it outright froze the last frame on screen.
    property bool procAlive: root.enabled
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
                let maxV = Math.max.apply(null, parts)
                // Silence is still sixty frames a second of zeros, and every one
                // of them used to be published -- which woke a Canvas repaint in
                // each wave on screen, all of them invisible by then. The frame
                // that goes quiet IS published, so the bars fall to nothing
                // rather than freezing tall behind the fade; after that nothing
                // is until there is something to say again.
                const speaking = maxV > 2
                if (speaking || root.isActive)
                    root.barValues = parts
                root.isActive = speaking
            }
        }
        onRunningChanged: if (!running && root.procAlive) running = true
    }
}
