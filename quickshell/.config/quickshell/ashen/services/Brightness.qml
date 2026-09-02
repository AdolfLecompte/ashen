// Ashen — Brightness service.  by Adolf — github.com/AdolfLecompte
pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// One screen, one number, and -- unlike Audio -- no graph to read it off: every
// reading and every write is a `brightnessctl` process. So the asking lives
// here once, and everyone who changes the level goes through setLevel.
Singleton {
    id: root
    property int level: 100

    // Three faces, the way Audio.icon has three: a backlight glyph that never
    // changes says the key was pressed but not what it did. The low face is a
    // hollow sun, so a dim screen reads as empty and not as another full one.
    function icon(pct) {
        return pct < 34 ? ""   // brightness_empty
             : pct < 67 ? ""   // brightness_6
                        : ""   // brightness_7
    }

    // Never 0: a backlight at zero is a black screen with no way back to the
    // slider that turned it off.
    function clamp(pct) { return Math.max(1, Math.min(100, Math.round(pct))) }

    // The write. `level` moves first so the slider and the pill answer at once
    // instead of waiting up to 1.5 s for the poll to agree -- Audio is instant
    // because PipeWire is a property; here the echo has to be made by hand.
    function setLevel(pct) {
        const v = root.clamp(pct)
        root.level = v
        Quickshell.execDetached(["sh", "-c", "brightnessctl set \"$1\"%", "sh", String(v)])
        settle.restart()
    }

    // Read it back once the write has landed, in case the hardware rounded it
    // to a step it actually has.
    Timer { id: settle; interval: 250; onTriggered: root.refresh() }

    // A key held down asks faster than a process can answer. Asking while one
    // is in flight used to be dropped, so the number lagged two steps behind;
    // the last ask is remembered and replayed when the reply lands.
    property bool pending: false
    function refresh() {
        if (brightnessProc.running) root.pending = true
        else brightnessProc.running = true
    }

    Timer {
        interval: 1500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Process {
        id: brightnessProc
        command: ["sh", "-c", "brightnessctl -m"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let parts = text.trim().split(",")
                if (parts.length > 3) {
                    let pct = parseInt(parts[3].replace("%", ""))
                    if (!isNaN(pct)) root.level = pct
                }
                if (root.pending) { root.pending = false; brightnessProc.running = true }
            }
        }
    }
}
