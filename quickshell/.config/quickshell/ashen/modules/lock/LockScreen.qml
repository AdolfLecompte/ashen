import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

Scope {
    id: root

    IpcHandler {
        target: "lockscreen"
        function lock() {
            sessionLock.locked = true
        }
    }

    WlSessionLock {
        id: sessionLock

        WlSessionLockSurface {
            id: surface

            // Inicializar inmediatamente para evitar delay
            property string currentTime: Qt.formatDateTime(new Date(), "hh:mm AP")
            property string currentSecs: Qt.formatDateTime(new Date(), "ss")
            property string currentDate: Qt.formatDateTime(new Date(), "MMMM d, yyyy")
            property string currentDay: Qt.locale().dayName(new Date().getDay())
            property string password: ""
            property string errorMsg: ""
            property bool checking: false
            property bool showPower: false
            property int battery: 0
            property bool charging: false
            property string wallpaper: ""

            color: "#080809"

            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: {
                    let now = new Date()
                    surface.currentTime = Qt.formatDateTime(now, "hh:mm AP")
                    surface.currentSecs = Qt.formatDateTime(now, "ss")
                    surface.currentDate = Qt.formatDateTime(now, "MMMM d, yyyy")
                    surface.currentDay = Qt.locale().dayName(now.getDay())
                }
            }

            Process {
                id: batProc
                command: ["sh", "-c", "cat /sys/class/power_supply/BAT0/capacity"]
                running: true
                stdout: StdioCollector { onStreamFinished: surface.battery = parseInt(text.trim()) || 0 }
            }

            Process {
                id: chargeProc
                command: ["sh", "-c", "cat /sys/class/power_supply/AC0/online"]
                running: true
                stdout: StdioCollector { onStreamFinished: surface.charging = text.trim() === "1" }
            }

            Process {
                id: wallpaperProc
                command: ["sh", "-c", "awww query | grep -o 'image: .*' | cut -d' ' -f2"]
                running: true
                stdout: StdioCollector { onStreamFinished: surface.wallpaper = text.trim() }
            }

            Timer {
                interval: 30000; running: true; repeat: true
                onTriggered: { batProc.running = true; chargeProc.running = true }
            }

            Process {
                id: authProc
                command: ["sh", "-c", "printf '%s' \"" + surface.password + "\" | su -s /bin/sh -c 'exit 0' adolf-arch 2>/dev/null && echo ok || echo fail"]
                running: false
                stdout: StdioCollector {
                    onStreamFinished: {
                        if (text.trim() === "ok") {
                            sessionLock.locked = false
                        } else {
                            surface.errorMsg = "Incorrect password"
                            surface.password = ""
                            passInput.text = ""
                            surface.checking = false
                            errorTimer.restart()
                        }
                    }
                }
            }

            Timer {
                id: errorTimer
                interval: 2000
                onTriggered: surface.errorMsg = ""
            }

            function tryUnlock() {
                if (surface.password.length === 0) return
                surface.checking = true
                surface.errorMsg = ""
                authProc.running = true
            }

            Rectangle {
                anchors.fill: parent
                color: "#080809"

                // Wallpaper semitransparente
                Image {
                    anchors.fill: parent
                    source: surface.wallpaper !== "" ? ("file://" + surface.wallpaper) : ""
                    fillMode: Image.PreserveAspectCrop
                    visible: status === Image.Ready
                    opacity: 0.35
                }

                // Overlay sutil
                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(0x08/255, 0x08/255, 0x09/255, 0.5)
                }

                // Contenido principal
                Column {
                    anchors.centerIn: parent
                    spacing: 32

                    // Reloj grande
                    Column {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 0

                        // Hora principal
                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 0

                            Text {
                                text: surface.currentTime.split(" ")[0]
                                color: "#e8e8ec"
                                font.pixelSize: 96
                                font.family: "JetBrainsMono NF"
                                font.weight: Font.Bold
                            }
                            Column {
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 16
                                spacing: 2
                                Text {
                                    text: surface.currentSecs
                                    color: Qt.rgba(0xe8/255, 0xe8/255, 0xec/255, 0.4)
                                    font.pixelSize: 28
                                    font.family: "JetBrainsMono NF"
                                    font.weight: Font.Bold
                                }
                                Text {
                                    text: surface.currentTime.split(" ")[1]
                                    color: Qt.rgba(0xe8/255, 0xe8/255, 0xec/255, 0.4)
                                    font.pixelSize: 14
                                    font.family: "JetBrainsMono NF"
                                    font.weight: Font.Bold
                                }
                            }
                        }

                        // Fecha
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: surface.currentDay + "  ·  " + surface.currentDate
                            color: Qt.rgba(0xe8/255, 0xe8/255, 0xec/255, 0.5)
                            font.pixelSize: 16
                            font.family: "JetBrainsMono NF"
                            font.weight: Font.Bold
                            font.letterSpacing: 1
                        }
                    }

                    // Avatar + saludo
                    Column {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 16

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 120; height: 120
                            radius: 20
                            color: Qt.rgba(0x6e/255, 0x6e/255, 0x7a/255, 0.15)
                            border.color: Qt.rgba(0x6e/255, 0x6e/255, 0x7a/255, 0.35)
                            border.width: 2

                            Image {
                                id: faceImg
                                anchors.fill: parent
                                anchors.margins: 2
                                source: "file:///home/adolf-arch/.face"
                                fillMode: Image.PreserveAspectCrop
                                visible: status === Image.Ready
                                layer.enabled: visible
                            }

                            Text {
                                anchors.centerIn: parent
                                text: ""
                                color: "#6e6e7a"
                                font.pixelSize: 68
                                font.family: "Material Symbols Rounded"
                                visible: faceImg.status !== Image.Ready
                            }
                        }

                        Column {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 2

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "adolf-arch"
                                color: "#e8e8ec"
                                font.pixelSize: 18
                                font.family: "JetBrainsMono NF"
                                font.weight: Font.Medium
                            }
                        }
                    }

                    // Campo contraseña
                    Column {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 10

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 320; height: 52
                            radius: 10
                            color: Qt.rgba(0x1c/255, 0x1c/255, 0x21/255, 0.85)
                            border.color: surface.errorMsg !== "" ? "#c87a7a"
                                : passInput.activeFocus ? "#6e6e7a"
                                : Qt.rgba(0x6e/255, 0x6e/255, 0x7a/255, 0.25)
                            border.width: 1
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                anchors.rightMargin: 16
                                spacing: 12

                                Text {
                                    text: ""
                                    color: surface.errorMsg !== "" ? "#c87a7a" : "#6e6e7a"
                                    font.pixelSize: 20
                                    font.family: "Material Symbols Rounded"
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }

                                Item {
                                    Layout.fillWidth: true
                                    height: 30

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "Enter password..."
                                        color: "#4a4a54"
                                        font.pixelSize: 14
                                        font.family: "JetBrainsMono NF"
                                        visible: surface.password.length === 0
                                    }

                                    Row {
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 8
                                        visible: surface.password.length > 0

                                        Repeater {
                                            model: Math.min(surface.password.length, 24)
                                            delegate: Rectangle {
                                                width: 8; height: 8
                                                radius: 2
                                                color: "#6e6e7a"
                                            }
                                        }
                                    }

                                    TextInput {
                                        id: passInput
                                        width: 1; height: 1
                                        x: -9999; y: -9999
                                        echoMode: TextInput.Password
                                        color: "transparent"
                                        cursorVisible: false
                                        focus: true
                                        onTextChanged: surface.password = text
                                        Keys.onReturnPressed: surface.tryUnlock()
                                        Keys.onEscapePressed: {
                                            text = ""
                                            surface.errorMsg = ""
                                        }
                                    }
                                }

                                Text {
                                    text: ""
                                    color: surface.checking ? "#6e6e7a" : "#4a4a54"
                                    font.pixelSize: 18
                                    font.family: "Material Symbols Rounded"
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    SequentialAnimation on opacity {
                                        running: surface.checking
                                        loops: Animation.Infinite
                                        NumberAnimation { to: 0.2; duration: 500 }
                                        NumberAnimation { to: 1.0; duration: 500 }
                                    }
                                }
                            }
                        }

                        Item {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 320
                            height: 16

                            Text {
                                anchors.centerIn: parent
                                text: surface.errorMsg
                                color: "#c87a7a"
                                font.pixelSize: 12
                                font.family: "JetBrainsMono NF"
                                opacity: surface.errorMsg !== "" ? 1.0 : 0.0
                                Behavior on opacity { NumberAnimation { duration: 200 } }
                            }
                        }
                    }
                }

                // Esquina inferior derecha
                Column {
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    anchors.margins: 24
                    spacing: 8

                    Column {
                        anchors.right: parent.right
                        spacing: 6
                        opacity: surface.showPower ? 1.0 : 0.0
                        visible: opacity > 0
                        Behavior on opacity { NumberAnimation { duration: 200 } }

                        Repeater {
                            model: [
                                { icon: "", label: "Suspend",  cmd: "systemctl suspend",  color: "#9090a0" },
                                { icon: "",  label: "Reboot",   cmd: "systemctl reboot",   color: "#9090a0" },
                                { icon: "", label: "Shutdown", cmd: "systemctl poweroff", color: "#c87a7a" },
                            ]
                            delegate: Rectangle {
                                required property var modelData
                                anchors.right: parent.right
                                width: optRow.implicitWidth + 20
                                height: 38
                                radius: 8
                                color: Qt.rgba(0x1c/255, 0x1c/255, 0x21/255, 0.92)
                                border.color: Qt.rgba(0x6e/255, 0x6e/255, 0x7a/255, 0.25)
                                border.width: 1
                                Behavior on color { ColorAnimation { duration: 150 } }

                                Row {
                                    id: optRow
                                    anchors.centerIn: parent
                                    spacing: 8
                                    Text {
                                        text: modelData.icon
                                        color: modelData.color
                                        font.pixelSize: 18
                                        font.family: "Material Symbols Rounded"
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Text {
                                        text: modelData.label
                                        color: modelData.color
                                        font.pixelSize: 12
                                        font.family: "JetBrainsMono NF"
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true
                                    onEntered: parent.color = Qt.rgba(0x6e/255, 0x6e/255, 0x7a/255, 0.2)
                                    onExited: parent.color = Qt.rgba(0x1c/255, 0x1c/255, 0x21/255, 0.92)
                                    onClicked: Quickshell.execDetached(["sh", "-c", modelData.cmd])
                                }
                            }
                        }
                    }

                    Rectangle {
                        anchors.right: parent.right
                        width: pillRow.implicitWidth + 20
                        height: 44
                        radius: 10
                        color: Qt.rgba(0x1c/255, 0x1c/255, 0x21/255, 0.85)
                        border.color: Qt.rgba(0x6e/255, 0x6e/255, 0x7a/255, 0.25)
                        border.width: 1

                        Row {
                            id: pillRow
                            anchors.centerIn: parent
                            spacing: 10

                            Row {
                                spacing: 4
                                anchors.verticalCenter: parent.verticalCenter
                                Text {
                                    text: surface.charging ? "" : surface.battery >= 90 ? "" : surface.battery >= 50 ? "" : surface.battery >= 20 ? "" : ""
                                    color: surface.battery < 20 && !surface.charging ? "#c87a7a" : "#9090a0"
                                    font.pixelSize: 18
                                    font.family: "Material Symbols Rounded"
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: surface.battery + "%"
                                    color: surface.battery < 20 && !surface.charging ? "#c87a7a" : "#9090a0"
                                    font.pixelSize: 12
                                    font.family: "JetBrainsMono NF"
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Rectangle {
                                width: 1; height: 24
                                color: Qt.rgba(0x6e/255, 0x6e/255, 0x7a/255, 0.3)
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: ""
                                color: surface.showPower ? "#e8e8ec" : "#4a4a54"
                                font.pixelSize: 20
                                font.family: "Material Symbols Rounded"
                                anchors.verticalCenter: parent.verticalCenter
                                Behavior on color { ColorAnimation { duration: 150 } }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: surface.showPower = !surface.showPower
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
