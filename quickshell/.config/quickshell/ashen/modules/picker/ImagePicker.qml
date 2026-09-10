import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls

import "root:/modules/widgets" as Widgets
import "root:/services" as Services

// The shell's own way of choosing a picture: the folders down one side, what
// is in the current one as a grid of the pictures themselves. A file browser
// that shows filenames is asking you to remember which photo IMG_2231 was.
PanelWindow {
    id: win

    anchors { top: true; left: true; right: true; bottom: true }
    screen: Services.Screens.active
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    readonly property bool shown: Services.Picker.visible
    visible: win.shown || closeDelay.running
    onShownChanged: if (!win.shown) closeDelay.restart()
    Timer { id: closeDelay; interval: card.closeMs }

    WlrLayershell.keyboardFocus: win.shown ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    // The desktop stands down while you choose. Without it the card floated over
    // whatever was open at full brightness and read as a screenshot pasted onto
    // the screen rather than a thing you are being asked to answer. Under the
    // click-away area (z -2 against its -1), so the dim is not also a lid over
    // the one gesture that closes it.
    Rectangle {
        anchors.fill: parent
        z: -2
        color: Services.Colors.scrim
        opacity: win.shown ? 1 : 0
        Behavior on opacity {
            NumberAnimation { duration: Services.Sizes.msStandard; easing.type: Services.Sizes.easeOut }
        }
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        enabled: Services.Picker.visible
        onClicked: Services.Picker.close()
    }
    FocusScope {
        anchors.fill: parent
        focus: win.shown
        Keys.onEscapePressed: Services.Picker.close()
    }

    Widgets.PanelHost {
        id: card
        shown: win.shown
        restSide: "center"
        openW: Math.min(1040, win.width - 120)
        openH: Math.min(680, win.height - 140)
        cardRadius: Services.Sizes.panelR

        body: Component {
            Item {
                anchors.fill: parent

                // The exchange when you change folder. Keyed on the path, and
                // the direction comes from whoever moved: Picker.step is 1 for
                // walking in, -1 for the way back up.
                Widgets.SlideSwap {
                    id: folderSwap
                    axis: "horizontal"
                    travel: 16
                    key: Services.Picker.dir
                    keyDir: Services.Picker.step
                }

                // ── Where you are, and the way back up ──────────────
                Row {
                    id: crumb
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 20
                    spacing: 10

                    Widgets.IconButton {
                        anchors.verticalCenter: parent.verticalCenter
                        glyph: "\ue5d8"
                        size: 28
                        onActivated: Services.Picker.up()
                    }
                    // WHAT you are choosing, over where you are looking. The
                    // same box answers two different questions -- the lock
                    // screen's face and a wallpaper widget's picture -- and it
                    // used to open with a path and nothing else, so the only
                    // way to know which one had asked was to remember.
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: crumb.width - 240
                        spacing: 1

                        Text {
                            width: parent.width
                            text: Services.Picker.purpose === "profile"
                                  ? Services.I18n.t("picker.profile")
                                  : Services.Picker.purpose.indexOf("widget:") === 0
                                    ? Services.I18n.t("picker.widget")
                                    : Services.I18n.t("picker.title")
                            color: Services.Colors.snow
                            font.pixelSize: Services.Sizes.fsInput
                            font.bold: true
                            font.family: "JetBrainsMono NF"
                            elide: Text.ElideRight
                        }
                        Text {
                            width: parent.width
                            text: Services.Picker.dir
                            color: Services.Colors.ash
                            font.pixelSize: Services.Sizes.fsMeta
                            font.family: "JetBrainsMono NF"
                            elide: Text.ElideMiddle
                        }
                    }
                }
                Widgets.IconButton {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 20
                    glyph: "\ue5cd"
                    size: 28
                    onActivated: Services.Picker.close()
                }

                // ── The places worth starting from ──────────────────
                Item {
                    id: placesWrap
                    anchors.top: crumb.bottom
                    anchors.topMargin: 14
                    anchors.left: parent.left
                    anchors.leftMargin: 20
                    width: 150
                    height: places.implicitHeight

                    // Which row the accent is standing on.
                    property Item hereRow: null

                    // One accent that TRAVELS between the places, rather than
                    // each row painting its own plate the instant you press it.
                    // Same sliding indicator the wallpaper picker's tabs wear.
                    Rectangle {
                        visible: placesWrap.hereRow !== null
                        y: placesWrap.hereRow ? placesWrap.hereRow.y : 0
                        height: placesWrap.hereRow ? placesWrap.hereRow.height : 0
                        width: placesWrap.width
                        radius: Services.Sizes.innerR
                        color: Services.Colors.ghost
                        gradient: Services.Prefs.useGradients ? Services.Colors.accentGradient : null
                        // Comes in with the list it stands on, not before it.
                        opacity: card.stage(0)
                        Behavior on y { SmoothedAnimation { duration: Services.Sizes.msPronounced } }
                        Behavior on height { SmoothedAnimation { duration: Services.Sizes.msStandard } }
                    }

                Column {
                    id: places
                    width: parent.width
                    spacing: 2

                    Repeater {
                        model: Services.Picker.startDirs

                        Rectangle {
                            id: placeRow
                            required property var modelData
                            required property int index
                            width: places.width
                            height: 30

                            // Arrives with the card, one after the next: a list
                            // that is simply there the instant the box opens
                            // reads as a screenshot of a list.
                            opacity: card.stage(index)
                            transform: Translate { x: (1 - card.stage(index)) * -10 }
                            readonly property bool here: Services.Picker.dir === modelData.path
                            // The plate is the sliding indicator above, never
                            // the row itself.
                            color: "transparent"
                            onHereChanged: if (here) placesWrap.hereRow = placeRow
                            Component.onCompleted: if (here) placesWrap.hereRow = placeRow

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.label
                                color: parent.here ? Services.Colors.accentText
                                     : placeHover.containsMouse ? Services.Colors.snow
                                                                : Services.Colors.mist
                                font.pixelSize: Services.Sizes.fsBody
                                font.family: "JetBrainsMono NF"
                            }
                            MouseArea {
                                id: placeHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Services.Picker.go(modelData.path)
                            }
                        }
                    }
                }
                }

                // The places are a rail, not the first column of the grid: one
                // line says so, and the grid stops looking like it starts at
                // the card's left edge and then thinks better of it.
                Rectangle {
                    anchors.top: crumb.bottom
                    anchors.topMargin: 14
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 20
                    anchors.left: placesWrap.right
                    anchors.leftMargin: 8
                    width: 1
                    color: Services.Colors.fillLine
                    opacity: card.stage(1)
                }

                // ── What is in this folder ──────────────────────────
                Flickable {
                    anchors.top: crumb.bottom
                    anchors.topMargin: 14
                    anchors.left: placesWrap.right
                    anchors.leftMargin: 24
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.rightMargin: 20
                    anchors.bottomMargin: 20
                    contentHeight: grid.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    // A folder of fifty pictures ends mid-row at the bottom of
                    // the card with nothing saying there is more. Same thin bar
                    // the Settings tabs use.
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded; width: 4 }

                    Grid {
                        id: grid
                        width: parent.width
                        columns: Math.max(1, Math.floor(width / 148))
                        spacing: 10
                        // The tiles SHARE OUT the row rather than each taking a
                        // fixed 138: whatever a whole number of columns did not
                        // use piled up as a column of dead air on the right, so
                        // the grid looked like it had failed to reach the edge
                        // of its own card. Everything reads these two.
                        readonly property int cellW: Math.floor(
                            (grid.width - (grid.columns - 1) * grid.spacing) / grid.columns)
                        readonly property int cellH: Math.round(grid.cellW * 96 / 138)

                        // Walking into a folder is a new set of pictures, not
                        // the same ones rearranged, so it SWEEPS the way you
                        // walked: out towards where you came from, in from
                        // where you went. It used to nudge 8 px down and back
                        // -- out and in on the same side, which says a list
                        // reloaded, not that you moved. Same primitive every
                        // other exchange in the shell uses.
                        opacity: folderSwap.fade
                        transform: Translate { x: folderSwap.offX }

                        // Folders first, as plates with their name: a picture
                        // grid you cannot walk out of is a dead end.
                        Repeater {
                            model: Services.Picker.folders

                            Item {
                                id: dirCell
                                required property string modelData
                                required property int index
                                width: grid.cellW
                                height: grid.cellH

                                opacity: card.stage(2 + index)
                                transform: Translate { y: (1 - card.stage(2 + index)) * 12 }

                                // Hover grows the plate INTO its cell rather
                                // than scaling it past one. A scaled tile
                                // overlapped its neighbours and, on the rows at
                                // the top and bottom of the view, was cut off
                                // by the Flickable's own clipping -- the grid
                                // has to clip to scroll, so nothing in it may
                                // grow outside its slot. The cell keeps the
                                // room; only what is drawn in it changes size.
                                property real inset: dirHover.containsMouse ? 0 : 4
                                Behavior on inset {
                                    NumberAnimation { duration: Services.Sizes.pillHoverMs
                                                      easing.type: Services.Sizes.easeOut }
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: dirCell.inset
                                    radius: Services.Sizes.cardR
                                    color: Services.Colors.fillInset

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "\ue2c7"
                                        font.family: "Material Symbols Rounded"
                                        font.pixelSize: 26
                                        color: dirHover.containsMouse ? Services.Colors.snow
                                                                      : Services.Colors.ghost
                                    }
                                    Text {
                                        width: grid.cellW - 20
                                        horizontalAlignment: Text.AlignHCenter
                                        text: Services.Picker.nameOf(modelData)
                                        color: dirHover.containsMouse ? Services.Colors.snow
                                                                      : Services.Colors.mist
                                        font.pixelSize: Services.Sizes.fsMeta
                                        font.family: "JetBrainsMono NF"
                                        elide: Text.ElideMiddle
                                    }
                                }
                                }

                                MouseArea {
                                    id: dirHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Services.Picker.go(dirCell.modelData)
                                }
                            }
                        }

                        // The pictures, as themselves.
                        Repeater {
                            model: Services.Picker.files

                            Item {
                                id: shot
                                required property string modelData
                                required property int index
                                readonly property string full: modelData
                                width: grid.cellW
                                height: grid.cellH

                                // Behind the folders in the same run, so the
                                // whole grid arrives as one sweep rather than
                                // two.
                                readonly property real beat:
                                    card.stage(2 + Services.Picker.folders.length + shot.index)
                                opacity: shot.beat
                                transform: Translate { y: (1 - shot.beat) * 12 }

                                // Grows into its cell, never past it: see the
                                // folder plate above for why scaling was wrong
                                // inside a grid that has to clip to scroll.
                                property real inset: fileHover.containsMouse ? 0 : 4
                                Behavior on inset {
                                    NumberAnimation { duration: Services.Sizes.pillHoverMs
                                                      easing.type: Services.Sizes.easeOut }
                                }

                                ClippingRectangle {
                                    anchors.fill: parent
                                    anchors.margins: shot.inset
                                    radius: Services.Sizes.cardR
                                    color: Services.Colors.fillInset

                                    // Each picture arrives when it is decoded,
                                    // not when its tile does. A folder of thirty
                                    // wallpapers decodes for a second or two,
                                    // and drawn straight the grid was a field of
                                    // empty plates filling in at random -- which
                                    // reads as something broken rather than
                                    // something loading. The plate underneath is
                                    // the placeholder; the picture fades onto it.
                                    Image {
                                        id: thumb
                                        anchors.fill: parent
                                        source: "file://" + shot.full
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                        sourceSize.width: 276
                                        opacity: thumb.status === Image.Ready ? 1 : 0
                                        Behavior on opacity {
                                            NumberAnimation { duration: Services.Sizes.msStandard
                                                              easing.type: Services.Sizes.easeOut }
                                        }
                                    }
                                    // The name only under the pointer: it is
                                    // the picture you are choosing, not the file.
                                    Rectangle {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.bottom: parent.bottom
                                        height: 22
                                        color: Services.Colors.scrim
                                        opacity: fileHover.containsMouse ? 1 : 0
                                        Behavior on opacity { NumberAnimation { duration: Services.Sizes.msMicro } }

                                        Text {
                                            anchors.fill: parent
                                            anchors.leftMargin: 6
                                            anchors.rightMargin: 6
                                            verticalAlignment: Text.AlignVCenter
                                            text: Services.Picker.nameOf(modelData)
                                            color: Services.Colors.snow
                                            font.pixelSize: Services.Sizes.fsMeta
                                            font.family: "JetBrainsMono NF"
                                            elide: Text.ElideMiddle
                                        }
                                    }
                                }

                                MouseArea {
                                    id: fileHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Services.Picker.choose(shot.full)
                                }
                            }
                        }
                    }

                    // Nothing here, said plainly rather than left blank -- and
                    // while the folder is still being read, that is said too:
                    // an empty grid and a folder with no pictures in it look
                    // exactly the same, and only one of them is an answer.
                    Text {
                        anchors.centerIn: parent
                        visible: Services.Picker.scanning
                                 || (Services.Picker.files.length === 0
                                     && Services.Picker.folders.length === 0)
                        text: Services.Picker.scanning ? Services.I18n.t("picker.loading")
                                                       : Services.I18n.t("picker.noPictures")
                        color: Services.Colors.ash
                        font.pixelSize: Services.Sizes.fsBody
                        font.family: "JetBrainsMono NF"
                        opacity: card.stage(1)
                        Behavior on opacity { NumberAnimation { duration: Services.Sizes.msMicro } }
                    }
                }
            }
        }
    }
}
