import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts
import "root:/services" as Services

// The "now playing" card, in one place: the bar's media panel morphs into this
// item and the lock screen mounts the same one. Content only, no background;
// `pad` is what the caller's plate leaves. The cover sets the height and
// nothing is allowed past it.
Item {
    id: root

    // ── Metrics ─────────────────────────────────────────────────────────
    readonly property real artSize: 160
    // Narrow on purpose: the bars stand on an axis in the middle of this, so
    // every pixel of column is two pixels of air between the words and the
    // sound. 130 read as two separate things sharing an edge.
    readonly property real cavaW: 100
    readonly property real gap: 18
    readonly property real pad: 20
    readonly property real contentW: 630
    readonly property real chipLg: 40
    readonly property real playLg: 48
    // The words' own column, when this copy of the card is offering them, and
    // the gap it keeps from the cava beside it -- half the card's, because the
    // two of them are ONE block: what is being sung and what it sounds like.
    readonly property real lyricsW: 260
    readonly property real wordGap: 8
    readonly property bool lyricsShown: root.offerLyrics && Services.Lyrics.has
                                        && Services.Prefs.mediaLyrics

    // The card is as wide as it has things to say: the lyric column pushes the
    // right edge out and takes it back when the next track has no words. Read
    // off the column's live width, not off the flag, so the panel's box grows
    // WITH it instead of stepping once and letting the words catch up.
    implicitWidth: contentW + lyricsCol.Layout.preferredWidth
    implicitHeight: artSize
    width: implicitWidth
    height: implicitHeight

    // ── Morph support ───────────────────────────────────────────────────
    // With this on, the pieces the media panel flies in from the pill are still
    // laid out (they are what the copies aim at) but neither drawn nor
    // clickable. Off, this is just the whole card.
    property bool ghostShared: false
    readonly property real sharedOpacity: ghostShared ? 0 : 1

    // Off where the surface draws its own, bigger one (the desktop widget).
    property bool showSpectrum: true

    // Fade for everything the bar pill has no counterpart for. The panel drives
    // it so those pieces arrive after the blob has finished opening; the lock
    // screen leaves it at 1 and shows the whole card at once.
    property real extrasOpacity: 1
    // Where each part of the card is in the arrival, when whoever opened it
    // hands one in -- the title before the transport, the transport before the
    // sound. One fade for all of it reads as a picture of a card.
    property var stageFn: null
    function beat(i) {
        return root.stageFn ? root.stageFn(i) * root.extrasOpacity : root.extrasOpacity
    }

    // Whether this copy of the card carries the lyric column. The panel does;
    // the lock screen has no room for it beside its other cards.
    property bool offerLyrics: false

    // ── Player ──────────────────────────────────────────────────────────
    // Raw MPRIS read: drops to null for a few ms while the player changes track
    property var livePlayer: {
        let list = Mpris.players.values.filter(p => p.playbackState !== MprisPlaybackState.Stopped)
        if (list.length === 0) return null
        let playing = list.find(p => p.isPlaying)
        return playing !== undefined ? playing : list[0]
    }

    // Held across that gap so the card does not flip to "Nothing playing"
    property var activePlayer: null
    readonly property bool hasPlayer: activePlayer !== null

    onLivePlayerChanged: {
        if (livePlayer !== null) {
            dropTimer.stop()
            activePlayer = livePlayer
        } else {
            dropTimer.restart()
        }
    }

    Timer {
        id: dropTimer
        interval: 5000
        onTriggered: if (root.livePlayer === null) root.activePlayer = null
    }

    // Cache the values the browser sends intermittently
    // (they sometimes arrive empty for an instant before coming back)
    property string stableArtUrl: ""
    property string stableArtist: ""
    property string stableAlbum: ""
    function updateTrackInfo() {
        if (!root.hasPlayer) {
            root.stableArtUrl = ""
            root.stableArtist = ""
            root.stableAlbum = ""
            return
        }
        if (root.activePlayer.trackArtUrl !== "")
            root.stableArtUrl = root.activePlayer.trackArtUrl
        if (root.activePlayer.trackArtist !== "") root.stableArtist = root.activePlayer.trackArtist
        if (root.activePlayer.trackAlbum !== "") root.stableAlbum = root.activePlayer.trackAlbum
    }
    onActivePlayerChanged: {
        root.stableArtist = ""
        root.stableAlbum = ""
        updateTrackInfo()
    }
    Component.onCompleted: { activePlayer = livePlayer; updateTrackInfo() }
    Connections {
        target: root.activePlayer
        ignoreUnknownSignals: true
        function onTrackArtUrlChanged() { root.updateTrackInfo() }
        function onTrackArtistChanged() { root.updateTrackInfo() }
        function onTrackAlbumChanged() { root.updateTrackInfo() }
        function onTrackTitleChanged() {
            // new title = possibly a new song, so reset the old artist/album
            // to avoid carrying the previous one over if the new one is slow
            root.stableArtist = ""
            root.stableAlbum = ""
            root.updateTrackInfo()
        }
    }

    // ── Changing track ──────────────────────────────────────────────────
    // Nothing here is bound straight to the player: title, cover and the rest
    // arrive on different frames and the cover decodes asynchronously, so a
    // live binding blinked the placeholder between songs. They are committed
    // together, halfway through a sweep, while nothing is legible.
    readonly property string liveTitle: root.hasPlayer ? (root.activePlayer.trackTitle || "") : ""
    // Settled, not live: the title empties for a moment on every change, and
    // sweeping to that would play two changes per track.
    property string settledKey: ""
    Timer {
        id: settle
        interval: 180
        // An empty title is the gap between tracks, never a track called
        // nothing: hold the last one and wait for the real one to land.
        onTriggered: {
            if (root.liveTitle !== "") root.settledKey = root.liveTitle
            else if (!root.hasPlayer) root.settledKey = ""
        }
    }
    onLiveTitleChanged: {
        if (root.liveTitle === "" && !root.hasPlayer) root.settledKey = ""
        else settle.restart()
    }
    // The player also flashes its OWN icon as the cover for a frame or two on
    // the way between tracks, while the old title is still up -- so a cover is
    // only believed once it has held still. One that lasts a frame is the gap.
    property string settledArt: ""
    // The cover as a file of our own: the player's temp file is deleted and
    // its name reused, and Spotify's is an https URL that has to be fetched.
    property string cachedArt: ""
    Timer {
        id: artSettle
        interval: 250
        onTriggered: {
            root.settledArt = root.stableArtUrl
            root.cachedArt = Services.MediaArt.local(root.settledArt)
            root.artWaiting = true
            Services.MediaArt.request(root.settledArt)
        }
    }
    onStableArtUrlChanged: artSettle.restart()
    Connections {
        target: Services.MediaArt
        function onReady(url) {
            if (url !== root.settledArt) return
            root.cachedArt = Services.MediaArt.local(url)
            // The album this cover came with -- the only thing that can prove
            // it is the player's icon rather than artwork.
            Services.MediaArt.note(url, root.artTag)
            // Same file as before means no reload and so no statusChanged to
            // wait for: the cover is already up, take it now.
            if (root.artWaiting && artProbe.status === Image.Ready) {
                root.artWaiting = false
                root.shownArtUrl = root.coverOrNothing()
            }
        }
        // It just worked out that what we are showing is the player's logo:
        // drop it, and let the same call go and ask for a real one.
        function onDecoysChanged() {
            if (Services.MediaArt.isDecoy(root.settledArt)) root.shownArtUrl = root.coverOrNothing()
        }
        // The web answered. It is only ours if it is the track we are on.
        function onWebReady(key) {
            if (key === Services.MediaArt.webKey(root.artArtist, root.artTitle))
                root.shownArtUrl = root.coverOrNothing()
        }
    }
    readonly property string artTag: root.hasPlayer
        ? (root.activePlayer.trackAlbum || root.activePlayer.trackArtist || "") : ""
    // One door: the player's own file while it is real, and the web's answer
    // when the player gives nothing or gives its own logo. The service owns
    // that decision -- this surface only draws it.
    function coverOrNothing() {
        return Services.MediaArt.coverFor(root.settledArt, root.artArtist, root.artTitle)
    }
    readonly property string artArtist: root.hasPlayer
        ? (root.activePlayer.trackArtist || "") : ""
    readonly property string artTitle: root.hasPlayer
        ? (root.activePlayer.trackTitle || "") : ""

    property string shownTitle: "Nothing playing"
    property string shownArtUrl: ""
    property string shownArtist: ""
    property string shownAlbum: ""
    property bool artWaiting: false

    // What the panel's flown pieces read to sweep with the card.
    readonly property real swapOffX: trackSwap.offX
    readonly property real swapFade: trackSwap.fade

    SlideSwap {
        id: trackSwap
        travel: 18
        key: root.settledKey
        keyDir: Services.AppState.mediaDir
        onCommit: {
            root.shownTitle = root.settledKey !== "" ? root.settledKey : root.titleText
            root.shownArtist = root.stableArtist
            root.shownAlbum = root.stableAlbum
            if (root.cachedArt !== "" && artProbe.status === Image.Ready) {
                root.artWaiting = false
                root.shownArtUrl = root.coverOrNothing()
            } else if (root.stableArtUrl === "") {
                root.artWaiting = false
                root.shownArtUrl = ""
            } else {
                // Still being fetched or decoded: hold the old cover and let
                // the probe hand the new one over the moment it is up.
                root.artWaiting = true
            }
            Services.AppState.mediaDir = 1
        }
    }

    // Decodes the next cover out of sight. Same source and no sourceSize on
    // either, so the drawn Image hits Qt's cache and is up on the first frame.
    Image {
        id: artProbe
        source: root.cachedArt
        asynchronous: true
        visible: false
        width: 1; height: 1
        onStatusChanged: if (status === Image.Ready && root.artWaiting) {
            root.artWaiting = false
            root.shownArtUrl = root.coverOrNothing()
        }
    }

    // MPRIS only emits position on demand
    Timer {
        interval: 1000
        repeat: true
        running: root.activePlayer !== null && root.activePlayer.isPlaying
        onTriggered: if (root.hasPlayer) root.activePlayer.positionChanged()
    }

    function formatTime(seconds) {
        if (!seconds || seconds <= 0) return "0:00"
        let m = Math.floor(seconds / 60)
        let s = Math.floor(seconds % 60)
        return m + ":" + (s < 10 ? "0" : "") + s
    }

    readonly property string titleText: root.hasPlayer
        ? (root.activePlayer.trackTitle || "Untitled") : "Nothing playing"
    // Seconds into the track, for whoever needs the number rather than the
    // words -- the lyric column places its line with it.
    readonly property real position: root.activePlayer !== null ? root.activePlayer.position : 0
    readonly property string posText: root.activePlayer !== null ? root.formatTime(root.activePlayer.position) : "0:00"
    readonly property string lenText: root.activePlayer !== null ? root.formatTime(root.activePlayer.length) : "0:00"
    readonly property string playGlyph: root.activePlayer !== null && root.activePlayer.isPlaying ? "\ue034" : "\ue037"

    // ── Where the shared pieces sit, in this item's coordinates ─────────
    // Chained by hand rather than with mapToItem, which is a plain function
    // call and would never re-run when the layout shifts.
    readonly property real artCX: row.x + artSlot.x + artSlot.width / 2
    readonly property real artCY: row.y + artSlot.y + artSlot.height / 2

    readonly property real titleX: row.x + col.x + top.x + titleT.x
    readonly property real titleCY: row.y + col.y + top.y + titleT.y + titleT.height / 2
    readonly property real titleW: titleT.width

    readonly property real posX: row.x + col.x + bottom.x + wave.x + times.x + posT.x
    readonly property real posCY: row.y + col.y + bottom.y + wave.y + times.y + posT.y + posT.height / 2
    readonly property real lenX: row.x + col.x + bottom.x + wave.x + times.x + lenT.x
    readonly property real lenCY: row.y + col.y + bottom.y + wave.y + times.y + lenT.y + lenT.height / 2

    readonly property real ctlY: row.y + col.y + bottom.y + ctl.y
    readonly property real prevCX: row.x + col.x + bottom.x + ctl.x + prevChip.x + prevChip.width / 2
    readonly property real prevCY: ctlY + prevChip.y + prevChip.height / 2
    readonly property real playCX: row.x + col.x + bottom.x + ctl.x + playChip.x + playChip.width / 2
    readonly property real playCY: ctlY + playChip.y + playChip.height / 2
    readonly property real nextCX: row.x + col.x + bottom.x + ctl.x + nextChip.x + nextChip.width / 2
    readonly property real nextCY: ctlY + nextChip.y + nextChip.height / 2

    // ── Layout ──────────────────────────────────────────────────────────
    RowLayout {
        id: row
        anchors.fill: parent
        spacing: root.gap

        ClippingRectangle {
            id: artSlot
            Layout.preferredWidth: root.artSize
            Layout.preferredHeight: root.artSize
            Layout.alignment: Qt.AlignVCenter
            radius: 28
            color: Services.Colors.accentText
            // The panel draws its own flying copy of this, so the sweep here is
            // for the lock screen, where the card stands on its own.
            opacity: root.sharedOpacity * trackSwap.fade
            transform: Translate { x: trackSwap.offX }

            Image {
                id: artImg
                anchors.fill: parent
                source: root.shownArtUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: status === Image.Ready
            }
            Text {
                anchors.centerIn: parent
                // Only when there is genuinely no cover, never while one decodes.
                visible: root.shownArtUrl === ""
                text: "\ue405"
                color: Services.Colors.ash
                font.family: "Material Symbols Rounded"
                font.pixelSize: 40
            }
        }

        Item {
            id: col
            Layout.fillWidth: true
            Layout.preferredHeight: root.artSize
            Layout.alignment: Qt.AlignVCenter

            Column {
                id: top
                anchors.top: parent.top
                width: parent.width
                spacing: 4

                Text {
                    id: titleT
                    opacity: root.sharedOpacity * trackSwap.fade
                    transform: Translate { x: trackSwap.offX }
                    width: parent.width
                    text: root.shownTitle
                    color: Services.Colors.snow
                    font.pixelSize: 18
                    font.bold: true
                    font.family: "JetBrainsMono NF"
                    elide: Text.ElideRight
                }
                Text {
                    opacity: root.beat(0) * trackSwap.fade
                    transform: Translate { x: trackSwap.offX }
                    visible: root.shownArtist !== ""
                    width: parent.width
                    text: root.shownArtist
                    color: Services.Colors.mist
                    font.pixelSize: 12
                    font.family: "JetBrainsMono NF"
                    elide: Text.ElideRight
                }
                Text {
                    opacity: root.beat(0) * trackSwap.fade
                    transform: Translate { x: trackSwap.offX }
                    visible: root.shownAlbum !== ""
                    width: parent.width
                    text: root.shownAlbum
                    color: Services.Colors.ash
                    font.pixelSize: 10
                    font.family: "JetBrainsMono NF"
                    elide: Text.ElideRight
                }
            }

            Column {
                id: bottom
                anchors.bottom: parent.bottom
                width: parent.width
                spacing: 8

                Item {
                    id: wave
                    width: parent.width
                    height: 38

                    // Snake progress: a sine wave whose played portion glows in
                    // the accent and scrolls while the track plays; the rest is
                    // a dim straight rule. The playhead is a dot: the wave is
                    // tapered flat where it lands (so it meets the rule without
                    // a step), and a tapered end is too thin to say where you
                    // are on its own.
                    Item {
                        id: snake
                        anchors.top: parent.top
                        width: parent.width
                        height: 20
                        opacity: root.beat(1)

                        property real progress: (root.activePlayer !== null && root.activePlayer.length > 0)
                            ? Math.max(0, Math.min(1, root.activePlayer.position / root.activePlayer.length)) : 0
                        Behavior on progress { NumberAnimation { duration: Services.Sizes.msEmphasis } }
                        property real phase: 0
                        readonly property bool playing: root.activePlayer !== null && root.activePlayer.isPlaying

                        // 0 = flat line (paused), 1 = full wave (playing). Animated
                        // so the straight<->snake transition morphs smoothly.
                        property real ampFactor: playing ? 1 : 0
                        Behavior on ampFactor { NumberAnimation { duration: 550; easing.type: Services.Sizes.easeInOut } }

                        // How loud it actually is, 0..1, smoothed. The wave is
                        // the song and not a decoration, so its height is the
                        // sound rather than a constant: a quiet passage flattens
                        // it and the drop swells it. Without cava running there
                        // is nothing to ask, and it holds its full height.
                        property real level: 0
                        readonly property real loudness: Services.Cava.enabled
                            ? (0.35 + 0.65 * snake.level) : 1
                        Connections {
                            target: Services.Cava
                            enabled: snake.playing && Services.Cava.enabled
                            function onBarValuesChanged() {
                                const src = Services.Cava.barValues
                                if (!src || src.length === 0) return
                                let v = 0
                                for (let i = 0; i < src.length; i++) v = Math.max(v, src[i] || 0)
                                // Smoothed towards the reading, never set to it:
                                // raw cava jitters every frame and the wave
                                // would buzz rather than breathe.
                                snake.level = snake.level * 0.72 + Math.min(1, v / 100) * 0.28
                            }
                        }
                        onLevelChanged: waveCanvas.requestPaint()

                        onProgressChanged: waveCanvas.requestPaint()
                        onPhaseChanged: waveCanvas.requestPaint()
                        onAmpFactorChanged: waveCanvas.requestPaint()
                        NumberAnimation on phase {
                            running: snake.playing
                            from: 0; to: 2 * Math.PI
                            duration: 1600; loops: Animation.Infinite
                        }

                        Canvas {
                            id: waveCanvas
                            anchors.fill: parent
                            // Straight segments every 2 px put a corner at every
                            // crest -- small, but a 5 px stroke turns each one
                            // into a nick in the curve. Smoothed and sampled
                            // finer, the wave has no flat spots to nick.
                            antialiasing: true
                            smooth: true
                            renderTarget: Canvas.Image
                            readonly property real amp: height * 0.30
                            readonly property real waves: 3.5
                            readonly property real step: 1
                            // How far the playhead is, in pixels. The wave has to
                            // KNOW it: its height is tapered to nothing there so
                            // it lands ON the dim rule instead of stopping in mid
                            // crest -- that step was the nick that read as the
                            // line breaking, and no round cap can hide it.
                            readonly property real headX: width * parent.progress
                            readonly property real taper: 30
                            function envAt(px) {
                                const d = headX - px
                                if (d <= 0) return 0
                                return Math.min(1, d / taper)
                            }
                            function yAt(px) {
                                return height / 2 + amp * parent.ampFactor * parent.loudness
                                     * envAt(px)
                                     * Math.sin((px / width) * waves * 2 * Math.PI + parent.phase)
                            }
                            // Drawn up to a length rather than clipped to one:
                            // a clip cuts the played end square, and the whole
                            // point of a round cap is that both ends are round.
                            // Quadratics through the midpoints: each sample bends
                            // the line instead of breaking it.
                            function trace(ctx, until) {
                                var end = Math.min(width, until)
                                ctx.beginPath()
                                ctx.moveTo(0, yAt(0))
                                var px = step
                                for (; px < end; px += step) {
                                    var prev = px - step
                                    ctx.quadraticCurveTo(prev, yAt(prev),
                                                         (prev + px) / 2, (yAt(prev) + yAt(px)) / 2)
                                }
                                // The last sample lands ON the playhead, so the
                                // round cap sits where the time says it does.
                                ctx.lineTo(end, yAt(end))
                            }
                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.reset()
                                ctx.lineWidth = 5
                                ctx.lineCap = "round"
                                ctx.lineJoin = "round"
                                // What is still to come is a STRAIGHT dim rule,
                                // never a second wave: two waves read as one
                                // long ripple and the playhead disappears into
                                // it. Only what has been played moves.
                                // And it starts AT the playhead, not at zero: a
                                // rule running under the wave crosses it twice
                                // per crest and reads as a seam.
                                ctx.strokeStyle = Services.Colors.ghostAlpha(0.18)
                                ctx.beginPath()
                                ctx.moveTo(Math.max(0, waveCanvas.headX), height / 2)
                                ctx.lineTo(width, height / 2)
                                ctx.stroke()
                                // Accent wave, as far as the playhead
                                var pw = width * parent.progress
                                if (pw > 0) {
                                    ctx.strokeStyle = Services.Colors.ghost
                                    trace(ctx, pw); ctx.stroke()
                                }
                                // The head itself. The wave is tapered to
                                // nothing where it lands, so without this the
                                // end of it is the thinnest part of the line --
                                // exactly where the eye is looking for "you are
                                // here". A ring of plate under the dot keeps it
                                // off the rule it sits on.
                                if (pw > 0.5) {
                                    ctx.beginPath()
                                    ctx.arc(pw, height / 2, 6, 0, 2 * Math.PI)
                                    ctx.fillStyle = Services.Colors.surfacePanel
                                    ctx.fill()
                                    ctx.beginPath()
                                    ctx.arc(pw, height / 2, 4.5, 0, 2 * Math.PI)
                                    ctx.fillStyle = Services.Colors.ghost
                                    ctx.fill()
                                }
                            }
                        }

                    }

                    Item {
                        id: times
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: 14

                        Text {
                            id: posT
                            opacity: root.sharedOpacity
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.posText
                            color: Services.Colors.mist
                            font.pixelSize: 10; font.bold: true
                            font.family: "JetBrainsMono NF"
                        }
                        Text {
                            id: lenT
                            opacity: root.sharedOpacity
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.lenText
                            color: Services.Colors.mist
                            font.pixelSize: 10; font.bold: true
                            font.family: "JetBrainsMono NF"
                        }
                    }
                }

                // Shuffle and repeat are only ever here, so they stay put; the
                // middle three are what the panel's morph replaces. They are
                // laid out either way, which is what makes the flying chips'
                // targets stand still.
                Row {
                    id: ctl
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 10

                    // Shuffle: lit when it is on, dimmed when the player does
                    // not offer it at all.
                    CtlChip {
                        anchors.verticalCenter: parent.verticalCenter
                        opacity: root.beat(2)
                        size: root.chipLg
                        glyphSize: 20
                        glyph: "\ue043"
                        available: root.activePlayer !== null && root.activePlayer.shuffleSupported
                        active: root.activePlayer !== null && root.activePlayer.shuffle
                        onTriggered: if (root.activePlayer)
                            root.activePlayer.shuffle = !root.activePlayer.shuffle
                    }
                    CtlChip {
                        id: prevChip
                        anchors.verticalCenter: parent.verticalCenter
                        opacity: root.sharedOpacity
                        inert: root.ghostShared
                        size: root.chipLg
                        glyphSize: 20
                        glyph: "\ue045"
                        available: root.activePlayer !== null && root.activePlayer.canGoPrevious
                        onTriggered: if (root.activePlayer) { Services.AppState.mediaStep(-1); root.activePlayer.previous() }
                    }
                    CtlChip {
                        id: playChip
                        anchors.verticalCenter: parent.verticalCenter
                        opacity: root.sharedOpacity
                        inert: root.ghostShared
                        size: root.playLg
                        glyphSize: 24
                        glyph: root.playGlyph
                        available: root.hasPlayer
                        active: root.activePlayer !== null && root.activePlayer.isPlaying
                        onTriggered: if (root.activePlayer) root.activePlayer.togglePlaying()
                    }
                    CtlChip {
                        id: nextChip
                        anchors.verticalCenter: parent.verticalCenter
                        opacity: root.sharedOpacity
                        inert: root.ghostShared
                        size: root.chipLg
                        glyphSize: 20
                        glyph: "\ue044"
                        available: root.activePlayer !== null && root.activePlayer.canGoNext
                        onTriggered: if (root.activePlayer) { Services.AppState.mediaStep(1); root.activePlayer.next() }
                    }
                    // The words, on or off. The column is the default and this
                    // only takes it away -- so the chip shows up only where
                    // there is a column to hide, and remembers the answer.
                    CtlChip {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: root.offerLyrics && Services.Lyrics.has
                        opacity: root.beat(2)
                        size: root.chipLg
                        glyphSize: 20
                        glyph: "\uec0b"
                        active: Services.Prefs.mediaLyrics
                        onTriggered: Services.Prefs.mediaLyrics = !Services.Prefs.mediaLyrics
                    }
                    // Repeat cycles the three MPRIS states, and says which one
                    // it is with the glyph: the whole list, or this one track.
                    CtlChip {
                        anchors.verticalCenter: parent.verticalCenter
                        opacity: root.beat(2)
                        size: root.chipLg
                        glyphSize: 20
                        glyph: (root.activePlayer !== null
                                && root.activePlayer.loopState === MprisLoopState.Track)
                               ? "\ue041" : "\ue040"
                        available: root.activePlayer !== null && root.activePlayer.loopSupported
                        active: root.activePlayer !== null
                                && root.activePlayer.loopState !== MprisLoopState.None
                        onTriggered: {
                            if (!root.activePlayer) return
                            const p = root.activePlayer
                            p.loopState = p.loopState === MprisLoopState.None ? MprisLoopState.Playlist
                                        : p.loopState === MprisLoopState.Playlist ? MprisLoopState.Track
                                        : MprisLoopState.None
                        }
                    }
                }
            }
        }

        // ── What is being sung, and what it sounds like ─────────────────
        // One block, not two columns that happen to be next to each other: the
        // words and the wave are the same thing said twice, so they keep half
        // the card's gap between them and the whole of it from the controls.
        RowLayout {
            id: rightBlock
            // Zero, and the words carry their own gap in their width: a
            // layout charges its spacing for a child of no width too, so a
            // closed column would leave a hole where it used to be.
            spacing: 0
            Layout.preferredHeight: root.artSize
            Layout.alignment: Qt.AlignVCenter

            // ── The words ───────────────────────────────────────────────────
            // A column of its own, not a drawer under the card: lyrics are the
            // second thing the card is about, and a drawer made them a thing you
            // had to ask for twice. No words for this track and the column takes
            // its width back, so the panel is exactly as wide as it has to be.
            Item {
                id: lyricsCol
                Layout.preferredWidth: root.lyricsShown ? root.lyricsW + root.wordGap : 0
                Layout.preferredHeight: root.artSize
                Layout.alignment: Qt.AlignVCenter
                clip: true
                opacity: root.beat(3)

                Behavior on Layout.preferredWidth {
                    NumberAnimation {
                        duration: Services.Sizes.msPanel
                        easing.type: Services.Sizes.easeBox
                    }
                }

                // The line follows the song; the body reads the COMMITTED index so
                // the arriving line does not both leave and arrive.
                SlideSwap {
                    id: verseSlide
                    index: Services.Lyrics.indexAt(root.position)
                    axis: "vertical"
                    travel: 16
                }

                // What the slide has committed. Before it has committed anything --
                // the case the moment a card is built -- the live index stands in,
                // or the column would sit empty until the song reached its next
                // line.
                property int at: -1
                readonly property int shown: lyricsCol.at >= 0 ? lyricsCol.at : verseSlide.index
                Component.onCompleted: lyricsCol.at = verseSlide.index
                Connections {
                    target: verseSlide
                    function onCommit() { lyricsCol.at = verseSlide.index }
                }

                function lineAt(i) {
                    return (i >= 0 && i < Services.Lyrics.lines.length)
                        ? Services.Lyrics.lines[i].text : ""
                }

                // Five slots, the sung one in the middle: two behind you and two
                // ahead is enough to follow without reading a page.
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.rightMargin: root.wordGap
                    spacing: 7
                    opacity: verseSlide.fade
                    transform: Translate { y: verseSlide.offY }

                    component Line: Text {
                        property int off: 0
                        width: parent.width
                        text: lyricsCol.lineAt(lyricsCol.shown + off)
                        // The sung line is the only one at full weight; the others
                        // fall back a step each, so the eye lands on it without a
                        // marker in the margin.
                        color: off === 0 ? Services.Colors.snow
                             : Math.abs(off) === 1 ? Services.Colors.mist
                                                   : Services.Colors.ash
                        font.pixelSize: off === 0 ? Services.Sizes.fsInput : Services.Sizes.fsMeta
                        font.bold: off === 0
                        font.family: "JetBrainsMono NF"
                        wrapMode: Text.WordWrap
                        maximumLineCount: off === 0 ? 2 : 1
                        elide: Text.ElideRight
                    }

                    Line { off: -2 }
                    Line { off: -1 }
                    Line { off: 0 }
                    Line { off: 1 }
                    Line { off: 2 }
                }
            }

            // ── Spectrum column ─────────────────────────────────────────────
            // Cava used to wash the whole card as a backdrop. It has its own room
            // now: bars laid on their side and mirrored about the centre line, so
            // the column reads as a swell rather than a row of teeth.
            Item {
                id: cavaCol
                // Switched off it takes no room either.
                visible: root.showSpectrum && Services.Cava.enabled
                Layout.preferredWidth: cavaCol.visible ? root.cavaW : 0
                Layout.preferredHeight: root.artSize
                Layout.alignment: Qt.AlignVCenter
                // Solid, and no fade when the room goes quiet: silence is said by
                // the bars collapsing onto their axis, not by the column going
                // translucent. A washed cava reads as a screenshot of one.
                opacity: root.beat(4)
                Behavior on opacity { NumberAnimation { duration: Services.Sizes.msPanel } }

                // Axis the bars grow out of. Silence collapses every bar to its cap,
                // and without something to sit on those caps read as a column of
                // stray dots rather than a level meter.
                Rectangle {
                    anchors.centerIn: parent
                    width: 2
                    height: parent.height
                    radius: 1
                    color: Services.Colors.fillLine
                }

                Canvas {
                    id: cavaCanvas
                    anchors.fill: parent

                    // 96 raw bars in 160 px would be slivers; folded down to two
                    // dozen they have room to be read as waves.
                    readonly property int rows: 24
                    readonly property real barH: 4

                    Connections {
                        target: Services.Cava
                        function onBarValuesChanged() { cavaCanvas.requestPaint() }
                    }

                    onPaint: {
                        const ctx = getContext("2d")
                        ctx.reset()
                        const src = Services.Cava.barValues
                        if (!src || src.length === 0) return

                        const n = rows
                        const group = Math.max(1, Math.floor(src.length / n))
                        let vals = []
                        for (let i = 0; i < n; i++) {
                            let sum = 0
                            for (let k = 0; k < group; k++) sum += src[i * group + k] || 0
                            vals.push(Math.max(0, Math.min(100, sum / group)) / 100)
                        }
                        // One pass of neighbour averaging: without it the column is
                        // noise, with it the peaks roll.
                        const sm = vals.map((v, i) => (vals[Math.max(0, i - 1)] + v
                                                     + vals[Math.min(n - 1, i + 1)]) / 3)

                        const gap = (height - n * barH) / (n - 1)
                        const cx = width / 2
                        const maxLen = width / 2

                        // The accent itself, not a mix with the plate: the bars are
                        // the one thing on the card that IS the sound.
                        ctx.fillStyle = Services.Colors.ghost
                        for (let i = 0; i < n; i++) {
                            const half = Math.max(barH / 2, sm[i] * maxLen)
                            const y = i * (barH + gap)
                            ctx.beginPath()
                            ctx.roundedRect(cx - half, y, half * 2, barH, barH / 2, barH / 2)
                            ctx.fill()
                        }
                    }
                }
            }
        }
    }
}
