import Quickshell
import QtQuick

import "root:/services" as Services

Rectangle {
    id: root

    width: 44; height: 44
    radius: 10
    color: Services.AppState.powerMenuVisible ? Qt.rgba(0xc4/255, 0x7a/255, 0x7a/255, 0.3) : Qt.rgba(0x1d/255, 0x1d/255, 0x24/255, 0.82)
    border.color: Qt.rgba(0x24/255, 0x24/255, 0x2d/255, 0.5)
    border.width: 1
    Behavior on color { ColorAnimation { duration: 200 } }

    Text {
        anchors.centerIn: parent
        text: ""
        color: "#c47a7a"
        font.pixelSize: 22
        font.family: "Material Symbols Rounded"
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onEntered: {
            if (!Services.AppState.powerMenuVisible)
                parent.color = Qt.rgba(0xc4/255, 0x7a/255, 0x7a/255, 0.2)
        }
        onExited: {
            if (!Services.AppState.powerMenuVisible)
                parent.color = Qt.rgba(0x1d/255, 0x1d/255, 0x24/255, 0.82)
        }
        onClicked: Services.AppState.powerMenuVisible = !Services.AppState.powerMenuVisible
    }
}
