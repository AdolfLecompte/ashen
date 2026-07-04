import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.SystemTray
import QtQuick
import QtQuick.Layouts

Scope {
    id: root
    property string currentTime: ""
    property string currentDate: ""
    property string timeIcon: "󰖔"
    property string wifiSsid: ""
    property string btDevice: ""
    property int volume: 0
    property int battery: 0
    property bool charging: false

    function isSystemTrayItem(id) {
        let excluded = ["blueman", "nm-applet", "networkmanager", "bluetooth", "pulseaudio", "pipewire"]
        let lower = id.toLowerCase()
        return excluded.some(e => lower.includes(e))
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            let now = new Date()
            let h = now.getHours()
            root.currentTime = Qt.formatDateTime(now, "hh:mm:ss AP")
            root.currentDate = Qt.formatDateTime(now, "ddd, MMM d")
            if (h >= 0 && h < 5)        root.timeIcon = "󰖔"
            else if (h >= 5 && h < 8)   root.timeIcon = "󰖜"
            else if (h >= 8 && h < 17)  root.timeIcon = "󰖙"
            else if (h >= 17 && h < 20) root.timeIcon = "󰖛"
            else                         root.timeIcon = "󰖑"
        }
    }

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
            onStreamFinished: {
                root.btDevice = text.trim()
            }
        }
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: btProc.running = true
    }

    Process {
        id: volProc
        command: ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{printf \"%d\", $2*100}'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root.volume = parseInt(text.trim()) || 0
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: volProc.running = true
    }

    Process {
        id: batProc
        command: ["sh", "-c", "cat /sys/class/power_supply/BAT0/capacity"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root.battery = parseInt(text.trim()) || 0
            }
        }
    }

    Process {
        id: chargeProc
        command: ["sh", "-c", "cat /sys/class/power_supply/AC0/online"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root.charging = text.trim() === "1"
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

    Variants {
        model: Quickshell.screens

        PanelWindow {
            property var modelData
            screen: modelData
            anchors { top: true; left: true; right: true }
            implicitHeight: 56
            color: "transparent"

            Item {
                anchors.fill: parent

                // ── Izquierda ──────────────────────────
                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    // Launcher
                    Rectangle {
                        width: 40; height: 44
                        radius: 10
                        color: "#1d1d24"
                        border.color: "#24242d"
                        border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: "󰍉"
                            color: "#6272a4"
                            font.pixelSize: 20
                            font.family: "JetBrainsMono NF"
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                        }
                    }

                    // Workspaces
                    Rectangle {
                        height: 44
                        radius: 10
                        color: "#1d1d24"
                        border.color: "#24242d"
                        border.width: 1
                        width: wsRow.width + 12

                        Rectangle {
                            id: slideIndicator
                            width: 30; height: 30
                            radius: 8
                            color: "#6272a4"
                            y: 7
                            x: {
                                let focused = Hyprland.focusedWorkspace
                                if (!focused) return 6
                                let base = Math.floor((focused.id - 1) / 5) * 5
                                let idx = focused.id - base - 1
                                return 6 + idx * 34
                            }
                            Behavior on x {
                                SmoothedAnimation { duration: 250 }
                            }
                        }

                        Row {
                            id: wsRow
                            anchors.centerIn: parent
                            spacing: 4

                            Repeater {
                                model: 5
                                delegate: Item {
                                    required property int index
                                    property int wsId: {
                                        let focused = Hyprland.focusedWorkspace
                                        if (!focused) return index + 1
                                        let base = Math.floor((focused.id - 1) / 5) * 5
                                        return base + index + 1
                                    }
                                    property bool isActive: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === wsId
                                    property bool hasWindows: Hyprland.workspaces.values.find(w => w.id === wsId) !== undefined
                                    width: 30; height: 30

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 8
                                        color: "#6272a4"
                                        opacity: parent.hasWindows && !parent.isActive ? 0.15 : 0
                                        Behavior on opacity {
                                            NumberAnimation { duration: 200 }
                                        }
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: wsId
                                        color: parent.isActive ? "#0f0f12" : "#7878a0"
                                        font.pixelSize: 13
                                        font.family: "JetBrainsMono NF"
                                        font.bold: parent.isActive
                                        z: 1
                                        Behavior on color {
                                            ColorAnimation { duration: 200 }
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Hyprland.dispatch("workspace " + wsId)
                                    }
                                }
                            }
                        }
                    }
                }

                // ── Centro ─────────────────────────────
                Rectangle {
                    anchors.centerIn: parent
                    height: 44
                    width: clockRow.implicitWidth + 40
                    radius: 10
                    color: "#1d1d24"
                    border.color: "#24242d"
                    border.width: 1

                    RowLayout {
                        id: clockRow
                        anchors.centerIn: parent
                        spacing: 16

                        Column {
                            spacing: 1
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: root.currentTime
                                color: "#d4d4e0"
                                font.pixelSize: 15
                                font.family: "JetBrainsMono NF"
                                font.bold: true
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: root.currentDate
                                color: "#7878a0"
                                font.pixelSize: 10
                                font.family: "JetBrainsMono NF"
                            }
                        }

                        Text {
                            text: root.timeIcon
                            font.pixelSize: 26
                            font.family: "JetBrainsMono NF"
                            color: {
                                let h = new Date().getHours()
                                if (h >= 0 && h < 5)        return "#aab4d4"
                                else if (h >= 5 && h < 8)   return "#c4a882"
                                else if (h >= 8 && h < 17)  return "#c4c882"
                                else if (h >= 17 && h < 20) return "#c4a882"
                                else                         return "#8899cc"
                            }
                        }
                    }
                }

                // ── Derecha ────────────────────────────
                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    // Tray
                    Rectangle {
                        height: 44
                        radius: 10
                        color: "#1d1d24"
                        border.color: "#24242d"
                        border.width: 1
                        width: trayRow.width + 16
                        visible: trayRow.visibleChildren.length > 0

                        Row {
                            id: trayRow
                            anchors.centerIn: parent
                            spacing: 6

                            Repeater {
                                model: SystemTray.items
                                delegate: Item {
                                    required property SystemTrayItem modelData
                                    width: visible ? 22 : 0
                                    height: 22
                                    visible: !root.isSystemTrayItem(modelData.id)

                                    Image {
                                        anchors.centerIn: parent
                                        source: modelData.icon
                                        width: 18; height: 18
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                                        onClicked: (mouse) => {
                                            if (mouse.button === Qt.LeftButton)
                                                modelData.activate()
                                            else
                                                modelData.provideContext(Qt.point(x, y))
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Sistema — píldora contenedora
                    Rectangle {
                        height: 44
                        radius: 10
                        color: "#1d1d24"
                        border.color: "#24242d"
                        border.width: 1
                        width: sysRow.width + 16

                        Row {
                            id: sysRow
                            anchors.centerIn: parent
                            spacing: 6

                            // Notificaciones
                            Rectangle {
                                height: 34
                                width: 34
                                radius: 8
                                color: Qt.rgba(0x62/255, 0x72/255, 0xa4/255, 0.15)

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰂚"
                                    color: "#d4d4e0"
                                    font.pixelSize: 16
                                    font.family: "JetBrainsMono NF"
                                }
                            }

                            // Wifi — siempre visible
                            Rectangle {
                                height: 34
                                radius: 8
                                width: wifiInner.width + 16
                                color: root.wifiSsid !== "" ? "#6272a4" : Qt.rgba(0x62/255, 0x72/255, 0xa4/255, 0.15)
                                Behavior on color { ColorAnimation { duration: 300 } }

                                Row {
                                    id: wifiInner
                                    anchors.centerIn: parent
                                    spacing: 5

                                    Text {
                                        text: root.wifiSsid !== "" ? "󰤨" : "󰤭"
                                        color: root.wifiSsid !== "" ? "#0f0f12" : "#7878a0"
                                        font.pixelSize: 16
                                        font.family: "JetBrainsMono NF"
                                        anchors.verticalCenter: parent.verticalCenter
                                        Behavior on color { ColorAnimation { duration: 200 } }
                                    }
                                    Text {
                                        text: root.wifiSsid !== "" ? root.wifiSsid : "Off"
                                        color: root.wifiSsid !== "" ? "#0f0f12" : "#7878a0"
                                        font.pixelSize: 12
                                        font.family: "JetBrainsMono NF"
                                        anchors.verticalCenter: parent.verticalCenter
                                        Behavior on color { ColorAnimation { duration: 200 } }
                                    }
                                }
                            }

                            // Bluetooth — siempre visible
                            Rectangle {
                                height: 34
                                radius: 8
                                width: btInner.width + 16
                                color: root.btDevice !== "" ? "#6272a4" : Qt.rgba(0x62/255, 0x72/255, 0xa4/255, 0.15)
                                Behavior on color { ColorAnimation { duration: 300 } }

                                Row {
                                    id: btInner
                                    anchors.centerIn: parent
                                    spacing: 5

                                    Text {
                                        text: root.btDevice !== "" ? "󰂯" : "󰂲"
                                        color: root.btDevice !== "" ? "#0f0f12" : "#7878a0"
                                        font.pixelSize: 16
                                        font.family: "JetBrainsMono NF"
                                        anchors.verticalCenter: parent.verticalCenter
                                        Behavior on color { ColorAnimation { duration: 200 } }
                                    }
                                    Text {
                                        text: root.btDevice !== "" ? root.btDevice : "Off"
                                        color: root.btDevice !== "" ? "#0f0f12" : "#7878a0"
                                        font.pixelSize: 12
                                        font.family: "JetBrainsMono NF"
                                        anchors.verticalCenter: parent.verticalCenter
                                        Behavior on color { ColorAnimation { duration: 200 } }
                                    }
                                }
                            }

                            // Volumen
Rectangle {
    height: 34
    radius: 8
    width: volInner.width + 16
    color: root.volume > 0 ? "#6272a4" : Qt.rgba(0x62/255, 0x72/255, 0xa4/255, 0.15)
    Behavior on color { ColorAnimation { duration: 300 } }

    Row {
        id: volInner
        anchors.centerIn: parent
        spacing: 8

        Text {
            text: {
                if (root.volume === 0)     return "󰝟"
                else if (root.volume < 33) return "󰕿"
                else if (root.volume < 66) return "󰖀"
                else                        return "󰕾"
            }
            color: root.volume > 0 ? "#0f0f12" : "#7878a0"
            font.pixelSize: 16
            font.family: "JetBrainsMono NF"
            anchors.verticalCenter: parent.verticalCenter
            Behavior on color { ColorAnimation { duration: 200 } }
        }
        Text {
            text: root.volume + "%"
            color: root.volume > 0 ? "#0f0f12" : "#7878a0"
            font.pixelSize: 12
            font.family: "JetBrainsMono NF"
            anchors.verticalCenter: parent.verticalCenter
            Behavior on color { ColorAnimation { duration: 200 } }
        }
    }
}

                            // Bateria — se ilumina al cargar
                            Rectangle {
                                height: 34
                                radius: 8
                                width: batInner.width + 16
                                color: root.charging ? "#6272a4" : Qt.rgba(0x62/255, 0x72/255, 0xa4/255, 0.15)
                                Behavior on color { ColorAnimation { duration: 300 } }

                                Row {
                                    id: batInner
                                    anchors.centerIn: parent
                                    spacing: 5

                                    Text {
                                        text: {
                                            if (root.charging)            return "󰚥"
                                            else if (root.battery >= 90) return "󰁹"
                                            else if (root.battery >= 70) return "󰂁"
                                            else if (root.battery >= 50) return "󰁿"
                                            else if (root.battery >= 30) return "󰁽"
                                            else if (root.battery >= 15) return "󰁻"
                                            else                          return "󰂃"
                                        }
                                        color: {
                                            if (root.charging)            return "#0f0f12"
                                            else if (root.battery >= 50) return "#d4d4e0"
                                            else if (root.battery >= 20) return "#c4a882"
                                            else                          return "#c47a7a"
                                        }
                                        font.pixelSize: 16
                                        font.family: "JetBrainsMono NF"
                                        anchors.verticalCenter: parent.verticalCenter
                                        Behavior on color { ColorAnimation { duration: 300 } }
                                    }
                                    Text {
                                        text: root.battery + "%"
                                        color: {
                                            if (root.charging)            return "#0f0f12"
                                            else if (root.battery >= 50) return "#d4d4e0"
                                            else if (root.battery >= 20) return "#c4a882"
                                            else                          return "#c47a7a"
                                        }
                                        font.pixelSize: 12
                                        font.family: "JetBrainsMono NF"
                                        anchors.verticalCenter: parent.verticalCenter
                                        Behavior on color { ColorAnimation { duration: 300 } }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
