pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    property int volume: 0
    property bool muted: false
    function toggleMute() {
        Quickshell.execDetached(["sh", "-c", "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"])
    }

    property int micVolume: 0
    property bool micMuted: false
    function toggleMicMute() {
        Quickshell.execDetached(["sh", "-c", "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"])
    }
    function setMicVolume(pct) {
        Quickshell.execDetached(["sh", "-c", "wpctl set-volume @DEFAULT_AUDIO_SOURCE@ " + pct + "%"])
    }


    Process {
        id: volProc
        command: ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root.muted = text.indexOf("MUTED") !== -1
                let match = text.match(/([0-9]*\.?[0-9]+)/)
                root.volume = match ? Math.round(parseFloat(match[1]) * 100) : 0
            }
        }
    }
    Process {
        id: micProc
        command: ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SOURCE@"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root.micMuted = text.indexOf("MUTED") !== -1
                let match = text.match(/([0-9]*\.?[0-9]+)/)
                root.micVolume = match ? Math.round(parseFloat(match[1]) * 100) : 0
            }
        }
    }


    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: { volProc.running = true; micProc.running = true }
    }
}
