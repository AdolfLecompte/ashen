import Quickshell
import Quickshell.Io
import QtQuick

import "root:/services" as Services

PanelWindow {
    id: root

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: Services.AppState.powerMenuVisible

    // Overlay oscuro
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.55)
        opacity: Services.AppState.powerMenuVisible ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 250 } }

        // Click fuera para cerrar
        MouseArea {
            anchors.fill: parent
            onClicked: Services.AppState.powerMenuVisible = false
        }
    }

    // Botones flotantes a la derecha
    Column {
        id: btnCol
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: 16
        spacing: 12

        opacity: Services.AppState.powerMenuVisible ? 1.0 : 0.0
        scale: Services.AppState.powerMenuVisible ? 1.0 : 0.85

        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        Repeater {
            model: [
                { icon: "",     cmd: "loginctl lock-session",  color: "#ffffff", label: "Lock"     },
                { icon: "", cmd: "systemctl poweroff",     color: "#ff8080", label: "Shutdown" },
                { icon: "",  cmd: "systemctl suspend",      color: "#ffffff", label: "Suspend"  },
                { icon: "",   cmd: "systemctl reboot",       color: "#ffcc80", label: "Reboot"   },
            ]

            delegate: Rectangle {
                required property var modelData
                width: 110
                height: 110
                radius: 22
                color: Qt.rgba(0x2a/255, 0x2a/255, 0x35/255, 0.95)
                border.color: Qt.rgba(1, 1, 1, 0.1)
                border.width: 1

                Behavior on color { ColorAnimation { duration: 150 } }

                Column {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData.icon
                        color: modelData.color
                        font.pixelSize: 44
                        font.family: "Material Symbols Rounded"
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData.label
                        color: Qt.rgba(1, 1, 1, 0.7)
                        font.pixelSize: 12
                        font.family: "JetBrainsMono NF"
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onEntered: parent.color = Qt.rgba(0x62/255, 0x72/255, 0xa4/255, 0.5)
                    onExited: parent.color = Qt.rgba(0x2a/255, 0x2a/255, 0x35/255, 0.95)
                    onClicked: {
                        Services.AppState.powerMenuVisible = false
                        Quickshell.execDetached(["sh", "-c", modelData.cmd])
                    }
                }
            }
        }
    }
}
