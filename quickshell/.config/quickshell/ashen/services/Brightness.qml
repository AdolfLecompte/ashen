pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    property int level: 100

    // Three faces, the way Audio.icon has three: a backlight glyph that never
    // changes says the key was pressed but not what it did. The low face is a
    // hollow sun, so a dim screen reads as empty and not as another full one.
    function icon(pct) {
        return pct < 34 ? "\uf7e8"   // brightness_empty
             : pct < 67 ? "\ue3ab"   // brightness_6
                        : "\ue3ac"   // brightness_7
    }

    Timer {
        interval: 1500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: brightnessProc.running = true
    }

    Process {
        id: brightnessProc
        command: ["sh", "-c", "brightnessctl -m"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let parts = text.trim().split(",")
                if (parts.length > 3) {
                    let pctStr = parts[3].replace("%", "")
                    let pct = parseInt(pctStr)
                    if (!isNaN(pct)) root.level = pct
                }
            }
        }
    }
}
