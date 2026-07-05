pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    property int level: 0
    property bool charging: false

    Process {
        id: batProc
        command: ["sh", "-c", "cat /sys/class/power_supply/BAT0/capacity"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.level = parseInt(text.trim()) || 0
        }
    }

    Process {
        id: chargeProc
        command: ["sh", "-c", "cat /sys/class/power_supply/AC0/online"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.charging = text.trim() === "1"
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: {
            batProc.running = true
            chargeProc.running = true
        }
    }
}
