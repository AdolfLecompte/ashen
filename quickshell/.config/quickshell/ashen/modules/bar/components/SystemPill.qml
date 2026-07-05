import QtQuick
import QtQuick.Layouts

import "root:/services" as Services

Rectangle {
    id: root
    readonly property int innerRadius: 8
    readonly property int innerHeight: 32

    height: 44
    radius: 10
    color: Qt.rgba(0x1d/255, 0x1d/255, 0x24/255, 0.82)
    border.color: Qt.rgba(0x24/255, 0x24/255, 0x2d/255, 0.5)
    border.width: 1
    width: sysRow.width + 16

    Row {
        id: sysRow
        anchors.centerIn: parent
        spacing: 4

        // Notificaciones
        Rectangle {
            width: root.innerHeight; height: root.innerHeight
            radius: root.innerRadius
            color: Qt.rgba(0x62/255, 0x72/255, 0xa4/255, 0.25)
            Text {
                anchors.centerIn: parent
                text: ""
                color: "#d4d4e0"
                font.pixelSize: 18
                font.family: "Material Symbols Rounded"
            }
        }

        // Wifi
        Rectangle {
            height: root.innerHeight
            radius: root.innerRadius
            width: wifiInner.width + 16
            color: Services.Network.wifiSsid !== "" ? "#6272a4" : Qt.rgba(0x62/255, 0x72/255, 0xa4/255, 0.25)
            Behavior on color { ColorAnimation { duration: 300 } }
            Row {
                id: wifiInner
                anchors.centerIn: parent
                spacing: 5
                Text {
                    text: Services.Network.wifiSsid !== "" ? "" : ""
                    color: Services.Network.wifiSsid !== "" ? "#0f0f12" : "#7878a0"
                    font.pixelSize: 18
                    font.family: "Material Symbols Rounded"
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
                Text {
                    text: Services.Network.wifiSsid !== "" ? Services.Network.wifiSsid : "Off"
                    color: Services.Network.wifiSsid !== "" ? "#0f0f12" : "#7878a0"
                    font.pixelSize: 12
                    font.family: "JetBrainsMono NF"
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }
        }

        // Bluetooth
        Rectangle {
            height: root.innerHeight
            radius: root.innerRadius
            width: btInner.width + 16
            color: Services.Network.btDevice !== "" ? "#6272a4" : Qt.rgba(0x62/255, 0x72/255, 0xa4/255, 0.25)
            Behavior on color { ColorAnimation { duration: 300 } }
            Row {
                id: btInner
                anchors.centerIn: parent
                spacing: 5
                Text {
                    text: Services.Network.btDevice !== "" ? "" : ""
                    color: Services.Network.btDevice !== "" ? "#0f0f12" : "#7878a0"
                    font.pixelSize: 18
                    font.family: "Material Symbols Rounded"
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
                Text {
                    text: Services.Network.btDevice !== "" ? Services.Network.btDevice : "Off"
                    color: Services.Network.btDevice !== "" ? "#0f0f12" : "#7878a0"
                    font.pixelSize: 12
                    font.family: "JetBrainsMono NF"
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }
        }

        // Volumen
        Rectangle {
            height: root.innerHeight
            radius: root.innerRadius
            width: volInner.width + 16
            color: Services.Audio.volume > 0 ? "#6272a4" : Qt.rgba(0x62/255, 0x72/255, 0xa4/255, 0.25)
            Behavior on color { ColorAnimation { duration: 300 } }
            Row {
                id: volInner
                anchors.centerIn: parent
                spacing: 5
                Text {
                    text: Services.Audio.volume === 0 ? "" : Services.Audio.volume < 66 ? "" : ""
                    color: Services.Audio.volume > 0 ? "#0f0f12" : "#7878a0"
                    font.pixelSize: 18
                    font.family: "Material Symbols Rounded"
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
                Text {
                    text: Services.Audio.volume + "%"
                    color: Services.Audio.volume > 0 ? "#0f0f12" : "#7878a0"
                    font.pixelSize: 12
                    font.family: "JetBrainsMono NF"
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }
        }

        // Bateria
        Rectangle {
            height: root.innerHeight
            radius: root.innerRadius
            width: batInner.width + 16
            color: Services.Battery.charging ? "#6272a4" : Qt.rgba(0x62/255, 0x72/255, 0xa4/255, 0.25)
            Behavior on color { ColorAnimation { duration: 300 } }
            Row {
                id: batInner
                anchors.centerIn: parent
                spacing: 5
                Text {
                    text: Services.Battery.charging ? "" : Services.Battery.level >= 90 ? "" : Services.Battery.level >= 70 ? "" : Services.Battery.level >= 50 ? "" : Services.Battery.level >= 30 ? "" : Services.Battery.level >= 15 ? "" : ""
                    color: Services.Battery.charging ? "#0f0f12" : Services.Battery.level >= 50 ? "#d4d4e0" : Services.Battery.level >= 20 ? "#c4a882" : "#c47a7a"
                    font.pixelSize: 18
                    font.family: "Material Symbols Rounded"
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on color { ColorAnimation { duration: 300 } }
                }
                Text {
                    text: Services.Battery.level + "%"
                    color: Services.Battery.charging ? "#0f0f12" : Services.Battery.level >= 50 ? "#d4d4e0" : Services.Battery.level >= 20 ? "#c4a882" : "#c47a7a"
                    font.pixelSize: 12
                    font.family: "JetBrainsMono NF"
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on color { ColorAnimation { duration: 300 } }
                }
            }
        }
    }
}
