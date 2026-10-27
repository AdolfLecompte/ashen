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
            Widgets.Anim {}
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

                // The exchange when you change folder. Keyed on the LISTING, not
                // the path: the path changes on the click and the pictures only
                // arrive when the folder has been read, so sliding on the path
                // changed the grid twice -- once on the slide, again when the
                // list landed. The grid shows what the swap last committed.
                // Vertical, like the grid it moves: you walk down into a folder.
                Widgets.SlideSwap {
                    id: folderSwap
                    axis: "vertical"
                    travel: 18
                    key: Services.Picker.listed
                    keyDir: Services.Picker.step
                    onCommit: {
                        pickBody.shownFolders = Services.Picker.folders
                        pickBody.shownFiles = Services.Picker.files
                    }
                }
                id: pickBody
                property var shownFolders: []
                property var shownFiles: []

                // ── What you are choosing, and where you are ────────
                // The panel header every card wears (USB, sound): the glyph in
                // its tile, the title, and the path under it as the detail.
                Row {
                    id: crumb
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: tools.left
                    anchors.margins: 20
                    anchors.rightMargin: 12
                    spacing: 12

                    Rectangle {
                        width: 40
                        height: 40
                        radius: Services.Sizes.innerR
                        color: Services.Colors.fillLine
                        Text {
                            textFormat: Text.PlainText
                            anchors.centerIn: parent
                            text: Services.Picker.purpose === "profile" ? "\ue853"
                                : Services.Picker.purpose.indexOf("widget:") === 0 ? "\ue251"
                                : "\ue413"
                            color: Services.Colors.ghost
                            font.pixelSize: 22
                            font.family: "Material Symbols Rounded"
                        }
                    }
                    // WHAT you are choosing, over where you are looking: the
                    // same box answers for the face and for a widget's picture.
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: crumb.width - 52
                        spacing: 2

                        Text {
                            textFormat: Text.PlainText
                            width: parent.width
                            text: Services.Picker.purpose === "profile"
                                  ? Services.I18n.t("picker.profile")
                                  : Services.Picker.purpose.indexOf("widget:") === 0
                                    ? Services.I18n.t("picker.widget")
                                    : Services.I18n.t("picker.title")
                            color: Services.Colors.snow
                            font.pixelSize: Services.Sizes.fsCardTitle
                            font.bold: true
                            font.family: "JetBrainsMono NF"
                            elide: Text.ElideRight
                        }
                        Text {
                            textFormat: Text.PlainText
                            width: parent.width
                            text: Services.Picker.dir.replace(Services.Paths.home, "~")
                            color: Services.Colors.ash
                            font.pixelSize: Services.Sizes.fsMeta
                            font.family: "JetBrainsMono NF"
                            elide: Text.ElideMiddle
                        }
                    }
                }
                Row {
                    id: tools
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 20
                    anchors.topMargin: 26
                    spacing: 6
                    Widgets.IconButton {
                        glyph: "\ue5d8"
                        tip: Services.I18n.t("tip.up")
                        size: 28
                        onActivated: Services.Picker.up()
                    }
                    Widgets.IconButton {
                        glyph: "\ue5cd"
                        tip: Services.I18n.t("tip.close")
                        size: 28
                        onActivated: Services.Picker.close()
                    }
                }

                // ── The places worth starting from ──────────────────
                Item {
                    id: placesWrap
                    anchors.top: crumb.bottom
                    anchors.topMargin: 14
                    anchors.left: parent.left
                    anchors.leftMargin: 20
                    width: 170
                    height: places.implicitHeight + 16

                    // The rail is a plate, like every group inside a panel.
                    Rectangle {
                        anchors.fill: parent
                        radius: Services.Sizes.cardLgR
                        color: Services.Colors.plate
                        opacity: card.stage(0)
                    }

                    // Which row the accent is standing on.
                    property Item hereRow: null

                    // One accent that TRAVELS between the places, rather than
                    // each row painting its own plate the instant you press it.
                    // Same sliding indicator the wallpaper picker's tabs wear.
                    Rectangle {
                        visible: placesWrap.hereRow !== null
                        x: places.x
                        y: places.y + (placesWrap.hereRow ? placesWrap.hereRow.y : 0)
                        height: placesWrap.hereRow ? placesWrap.hereRow.height : 0
                        width: places.width
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
                    x: 8
                    y: 8
                    width: parent.width - 16
                    spacing: 2

                    Repeater {
                        model: Services.Picker.startDirs

                        Rectangle {
                            id: placeRow
                            required property var modelData
                            required property int index
                            width: places.width
                            height: 36

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

                            readonly property color ink: here ? Services.Colors.accentText
                                : placeHover.containsMouse ? Services.Colors.snow
                                                           : Services.Colors.mist
                            Row {
                                anchors.left: parent.left
                                anchors.leftMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 10
                                Text {
                                    textFormat: Text.PlainText
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: ({ "Pictures": "\ue251", "Wallpapers": "\ue1bc",
                                             "Downloads": "\ue171", "Home": "\ue88a" })[modelData.label] || "\ue2c7"
                                    color: placeRow.here ? Services.Colors.accentText
                                         : placeHover.containsMouse ? Services.Colors.snow
                                                                    : Services.Colors.ghost
                                    font.pixelSize: 18
                                    font.family: "Material Symbols Rounded"
                                }
                                Text {
                                    textFormat: Text.PlainText
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: Services.I18n.tr("picker.dir." + Services.I18n.slug(modelData.label), modelData.label)
                                    color: placeRow.ink
                                    font.pixelSize: Services.Sizes.fsBody
                                    font.family: "JetBrainsMono NF"
                                }
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

                // ── What is in this folder ──────────────────────────
                Flickable {
                    anchors.top: crumb.bottom
                    anchors.topMargin: 14
                    anchors.left: placesWrap.right
                    anchors.leftMargin: 18
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.rightMargin: 20
                    anchors.bottomMargin: 20
                    contentHeight: stack.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    // A folder of fifty pictures ends mid-row at the bottom of
                    // the card with nothing saying there is more. Same thin bar
                    // the Settings tabs use.
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded; width: 4 }

                    Column {
                        id: stack
                        width: parent.width
                        spacing: 14

                        // Walking into a folder is a new set of pictures, not
                        // the same ones rearranged, so it SWEEPS the way you
                        // walked. Same primitive every other exchange uses.
                        opacity: folderSwap.fade
                        transform: Translate { y: folderSwap.offY }

                    // Folders first, as rows in the USB panel's language: the
                    // folder in its tile, the name beside it. A picture grid
                    // you cannot walk out of is a dead end.
                    Grid {
                        id: dirs
                        width: parent.width
                        visible: pickBody.shownFolders.length > 0
                        columns: Math.max(1, Math.floor(width / 200))
                        spacing: 8
                        readonly property int cellW: Math.floor(
                            (dirs.width - (dirs.columns - 1) * dirs.spacing) / dirs.columns)

                        Repeater {
                            model: pickBody.shownFolders

                            Item {
                                id: dirCell
                                required property string modelData
                                required property int index
                                width: dirs.cellW
                                height: 52

                                opacity: card.stage(2 + index)
                                transform: Translate { y: (1 - card.stage(2 + index)) * 12 }

                                // Grows into its cell, never past it: the view
                                // clips to scroll.
                                property real inset: dirHover.containsMouse ? 0 : 3
                                Behavior on inset {
                                    NumberAnimation { duration: Services.Sizes.pillHoverMs
                                                      easing.type: Services.Sizes.easeOut }
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: dirCell.inset
                                    radius: Services.Sizes.cardR
                                    color: Services.Colors.plate

                                    Row {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 8
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 10
                                        Rectangle {
                                            width: 32
                                            height: 32
                                            radius: Services.Sizes.innerR
                                            color: Services.Colors.fillLine
                                            Text {
                                                textFormat: Text.PlainText
                                                anchors.centerIn: parent
                                                text: dirHover.containsMouse ? "\ue2c8" : "\ue2c7"
                                                color: dirHover.containsMouse ? Services.Colors.snow
                                                                              : Services.Colors.ghost
                                                font.pixelSize: 18
                                                font.family: "Material Symbols Rounded"
                                            }
                                        }
                                        Text {
                                            textFormat: Text.PlainText
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: dirs.cellW - 66
                                            text: Services.Picker.nameOf(dirCell.modelData)
                                            color: dirHover.containsMouse ? Services.Colors.snow
                                                                          : Services.Colors.mist
                                            font.pixelSize: Services.Sizes.fsBody
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
                    }

                    Grid {
                        id: grid
                        width: parent.width
                        visible: pickBody.shownFiles.length > 0
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

                        // The pictures, as themselves.
                        Repeater {
                            model: pickBody.shownFiles

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
                                    card.stage(2 + pickBody.shownFolders.length + shot.index)
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
                                        // The cached copy when there is one. Picked
                                        // once, and switched to the copy later only if
                                        // the original has not finished decoding: a
                                        // tile that is already drawn does not blink.
                                        property string chosen: ""
                                        function choose() {
                                            const t = Services.Picker.thumbs[shot.full]
                                            if (chosen === "") chosen = t || ("file://" + shot.full)
                                            else if (t && status !== Image.Ready) chosen = t
                                        }
                                        Component.onCompleted: choose()
                                        Connections {
                                            target: Services.Picker
                                            function onThumbsChanged() { thumb.choose() }
                                        }
                                        source: chosen
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
                                        Behavior on opacity { Widgets.Anim { speed: Services.Sizes.msMicro } }

                                        Text {
                                            textFormat: Text.PlainText
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

                    }

                    // Nothing here, said plainly rather than left blank -- and
                    // while the folder is still being read, that is said too:
                    // an empty grid and a folder with no pictures in it look
                    // exactly the same, and only one of them is an answer.
                    Text {
                        textFormat: Text.PlainText
                        anchors.centerIn: parent
                        // Only over an empty grid: over the last folder it flashed
                        // for the moment the next one took to read.
                        visible: pickBody.shownFiles.length === 0
                                 && pickBody.shownFolders.length === 0
                        text: Services.Picker.scanning ? Services.I18n.t("picker.loading")
                                                       : Services.I18n.t("picker.noPictures")
                        color: Services.Colors.ash
                        font.pixelSize: Services.Sizes.fsBody
                        font.family: "JetBrainsMono NF"
                        opacity: card.stage(1)
                        Behavior on opacity { Widgets.Anim { speed: Services.Sizes.msMicro } }
                    }
                }
            }
        }
    }
}
