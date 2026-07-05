pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    property string wifiSsid: ""
    property string btDevice: ""

    Process {
        id: wifiProc
        command: ["nmcli", "-t", "-f", "active,ssid", "dev", "wifi"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = text.split("\n")
                for (let line of lines) {
                    if (line.startsWith("yes:")) {
                        root.wifiSsid = line.substring(4).trim()
                        return
                    }
                }
                root.wifiSsid = ""
            }
        }
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: wifiProc.running = true
    }

    Process {
        id: btProc
        command: ["sh", "-c", "bluetoothctl devices Connected | head -1 | cut -d' ' -f3-"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.btDevice = text.trim()
        }
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: btProc.running = true
    }
}
