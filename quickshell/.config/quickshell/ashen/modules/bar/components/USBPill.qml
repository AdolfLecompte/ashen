import Quickshell
import QtQuick
import QtQuick.Layouts

import "root:/services" as Services

Rectangle {
    id: root
    readonly property bool anyMounted: {
        for (let d of Services.USB.devices) {
            if (d.mountpoint && d.mountpoint.length > 0) return true
        }
        return false
    }

    height: 44
    radius: 10
    color: root.anyMounted ? Services.Colors.ghost
                           : (hover.containsMouse ? Services.Colors.ghostAlpha(0.3)
                                                  : Services.Colors.surfaceAlpha(0.82))
    border.width: 0
    width: Services.USB.devices.length > 0 ? (icon.implicitWidth + 24) : 0
    opacity: Services.USB.devices.length > 0 ? 1.0 : 0.0
    clip: true
    Behavior on color { ColorAnimation { duration: 300 } }
    Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 150 } }

    Text {
        id: icon
        anchors.centerIn: parent
        text: "\ue1e0"
        color: (root.anyMounted || hover.containsMouse) ? Services.Colors.abyss : Services.Colors.mist
        font.pixelSize: 22
        font.family: "Material Symbols Rounded"
        Behavior on color { ColorAnimation { duration: 300 } }
    }

    Timer {
        interval: 400
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            let g = root.mapToGlobal(0, 0)
            Services.AppState.usbPillCenterX = g.x + root.width / 2
        }
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: Services.AppState.usbVisible = !Services.AppState.usbVisible
    }
}
