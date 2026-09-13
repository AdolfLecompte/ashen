import QtQuick

import "root:/services" as Services

// One of the day's figures: a glyph and the reading. No caption: a raindrop
// beside 67% is humidity without the word under it. No plate --
// four of these on a line ARE the row. Shared by the clock panel and the
// desktop weather widget so the same four numbers read the same in both.
Column {
    id: cell

    property string glyph: ""
    property string value: ""

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
}
