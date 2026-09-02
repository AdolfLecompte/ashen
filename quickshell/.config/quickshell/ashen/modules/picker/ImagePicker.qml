import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick

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
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: crumb.width - 240
                        text: Services.Picker.dir
                        color: Services.Colors.mist
                        font.pixelSize: Services.Sizes.fsBody
                        font.family: "JetBrainsMono NF"
                        elide: Text.ElideMiddle
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

                // ── What is in this folder ──────────────────────────
                Flickable {
                    anchors.top: crumb.bottom
                    anchors.topMargin: 14
                    anchors.left: placesWrap.right
                    anchors.leftMargin: 16
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.rightMargin: 20
                    anchors.bottomMargin: 20
                    contentHeight: grid.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Grid {
                        id: grid
                        width: parent.width
                        columns: Math.max(1, Math.floor(width / 148))
                        spacing: 10

                        // Walking into a folder is a new set of pictures, not
                        // the same ones rearranged: the grid goes out, the
                        // scan lands, and it comes back.
                        opacity: Services.Picker.scanning ? 0 : 1
                        Behavior on opacity { NumberAnimation { duration: Services.Sizes.msStandard; easing.type: Services.Sizes.easeOut } }
                        transform: Translate { y: Services.Picker.scanning ? 8 : 0
                            Behavior on y { NumberAnimation { duration: Services.Sizes.msStandard; easing.type: Services.Sizes.easeOut } } }

                        // Folders first, as plates with their name: a picture
                        // grid you cannot walk out of is a dead end.
                        Repeater {
                            model: Services.Picker.folders

                            Rectangle {
                                required property string modelData
                                required property int index
                                width: 138
                                height: 96
                                radius: Services.Sizes.cardR
                                color: Services.Colors.fillInset

                                opacity: card.stage(2 + index)
                                transform: Translate { y: (1 - card.stage(2 + index)) * 12 }

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
                                        width: 118
                                        horizontalAlignment: Text.AlignHCenter
                                        text: Services.Picker.nameOf(modelData)
                                        color: dirHover.containsMouse ? Services.Colors.snow
                                                                      : Services.Colors.mist
                                        font.pixelSize: Services.Sizes.fsMeta
                                        font.family: "JetBrainsMono NF"
                                        elide: Text.ElideMiddle
                                    }
                                }

                                scale: Services.Sizes.hoverScale(dirHover.containsMouse, dirHover.pressed)
                                Behavior on scale { NumberAnimation { duration: Services.Sizes.pillHoverMs; easing.type: Services.Sizes.easeOut } }

                                MouseArea {
                                    id: dirHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Services.Picker.go(modelData)
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
                                width: 138
                                height: 96

                                // Behind the folders in the same run, so the
                                // whole grid arrives as one sweep rather than
                                // two.
                                readonly property real beat:
                                    card.stage(2 + Services.Picker.folders.length + shot.index)
                                opacity: shot.beat
                                transform: Translate { y: (1 - shot.beat) * 12 }

                                ClippingRectangle {
                                    anchors.fill: parent
                                    radius: Services.Sizes.cardR
                                    color: Services.Colors.fillInset

                                    Image {
                                        anchors.fill: parent
                                        source: "file://" + shot.full
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                        sourceSize.width: 276
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

                                scale: Services.Sizes.hoverScale(fileHover.containsMouse, fileHover.pressed)
                                Behavior on scale { NumberAnimation { duration: Services.Sizes.pillHoverMs; easing.type: Services.Sizes.easeOut } }

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

                    // Nothing here, said plainly rather than left blank.
                    Text {
                        anchors.centerIn: parent
                        visible: !Services.Picker.scanning
                                 && Services.Picker.files.length === 0
                                 && Services.Picker.folders.length === 0
                        text: "No pictures in this folder"
                        color: Services.Colors.ash
                        font.pixelSize: Services.Sizes.fsBody
                        font.family: "JetBrainsMono NF"
                    }
                }
            }
        }
    }
}
