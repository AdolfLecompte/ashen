import QtQuick
import QtQuick.Layouts

import "root:/services" as Services

Rectangle {
    id: root
    readonly property int innerR: 8
    readonly property int innerH: 32

    height: 44
    radius: 10
    color: Services.Colors.surfaceAlpha(0.82)
    border.color: Services.Colors.ghostAlpha(0.2)
    border.width: 1
    width: sysRow.width + 16

    Row {
        id: sysRow
        anchors.centerIn: parent
        spacing: 4

        // Notificaciones
        Rectangle {
            width: root.innerH; height: root.innerH
            radius: root.innerR
            color: Services.Colors.ghostAlpha(0.2)
            Text {
                anchors.centerIn: parent
                text: ""
                color: Services.Colors.mist
                font.pixelSize: 18
                font.family: "Material Symbols Rounded"
            }
        }

        // Wifi
        Rectangle {
            height: root.innerH
            radius: root.innerR
            width: wifiInner.width + 16
            color: Services.Network.wifiSsid !== "" ? Services.Colors.ghost : Services.Colors.ghostAlpha(0.2)
            Behavior on color { ColorAnimation { duration: 300 } }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    Services.AppState.networkTab = "wifi"
                    Services.AppState.networkVisible = !Services.AppState.networkVisible
                }
            }

            Row {
                id: wifiInner
                anchors.centerIn: parent
                spacing: 5
                Text {
                    text: Services.Network.wifiSsid !== "" ? "" : ""
                    color: Services.Network.wifiSsid !== "" ? Services.Colors.abyss : Services.Colors.ash
                    font.pixelSize: 18
                    font.family: "Material Symbols Rounded"
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
                Text {
                    text: Services.Network.wifiSsid !== "" ? Services.Network.wifiSsid : "Off"
                    color: Services.Network.wifiSsid !== "" ? Services.Colors.abyss : Services.Colors.ash
                    font.pixelSize: 12
                    font.family: "JetBrainsMono NF"
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }
        }

        // Bluetooth
        Rectangle {
            height: root.innerH
            radius: root.innerR
            width: btInner.width + 16
            color: Services.Network.btEnabled ? Services.Colors.ghost : Services.Colors.ghostAlpha(0.2)
            Behavior on color { ColorAnimation { duration: 300 } }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Services.AppState.bluetoothVisible = !Services.AppState.bluetoothVisible
            }

            Row {
                id: btInner
                anchors.centerIn: parent
                spacing: 5
                Text {
                    text: Services.Network.btEnabled ? "" : ""
                    color: Services.Network.btEnabled ? Services.Colors.abyss : Services.Colors.ash
                    font.pixelSize: 18
                    font.family: "Material Symbols Rounded"
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
                Text {
                    text: Services.Network.btDevice !== "" ? Services.Network.btDevice : (Services.Network.btEnabled ? "On" : "Off")
                    color: Services.Network.btEnabled ? Services.Colors.abyss : Services.Colors.ash
                    font.pixelSize: 12
                    font.family: "JetBrainsMono NF"
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }
        }

        // Volumen
        Rectangle {
            height: root.innerH
            radius: root.innerR
            width: volInner.width + 16
            color: Services.Audio.volume > 0 ? Services.Colors.ghost : Services.Colors.ghostAlpha(0.2)
            Behavior on color { ColorAnimation { duration: 300 } }
            Row {
                id: volInner
                anchors.centerIn: parent
                spacing: 5
                Text {
                    text: Services.Audio.volume === 0 ? "" : Services.Audio.volume < 66 ? "" : ""
                    color: Services.Audio.volume > 0 ? Services.Colors.abyss : Services.Colors.ash
                    font.pixelSize: 18
                    font.family: "Material Symbols Rounded"
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
                Text {
                    text: Services.Audio.volume + "%"
                    color: Services.Audio.volume > 0 ? Services.Colors.abyss : Services.Colors.ash
                    font.pixelSize: 12
                    font.family: "JetBrainsMono NF"
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }
        }

        // Bateria
        Rectangle {
            height: root.innerH
            radius: root.innerR
            width: batInner.width + 16
            color: Services.Battery.charging ? Services.Colors.ghost : Services.Colors.ghostAlpha(0.2)
            Behavior on color { ColorAnimation { duration: 300 } }
            Row {
                id: batInner
                anchors.centerIn: parent
                spacing: 5
                Text {
                    text: Services.Battery.charging ? "" : Services.Battery.level >= 90 ? "" : Services.Battery.level >= 70 ? "" : Services.Battery.level >= 50 ? "" : Services.Battery.level >= 30 ? "" : Services.Battery.level >= 15 ? "" : ""
                    color: {
                        if (Services.Battery.charging) return Services.Colors.abyss
                        if (Services.Battery.level >= 20) return Services.Colors.snow
                        return Services.Colors.error_
                    }
                    font.pixelSize: 18
                    font.family: "Material Symbols Rounded"
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on color { ColorAnimation { duration: 300 } }
                }
                Text {
                    text: Services.Battery.level + "%"
                    color: {
                        if (Services.Battery.charging) return Services.Colors.abyss
                        if (Services.Battery.level >= 20) return Services.Colors.snow
                        return Services.Colors.error_
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
