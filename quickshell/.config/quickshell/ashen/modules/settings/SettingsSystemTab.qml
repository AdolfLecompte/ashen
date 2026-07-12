import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "root:/services" as Services

Item {
    anchors.fill: parent

    Flickable {
        anchors.fill: parent
        anchors.margins: 28
        contentHeight: col.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded; width: 4 }

        ColumnLayout {
            id: col
            width: parent.width
            spacing: 14

            property string timeRemaining: "--"
            property var availableProfiles: []
            property string activeProfile: ""

            property real ramUsedMB: 0
            property real ramTotalMB: 0
            property real cpuPercent: 0
            property string cpuModel: "..."
            property real cpuTemp: 0
            property string gpuInfo: "..."
            property real prevCpuTotal: 0
            property real prevCpuIdle: 0

            property real gpuUsage: 0
            property real gpuTemp: 0
            property bool hasGpuStats: false

            property real diskUsedGB: 0
            property real diskTotalGB: 0
            property int diskPercent: 0

            property real netRxKBs: 0
            property real netTxKBs: 0
            property real prevRxBytes: -1
            property real prevTxBytes: -1

            property var cpuHistory: []
            property var ramHistory: []

            function pushHistory(arr, val) {
                let a = arr.slice()
                a.push(val)
                if (a.length > 40) a.shift()
                return a
            }

            function setProfile(name) {
                if (!availableProfiles.includes(name)) return
                Quickshell.execDetached(["sh", "-c", "powerprofilesctl set " + name])
                activeProfile = name
            }

            Component.onCompleted: {
                battProc.running = true
                profProc.running = true
                cpuModelProc.running = true
                gpuProc.running = true
                ramProc.running = true
                cpuProc.running = true
                diskProc.running = true
                netProc.running = true
                sensorsProc.running = true
                gpuStatProc.running = true
            }

            Timer {
                interval: 1500
                running: true
                repeat: true
                onTriggered: { ramProc.running = true; cpuProc.running = true; netProc.running = true; sensorsProc.running = true; gpuStatProc.running = true }
            }
            Timer {
                interval: 10000
                running: true
                repeat: true
                onTriggered: { diskProc.running = true }
            }

            Process {
                id: battProc
                command: ["sh", "-c", "upower -i $(upower -e | grep BAT) 2>/dev/null | grep -E 'time to (empty|full)'"]
                running: false
                stdout: StdioCollector {
                    onStreamFinished: {
                        let line = text.trim()
                        col.timeRemaining = line.length > 0 ? line.split(":").slice(1).join(":").trim() : "--"
                    }
                }
            }
            Process {
                id: profProc
                command: ["sh", "-c", "powerprofilesctl list"]
                running: false
                stdout: StdioCollector {
                    onStreamFinished: {
                        let lines = text.split("\n")
                        let profiles = []
                        let active = ""
                        for (let line of lines) {
                            let m = line.match(/^\s*(\*?)\s*([\w-]+):$/)
                            if (m) { profiles.push(m[2]); if (m[1] === "*") active = m[2] }
                        }
                        col.availableProfiles = profiles
                        col.activeProfile = active
                    }
                }
            }
            Process {
                id: cpuModelProc
                command: ["sh", "-c", "grep -m1 'model name' /proc/cpuinfo | cut -d: -f2"]
                running: false
                stdout: StdioCollector { onStreamFinished: col.cpuModel = text.trim() }
            }
            Process {
                id: sensorsProc
                command: ["sh", "-c", "sensors 2>/dev/null | grep -iE 'Package id 0|Tctl|Tdie' | head -1 | grep -oE '[0-9]+\\.[0-9]+' | head -1"]
                running: false
                stdout: StdioCollector {
                    onStreamFinished: {
                        let t = parseFloat(text.trim())
                        col.cpuTemp = isNaN(t) ? 0 : t
                    }
                }
            }
            Process {
                id: gpuProc
                command: ["sh", "-c", "lspci | grep -E 'VGA|3D controller'"]
                running: false
                stdout: StdioCollector {
                    onStreamFinished: {
                        let lines = text.trim().split("\n").filter(l => l.length > 0)
                        col.gpuInfo = lines.length > 0 ? lines.map(l => l.split(": ").pop()).join(" / ") : "Unknown"
                    }
                }
            }
            Process {
                id: gpuStatProc
                command: ["sh", "-c", "nvidia-smi --query-gpu=utilization.gpu,temperature.gpu --format=csv,noheader,nounits 2>/dev/null"]
                running: false
                stdout: StdioCollector {
                    onStreamFinished: {
                        let t = text.trim()
                        if (t.length > 0) {
                            let parts = t.split(",").map(s => parseFloat(s.trim()))
                            col.gpuUsage = parts[0] || 0
                            col.gpuTemp = parts[1] || 0
                            col.hasGpuStats = true
                        } else {
                            col.hasGpuStats = false
                        }
                    }
                }
            }
            Process {
                id: diskProc
                command: ["sh", "-c", "df -BG --output=used,size,pcent / | tail -1"]
                running: false
                stdout: StdioCollector {
                    onStreamFinished: {
                        let parts = text.trim().split(/\s+/)
                        if (parts.length === 3) {
                            col.diskUsedGB = parseFloat(parts[0].replace("G", "")) || 0
                            col.diskTotalGB = parseFloat(parts[1].replace("G", "")) || 0
                            col.diskPercent = parseInt(parts[2].replace("%", "")) || 0
                        }
                    }
                }
            }
            Process {
                id: ramProc
                command: ["sh", "-c", "free -m | awk '/^Mem:/{print $3\",\"$2}'"]
                running: false
                stdout: StdioCollector {
                    onStreamFinished: {
                        let parts = text.trim().split(",")
                        if (parts.length === 2) {
                            col.ramUsedMB = parseFloat(parts[0]) || 0
                            col.ramTotalMB = parseFloat(parts[1]) || 0
                            let pct = col.ramTotalMB > 0 ? (col.ramUsedMB / col.ramTotalMB) * 100 : 0
                            col.ramHistory = col.pushHistory(col.ramHistory, pct)
                        }
                    }
                }
            }
            Process {
                id: cpuProc
                command: ["sh", "-c", "grep '^cpu ' /proc/stat"]
                running: false
                stdout: StdioCollector {
                    onStreamFinished: {
                        let parts = text.trim().split(/\s+/).slice(1).map(Number)
                        let idle = parts[3] + (parts[4] || 0)
                        let total = parts.reduce((a, b) => a + b, 0)
                        if (col.prevCpuTotal > 0) {
                            let totalDiff = total - col.prevCpuTotal
                            let idleDiff = idle - col.prevCpuIdle
                            if (totalDiff > 0) {
                                col.cpuPercent = Math.max(0, Math.min(100, 100 * (1 - idleDiff / totalDiff)))
                                col.cpuHistory = col.pushHistory(col.cpuHistory, col.cpuPercent)
                            }
                        }
                        col.prevCpuTotal = total
                        col.prevCpuIdle = idle
                    }
                }
            }
            Process {
                id: netProc
                command: ["sh", "-c", "cat /proc/net/dev | tail -n +3 | awk '{sub(\":\",\"\",$1); if ($1!=\"lo\") {rx+=$2; tx+=$10}} END {print rx\",\"tx}'"]
                running: false
                stdout: StdioCollector {
                    onStreamFinished: {
                        let parts = text.trim().split(",")
                        if (parts.length === 2) {
                            let rx = parseFloat(parts[0]) || 0
                            let tx = parseFloat(parts[1]) || 0
                            if (col.prevRxBytes >= 0) {
                                col.netRxKBs = Math.max(0, (rx - col.prevRxBytes) / 1024 / 1.5)
                                col.netTxKBs = Math.max(0, (tx - col.prevTxBytes) / 1024 / 1.5)
                            }
                            col.prevRxBytes = rx
                            col.prevTxBytes = tx
                        }
                    }
                }
            }

            Text {
                text: "System"
                color: Services.Colors.snow
                font.pixelSize: 20
                font.bold: true
                font.family: "JetBrainsMono NF"
            }

            RowLayout {
                spacing: 14
                Text {
                    text: Services.Battery.level + "%"
                    color: Services.Colors.snow
                    font.pixelSize: 24
                    font.bold: true
                    font.family: "JetBrainsMono NF"
                }
                ColumnLayout {
                    spacing: 2
                    Text {
                        text: Services.Battery.charging ? "Charging" : "On battery"
                        color: Services.Colors.mist
                        font.pixelSize: 11
                        font.family: "JetBrainsMono NF"
                    }
                    Text {
                        text: col.timeRemaining !== "--" ? col.timeRemaining : (Services.Battery.charging ? "Fully charged" : "Calculating...")
                        color: Services.Colors.ash
                        font.pixelSize: 10
                        font.family: "JetBrainsMono NF"
                    }
                }
            }

            Text {
                text: "Power Profile"
                color: Services.Colors.mist
                font.pixelSize: 11
                font.family: "JetBrainsMono NF"
            }

            RowLayout {
                spacing: 10
                Repeater {
                    model: [
                        { id: "power-saver", icon: "\uec1a", label: "Saver" },
                        { id: "balanced", icon: "\ueaf6", label: "Balanced" },
                        { id: "performance", icon: "\ueb9b", label: "Performance" },
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        property bool available: col.availableProfiles.includes(modelData.id)
                        width: 100; height: 64
                        radius: 12
                        color: col.activeProfile === modelData.id ? Services.Colors.ghost : Services.Colors.ghostAlpha(0.12)
                        opacity: available ? 1.0 : 0.35
                        Behavior on color { ColorAnimation { duration: 150 } }
                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 4
                            Text {
                                text: modelData.icon
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 20
                                color: col.activeProfile === modelData.id ? Services.Colors.abyss : Services.Colors.mist
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Text {
                                text: modelData.label
                                font.pixelSize: 10
                                font.family: "JetBrainsMono NF"
                                color: col.activeProfile === modelData.id ? Services.Colors.abyss : Services.Colors.mist
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: parent.available ? Qt.PointingHandCursor : Qt.ForbiddenCursor
                            enabled: parent.available
                            onClicked: col.setProfile(modelData.id)
                        }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Services.Colors.ghostAlpha(0.15); Layout.topMargin: 4 }

            Text {
                text: "Hardware"
                color: Services.Colors.mist
                font.pixelSize: 11
                font.family: "JetBrainsMono NF"
            }

            // CPU
            RowLayout {
                Layout.fillWidth: true
                spacing: 16
                Item {
                    id: ringCpu
                    property real percent: col.cpuPercent
                    width: 60; height: 60
                    Canvas {
                        id: canvasCpu
                        anchors.fill: parent
                        onPaint: {
                            let ctx = getContext("2d")
                            ctx.reset()
                            let cx = width / 2, cy = height / 2
                            let r = (Math.min(width, height) - 5) / 2
                            ctx.lineWidth = 5
                            ctx.lineCap = "round"
                            ctx.strokeStyle = Services.Colors.ghostAlpha(0.15)
                            ctx.beginPath(); ctx.arc(cx, cy, r, 0, Math.PI * 2); ctx.stroke()
                            let frac = Math.max(0, Math.min(1, ringCpu.percent / 100))
                            if (frac > 0) {
                                ctx.strokeStyle = Services.Colors.ghost
                                ctx.beginPath(); ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + frac * Math.PI * 2); ctx.stroke()
                            }
                        }
                        Component.onCompleted: requestPaint()
                        Connections { target: ringCpu; function onPercentChanged() { canvasCpu.requestPaint() } }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: Math.round(ringCpu.percent) + "%"
                        color: Services.Colors.snow
                        font.pixelSize: 13
                        font.bold: true
                        font.family: "JetBrainsMono NF"
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    Text { text: "CPU"; color: Services.Colors.snow; font.pixelSize: 12; font.bold: true; font.family: "JetBrainsMono NF" }
                    Text { text: col.cpuModel; color: Services.Colors.mist; font.pixelSize: 10; font.family: "JetBrainsMono NF"; elide: Text.ElideRight; Layout.fillWidth: true }
                    Text { visible: col.cpuTemp > 0; text: col.cpuTemp.toFixed(0) + "°C"; color: Services.Colors.ash; font.pixelSize: 10; font.family: "JetBrainsMono NF" }
                    Canvas {
                        id: cpuHistCanvas
                        Layout.fillWidth: true
                        height: 24
                        property var hist: col.cpuHistory
                        onHistChanged: requestPaint()
                        onPaint: {
                            let ctx = getContext("2d")
                            ctx.reset()
                            ctx.clearRect(0, 0, width, height)
                            let h = hist
                            if (h.length < 2) return
                            ctx.strokeStyle = Services.Colors.ghost
                            ctx.lineWidth = 1.5
                            ctx.beginPath()
                            for (let i = 0; i < h.length; i++) {
                                let x = (i / (h.length - 1)) * width
                                let y = height - (h[i] / 100) * height
                                if (i === 0) ctx.moveTo(x, y)
                                else ctx.lineTo(x, y)
                            }
                            ctx.stroke()
                        }
                    }
                }
            }

            // Memory
            RowLayout {
                Layout.fillWidth: true
                spacing: 16
                Item {
                    id: ringRam
                    property real percent: col.ramTotalMB > 0 ? (col.ramUsedMB / col.ramTotalMB) * 100 : 0
                    width: 60; height: 60
                    Canvas {
                        id: canvasRam
                        anchors.fill: parent
                        onPaint: {
                            let ctx = getContext("2d")
                            ctx.reset()
                            let cx = width / 2, cy = height / 2
                            let r = (Math.min(width, height) - 5) / 2
                            ctx.lineWidth = 5
                            ctx.lineCap = "round"
                            ctx.strokeStyle = Services.Colors.ghostAlpha(0.15)
                            ctx.beginPath(); ctx.arc(cx, cy, r, 0, Math.PI * 2); ctx.stroke()
                            let frac = Math.max(0, Math.min(1, ringRam.percent / 100))
                            if (frac > 0) {
                                ctx.strokeStyle = Services.Colors.mist
                                ctx.beginPath(); ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + frac * Math.PI * 2); ctx.stroke()
                            }
                        }
                        Component.onCompleted: requestPaint()
                        Connections { target: ringRam; function onPercentChanged() { canvasRam.requestPaint() } }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: Math.round(ringRam.percent) + "%"
                        color: Services.Colors.snow
                        font.pixelSize: 13
                        font.bold: true
                        font.family: "JetBrainsMono NF"
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    Text { text: "Memory"; color: Services.Colors.snow; font.pixelSize: 12; font.bold: true; font.family: "JetBrainsMono NF" }
                    Text { text: col.ramUsedMB.toFixed(0) + " / " + col.ramTotalMB.toFixed(0) + " MB"; color: Services.Colors.mist; font.pixelSize: 10; font.family: "JetBrainsMono NF" }
                    Canvas {
                        id: ramHistCanvas
                        Layout.fillWidth: true
                        height: 24
                        property var hist: col.ramHistory
                        onHistChanged: requestPaint()
                        onPaint: {
                            let ctx = getContext("2d")
                            ctx.reset()
                            ctx.clearRect(0, 0, width, height)
                            let h = hist
                            if (h.length < 2) return
                            ctx.strokeStyle = Services.Colors.mist
                            ctx.lineWidth = 1.5
                            ctx.beginPath()
                            for (let i = 0; i < h.length; i++) {
                                let x = (i / (h.length - 1)) * width
                                let y = height - (h[i] / 100) * height
                                if (i === 0) ctx.moveTo(x, y)
                                else ctx.lineTo(x, y)
                            }
                            ctx.stroke()
                        }
                    }
                }
            }

            // Storage
            RowLayout {
                Layout.fillWidth: true
                spacing: 16
                Item {
                    id: ringDisk
                    property real percent: col.diskPercent
                    width: 60; height: 60
                    Canvas {
                        id: canvasDisk
                        anchors.fill: parent
                        onPaint: {
                            let ctx = getContext("2d")
                            ctx.reset()
                            let cx = width / 2, cy = height / 2
                            let r = (Math.min(width, height) - 5) / 2
                            ctx.lineWidth = 5
                            ctx.lineCap = "round"
                            ctx.strokeStyle = Services.Colors.ghostAlpha(0.15)
                            ctx.beginPath(); ctx.arc(cx, cy, r, 0, Math.PI * 2); ctx.stroke()
                            let frac = Math.max(0, Math.min(1, ringDisk.percent / 100))
                            if (frac > 0) {
                                ctx.strokeStyle = col.diskPercent >= 90 ? Services.Colors.error_ : Services.Colors.ghost
                                ctx.beginPath(); ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + frac * Math.PI * 2); ctx.stroke()
                            }
                        }
                        Component.onCompleted: requestPaint()
                        Connections { target: ringDisk; function onPercentChanged() { canvasDisk.requestPaint() } }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: Math.round(ringDisk.percent) + "%"
                        color: Services.Colors.snow
                        font.pixelSize: 13
                        font.bold: true
                        font.family: "JetBrainsMono NF"
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    Text { text: "Storage"; color: Services.Colors.snow; font.pixelSize: 12; font.bold: true; font.family: "JetBrainsMono NF" }
                    Text { text: col.diskUsedGB.toFixed(0) + " / " + col.diskTotalGB.toFixed(0) + " GB  ·  /"; color: Services.Colors.mist; font.pixelSize: 10; font.family: "JetBrainsMono NF" }
                }
            }

            // Graphics
            RowLayout {
                Layout.fillWidth: true
                spacing: 16
                Item {
                    id: ringGpu
                    visible: col.hasGpuStats
                    property real percent: col.gpuUsage
                    width: 60; height: 60
                    Canvas {
                        id: canvasGpu
                        anchors.fill: parent
                        onPaint: {
                            let ctx = getContext("2d")
                            ctx.reset()
                            let cx = width / 2, cy = height / 2
                            let r = (Math.min(width, height) - 5) / 2
                            ctx.lineWidth = 5
                            ctx.lineCap = "round"
                            ctx.strokeStyle = Services.Colors.ghostAlpha(0.15)
                            ctx.beginPath(); ctx.arc(cx, cy, r, 0, Math.PI * 2); ctx.stroke()
                            let frac = Math.max(0, Math.min(1, ringGpu.percent / 100))
                            if (frac > 0) {
                                ctx.strokeStyle = Services.Colors.ghost
                                ctx.beginPath(); ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + frac * Math.PI * 2); ctx.stroke()
                            }
                        }
                        Component.onCompleted: requestPaint()
                        Connections { target: ringGpu; function onPercentChanged() { canvasGpu.requestPaint() } }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: Math.round(ringGpu.percent) + "%"
                        color: Services.Colors.snow
                        font.pixelSize: 13
                        font.bold: true
                        font.family: "JetBrainsMono NF"
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    Text { text: "Graphics"; color: Services.Colors.snow; font.pixelSize: 12; font.bold: true; font.family: "JetBrainsMono NF" }
                    Text { text: col.gpuInfo; color: Services.Colors.mist; font.pixelSize: 10; font.family: "JetBrainsMono NF"; elide: Text.ElideRight; Layout.fillWidth: true }
                    Text { visible: col.hasGpuStats && col.gpuTemp > 0; text: col.gpuTemp.toFixed(0) + "°C"; color: Services.Colors.ash; font.pixelSize: 10; font.family: "JetBrainsMono NF" }
                }
            }

            // Network
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Text { text: "Network"; color: Services.Colors.snow; font.pixelSize: 12; font.bold: true; font.family: "JetBrainsMono NF"; Layout.fillWidth: true }
                Text { text: "↓ " + col.netRxKBs.toFixed(0) + " KB/s"; color: Services.Colors.mist; font.pixelSize: 11; font.family: "JetBrainsMono NF" }
                Text { text: "↑ " + col.netTxKBs.toFixed(0) + " KB/s"; color: Services.Colors.mist; font.pixelSize: 11; font.family: "JetBrainsMono NF" }
            }

            Item { Layout.preferredHeight: 8 }
        }
    }
}
