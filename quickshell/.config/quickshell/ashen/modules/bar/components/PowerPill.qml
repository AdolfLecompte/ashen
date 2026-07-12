import Quickshell
import QtQuick

import "root:/services" as Services

Rectangle {
    id: root

    width: 44; height: 44
    radius: 10
    color: Services.Colors.surfaceAlpha(0.82)
    border.color: Services.Colors.ghostAlpha(0.2)
    border.width: 1
    Behavior on color { ColorAnimation { duration: 200 } }

    Text {
        anchors.centerIn: parent
        text: ""
        color: Services.Colors.mist
        font.pixelSize: 22
        font.family: "Material Symbols Rounded"
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onEntered: parent.color = Services.Colors.ghostAlpha(0.3)
        onExited: parent.color = Services.Colors.surfaceAlpha(0.82)
        onClicked: Services.AppState.powerMenuVisible = !Services.AppState.powerMenuVisible
    }
}
