import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Effects

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
            text: "\ue405"
            font.family: "Material Symbols Rounded"
            font.pixelSize: parent.width * 0.4
            color: Services.Colors.ash
        }
    }

    // The words on the cover: opened by the card's lyric chip, only on the
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
            spacing: card.gap

            // The cover stands the whole height of the card and the strip; the
            // words sit on it, blurred, the way the media panel shows them.
            ClippingRectangle {
                id: big
                width: main.height
                height: main.height
                radius: 28
                color: Services.Colors.fillInset
                opacity: card.swapFade
                transform: Translate { x: card.swapOffX }
                property real face: root.wordsOpen ? 1 : 0
                Behavior on face { NumberAnimation { duration: 620; easing.type: Easing.InOutCubic } }

                Image {
                    id: bigImg
                    anchors.fill: parent
                    source: root.art
                    sourceSize: Qt.size(512, 512)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    // The player reuses its temp file name: never serve a cached picture.
                    cache: false
                    visible: status === Image.Ready
                }
                Text {
                    textFormat: Text.PlainText
                    anchors.centerIn: parent
                    visible: bigImg.status !== Image.Ready
                    text: "\ue405"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: parent.width * 0.3
                    color: Services.Colors.ash
                }

                Item {
                    id: words
                    anchors.fill: parent
                    visible: big.face > 0.01
                    readonly property int live: Services.Lyrics.indexAt(root.position + 0.35)
                    // The text reads the committed index, so the new line does not
                    // both leave and arrive.
                    Widgets.SlideSwap {
                        id: lineSlide
                        index: words.live
                        axis: "vertical"
                        travel: 18
                        onCommit: words.at = words.live
                    }
                    property int at: -1
                    Component.onCompleted: words.at = words.live
                    function lineOf(i) {
                        const l = Services.Lyrics.lines
                        return i >= 0 && i < l.length ? l[i].text : ""
                    }

                    MultiEffect {
                        anchors.fill: parent
                        source: bigImg
                        visible: bigImg.status === Image.Ready
                        blurEnabled: true
                        blurMax: 48
                        blur: big.face
                        scale: 1 + 0.06 * big.face
                    }
                    Rectangle {
                        anchors.fill: parent
                        color: Qt.rgba(Services.Colors.abyss.r, Services.Colors.abyss.g,
                                       Services.Colors.abyss.b, 0.55 * big.face)
                    }
                    Column {
                        anchors.centerIn: parent
                        width: parent.width - 32
                        spacing: 12
                        opacity: lineSlide.fade * Math.max(0, (big.face - 0.35) / 0.65)
                        transform: Translate { y: lineSlide.offY + (1 - big.face) * 12 }
                        Text {
                            textFormat: Text.PlainText
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                            text: words.lineOf(words.at - 1)
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
                            text: words.at < 0 ? "\u2026" : words.lineOf(words.at)
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
                            text: words.lineOf(words.at + 1)
                            color: Services.Colors.ash
                            font.pixelSize: Services.Sizes.fsInput
                            font.family: "JetBrainsMono NF"
                        }
                    }
                }
            }

            Column {
                id: main
                spacing: 12
                Widgets.MediaCard {
                    followSwitch: !root.managed
                    id: card
                    showArt: false
                    // The column keeps the width it had beside the small cover.
                    contentW: 630 - 160 - card.gap
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
                        tip: Services.I18n.t("kb.playPause")
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
