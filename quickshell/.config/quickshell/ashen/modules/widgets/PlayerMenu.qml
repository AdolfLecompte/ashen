import QtQuick
import "root:/services" as Services

// Every player with something loaded, to pick which one the card follows:
// its name, what it is playing, and a check on the one in charge. Picking
// writes Media.chosen, so the bar, the panel and the widgets all follow.
Rectangle {
    id: menu

    property bool open: false
    signal picked()

    width: 240
    height: list.implicitHeight + 8
    radius: Services.Sizes.cardR
    color: Services.Colors.surfacePopup
    border.width: 1
    border.color: Services.Colors.fillOutline
    opacity: menu.open ? 1 : 0
    visible: opacity > 0.01
    Behavior on opacity { Anim { speed: Services.Sizes.msMicro } }

    Column {
        id: list
        anchors.centerIn: parent
        width: parent.width - 8

        Repeater {
            model: Services.Media.live
            delegate: Item {
                id: entry
                required property var modelData
                readonly property bool current: modelData === Services.Media.player
                width: list.width
                height: 44

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10

                    Text {
                        textFormat: Text.PlainText
                        anchors.verticalCenter: parent.verticalCenter
                        width: 18
                        text: entry.current ? "" : (entry.modelData.isPlaying ? "" : "")
                        color: entry.current || hover.containsMouse ? Services.Colors.ghost : Services.Colors.mist
                        font.pixelSize: 16
                        font.family: "Material Symbols Rounded"
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 28
                        spacing: 1
                        Text {
                            textFormat: Text.PlainText
                            width: parent.width
                            text: Services.Media.nameOf(entry.modelData)
                            color: entry.current || hover.containsMouse ? Services.Colors.snow : Services.Colors.mist
                            font.pixelSize: Services.Sizes.fsBody
                            font.bold: true
                            font.family: "JetBrainsMono NF"
                            elide: Text.ElideRight
                        }
                        Text {
                            textFormat: Text.PlainText
                            width: parent.width
                            visible: text !== ""
                            text: entry.modelData.trackTitle || ""
                            color: Services.Colors.ash
                            font.pixelSize: Services.Sizes.fsMeta
                            font.family: "JetBrainsMono NF"
                            elide: Text.ElideRight
                        }
                    }
                }
                MouseArea {
                    id: hover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Services.Media.chosen = entry.modelData
                        menu.picked()
                    }
                }
            }
        }
    }
}
