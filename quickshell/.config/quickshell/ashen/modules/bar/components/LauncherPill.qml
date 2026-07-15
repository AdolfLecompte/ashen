import QtQuick

import "root:/services" as Services

Rectangle {
    id: root
    readonly property int pillH: 44
    readonly property bool active: Services.AppState.launcherVisible

    width: pillH; height: pillH
    radius: 10
    // Fills with the accent while open, ghost tint on hover, the same inversion
    // every other toggle pill uses (see NotificationPill / RecordingPill).
    color: active ? Services.Colors.ghost
                  : (hover.containsMouse ? Services.Colors.ghostAlpha(0.3)
                                         : Services.Colors.surfaceAlpha(0.82))
    border.width: 0
    Behavior on color { ColorAnimation { duration: 200 } }

    Text {
        anchors.centerIn: parent
        text: "\uE9B0"
        color: (root.active || hover.containsMouse) ? Services.Colors.abyss : Services.Colors.ghost
        font.pixelSize: 22
        font.family: "Material Symbols Rounded"
        Behavior on color { ColorAnimation { duration: 200 } }
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: Services.AppState.launcherVisible = !Services.AppState.launcherVisible
    }
}
