pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import QtQuick

// Who is using the microphone, the camera or the screen right now.
Singleton {
    id: root

    PwObjectTracker { objects: Pipewire.nodes.values }

    // A recording stream (isStream, not a sink) taking from a real source. One
    // that listens to an output -- cava on the monitor -- is not a microphone.
    readonly property var micStreams: Pipewire.nodes.values.filter(n => {
        if (!n.isStream || n.isSink || !n.audio) return false
        const p = n.properties || {}
        if (p["stream.capture.sink"] === "true") return false
        if (String(p["target.object"] || "").endsWith(".monitor")) return false
        const bin = p["application.process.binary"] || ""
        return bin !== "cava" && bin !== "quickshell"
    })
    readonly property bool mic: root.micStreams.length > 0
    readonly property string micApp: root.mic
        ? (root.micStreams[0].properties["application.name"] || "") : ""

    // Browsers open the camera through v4l2, not PipeWire. A streaming USB
    // camera leaves autosuspend, so its power state is read (no process) and
    // only an "active" one is confirmed by asking who holds /dev/video*.
    property bool camera: false
    property var camPower: []
    Process {
        running: true
        command: ["sh", "-c", 'for v in /sys/class/video4linux/video*; do [ -e "$v" ] && readlink -f "$v/device/.."; done | sort -u']
        stdout: StdioCollector {
            onStreamFinished: root.camPower = text.trim().split("\n").filter(l => l !== "")
        }
    }
    Instantiator {
        id: camFiles
        model: root.camPower
        delegate: SysFile { required property string modelData; path: modelData + "/power/runtime_status" }
    }
    Process {
        id: camProbe
        command: ["sh", "-c", "fuser -s /dev/video* 2>/dev/null"]
        onExited: code => root.camera = code === 0
    }
    Timer {
        interval: 3000
        running: root.camPower.length > 0
        repeat: true
        onTriggered: {
            let awake = false
            for (let i = 0; i < camFiles.count; i++)
                if (camFiles.objectAt(i).read() !== "suspended") awake = true
            if (awake) camProbe.running = true
            else root.camera = false
        }
    }

    // Hyprland says when a screencast starts and stops ("screencast>>1,0").
    property bool screen: false
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "screencast") root.screen = String(event.data).split(",")[0] === "1"
        }
    }

    readonly property bool any: root.mic || root.camera || root.screen
}
