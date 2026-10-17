import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import QtQuick

import "root:/modules/desktop"
import "root:/modules/widgets" as Widgets
import "root:/services" as Services

// What is playing, and the buttons to steer it. The full one is the card the
// panel and the lock screen already wear; the compact one wants a corner. The
// sound drawn large is the visualizer's, the words are the lyrics widget's.
DesktopWidget {
    id: root
    wid: "media"
    // The one piece of desktop furniture you actually press: the layer cuts a
    // hole for this box so its transport works without arranging first.
    wantsInput: true

    // Its own sticky read, so the compact shape does not have to mount
    // the whole card to know what is on. Same drop-guard as MediaCard: MPRIS
    // goes null for a few ms between tracks.
    readonly property var livePlayer: Services.Media.player
    property var player: null
    onLivePlayerChanged: {
        if (root.livePlayer !== null) { drop.stop(); root.player = root.livePlayer }
        else drop.restart()
    }
    Timer { id: drop; interval: 400; onTriggered: root.player = null }

    // Nothing playing at all, said rather than labelled -- picked on the drop,
    // not per frame.
    property string idleLine: Services.Voice.pick("media.quiet")
    onPlayerChanged: if (root.player === null) root.idleLine = Services.Voice.pick("media.quiet")
    // Picked at creation, it came back empty whenever the phrase bank loaded
    // after the widget did -- which it does at login -- and was only asked
    // again when a player went away.
    Connections {
        target: Services.Voice
        function onBaseChanged() { if (root.idleLine === "") root.idleLine = Services.Voice.pick("media.quiet") }
        function onBankChanged() { if (root.idleLine === "") root.idleLine = Services.Voice.pick("media.quiet") }
    }

    readonly property string title: root.player ? (root.player.trackTitle || "") : ""
    readonly property string artist: root.player ? (root.player.trackArtist || "") : ""
    readonly property string art: Services.Media.art

    component Cover: ClippingRectangle {
        property alias source: img.source
        radius: Services.Sizes.cardR
        color: Services.Colors.fillInset

        Image {
            id: img
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
        }
        Text {
            textFormat: Text.PlainText
            anchors.centerIn: parent
            visible: img.status !== Image.Ready
            text: ""
            font.family: "Material Symbols Rounded"
            font.pixelSize: parent.width * 0.4
            color: Services.Colors.ash
        }
    }

    Component {
        id: fullShape
        Column {
            spacing: 12
            Widgets.MediaCard {
                followSwitch: !root.managed
                id: card
                // Its own column of bars would say the same thing as the strip
                // below, in a tenth of the room.
                showSpectrum: false
            }
            Spectrum {
                width: card.width
                height: 74
                live: root.live
                // The accent straight, like the panel's column: mixed into the
                // plate it read as a picture of a visualiser rather than one.
                color_: Services.Colors.ghost
            }
        }
    }

    Component {
        id: compactShape
        Row {
            spacing: 12

            Cover {
                width: 64; height: 64
                source: root.art
                anchors.verticalCenter: parent.verticalCenter
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                width: 220

                Text {
                    textFormat: Text.PlainText
                    width: parent.width
                    text: root.title !== "" ? root.title : root.idleLine
                    color: Services.Colors.snow
                    font.pixelSize: Services.Sizes.fsInput
                    font.bold: true
                    font.family: "JetBrainsMono NF"
                    elide: Text.ElideRight
                }
                Text {
                    textFormat: Text.PlainText
                    width: parent.width
                    text: root.artist
                    color: Services.Colors.mist
                    font.pixelSize: Services.Sizes.fsBody
                    font.family: "JetBrainsMono NF"
                    elide: Text.ElideRight
                }
                Row {
                    spacing: 6
                    topPadding: 4
                    Widgets.CtlChip {
                        size: 28; glyph: ""
                        onTriggered: Services.Media.previous()
                    }
                    Widgets.CtlChip {
                        size: 28
                        glyph: (root.player && root.player.isPlaying) ? "" : ""
                        active: root.player !== null && root.player.isPlaying
                        onTriggered: Services.Media.playPause()
                    }
                    Widgets.CtlChip {
                        size: 28; glyph: ""
                        onTriggered: Services.Media.next()
                    }
                }
            }
        }
    }

    Loader {
        sourceComponent: root.style === "compact" ? compactShape
                       : fullShape
    }
}
