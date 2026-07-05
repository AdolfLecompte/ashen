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

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.55)
        opacity: Services.AppState.powerMenuVisible ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 250 } }

        MouseArea {
            anchors.fill: parent
            onClicked: Services.AppState.powerMenuVisible = false
        }
    }

    Column {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: 16
        spacing: 12
        opacity: Services.AppState.powerMenuVisible ? 1.0 : 0.0
        scale: Services.AppState.powerMenuVisible ? 1.0 : 0.85
        visible: Services.AppState.powerMenuVisible || opacity > 0

        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        Repeater {
            model: [
                { icon: "",     cmd: "qs ipc -c ashen call lockscreen lock", color: Services.Colors.snow,    label: "Lock"     },
                { icon: "", cmd: "systemctl poweroff",                   color: Services.Colors.error_,  label: "Shutdown" },
                { icon: "",  cmd: "systemctl suspend",                    color: Services.Colors.snow,    label: "Suspend"  },
                { icon: "",   cmd: "systemctl reboot",                     color: Services.Colors.neutral, label: "Reboot"   },
            ]

            delegate: Rectangle {
                required property var modelData
                width: 110; height: 110
                radius: 16
                color: Services.Colors.surfaceAlpha(0.95)
                border.color: Services.Colors.ghostAlpha(0.2)
                border.width: 1
                Behavior on color { ColorAnimation { duration: 150 } }

                Column {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData.icon
                        color: modelData.color
                        font.pixelSize: 40
                        font.family: "Material Symbols Rounded"
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData.label
                        color: Services.Colors.mist
                        font.pixelSize: 11
                        font.family: "JetBrainsMono NF"
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onEntered: parent.color = Services.Colors.ghostAlpha(0.2)
                    onExited: parent.color = Services.Colors.surfaceAlpha(0.95)
                    onClicked: {
                        Services.AppState.powerMenuVisible = false
                        Quickshell.execDetached(["sh", "-c", modelData.cmd])
                    }
                }
            }
        }
    }
}
