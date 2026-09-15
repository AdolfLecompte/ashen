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

    // Nothing playing at all, said rather than labelled -- picked on the drop,
    // not per frame.
    property string idleLine: Services.Voice.pick("media.quiet")
    onPlayerChanged: if (root.player === null) root.idleLine = Services.Voice.pick("media.quiet")

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
    // dim around it. Two arrangements in one box that never changes size:
    // nothing to sing -- no lyrics for this track, the quiet before the first
    // line, nothing playing -- and the song fills the box, a large cover and
    // its name; with a line to sing, the cover steps up into a header and the
    // words take the room it left.
    //
    // One movement per change. A new track sweeps the WHOLE widget out and back
    // in, and it waits to leave until it knows whether the new track has words,
    // so it comes back already in its final arrangement. What is on screen is a
    // snapshot taken at that commit: reading the services live, the header
    // changed before the sweep, the old words were cleared mid-sweep, the cover
    // grew while the lyrics were looked up and shrank when they came -- two
    // blinks for one song.
    Component {
        id: lyricsShape
        Item {
            id: lyr
            // Fixed, both ways: on this desktop a box that resized would also
            // move everything magnetised to it. Sized for the 48 grid the plate
            // snaps to -- 440 x 152 plus its padding lands on 480 x 192, which
            // leaves the same 20 px on all four sides.
            width: 440
            height: 152

            // ── What is on screen ────────────────────────────────────────
            property string shownTitle: ""
            property string shownArtist: ""
            property string shownArt: ""
            property var shownLines: []
            property bool shownPlaying: false
            // ── What the widget says about the track ────────────────────
            // A new track always arrives large, and a line from the phrase bank
            // types itself under its name: that it has words, or that it has
            // none. Only once that is said does a track with words step aside
            // for them -- so a song with lyrics visibly announces it has them.
            property string phrase: ""
            // True from the sweep until the line has been read.
            property bool intro: false
            // What was last said about the track on screen: "", "found", "none".
            property string said: ""
            function say() {
                if (!lyr.shownPlaying) { lyr.phrase = ""; lyr.said = ""; lyr.intro = false; return }
                const known = Services.Lyrics.wanted === lyr.swapKey && !Services.Lyrics.loading
                if (!known) { lyr.phrase = ""; lyr.said = ""; lyr.intro = true; return }
                const now = lyr.shownLines.length > 0 ? "found" : "none"
                if (now === lyr.said) return
                lyr.said = now
                lyr.intro = true
                lyr.phrase = Services.Voice.pick("lyrics." + now)
            }
            // Read, then a breath, then the words take the room.
            Timer {
                id: readHold
                interval: 700
                onTriggered: { lyr.intro = false; lyr.aim() }
            }
            // Where in the song on screen we are. Frozen while a change waits:
            // the player's position already belongs to the NEXT track, and read
            // against the old words it put the widget before their first line
            // -- the lines emptied and the cover started to grow mid-wait.
            property real pos: 0
            Connections {
                target: root
                function onPositionChanged() { if (lyr.swapKey === lyr.liveKey) lyr.pos = root.position }
            }
            function indexIn(lines, pos) {
                let idx = -1
                for (let i = 0; i < lines.length; i++) {
                    if (lines[i].at <= pos) idx = i
                    else break
                }
                return idx
            }

            // ── When a track change may be shown ─────────────────────────
            // The live track, and whether the lyrics service has finished with
            // THAT track -- found words or found none.
            readonly property string liveKey: root.player ? root.artist + "|" + root.title : ""
            readonly property bool settled: lyr.liveKey !== ""
                && !Services.Lyrics.loading && Services.Lyrics.wanted === lyr.liveKey
            // What the sweep is keyed on. Moves to the live track once its words
            // are known, or when the wait runs out.
            property string swapKey: ""
            function release() { if (lyr.swapKey !== lyr.liveKey) lyr.swapKey = lyr.liveKey }
            // Deferred: a handler for liveKey reads `settled`, which is a
            // binding on the same change and is not re-evaluated yet.
            //
            // A gap is not a change. Between two songs Brave reports no title
            // for about a second, or no player at all, and treating that as a
            // track swept the widget to "nothing playing" under Brave's own
            // icon and straight back to the next song: two sweeps. Silence is
            // only shown once it has lasted; an untitled track is waited out.
            onLiveKeyChanged: Qt.callLater(function() {
                if (lyr.liveKey === "") { waitWords.stop(); waitGone.restart(); return }
                waitGone.stop()
                if (root.title === "") { waitWords.restart(); return }
                if (lyr.settled) { waitWords.stop(); lyr.release() }
                else waitWords.restart()
            })
            onSettledChanged: if (lyr.settled && root.title !== "") {
                waitWords.stop()
                // Looked up after the wait ran out: the track already on screen
                // learns what it has.
                if (lyr.swapKey === lyr.liveKey) {
                    lyr.shownLines = Services.Lyrics.lines
                    lyr.say()
                }
                lyr.release()
            }
            Timer { id: waitGone; interval: 1200; onTriggered: if (lyr.liveKey === "") lyr.release() }
            // A lookup is 0.9 s of waiting for the artist plus a network call;
            // past this the track is shown without words and they arrive later.
            Timer { id: waitWords; interval: 2500; onTriggered: lyr.release() }

            Widgets.SlideSwap {
                id: trackSwap
                key: lyr.swapKey
                keyDir: Services.AppState.mediaDir
                travel: 22
                onCommit: lyr.take()
            }

            // Everything the new track brings, put on while nothing is legible.
            function take() {
                lyr.shownTitle = root.title !== "" ? root.title : root.idleLine
                lyr.shownArtist = root.artist
                lyr.shownArt = root.art
                lyr.shownPlaying = root.player !== null
                lyr.shownLines = lyr.settled ? Services.Lyrics.lines : []
                lyr.pos = root.position
                verse.shownAt = lyr.indexIn(lyr.shownLines, lyr.pos)
                // Always large on arrival; the words come after it is said.
                readHold.stop()
                lyr.said = ""
                lyr.snap = true
                lyr.words = 0
                lyr.snap = false
                lyr.say()
            }
            Component.onCompleted: { lyr.swapKey = lyr.liveKey; lyr.take() }

            // Within the track on screen: the cover still changes, and words
            // that were looked up too slowly for the sweep still arrive.
            // Brave swaps the cover BEFORE the title, so the cover changing
            // while the title has not is usually the next song arriving, not
            // this one's art: it emptied the old header while the widget waited.
            // Taken only once it has held still, is not empty, and still
            // belongs to the track on screen.
            Connections {
                target: Services.Media
                function onArtChanged() { artHold.restart() }
            }
            Timer {
                id: artHold
                interval: 700
                onTriggered: if (lyr.swapKey === lyr.liveKey && root.art !== "") lyr.shownArt = root.art
            }
            Connections {
                target: Services.Lyrics
                function onLinesChanged() {
                    if (lyr.swapKey === lyr.liveKey && Services.Lyrics.wanted === lyr.swapKey) {
                        lyr.shownLines = Services.Lyrics.lines
                        lyr.say()
                    }
                }
            }

            // ── The arrangement ──────────────────────────────────────────
            readonly property int liveIndex: lyr.indexIn(lyr.shownLines, lyr.pos)
            function target() { return lyr.shownPlaying && lyr.shownLines.length > 0 && verse.shownAt >= 0 }
            // 0 = the song fills the box, 1 = header and words. Set, never
            // bound: a sweep snaps it while the widget is out of sight, and
            // only a change inside a track (the first line, words arriving
            // late, the last line ending) animates it.
            property real words: 0
            property bool snap: false
            Behavior on words {
                enabled: !lyr.snap
                Widgets.Anim { speed: Services.Sizes.msPanel }
            }
            function aim() {
                if (trackSwap.fade < 1 || lyr.intro) return
                const t = lyr.target() ? 1 : 0
                if (lyr.words !== t) lyr.words = t
            }
            onShownLinesChanged: Qt.callLater(lyr.aim)
            // Whatever changed while the sweep was still coming in is looked at
            // once it has landed.
            Connections {
                target: trackSwap
                function onFadeChanged() { if (trackSwap.fade >= 1) Qt.callLater(lyr.aim) }
            }
            onLiveIndexChanged: Qt.callLater(lyr.aim)
            function lerp(a, b) { return a + (b - a) * lyr.words }

            // ── Drawn ────────────────────────────────────────────────────
            Item {
                id: stage
                anchors.fill: parent
                opacity: trackSwap.fade
                transform: Translate { x: trackSwap.offX }

                Cover {
                    id: cover
                    source: lyr.shownArt
                    width: lyr.lerp(lyr.height, 56)
                    height: width
                }

                // Laid out at the large size and scaled down, never re-sized:
                // stepping font.pixelSize reflows the glyphs in integer jumps
                // and reads as a stutter. The elide width is divided back out
                // so the visible width stays honest.
                Column {
                    id: names
                    readonly property real s: lyr.lerp(1, 17 / 21)
                    x: cover.width + 16
                    y: (cover.height - names.height * names.s) / 2
                    width: (lyr.width - x) / names.s
                    spacing: 3
                    transform: Scale { xScale: names.s; yScale: names.s }

                    // A long name gets two lines while the song fills the box, and
                    // one, cut, once the words have the room: there the name is
                    // the header and the words are what you read. Two copies
                    // crossfading, because a text that re-flows from two lines to
                    // one jumps.
                    Item {
                        width: parent.width
                        height: lyr.lerp(fullTitle.height, oneTitle.height)
                        Text {
                            textFormat: Text.PlainText
                            id: fullTitle
                            width: parent.width
                            opacity: 1 - lyr.words
                            text: lyr.shownTitle
                            color: Services.Colors.snow
                            font.pixelSize: 21
                            font.bold: true
                            font.family: "JetBrainsMono NF"
                            wrapMode: Text.WordWrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                        }
                        Text {
                            textFormat: Text.PlainText
                            id: oneTitle
                            width: parent.width
                            opacity: lyr.words
                            text: lyr.shownTitle
                            color: Services.Colors.snow
                            font.pixelSize: 21
                            font.bold: true
                            font.family: "JetBrainsMono NF"
                            elide: Text.ElideRight
                        }
                    }
                    Text {
                        textFormat: Text.PlainText
                        width: parent.width
                        visible: text !== ""
                        text: lyr.shownArtist
                        color: Services.Colors.mist
                        font.pixelSize: 15
                        font.family: "JetBrainsMono NF"
                        elide: Text.ElideRight
                    }
                    // What the widget says about the track, typed: a moment, not
                    // an empty state (docs/DESIGN.md §6b). Armed only once the
                    // sweep has landed, so it is written where it can be read.
                    Widgets.SaidLine {
                        id: saidLine
                        width: parent.width
                        visible: lyr.phrase !== ""
                        opacity: 1 - lyr.words
                        topPadding: 6
                        line: lyr.phrase
                        armed: root.live && trackSwap.fade >= 1
                        color: Services.Colors.ash
                        font.pixelSize: Services.Sizes.fsInput
                        onDoneChanged: if (saidLine.done && lyr.said !== "") {
                            if (lyr.said === "found") readHold.restart()
                            else lyr.intro = false
                        }
                    }
                }

                // The words move the way the song does: the line that arrives
                // comes up from under the one it replaces. The body reads the
                // COMMITTED index, never the live one, or the new line would
                // both leave and arrive -- which reads as two sweeps. Only while
                // the words are fully in: the first line arriving is the
                // header's movement, not a second one on top of it.
                Widgets.SlideSwap {
                    id: verseSlide
                    index: lyr.liveIndex
                    axis: "vertical"
                    travel: 18
                    animate: lyr.words >= 1 && trackSwap.fade >= 1
                    onCommit: verse.shownAt = verseSlide.index
                }

                // Reserved slots, never a column that packs to its content: a
                // line that wraps must not move the next one.
                Item {
                    id: verse
                    y: 56 + 12
                    width: parent.width
                    height: lyr.height - y

                    property int shownAt: -1

                    opacity: lyr.words * verseSlide.fade
                    visible: opacity > 0.01
                    transform: Translate { y: verseSlide.offY + (1 - lyr.words) * 14 }

                    function lineAt(i) {
                        return (i >= 0 && i < lyr.shownLines.length) ? lyr.shownLines[i].text : ""
                    }

                    Text {
                        textFormat: Text.PlainText
                        id: prevLine
                        width: parent.width
                        height: 18
                        verticalAlignment: Text.AlignVCenter
                        text: verse.lineAt(verse.shownAt - 1)
                        color: Services.Colors.ash
                        font.pixelSize: Services.Sizes.fsInput
                        font.family: "JetBrainsMono NF"
                        elide: Text.ElideRight
                    }
                    // Two lines of room and no more: a long one is cut rather
                    // than allowed to grow the box.
                    Text {
                        textFormat: Text.PlainText
                        anchors.top: prevLine.bottom
                        width: parent.width
                        height: 48
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
                        textFormat: Text.PlainText
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: 18
                        verticalAlignment: Text.AlignVCenter
                        text: verse.lineAt(verse.shownAt + 1)
                        color: Services.Colors.ash
                        font.pixelSize: Services.Sizes.fsInput
                        font.family: "JetBrainsMono NF"
                        elide: Text.ElideRight
                    }
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
