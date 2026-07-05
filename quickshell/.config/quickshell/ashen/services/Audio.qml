pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    property int volume: 0

    Process {
        id: volProc
        command: ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{printf \"%d\", $2*100}'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.volume = parseInt(text.trim()) || 0
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: volProc.running = true
    }
}
