import QtQuick

import "root:/services" as Services

// One of the day's figures: a glyph, the reading, and what it is. No plate --
// four of these on a line ARE the row. Shared by the clock panel and the
// desktop weather widget so the same four numbers read the same in both.
Column {
    id: cell

    property string glyph: ""
    property string value: ""
    property string caption: ""

    spacing: 3

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 5
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: cell.glyph
            color: Services.Colors.ghost
            font.pixelSize: 15
            font.family: "Material Symbols Rounded"
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: cell.value
            color: Services.Colors.snow
            font.pixelSize: 13
            font.bold: true
            font.family: "JetBrainsMono NF"
        }
    }
    // The caption never grows past its cell: four of them share a row, and a
    // translated word is wider than the English one this was drawn with.
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        width: cell.width > 0 ? cell.width : implicitWidth
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        text: cell.caption
        color: Services.Colors.ash
        font.pixelSize: 8
        font.letterSpacing: 1
        font.family: "JetBrainsMono NF"
    }
}
