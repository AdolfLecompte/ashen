import QtQuick

import "root:/modules/widgets" as Widgets
import "root:/services" as Services

Rectangle {
    id: root

    // How this pill draws itself, chosen in Settings > Bar > Layout.
    readonly property string content: Services.Pills.contentOf("launcher")
    readonly property bool outlined: Services.Pills.isOutlined("launcher")
    // The bar's one hover language, from Sizes: grow under the pointer, give
    // a little under the click.
    scale: Services.Sizes.hoverScale(hover.containsMouse, hover.pressed)
    Behavior on scale { NumberAnimation { duration: Services.Sizes.pillHoverMs; easing.type: Services.Sizes.easeOut } }
    readonly property int pillH: Services.Sizes.pillH
    readonly property bool active: Services.AppState.launcherVisible

    width: pillH; height: pillH
    radius: Services.Sizes.pillR
    border.width: root.outlined ? Services.Sizes.outlineW : 0
    border.color: Services.Colors.fillOutline
    // Fills with the accent while open, the same inversion every other toggle
    // pill uses (see NotificationPill / RecordingPill). No hover tint: the
    // plate is the pill itself, and it answers the pointer by growing.
    color: root.outlined ? Services.Colors.surfaceGlass : ((active && Services.Pills.fills) ? Services.Colors.ghost : Services.Colors.pillPlate)
    gradient: Services.Prefs.useGradients && active ? Services.Colors.accentGradient : null
    Behavior on color { ColorAnimation { duration: Services.Sizes.msStandard } }

    Text {
        anchors.centerIn: parent
        text: "\uE8B6"
        // Dark only on the accent fill; on the hover plate, which is a surface
        // tone, the glyph lifts to snow. At rest it is `mist` like the pills
        // beside it -- the accent reads as "this one is on", and a pill that is
        // merely there must not wear it.
        color: root.active ? (Services.Pills.fills ? Services.Colors.accentText : Services.Colors.ghost)
             : hover.containsMouse ? Services.Colors.snow : Services.Colors.mist
        font.pixelSize: 22
        font.family: "Material Symbols Rounded"
        Behavior on color { ColorAnimation { duration: Services.Sizes.msStandard } }
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: Services.AppState.togglePanel("launcherVisible")
    }
}
