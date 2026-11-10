import QtQuick
import "root:/services" as Services

// The line under a count-down: how far it has run, and when it ends.
Item {
    id: rb

    property real progress: 0
    property bool playing: false
    property string ends: ""

    width: 360
    height: 34

    WaveProgress {
        width: parent.width
        height: 14
        progress: rb.progress
        playing: rb.playing
    }
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 20
        spacing: 4
        opacity: rb.ends !== "" ? 1 : 0
        Behavior on opacity { Anim { speed: Services.Sizes.msMicro } }
        Text {
            textFormat: Text.PlainText
            anchors.verticalCenter: parent.verticalCenter
            text: ""
            color: Services.Colors.mist
            font.family: "Material Symbols Rounded"
            font.pixelSize: 13
        }
        Text {
            textFormat: Text.PlainText
            anchors.verticalCenter: parent.verticalCenter
            text: rb.ends
            color: Services.Colors.mist
            font.pixelSize: Services.Sizes.fsMeta
            font.bold: true
            font.family: "JetBrainsMono NF"
        }
    }
}
