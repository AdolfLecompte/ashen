import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import QtQuick

import "root:/modules/desktop"
import "root:/modules/widgets" as Widgets
import "root:/services" as Services

// The words of what is playing, apart from the music widget: reading them no
// longer costs the play button. Three shapes -- a page with the cover, one
// line for a corner, and the line large in the middle of the wall.
DesktopWidget {
    id: root
    wid: "lyrics"

    // Same sticky read as the music widget: MPRIS goes null for a few ms
    // between tracks.
    readonly property var livePlayer: Services.Media.player
    property var player: null
    onLivePlayerChanged: {
        if (root.livePlayer !== null) { drop.stop(); root.player = root.livePlayer }
        else drop.restart()
    }
    Timer { id: drop; interval: 400; onTriggered: root.player = null }

    // MPRIS only pushes position on a seek, so it is asked for, while the
    // desktop is being looked at. Every quarter second: at half a second the
    // line changed up to that much after it had started being sung.
    property real position: 0
    Timer {
        interval: 250
        repeat: true
        running: root.live && root.player !== null
        onTriggered: {
            if (root.player) { root.player.positionChanged(); root.position = root.player.position }
        }
    }

    readonly property string title: root.player ? (root.player.trackTitle || "") : ""
    readonly property string artist: root.player ? (root.player.trackArtist || "") : ""
    readonly property string art: Services.Media.art

    // A line is shown a little BEFORE its time stamp: the position is a
    // quarter-second sample and the line slides in over another tenth.
    readonly property real lead: 0.35
    function indexIn(lines, pos) {
        let idx = -1
        for (let i = 0; i < lines.length; i++) {
            if (lines[i].at <= pos) idx = i
            else break
        }
        return idx
    }

    // ── When a track change may be shown ─────────────────────────────────
    // The live track, and whether the lyrics service has finished with THAT
    // track -- found words or found none.
    readonly property string liveKey: root.player ? root.artist + "|" + root.title : ""
    readonly property bool settled: root.liveKey !== ""
        && !Services.Lyrics.loading && Services.Lyrics.wanted === root.liveKey
    // What every shape's sweep is keyed on. Moves to the live track once its
    // words are known, or when the wait runs out.
    property string swapKey: ""
    function release() { if (root.swapKey !== root.liveKey) root.swapKey = root.liveKey }
    // The words of the track already on screen arrived after it was shown.
    signal learned()
    Component.onCompleted: root.swapKey = root.liveKey
    // Deferred: a handler for liveKey reads `settled`, which is a binding on
    // the same change and is not re-evaluated yet.
    //
    // A gap is not a change. Between two songs Brave reports no title for
    // about a second, or no player at all, and treating that as a track swept
    // the widget to "nothing playing" and straight back: two sweeps. Silence
    // is only shown once it has lasted; an untitled track is waited out.
    onLiveKeyChanged: Qt.callLater(function() {
        if (root.liveKey === "") { waitWords.stop(); waitGone.restart(); return }
        waitGone.stop()
        if (root.title === "") { waitWords.restart(); return }
        if (root.settled) { waitWords.stop(); root.release() }
        else waitWords.restart()
    })
    onSettledChanged: if (root.settled && root.title !== "") {
        waitWords.stop()
        if (root.swapKey === root.liveKey) root.learned()
        root.release()
    }
    Timer { id: waitGone; interval: 1200; onTriggered: if (root.liveKey === "") root.release() }
    // A lookup is 0.9 s of waiting for the artist plus a network call; past
    // this the track is shown without words and they arrive later.
    Timer { id: waitWords; interval: 2500; onTriggered: root.release() }

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

    // What the line and focus shapes share: the track on screen as a snapshot
    // taken at the sweep, and the line being sung with its own slide.
    component Follow: Item {
        id: fol
        property string shownTitle: ""
        property string shownArtist: ""
        property bool shownPlaying: false
        property var shownLines: []
        // Said instead of words: nothing playing, or a song with none.
        property string phrase: ""
        property int shownAt: -1
        readonly property bool singing: fol.shownLines.length > 0 && fol.shownAt >= 0
        readonly property real fade: swap.fade
        readonly property real offX: swap.offX
        readonly property real lineFade: slide.fade
        readonly property real lineOffY: slide.offY

        function lineAt(i) {
            return (i >= 0 && i < fol.shownLines.length) ? fol.shownLines[i].text : ""
        }
        function say() {
            const known = Services.Lyrics.wanted === root.swapKey && !Services.Lyrics.loading
            fol.phrase = !fol.shownPlaying ? Services.Voice.pick("media.quiet")
                       : (known && fol.shownLines.length === 0) ? Services.Voice.pick("lyrics.none")
                       : ""
        }
        function take() {
            fol.shownTitle = root.title
            fol.shownArtist = root.artist
            fol.shownPlaying = root.player !== null
            fol.shownLines = root.settled ? Services.Lyrics.lines : []
            fol.pos = root.position
            fol.shownAt = root.indexIn(fol.shownLines, fol.pos + root.lead)
            fol.say()
        }
        Component.onCompleted: fol.take()

        // Frozen while a change waits: the player's position already belongs
        // to the NEXT track.
        property real pos: 0
        Connections {
            target: root
            function onPositionChanged() { if (root.swapKey === root.liveKey) fol.pos = root.position }
            function onLearned() { fol.shownLines = Services.Lyrics.lines; fol.say() }
        }
        Connections {
            target: Services.Lyrics
            function onLinesChanged() {
                if (root.swapKey === root.liveKey && Services.Lyrics.wanted === root.swapKey) {
                    fol.shownLines = Services.Lyrics.lines
                    fol.say()
                }
            }
        }
        // The bank loads after the shell does.
        Connections {
            target: Services.Voice
            function onBaseChanged() { if (fol.phrase === "") fol.say() }
            function onBankChanged() { if (fol.phrase === "") fol.say() }
        }

        Widgets.SlideSwap {
            id: swap
            key: root.swapKey
            keyDir: Services.AppState.mediaDir
            travel: 22
            onCommit: fol.take()
        }
        // The new line comes up from under the one it replaces; the body reads
        // the committed index, never the live one.
        Widgets.SlideSwap {
            id: slide
            index: root.indexIn(fol.shownLines, fol.pos + root.lead)
            axis: "vertical"
            travel: 14
            animate: swap.fade >= 1
            onCommit: fol.shownAt = slide.index
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
        id: pageShape
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
                // Nothing playing: the widget says so, typed, as its headline.
                if (!lyr.shownPlaying) {
                    lyr.said = "quiet"
                    lyr.intro = false
                    lyr.phrase = Services.Voice.pick("media.quiet")
                    return
                }
                const known = Services.Lyrics.wanted === root.swapKey && !Services.Lyrics.loading
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
                function onPositionChanged() { if (root.swapKey === root.liveKey) lyr.pos = root.position }
            }
            function indexIn(lines, pos) {
                let idx = -1
                for (let i = 0; i < lines.length; i++) {
                    if (lines[i].at <= pos) idx = i
                    else break
                }
                return idx
            }

            // Words looked up after the wait ran out: the track already on
            // screen learns what it has.
            Connections {
                target: root
                function onLearned() {
                    lyr.shownLines = Services.Lyrics.lines
                    lyr.say()
                }
            }

            Widgets.SlideSwap {
                id: trackSwap
                key: root.swapKey
                keyDir: Services.AppState.mediaDir
                travel: 22
                onCommit: lyr.take()
            }

            // Everything the new track brings, put on while nothing is legible.
            function take() {
                lyr.shownTitle = root.title
                lyr.shownArtist = root.artist
                lyr.shownArt = root.art
                lyr.shownPlaying = root.player !== null
                lyr.shownLines = root.settled ? Services.Lyrics.lines : []
                lyr.pos = root.position
                verse.shownAt = lyr.indexIn(lyr.shownLines, lyr.pos + lyr.lead)
                // Always large on arrival; the words come after it is said.
                readHold.stop()
                lyr.said = ""
                lyr.snap = true
                lyr.words = 0
                lyr.snap = false
                lyr.say()
            }
            Component.onCompleted: lyr.take()
            // The phrase bank loads after the shell does: a line asked for
            // before it arrived came back empty and was never asked for again.
            Connections {
                target: Services.Voice
                function onBaseChanged() { if (lyr.phrase === "" && !lyr.shownPlaying) lyr.say() }
                function onBankChanged() { if (lyr.phrase === "" && !lyr.shownPlaying) lyr.say() }
            }

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
                onTriggered: if (root.swapKey === root.liveKey && root.art !== "") lyr.shownArt = root.art
            }
            Connections {
                target: Services.Lyrics
                function onLinesChanged() {
                    if (root.swapKey === root.liveKey && Services.Lyrics.wanted === root.swapKey) {
                        lyr.shownLines = Services.Lyrics.lines
                        lyr.say()
                    }
                }
            }

            // ── The arrangement ──────────────────────────────────────────
            // A line is shown a little BEFORE its time stamp: the position is a
            // quarter-second sample and the line slides in over another tenth,
            // so read on the stamp it landed after the singer had started it.
            readonly property real lead: 0.35
            readonly property int liveIndex: lyr.indexIn(lyr.shownLines, lyr.pos + lyr.lead)
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
                        visible: lyr.shownTitle !== ""
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
                        readonly property bool headline: !lyr.shownPlaying
                        topPadding: headline ? 0 : 6
                        line: lyr.phrase
                        armed: root.live && trackSwap.fade >= 1
                        color: headline ? Services.Colors.snow : Services.Colors.ash
                        font.pixelSize: headline ? 21 : Services.Sizes.fsInput
                        font.bold: headline
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

    // One strip for a corner: the line being sung, the next one under it.
    // Before the first line, or with no words, the song and what is said.
    Component {
        id: lineShape
        Follow {
            id: ln
            width: 440
            height: 64

            Item {
                anchors.fill: parent
                opacity: ln.fade
                transform: Translate { x: ln.offX }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    spacing: 4
                    opacity: ln.singing ? ln.lineFade : 1
                    transform: Translate { y: ln.singing ? ln.lineOffY : 0 }

                    Text {
                        textFormat: Text.PlainText
                        width: parent.width
                        text: ln.singing ? ln.lineAt(ln.shownAt)
                            : ln.shownTitle !== "" ? ln.shownTitle : ln.phrase
                        color: Services.Colors.snow
                        font.pixelSize: 20
                        font.bold: true
                        font.family: "JetBrainsMono NF"
                        elide: Text.ElideRight
                    }
                    Text {
                        textFormat: Text.PlainText
                        width: parent.width
                        visible: text !== ""
                        text: ln.singing ? ln.lineAt(ln.shownAt + 1)
                            : ln.shownTitle === "" ? ""
                            : ln.phrase !== "" ? ln.phrase : ln.shownArtist
                        color: Services.Colors.ash
                        font.pixelSize: Services.Sizes.fsInput
                        font.family: "JetBrainsMono NF"
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }

    // The line large in the middle of the wall, the one before and the one
    // after dim around it, and the song named small underneath.
    Component {
        id: focusShape
        Follow {
            id: fc
            width: 560
            height: 216

            Item {
                anchors.fill: parent
                opacity: fc.fade
                transform: Translate { x: fc.offX }

                // Reserved slots: a line that wraps must not move the others.
                Item {
                    id: lines
                    width: parent.width
                    height: 176
                    visible: fc.singing
                    opacity: fc.lineFade
                    transform: Translate { y: fc.lineOffY }

                    Text {
                        textFormat: Text.PlainText
                        id: before
                        width: parent.width
                        height: 30
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: fc.lineAt(fc.shownAt - 1)
                        color: Services.Colors.ash
                        font.pixelSize: Services.Sizes.fsInput
                        font.family: "JetBrainsMono NF"
                        elide: Text.ElideRight
                    }
                    Text {
                        textFormat: Text.PlainText
                        anchors.top: before.bottom
                        width: parent.width
                        height: 116
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: fc.lineAt(fc.shownAt)
                        color: Services.Colors.snow
                        font.pixelSize: 28
                        font.bold: true
                        font.family: "JetBrainsMono NF"
                        wrapMode: Text.WordWrap
                        maximumLineCount: 3
                        elide: Text.ElideRight
                    }
                    Text {
                        textFormat: Text.PlainText
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: 30
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: fc.lineAt(fc.shownAt + 1)
                        color: Services.Colors.ash
                        font.pixelSize: Services.Sizes.fsInput
                        font.family: "JetBrainsMono NF"
                        elide: Text.ElideRight
                    }
                }

                // No words to sing: the song itself takes the middle.
                Column {
                    anchors.centerIn: lines
                    width: parent.width
                    spacing: 8
                    visible: !fc.singing
                    Text {
                        textFormat: Text.PlainText
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: fc.shownTitle !== "" ? fc.shownTitle : fc.phrase
                        color: Services.Colors.snow
                        font.pixelSize: 28
                        font.bold: true
                        font.family: "JetBrainsMono NF"
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                    }
                    Text {
                        textFormat: Text.PlainText
                        width: parent.width
                        visible: text !== ""
                        horizontalAlignment: Text.AlignHCenter
                        text: fc.shownTitle !== "" ? fc.phrase : ""
                        color: Services.Colors.ash
                        font.pixelSize: Services.Sizes.fsInput
                        font.family: "JetBrainsMono NF"
                        elide: Text.ElideRight
                    }
                }

                Text {
                    textFormat: Text.PlainText
                    anchors.bottom: parent.bottom
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    visible: fc.singing || (fc.shownTitle !== "" && fc.phrase === "")
                    text: fc.shownArtist !== "" ? fc.shownTitle + " \u00b7 " + fc.shownArtist : fc.shownTitle
                    color: Services.Colors.mist
                    font.pixelSize: Services.Sizes.fsMeta
                    font.family: "JetBrainsMono NF"
                    elide: Text.ElideRight
                }
            }
        }
    }

    Loader {
        sourceComponent: root.style === "line" ? lineShape
                       : root.style === "focus" ? focusShape
                       : pageShape
    }
}
