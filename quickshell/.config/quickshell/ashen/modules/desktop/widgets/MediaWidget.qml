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
    // The words open beside the card: the plate eases out to them.
    easeSize: true

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
            text: "\ue405"
            font.family: "Material Symbols Rounded"
            font.pixelSize: parent.width * 0.4
            color: Services.Colors.ash
        }
    }

    // The words beside the card: opened by the card's lyric chip, only on the
    // desktop (the lock screen lays its columns out itself).
    readonly property bool wordsOpen: root.managed && Services.Prefs.mediaWidgetLyrics
                                      && Services.Lyrics.has
    // The compact shape (also the lock's) folds one line out under itself.
    readonly property bool lineOpen: root.style === "compact" && Services.Prefs.mediaWidgetLyrics
                                     && Services.Lyrics.has

    // MPRIS only pushes position on a seek, so it is asked for while the words
    // are out and the desktop is being looked at.
    property real position: 0
    Timer {
        interval: 250
        repeat: true
        running: (root.wordsOpen || root.lineOpen) && root.live && root.player !== null
        onTriggered: if (root.player) { root.player.positionChanged(); root.position = root.player.position }
    }

    Component {
        id: fullShape
        Row {
            Column {
                id: main
                spacing: 12
                Widgets.MediaCard {
                    followSwitch: !root.managed
                    id: card
                    // Its own column of bars would say the same thing as the strip
                    // below, in a tenth of the room.
                    showSpectrum: false
                    lyricChip: root.managed
                    lyricsActive: Services.Prefs.mediaWidgetLyrics
                    onLyricsPressed: Services.Prefs.mediaWidgetLyrics = !Services.Prefs.mediaWidgetLyrics
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

            // Takes its room at once, so the plate eases there in one motion;
            // what is drawn is revealed by `reveal` on the plate's beat.
            Item {
                id: side
                readonly property real gap: 24
                // ~300 for the words, rounded so the open plate keeps the same
                // grid slack as the closed one: the card then stays put.
                readonly property real room: root.toGrid(main.width + root.padH + side.gap + 300)
                                             - root.toGrid(main.width + root.padH)
                readonly property real wordsW: side.room - side.gap
                property real amt: root.wordsOpen ? 1 : 0
                Behavior on amt { Widgets.Anim { speed: Services.Sizes.msPanel } }
                width: root.wordsOpen ? side.room : 0
                height: main.height

                readonly property int live: Services.Lyrics.indexAt(root.position + 0.35)
                // The text reads the committed index, so the new line does not
                // both leave and arrive.
                Widgets.SlideSwap {
                    id: lineSlide
                    index: side.live
                    axis: "vertical"
                    travel: 18
                    onCommit: side.at = side.live
                }
                property int at: -1
                Component.onCompleted: side.at = side.live
                function lineOf(i) {
                    const l = Services.Lyrics.lines
                    return i >= 0 && i < l.length ? l[i].text : ""
                }

                Item {
                    id: reveal
                    width: side.room * side.amt
                    height: parent.height
                    visible: side.amt > 0.01
                    clip: true

                    Rectangle {
                        x: side.gap / 2 - width / 2
                        anchors.verticalCenter: parent.verticalCenter
                        width: 1
                        height: parent.height * 0.6
                        color: Services.Colors.fillLine
                        opacity: side.amt
                    }

                    Column {
                        x: side.gap
                        anchors.verticalCenter: parent.verticalCenter
                        width: side.wordsW
                        spacing: 14
                        opacity: lineSlide.fade * Math.max(0, (side.amt - 0.4) / 0.6)
                        transform: Translate { y: lineSlide.offY }
                        Text {
                            textFormat: Text.PlainText
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                            text: side.lineOf(side.at - 1)
                            color: Services.Colors.ash
                            font.pixelSize: Services.Sizes.fsInput
                            font.family: "JetBrainsMono NF"
                        }
                        Text {
                            textFormat: Text.PlainText
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            maximumLineCount: 3
                            elide: Text.ElideRight
                            text: side.at < 0 ? "…" : side.lineOf(side.at)
                            color: Services.Colors.snow
                            font.pixelSize: Services.Sizes.fsSectionTitle
                            font.bold: true
                            font.family: "JetBrainsMono NF"
                        }
                        Text {
                            textFormat: Text.PlainText
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                            text: side.lineOf(side.at + 1)
                            color: Services.Colors.ash
                            font.pixelSize: Services.Sizes.fsInput
                            font.family: "JetBrainsMono NF"
                        }
                    }
                }
            }
        }
    }

    Component {
        id: compactShape
        Column {
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
                        size: 28; glyph: "\ue045"
                        onTriggered: Services.Media.previous()
                    }
                    Widgets.CtlChip {
                        size: 28
                        glyph: (root.player && root.player.isPlaying) ? "\ue034" : "\ue037"
                        active: root.player !== null && root.player.isPlaying
                        onTriggered: Services.Media.playPause()
                    }
                    Widgets.CtlChip {
                        size: 28; glyph: "\ue044"
                        onTriggered: Services.Media.next()
                    }
                    // The words, folded out under the card. Opens in width so
                    // the row glides, and only when the track has any.
                    Widgets.CtlChip {
                        property real amt: Services.Lyrics.has ? 1 : 0
                        Behavior on amt { Widgets.Anim { speed: Services.Sizes.msPronounced } }
                        visible: amt > 0.01
                        width: 28 * amt
                        clip: true
                        opacity: amt
                        size: 28; glyph: "\uec0b"
                        active: Services.Prefs.mediaWidgetLyrics
                        onTriggered: Services.Prefs.mediaWidgetLyrics = !Services.Prefs.mediaWidgetLyrics
                    }
                }
            }
        }

        // One line, the one being sung, unfolding downwards.
        Item {
            id: fold
            property real amt: root.lineOpen ? 1 : 0
            Behavior on amt { Widgets.Anim { speed: Services.Sizes.msPanel } }
            width: parent.width
            height: 30 * fold.amt
            visible: fold.amt > 0.01
            clip: true
            Binding { target: root; property: "foldH"; value: fold.height }
            Binding { target: root; property: "foldTo"; value: root.lineOpen ? 30 : 0 }

            readonly property int live: Services.Lyrics.indexAt(root.position + 0.35)
            property int at: -1
            Component.onCompleted: fold.at = fold.live
            Widgets.SlideSwap {
                id: foldSlide
                index: fold.live
                axis: "vertical"
                travel: 12
                onCommit: fold.at = fold.live
            }

            Text {
                textFormat: Text.PlainText
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 2
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: fold.at >= 0 && fold.at < Services.Lyrics.lines.length
                      ? Services.Lyrics.lines[fold.at].text : "\u2026"
                color: Services.Colors.snow
                font.pixelSize: Services.Sizes.fsBody
                font.family: "JetBrainsMono NF"
                elide: Text.ElideRight
                opacity: foldSlide.fade * fold.amt
                transform: Translate { y: foldSlide.offY }
            }
        }
        }
    }

    Loader {
        sourceComponent: root.style === "compact" ? compactShape
                       : fullShape
    }
}
