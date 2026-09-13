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
    transform: Translate { y: root.shown ? 0 : -12 }

    // A tile in the tray: the widget's face over its name, and under that the
    // shape it is wearing. Out = the accent fill, the same mark the shapes use;
    // idle is a bare plate that only brightens under the pointer.
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
            color: tile.lit ? Services.Colors.ghost : Services.Colors.fillRest
            gradient: Services.Prefs.useGradients && tile.lit
                ? Services.Colors.accentGradient : null
            Behavior on color { Widgets.ColorAnim { speed: Services.Sizes.msMicro } }
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
                color: tile.lit ? Services.Colors.accentText
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
                color: tile.lit ? Services.Colors.accentText
                     : tile.warm ? Services.Colors.snow : Services.Colors.mist
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
                color: tile.lit ? Services.Colors.accentText : Services.Colors.ash
                opacity: tile.lit ? 0.75 : 1
                font.pixelSize: Services.Sizes.fsMeta
                font.family: "JetBrainsMono NF"
                elide: Text.ElideMiddle
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

    Rectangle {
        id: plate
        width: grid.width + 24
        height: grid.height + 24
        radius: Services.Sizes.panelR
        color: Services.Colors.surfacePanel
        border.width: Services.Colors.panelEdgeW
        border.color: Services.Colors.fillOutline

        // One grid for everything -- the widgets, the pictures you have, and
        // the way to add another. Two grids left the last widget alone on a row
        // and the pictures stranded on another; a palette is a block or it is
        // nothing.
        Grid {
            id: grid
            x: 12
            y: 12
            columns: Math.max(1, Math.min(7, Math.floor((root.maxWidth + 8) / 104)))
            spacing: 8

            Repeater {
                model: {
                    let out = []
                    for (const w of Services.Desktop.trayOrder)
                        out.push({ kind: "widget", id: w.id, glyph: w.glyph, label: w.label })
                    for (const id of Services.Desktop.idsOf("image"))
                        out.push({ kind: "picture", id: id, glyph: "\ue3f4", label: Services.I18n.t("widget.picture") })
                    out.push({ kind: "add", id: "", glyph: "\ue145", label: Services.I18n.t("widget.picture") })
                    return out
                }

                Item {
                    id: cell
                    required property var modelData
                    readonly property bool isPic: cell.modelData.kind === "picture"
                    readonly property string src: cell.isPic
                        ? Services.Desktop.entry(cell.modelData.id).src : ""

                    width: 96
                    height: 72

                    Tile {
                        anchors.fill: parent
                        glyph: cell.modelData.glyph
                        label: cell.modelData.label
                        // A picture is on by existing, so the accent here would
                        // be saying something untrue; the "add" tile is a verb.
                        lit: cell.modelData.kind === "widget"
                             && Services.Desktop.shown(cell.modelData.id)
                        note: cell.modelData.kind === "add" ? "add"
                            : cell.isPic ? ""
                            : (lit ? Services.Desktop.styleLabel(cell.modelData.id) : "")
                        // The photo itself, behind its own tile: "Picture" over
                        // a filename told you nothing about which one it was.
                        thumb: cell.src
                        onPicked: {
                            if (cell.modelData.kind === "add")
                                Services.Desktop.pickInto(Services.Desktop.add("image"))
                            else if (cell.isPic)
                                Services.Desktop.pickInto(cell.modelData.id)
                            else
                                Services.Desktop.toggle(cell.modelData.id)
                        }
                    }

                    // Taking one away is the same cross as everywhere else in
                    // the shell; there is no bin in this project.
                    Widgets.IconButton {
                        visible: cell.isPic
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 3
                        glyph: "\ue5cd"
                        size: 22
                        onActivated: Services.Desktop.remove(cell.modelData.id)
                    }
                }
            }
        }
    }
}
