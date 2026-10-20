import QtQuick

import "root:/services" as Services
import "root:/modules/widgets" as Widgets

// A pill or a shortcut in the dock: a glyph (or a few words, the clock), the
// same dot an open application gets when it is on, and the dock's hover.
Item {
    id: root

    property string glyph: ""
    property string text: ""
    property bool lit: false
    signal clicked()
    signal rightClicked()
    signal wheeled(int delta)

    readonly property bool warm: hover.containsMouse
    implicitWidth: root.text !== "" ? Math.max(Services.Sizes.dockIcon, words.implicitWidth + 12)
                                    : Services.Sizes.dockIcon
    implicitHeight: Services.Sizes.dockIcon

    scale: Services.Sizes.hoverScale(root.warm, hover.pressed)
    Behavior on scale { NumberAnimation { duration: Services.Sizes.pillHoverMs; easing.type: Services.Sizes.easeOut } }

    Text {
        textFormat: Text.PlainText
        visible: root.text === ""
        anchors.centerIn: parent
        // Material Symbols draws its glyphs above the middle of their box.
        anchors.verticalCenterOffset: Math.round(font.pixelSize * 0.08)
        text: root.glyph
        color: root.warm || root.lit ? Services.Colors.snow : Services.Colors.mist
        Behavior on color { Widgets.ColorAnim { speed: Services.Sizes.msMicro } }
        font.pixelSize: Math.round(Services.Sizes.dockIcon * 0.5)
        font.family: "Material Symbols Rounded"
    }
    Text {
        id: words
        textFormat: Text.PlainText
        visible: root.text !== ""
        anchors.centerIn: parent
        text: root.text
        horizontalAlignment: Text.AlignHCenter
        lineHeight: 0.85
        color: root.warm ? Services.Colors.snow : Services.Colors.mist
        Behavior on color { Widgets.ColorAnim { speed: Services.Sizes.msMicro } }
        font.pixelSize: Math.round(Services.Sizes.dockIcon * 0.32)
        font.bold: true
        font.family: "JetBrainsMono NF"
    }

    // On, or waiting: the running dot of an application.
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 2
        width: 4; height: 4; radius: 2
        color: Services.Colors.ghost
        opacity: root.lit ? 1 : 0
        Behavior on opacity { Widgets.Anim {} }
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => mouse.button === Qt.RightButton ? root.rightClicked() : root.clicked()
        onWheel: wheel => root.wheeled(wheel.angleDelta.y)
    }
}
