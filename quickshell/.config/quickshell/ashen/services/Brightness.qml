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

    // The backlight is named per machine -- intel_backlight, amdgpu_bl0,
    // acpi_video0 -- so it is found once and then read in-process. The poll used
    // to be a shell and a brightnessctl every 1.5 s. The writes still go through
    // brightnessctl: it is what holds the permission to write the file.
    SysFile { id: curFile }
    SysFile { id: maxFile }
    Process {
        id: finder
        running: true
        command: ["sh", "-c", "for d in /sys/class/backlight/*; do [ -e \"$d/brightness\" ] && { printf %s \"$d\"; break; }; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const d = text.trim()
                if (d === "") return
                curFile.path = d + "/brightness"
                maxFile.path = d + "/max_brightness"
                root.refresh()
            }
        }
    }

    // Synchronous now, so a key held down can no longer ask faster than the
    // answer comes back -- the old in-flight bookkeeping has nothing left to do.
    function refresh() {
        if (curFile.path === "") return
        const cur = parseInt(curFile.read())
        const max = parseInt(maxFile.read())
        if (isNaN(cur) || !(max > 0)) return
        root.level = Math.round(cur / max * 100)
    }

    Timer {
        interval: 1500
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
}
