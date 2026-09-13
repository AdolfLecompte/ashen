import QtQuick
import "root:/services" as Services
import "root:/modules/widgets" as Widgets

// The one button in Settings with a word inside it rather than a glyph: the
// end of a card, where something actually happens. Lived privately in the
// Display tab until the Appearance tab needed the same thing.
Rectangle {
    id: btn
    property string label: ""
    property bool accent: false
    signal go()
    readonly property bool warm: hov.containsMouse

    // Wide enough to read as the end of the card rather than a chip stuck
    // to the corner: this is the one control here that does anything.
    implicitWidth: Math.max(112, btnText.implicitWidth + 40)
    implicitHeight: 34
    radius: Services.Sizes.innerR
    color: btn.accent ? Services.Colors.ghost : Services.Colors.fillRest
    gradient: Services.Prefs.useGradients && btn.accent ? Services.Colors.accentGradient : null
    // The BOX does not move. In a card full of rows, a button that swells
    // shoves the row's rhythm around; the bar's pills grow because they float
    // on a wallpaper with nothing to disturb. Here the word grows instead.
    Behavior on color { Widgets.ColorAnim {} }

    Text {
        textFormat: Text.PlainText
        id: btnText
        anchors.centerIn: parent
        text: btn.label
        color: btn.accent ? Services.Colors.accentText
             : btn.warm ? Services.Colors.snow : Services.Colors.surfaceText
        font.pixelSize: Services.Sizes.fsBody
        font.bold: true
        font.family: "JetBrainsMono NF"
        // Grow and brighten: the same two things the bar's hover says, moved
        // from the plate to the letters. A transform, so the row never
        // remeasures and nothing beside it shifts.
        scale: Services.Sizes.hoverScale(btn.warm, hov.pressed)
        Behavior on scale { NumberAnimation { duration: Services.Sizes.pillHoverMs; easing.type: Services.Sizes.easeOut } }
        Behavior on color { Widgets.ColorAnim {} }
    }
    MouseArea {
        id: hov
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: btn.go()
    }
}
