import Quickshell.Widgets
import QtQuick

import "root:/modules/widgets" as Widgets
import "root:/services" as Services

// Everything the desktop can wear, offered while you are arranging it: turn one
// on and it appears under the tray, ready to be dragged. It used to live in
// Settings, which covers the half of the screen the widgets are on.
//
// A sibling of EditBar rather than a child: Qt does not deliver clicks to
// anything drawn outside its ancestors' bounds -- the same reason WidgetSlot
// exists. See StyleChips.
Item {
    id: root

    readonly property bool shown: Services.Desktop.editMode && Services.Desktop.trayOpen
    // How wide it may run before the tiles wrap.
    property real maxWidth: 860

    implicitWidth: plate.width
    implicitHeight: plate.height
    width: implicitWidth
    height: implicitHeight

    z: 11
    visible: opacity > 0
    opacity: root.shown ? 1 : 0
    Behavior on opacity { Widgets.Anim {} }
    transform: Translate { y: root.shown ? 0 : -12; Behavior on y { Widgets.Anim {} } }

    // A tile in the tray: the widget's face over its name, and under that the
    // shape it is wearing. Out = accent glyph and a check; the plate never fills,
    // so a desktop with ten widgets out is not a wall of accent.
    component Tile: Item {
        id: tile
        property string glyph: ""
        property string label: ""
        property string note: ""
        property bool lit: false
        // A picture standing in for the glyph: the tile of a photo IS the photo.
        property string thumb: ""
        signal picked()

        readonly property bool warm: tileHover.containsMouse
        readonly property bool shows: tile.thumb !== ""

        width: 96
        height: 72

        Rectangle {
            anchors.fill: parent
            radius: Services.Sizes.cardR
            color: Services.Colors.fillRest
        }

        // The photo over that plate rather than as its colour: a
        // ClippingRectangle is what rounds a picture's corners (clip: true does
        // not), and it has no gradient of its own to lose.
        ClippingRectangle {
            anchors.fill: parent
            visible: tile.shows
            radius: Services.Sizes.cardR
            color: "transparent"

            Image {
                anchors.fill: parent
                visible: tile.shows
                source: tile.shows ? "file://" + tile.thumb : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize.width: 192
            }
            // The name has to stay readable over whatever the photo is.
            Rectangle {
                anchors.fill: parent
                visible: tile.shows
                color: Services.Colors.scrim
            }
        }

        Column {
            anchors.centerIn: parent
            width: parent.width - 12
            spacing: 1

            Text {
                textFormat: Text.PlainText
                anchors.horizontalCenter: parent.horizontalCenter
                visible: !tile.shows
                text: tile.glyph
                color: tile.lit ? Services.Colors.ghost
                     : tile.warm ? Services.Colors.snow : Services.Colors.ash
                font.pixelSize: 24
                font.family: "Material Symbols Rounded"
                bottomPadding: 4
                Behavior on color { Widgets.ColorAnim { speed: Services.Sizes.msMicro } }
            }
            Text {
                textFormat: Text.PlainText
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: tile.label
                color: tile.lit || tile.warm ? Services.Colors.snow : Services.Colors.mist
                font.pixelSize: Services.Sizes.fsBody
                font.bold: true
                font.family: "JetBrainsMono NF"
                // A long name shrinks to fit rather than losing its middle:
                // "Notif...tions" is not a word, and the tile has one job.
                fontSizeMode: Text.HorizontalFit
                minimumPixelSize: 9
                elide: Text.ElideRight
                Behavior on color { Widgets.ColorAnim { speed: Services.Sizes.msMicro } }
            }
            Text {
                textFormat: Text.PlainText
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                // The shape it is wearing, which is the one thing about a
                // widget you cannot read off its own tile.
                text: tile.note
                visible: tile.note !== ""
                color: Services.Colors.ash
                font.pixelSize: Services.Sizes.fsMeta
                font.family: "JetBrainsMono NF"
                elide: Text.ElideMiddle
            }
        }

        // Out on the desktop.
        Rectangle {
            visible: tile.lit
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 6
            width: 16; height: 16; radius: 8
            color: Services.Colors.ghost
            Text {
                textFormat: Text.PlainText
                anchors.centerIn: parent
                text: "\ue5ca"
                color: Services.Colors.accentText
                font.pixelSize: 12
                font.bold: true
                font.family: "Material Symbols Rounded"
            }
        }

        scale: Services.Sizes.hoverScale(tileHover.containsMouse, tileHover.pressed)
        Behavior on scale { Widgets.Anim { speed: Services.Sizes.pillHoverMs } }

        MouseArea {
            id: tileHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: tile.picked()
        }
    }

    readonly property int cols: Math.max(1, Math.min(7, Math.floor((root.maxWidth + 8) / 104)))
    readonly property int blockW: root.cols * 96 + (root.cols - 1) * 8

    Rectangle {
        id: plate
        width: groups.width + 24
        height: groups.height + 24
        radius: Services.Sizes.panelR
        color: Services.Colors.surfacePanel
        border.width: Services.Colors.panelEdgeW
        border.color: Services.Colors.panelEdgeColor

        // A block per kind (Desktop.groupOrder), each under its name; pictures
        // close the tray with the tile that adds one.
        Column {
            id: groups
            x: 12
            y: 12
            width: root.blockW
            spacing: 12

            Repeater {
                model: Services.Desktop.groupOrder

                Column {
                    id: group
                    required property string modelData
                    readonly property var items: {
                        if (group.modelData === "picture") {
                            let out = []
                            for (const id of Services.Desktop.idsOf("image"))
                                out.push({ kind: "picture", id: id, glyph: "\ue3f4", label: Services.I18n.t("widget.picture") })
                            out.push({ kind: "add", id: "", glyph: "\ue145", label: Services.I18n.t("widget.picture") })
                            return out
                        }
                        return Services.Desktop.trayOrder.filter(w => w.group === group.modelData)
                            .map(w => ({ kind: "widget", id: w.id, glyph: w.glyph,
                                         label: Services.I18n.tr("desktop.w." + w.id, w.label) }))
                    }
                    width: groups.width
                    spacing: 6
                    visible: group.items.length > 0

                    Text {
                        textFormat: Text.PlainText
                        leftPadding: 2
                        text: Services.I18n.t("widget.group." + group.modelData)
                        color: Services.Colors.ash
                        font.pixelSize: Services.Sizes.fsMeta
                        font.bold: true
                        font.letterSpacing: 1
                        font.family: "JetBrainsMono NF"
                    }
                    Flow {
                        width: groups.width
                        spacing: 8
                        Repeater {
                            model: group.items
                            // One cell: a widget, a picture you have, or the way to add one.
                            Item {
                                id: cell
                                required property var modelData
                                readonly property var item: modelData
                                readonly property bool isPic: cell.item.kind === "picture"
                                readonly property string src: cell.isPic ? Services.Desktop.entry(cell.item.id).src : ""

                                width: 96
                                height: 72

                                Tile {
                                    anchors.fill: parent
                                    glyph: cell.item.glyph
                                    label: cell.item.label
                                    // A picture is on by existing, and "add" is a verb: neither is lit.
                                    lit: cell.item.kind === "widget" && Services.Desktop.shown(cell.item.id)
                                    note: cell.item.kind === "add" ? Services.I18n.t("widget.add")
                                        : cell.isPic ? ""
                                        : (lit ? Services.Desktop.styleLabel(cell.item.id) : "")
                                    // The photo itself, behind its own tile.
                                    thumb: cell.src
                                    onPicked: {
                                        if (cell.item.kind === "add")
                                            Services.Desktop.pickInto(Services.Desktop.add("image"))
                                        else if (cell.isPic)
                                            Services.Desktop.pickInto(cell.item.id)
                                        else
                                            Services.Desktop.toggle(cell.item.id)
                                    }
                            }

                            // Taking one away is the same cross as everywhere else in the shell.
                            Widgets.IconButton {
                                visible: cell.isPic
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 3
                                glyph: "\ue5cd"
                                tip: Services.I18n.t("tip.remove")
                                size: 22
                                onActivated: Services.Desktop.remove(cell.item.id)
                            }

                            }
                        }
                    }
                }
            }
        }
    }
}
