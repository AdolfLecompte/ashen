pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import "root:/services" as Services

Singleton {
    id: root
    property int level: 0
    property bool charging: false

    // Low-battery warning. Fires once when crossing the threshold on battery;
    // re-arms when charging or once the level climbs back up, so it never spams.
    // Routed through addSystemToast so it wears the system look (icon box + two
    // lines) and its own battery_alert glyph, not a third-party app style.
    property bool lowWarned: false
    readonly property int lowThreshold: 15
    onLevelChanged: root.maybeWarnLow()
    onChargingChanged: { if (root.charging) root.lowWarned = false; root.maybeWarnLow() }
    function maybeWarnLow() {
        if (root.charging || root.level <= 0) return
        if (root.level > root.lowThreshold) { root.lowWarned = false; return }
        if (root.lowWarned) return
        root.lowWarned = true
        Services.Notifications.addSystemToast(
            "Battery low - " + root.level + "% left", "", false, "battery")
    }

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
        command: ["sh", "-c", "cat /sys/class/power_supply/BAT0/status"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const status = text.trim()
                root.charging = status === "Charging" || status === "Full" || status === "Not charging"
            }
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
