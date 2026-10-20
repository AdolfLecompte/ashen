import QtQuick

import "root:/modules/widgets" as Widgets
import "root:/services" as Services

// A square pill wearing one glyph: the shape most small tools on the bar take.
// Click, right-click and the wheel are handed to whoever uses it.
Rectangle {
    id: root
    // The bar this pill stands on (Bar.qml hands it in).
    property var spec: Services.Sizes.first
    property string key: ""
    property string glyph: ""
    property bool active: false
    signal clicked()
    signal rightClicked()
    signal wheeled(int delta)

    readonly property bool outlined: root.spec.outlined(root.key)
    scale: Services.Sizes.hoverScale(hover.containsMouse, hover.pressed)
    Behavior on scale { Widgets.Anim { speed: Services.Sizes.pillHoverMs } }
    readonly property int pillH: Services.Sizes.pillH

    width: pillH; height: pillH
    radius: Services.Sizes.pillR
    border.width: root.outlined ? Services.Sizes.outlineW : 0
    border.color: Services.Colors.fillOutline
    color: root.outlined ? Services.Colors.surfaceGlass
         : ((root.active && root.spec.fills) ? Services.Colors.ghost : root.spec.pillPlate)
    Behavior on color { Widgets.ColorAnim {} }

    Text {
        textFormat: Text.PlainText
        anchors.centerIn: parent
        text: root.glyph
        color: root.active ? (root.spec.fills ? Services.Colors.accentText : Services.Colors.ghost)
             : hover.containsMouse ? Services.Colors.snow : Services.Colors.mist
        font.pixelSize: 22
        font.family: "Material Symbols Rounded"
        Behavior on color { Widgets.ColorAnim {} }
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => mouse.button === Qt.RightButton ? root.rightClicked() : root.clicked()
        onWheel: wheel => root.wheeled(wheel.angleDelta.y)
    }
}
