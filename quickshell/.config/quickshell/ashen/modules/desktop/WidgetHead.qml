import QtQuick

import "root:/services" as Services

// The one cap a desktop widget wears: a glyph, its name spaced out, and the
// figure that matters on the right. Only widgets that show SEVERAL readings
// take one -- a widget that says a single thing names itself.
Item {
    id: root

    property string glyph: ""
    property string name: ""
    property string note: ""

    implicitHeight: 18

    Row {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: 7

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.glyph
            color: Services.Colors.ghost
            font.pixelSize: 15
            font.family: "Material Symbols Rounded"
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.name
            color: Services.Colors.mist
            font.pixelSize: Services.Sizes.fsCaption
            font.bold: true
            font.letterSpacing: 1.4
            font.family: "JetBrainsMono NF"
        }
    }
    Text {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: root.note
        color: Services.Colors.snow
        font.pixelSize: Services.Sizes.fsBody
        font.bold: true
        font.family: "JetBrainsMono NF"
    }
}
