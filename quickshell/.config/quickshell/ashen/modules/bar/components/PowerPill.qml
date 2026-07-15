import Quickshell
import QtQuick

import "root:/services" as Services

Rectangle {
    id: root
    readonly property bool active: Services.AppState.powerMenuVisible

    width: 44; height: 44
    radius: 10
    // Declarative hover/active fill (no imperative color assignment, which would
    // clobber the binding). Fills accent while the power menu is open.
    color: active ? Services.Colors.ghost
                  : (hover.containsMouse ? Services.Colors.ghostAlpha(0.3)
                                         : Services.Colors.surfaceAlpha(0.82))
    border.width: 0
    Behavior on color { ColorAnimation { duration: 200 } }

    Text {
        anchors.centerIn: parent
        text: ""
        color: (root.active || hover.containsMouse) ? Services.Colors.abyss : Services.Colors.mist
        font.pixelSize: 22
        font.family: "Material Symbols Rounded"
        Behavior on color { ColorAnimation { duration: 200 } }
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: Services.AppState.powerMenuVisible = !Services.AppState.powerMenuVisible
    }
}
