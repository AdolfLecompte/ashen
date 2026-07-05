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

            property string password: ""
            property string errorMsg: ""
            property string currentTime: ""
            property string currentDate: ""
            property string currentDay: ""
            property bool checking: false
            property bool showPower: false
            property int battery: 0
            property bool charging: false
            property string wallpaper: ""

            Process {
                id: wallpaperProc
                command: ["sh", "-c", "awww query | grep -o 'image: .*' | cut -d' ' -f2"]
                running: true
                stdout: StdioCollector {
                    onStreamFinished: surface.wallpaper = text.trim()
                }
            }

            color: "#080809"

            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: {
                    let now = new Date()
                    surface.currentTime = Qt.formatDateTime(now, "hh:mm AP")
                    surface.currentDate = Qt.formatDateTime(now, "MMMM d, yyyy")
                    surface.currentDay = Qt.locale().dayName(now.getDay())
                }
            }

            Process {
                id: batProc
                command: ["sh", "-c", "cat /sys/class/power_supply/BAT0/capacity"]
                running: true
                stdout: StdioCollector {
                    onStreamFinished: surface.battery = parseInt(text.trim()) || 0
                }
            }

            Process {
                id: chargeProc
                command: ["sh", "-c", "cat /sys/class/power_supply/AC0/online"]
                running: true
                stdout: StdioCollector {
                    onStreamFinished: surface.charging = text.trim() === "1"
                }
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

                Image {
                    anchors.fill: parent
                    source: surface.wallpaper !== "" ? ("file://" + surface.wallpaper) : ""
                    fillMode: Image.PreserveAspectCrop
                    visible: status === Image.Ready
                    opacity: 0.4
                }

                // Contenido principal
                Column {
                    anchors.centerIn: parent
                    spacing: 40

                    // Reloj
                    Column {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 6
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: surface.currentTime
                            color: "#d4d4e0"
                            font.pixelSize: 80
                            font.family: "JetBrainsMono NF"
                            font.bold: true
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: surface.currentDay + ", " + surface.currentDate
                            color: "#7878a0"
                            font.pixelSize: 18
                            font.family: "JetBrainsMono NF"
                        }
                    }

                    // Avatar + usuario
                    Column {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 14

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 96; height: 96
                            radius: 16
                            color: Qt.rgba(0x62/255, 0x72/255, 0xa4/255, 0.15)
                            border.color: Qt.rgba(0x62/255, 0x72/255, 0xa4/255, 0.4)
                            border.width: 2

                            Image {
                                id: faceImg
                                anchors.fill: parent
                                anchors.margins: 2
                                source: "file:///home/adolf-arch/.face"
                                fillMode: Image.PreserveAspectCrop
                                visible: status === Image.Ready
                            }

                            Text {
                                anchors.centerIn: parent
                                text: ""
                                color: "#6272a4"
                                font.pixelSize: 52
                                font.family: "Material Symbols Rounded"
                                visible: faceImg.status !== Image.Ready
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "adolf-arch"
                            color: "#d4d4e0"
                            font.pixelSize: 18
                            font.family: "JetBrainsMono NF"
                            font.bold: true
                        }
                    }

                    // Campo contraseña
                    Column {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 10

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 340; height: 52
                            radius: 10
                            color: Qt.rgba(0x1d/255, 0x1d/255, 0x24/255, 0.9)
                            border.color: surface.errorMsg !== "" ? "#c47a7a"
                                : passInput.activeFocus ? "#6272a4"
                                : Qt.rgba(0x62/255, 0x72/255, 0xa4/255, 0.3)
                            border.width: 1
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                anchors.rightMargin: 16
                                spacing: 12

                                // Icono llave
                                Text {
                                    text: ""
                                    color: surface.errorMsg !== "" ? "#c47a7a" : "#6272a4"
                                    font.pixelSize: 20
                                    font.family: "Material Symbols Rounded"
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }

                                // Area de input
                                Item {
                                    Layout.fillWidth: true
                                    height: 30

                                    // Placeholder
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "Enter password..."
                                        color: "#404052"
                                        font.pixelSize: 15
                                        font.family: "JetBrainsMono NF"
                                        visible: surface.password.length === 0
                                    }

                                    // Indicadores cuadrados con bordes redondeados
                                    Row {
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 8
                                        visible: surface.password.length > 0

                                        Repeater {
                                            model: Math.min(surface.password.length, 24)
                                            delegate: Rectangle {
                                                width: 10; height: 10
                                                radius: 3
                                                color: "#6272a4"
                                            }
                                        }
                                    }

                                    // TextInput invisible que captura el teclado
                                    TextInput {
                                        id: passInput
                                        anchors.fill: parent
                                        echoMode: TextInput.Password
                                        color: "transparent"
                                        focus: true
                                        onTextChanged: surface.password = text
                                        Keys.onReturnPressed: surface.tryUnlock()
                                        Keys.onEscapePressed: {
                                            text = ""
                                            surface.errorMsg = ""
                                        }
                                    }
                                }

                                // Icono estado
                                Text {
                                    text: surface.checking ? "" : ""
                                    color: surface.checking ? "#6272a4" : "#404052"
                                    font.pixelSize: 18
                                    font.family: "Material Symbols Rounded"
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    RotationAnimation on rotation {
                                        running: surface.checking
                                        loops: Animation.Infinite
                                        from: 0; to: 360
                                        duration: 1000
                                    }
                                }
                            }
                        }

                        // Error message
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: surface.errorMsg
                            color: "#c47a7a"
                            font.pixelSize: 12
                            font.family: "JetBrainsMono NF"
                            opacity: surface.errorMsg !== "" ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 200 } }
                        }
                    }
                }

                // Esquina inferior derecha
                Column {
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    anchors.margins: 24
                    spacing: 8

                    // Opciones power desplegadas
                    Column {
                        anchors.right: parent.right
                        spacing: 6
                        opacity: surface.showPower ? 1.0 : 0.0
                        visible: opacity > 0
                        Behavior on opacity { NumberAnimation { duration: 200 } }

                        Repeater {
                            model: [
                                { icon: "", label: "Suspend",  cmd: "systemctl suspend",  color: "#d4d4e0" },
                                { icon: "",  label: "Reboot",   cmd: "systemctl reboot",   color: "#c4a882" },
                                { icon: "", label: "Shutdown", cmd: "systemctl poweroff", color: "#c47a7a" },
                            ]
                            delegate: Rectangle {
                                required property var modelData
                                anchors.right: parent.right
                                width: optRow.implicitWidth + 20
                                height: 38
                                radius: 8
                                color: Qt.rgba(0x1d/255, 0x1d/255, 0x24/255, 0.92)
                                border.color: Qt.rgba(0x62/255, 0x72/255, 0xa4/255, 0.25)
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
                                    onEntered: parent.color = Qt.rgba(0x62/255, 0x72/255, 0xa4/255, 0.2)
                                    onExited: parent.color = Qt.rgba(0x1d/255, 0x1d/255, 0x24/255, 0.92)
                                    onClicked: Quickshell.execDetached(["sh", "-c", modelData.cmd])
                                }
                            }
                        }
                    }

                    // Pill bateria + power
                    Rectangle {
                        anchors.right: parent.right
                        width: pillRow.implicitWidth + 20
                        height: 44
                        radius: 10
                        color: Qt.rgba(0x1d/255, 0x1d/255, 0x24/255, 0.92)
                        border.color: Qt.rgba(0x62/255, 0x72/255, 0xa4/255, 0.25)
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
                                    color: surface.charging ? "#7a9e7e" : surface.battery >= 20 ? "#d4d4e0" : "#c47a7a"
                                    font.pixelSize: 18
                                    font.family: "Material Symbols Rounded"
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: surface.battery + "%"
                                    color: surface.charging ? "#7a9e7e" : surface.battery >= 20 ? "#d4d4e0" : "#c47a7a"
                                    font.pixelSize: 12
                                    font.family: "JetBrainsMono NF"
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Rectangle {
                                width: 1; height: 24
                                color: Qt.rgba(0x62/255, 0x72/255, 0xa4/255, 0.3)
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: ""
                                color: surface.showPower ? "#c47a7a" : "#7878a0"
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
