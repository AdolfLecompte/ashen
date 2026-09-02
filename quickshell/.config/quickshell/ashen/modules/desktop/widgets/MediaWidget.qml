import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import QtQuick

import "root:/modules/desktop"
import "root:/modules/widgets" as Widgets
import "root:/services" as Services

// What is playing, in three sizes. The full one is the card the panel and the
// lock screen already wear; the other two exist because a desktop is not a
// panel -- one wants the corner of a screen, the other wants to be the wall.
DesktopWidget {
    id: root
    wid: "media"
    // The one piece of desktop furniture you actually press: the layer cuts a
    // hole for this box so its transport works without arranging first. Only
    // for the shapes that HAVE a transport -- the lyric shape is a page, and a
    // hole over it would eat clicks meant for the wallpaper.
    wantsInput: root.style === "compact" || root.style === "full"

    // Its own sticky read, so the compact and wave shapes do not have to mount
    // the whole card to know what is on. Same drop-guard as MediaCard: MPRIS
    // goes null for a few ms between tracks.
    readonly property var livePlayer: {
        const live = Mpris.players.values.filter(p => p.playbackState !== MprisPlaybackState.Stopped)
        if (live.length === 0) return null
        const playing = live.find(p => p.isPlaying)
        return playing !== undefined ? playing : live[0]
    }
    property var player: null
    onLivePlayerChanged: {
        if (root.livePlayer !== null) { drop.stop(); root.player = root.livePlayer }
        else drop.restart()
    }
    Timer { id: drop; interval: 400; onTriggered: root.player = null }

    // MPRIS only pushes position on a seek, so it is asked for -- but only by
    // the shape that needs it, and only while the desktop is being looked at.
    property real position: 0
    Timer {
        interval: 500
        repeat: true
        running: root.live && root.style === "lyrics" && root.player !== null
        onTriggered: {
            if (root.player) { root.player.positionChanged(); root.position = root.player.position }
        }
    }

    // What the words box says when there are none. Picked on the change, never
    // per frame, or it would shuffle under your eyes -- same as the empty
    // notification history.
    property string quietLine: Services.Voice.pick("lyrics.none")
    function reQuiet() { root.quietLine = Services.Voice.pick("lyrics.none") }
    // What it says while the words are still being fetched. A wait, so this one
    // is typed where the quiet line is printed.
    property string lookLine: Services.Voice.pick("lyrics.looking")
    Connections {
        target: Services.Lyrics
        // A new search starting, or one that came back empty: either way the
        // line is about to be read again.
        function onHasChanged() { if (!Services.Lyrics.has) root.reQuiet() }
        function onLoadingChanged() {
            if (Services.Lyrics.loading) {
                root.reQuiet()
                root.lookLine = Services.Voice.pick("lyrics.looking")
            }
        }
    }

    // Nothing playing at all, said rather than labelled -- picked on the drop,
    // not per frame.
    property string idleLine: Services.Voice.pick("media.quiet")
    onPlayerChanged: if (root.player === null) root.idleLine = Services.Voice.pick("media.quiet")

    readonly property string title: root.player ? (root.player.trackTitle || "") : ""
    readonly property string artist: root.player ? (root.player.trackArtist || "") : ""
    readonly property string art: root.player ? (root.player.trackArtUrl || "") : ""

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
                    width: parent.width
                    text: root.title !== "" ? root.title : root.idleLine
                    color: Services.Colors.snow
                    font.pixelSize: Services.Sizes.fsInput
                    font.bold: true
                    font.family: "JetBrainsMono NF"
                    elide: Text.ElideRight
                }
                Text {
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

    // The wall shape: the cover small, the sound taking the room. This is the
    // one that is not a panel in disguise.
    Component {
        id: waveShape
        Column {
            spacing: 10

            Row {
                spacing: 12
                Cover {
                    width: 44; height: 44
                    source: root.art
                    anchors.verticalCenter: parent.verticalCenter
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1
                    width: 380
                    Text {
                        width: parent.width
                        text: root.title !== "" ? root.title : root.idleLine
                        color: Services.Colors.snow
                        font.pixelSize: Services.Sizes.fsInput
                        font.bold: true
                        font.family: "JetBrainsMono NF"
                        elide: Text.ElideRight
                    }
                    Text {
                        width: parent.width
                        text: root.artist
                        color: Services.Colors.mist
                        font.pixelSize: Services.Sizes.fsMeta
                        font.family: "JetBrainsMono NF"
                        elide: Text.ElideRight
                    }
                }
            }

            Spectrum {
                width: 436
                height: 132
                live: root.live
                color_: Services.Colors.ghost
            }
        }
    }


    // The line that is being sung, with the one before and the one after kept
    // dim around it. No lyrics for this track is the normal case, and then this
    // shape says the title instead of an empty box.
    Component {
        id: lyricsShape
        Column {
            spacing: 10
            width: 420

            Row {
                spacing: 12
                Cover {
                    width: 48; height: 48
                    source: root.art
                    anchors.verticalCenter: parent.verticalCenter
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 360
                    spacing: 1
                    Text {
                        width: parent.width
                        text: root.title !== "" ? root.title : root.idleLine
                        color: Services.Colors.snow
                        font.pixelSize: Services.Sizes.fsInput
                        font.bold: true
                        font.family: "JetBrainsMono NF"
                        elide: Text.ElideRight
                    }
                    Text {
                        width: parent.width
                        // The artist keeps its place: the phrase below says
                        // the rest.
                        text: root.artist
                        color: Services.Colors.mist
                        font.pixelSize: Services.Sizes.fsMeta
                        font.family: "JetBrainsMono NF"
                        elide: Text.ElideRight
                    }
                }
            }

            // The words move the way the song does: the line that arrives
            // comes up from under the one it replaces. The body reads the
            // COMMITTED index, never the live one, or the new line would both
            // leave and arrive -- which reads as two sweeps.
            Widgets.SlideSwap {
                id: verseSlide
                index: Services.Lyrics.indexAt(root.position)
                axis: "vertical"
                travel: 18
                onCommit: verse.shownAt = verseSlide.index
            }

            // A new track is not a new line: the words go out sideways, the way
            // the card itself sweeps, and whatever the next song has -- its
            // lyrics or the remark that it has none -- comes in behind them.
            // Vertical is reserved for advancing WITHIN a song.
            Widgets.SlideSwap {
                id: trackSwap
                key: root.title + " " + root.artist
                keyDir: Services.AppState.mediaDir
                travel: 22
                onCommit: {
                    verse.shownAt = verseSlide.index
                    root.reQuiet()
                }
            }

            // Fixed height, always. A line that wraps -- or no lyrics at all
            // -- would otherwise resize the whole widget under the pointer,
            // and on this desktop that also moves everything magnetised to it.
            // Same rule as the dial's centre: reserved slots, never a column
            // that packs to its content.
            Item {
                id: verse
                width: parent.width
                height: 96

                property int shownAt: -1
                Component.onCompleted: verse.shownAt = verseSlide.index

                // Not `visible`: an invisible child still holds its slot, and
                // the box has to measure the same with words or without.
                // Never empty: with words it slides them, without it says so.
                // Two fades multiplied, neither of them animated here: the line
                // change and the track change each own their own curve, and a
                // Behavior over the product would smooth them a second time.
                opacity: (Services.Lyrics.has ? verseSlide.fade : 1) * trackSwap.fade
                transform: [
                    Translate { y: verseSlide.offY },
                    Translate { x: trackSwap.offX }
                ]

                function lineAt(i) {
                    return (i >= 0 && i < Services.Lyrics.lines.length)
                        ? Services.Lyrics.lines[i].text : ""
                }

                Text {
                    id: prevLine
                    width: parent.width
                    height: 18
                    visible: Services.Lyrics.has
                    verticalAlignment: Text.AlignVCenter
                    text: verse.lineAt(verse.shownAt - 1)
                    color: Services.Colors.ash
                    font.pixelSize: Services.Sizes.fsBody
                    font.family: "JetBrainsMono NF"
                    elide: Text.ElideRight
                }
                Text {
                    // Two lines of room and no more: a long one is cut rather
                    // than allowed to grow the box.
                    anchors.top: prevLine.bottom
                    anchors.topMargin: 6
                    width: parent.width
                    height: 48
                    visible: Services.Lyrics.has
                    verticalAlignment: Text.AlignVCenter
                    text: verse.lineAt(verse.shownAt)
                    color: Services.Colors.snow
                    font.pixelSize: Services.Sizes.fsSectionTitle
                    font.bold: true
                    font.family: "JetBrainsMono NF"
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }
                Text {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 18
                    visible: Services.Lyrics.has
                    verticalAlignment: Text.AlignVCenter
                    text: verse.lineAt(verse.shownAt + 1)
                    color: Services.Colors.ash
                    font.pixelSize: Services.Sizes.fsBody
                    font.family: "JetBrainsMono NF"
                    elide: Text.ElideRight
                }

                // Nothing found. Half of what plays is not in any lyric
                // database, so this is a normal state and deserves a voice
                // rather than an empty box.
                Widgets.SaidLine {
                    anchors.centerIn: parent
                    width: parent.width
                    visible: !Services.Lyrics.has
                    horizontalAlignment: Text.AlignHCenter
                    // Looking for them is a wait, so it types itself; having
                    // none is a hole, so it prints whole (docs/DESIGN.md §6b).
                    line: (Services.Lyrics.loading && root.player !== null)
                        ? root.lookLine : root.quietLine
                    msPerChar: (Services.Lyrics.loading && root.player !== null) ? 26 : 0
                    armed: root.live
                    color: Services.Colors.mist
                    font.pixelSize: Services.Sizes.fsInput
                }
            }
        }
    }

    Loader {
        sourceComponent: root.style === "compact" ? compactShape
                       : root.style === "wave" ? waveShape
                       : root.style === "lyrics" ? lyricsShape
                       : fullShape
    }
}
