import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import "root:/services" as Services
import "root:/modules/widgets" as Widgets

Item {
    id: root
    readonly property int pillH: Services.Sizes.pillH
    readonly property bool vertical: Services.Sizes.barVertical

    // Raw MPRIS read: drops to null for a few ms while the player changes track
    property var livePlayer: {
        let list = Mpris.players.values.filter(p => p.playbackState !== MprisPlaybackState.Stopped)
        if (list.length === 0) return null
        let playing = list.find(p => p.isPlaying)
        return playing !== undefined ? playing : list[0]
    }

    // Held across that gap so the pill does not collapse or flicker
    property var activePlayer: null
    // readonly: it is a fact about activePlayer, never something to set.
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
        onTriggered: if (root.livePlayer === null) {
            root.activePlayer = null
            root.stableArtUrl = ""
        }
    }
    function formatTime(seconds) {
        if (!seconds || seconds <= 0) return "0:00"
        let m = Math.floor(seconds / 60)
        let s = Math.floor(seconds % 60)
        return m + ":" + (s < 10 ? "0" : "") + s
    }
    function seekPrev() {
        if (!root.hasPlayer) return
        let p = root.activePlayer
        Services.AppState.mediaStep(-1)
        if (p.canGoPrevious) { p.previous(); return }
        if (p.canSeek) p.position = Math.max(0, p.position - 10)
    }
    function seekNext() {
        if (!root.hasPlayer) return
        let p = root.activePlayer
        Services.AppState.mediaStep(1)
        if (p.canGoNext) { p.next(); return }
        if (p.canSeek) p.position = Math.min(p.length, p.position + 10)
    }
    property string stableArtUrl: ""
    readonly property string liveTitle: root.hasPlayer ? (root.activePlayer.trackTitle || "") : ""
    function updateArt() {
        if (!root.hasPlayer) {
            root.stableArtUrl = ""
        } else if (root.activePlayer.trackArtUrl !== "") {
            root.stableArtUrl = root.activePlayer.trackArtUrl
        }
    }
    onActivePlayerChanged: updateArt()
    Connections {
        target: root.activePlayer
        ignoreUnknownSignals: true
        function onTrackArtUrlChanged() { root.updateArt() }
        // The cover often lands before the title it belongs to, and a cover
        // without a title is refused, so look again once the title is in.
        function onTrackTitleChanged() { root.updateArt() }
    }

    // ── Changing track ──────────────────────────────────────────────────
    // What the pill shows is committed halfway through a sweep, never bound
    // straight to the player: a new title and its cover do not arrive on the
    // same frame, and the cover loads asynchronously, so binding them live
    // blinked the placeholder between every song.
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

    property string shownTitle: ""
    property string shownArtUrl: ""
    // The cover was not decoded yet when the sweep committed: swap it in the
    // moment it is, rather than showing a hole.
    property bool artWaiting: false
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

    Widgets.SlideSwap {
        id: trackSwap
        travel: 12
        key: root.settledKey
        keyDir: Services.AppState.mediaDir
        onCommit: {
            root.shownTitle = root.settledKey !== "" ? root.settledKey
                            : (root.hasPlayer ? "Untitled" : "")
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
    // either, so the visible Image hits Qt's cache and is up on the first frame.
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

    height: root.vertical ? (hasPlayer ? expandedRow.implicitHeight + 20 : 0) : pillH
    width: root.vertical ? pillH : (hasPlayer ? expandedRow.implicitWidth + 20 : 0)
    // No player, no pill, and no slot either.
    readonly property bool wanted: root.opacity > 0
    visible: root.wanted
    Behavior on height { SmoothedAnimation { duration: Services.Sizes.msPronounced } }
    // The panel is a morphed copy of this pill, so while it is open the pill
    // itself steps aside: the card standing on its rect *is* the pill now.
    // Coming back it waits for the card to finish shrinking before reappearing,
    // otherwise both are drawn on the same spot for a frame.
    property bool takenOverByPanel: false
    Connections {
        target: Services.AppState
        // mediaMorphing, not mediaVisible: the pill must stay on screen until
        // the panel's surface is really up and the morph starts drawing
        function onMediaMorphingChanged() {
            if (Services.AppState.mediaMorphing) {
                handBack.stop()
                root.takenOverByPanel = true
            } else {
                handBack.restart()
            }
        }
    }
    // The card un-transforms where it stands and only then travels home,
    // landing on this rect at ~720 ms; fade in just under that so the two
    // overlap for a few frames instead of leaving a hole.
    Timer { id: handBack; interval: 330; onTriggered: root.takenOverByPanel = false }

    // Only the body fades out on takeover, never this Item: it has to keep
    // holding its slot in the bar or the row would close the gap and shift.
    opacity: hasPlayer ? 1.0 : 0.0
    Behavior on width { SmoothedAnimation { duration: Services.Sizes.msPronounced } }
    Behavior on opacity { NumberAnimation { duration: Services.Sizes.msStandard } }

    // The pointer being on the pill is what lets a long title walk, and a
    // HoverHandler sees it even while the transport chips have the mouse --
    // a MouseArea underneath them would go blind the moment you reached for
    // play.
    HoverHandler { id: pillHover }

    // Reports its real on-screen position so MediaPanel can center below it
    PillCenter { key: "media" }

    // …and its size, so the panel knows the rect it has to grow out of
    Binding { target: Services.AppState; property: "mediaPillW"; value: root.width }
    Binding { target: Services.AppState; property: "mediaPillH"; value: root.height }
Component.onCompleted: { activePlayer = livePlayer; updateArt() }

    Rectangle {
        anchors.fill: parent
        radius: Services.Sizes.pillR
        // No hover plate, deliberately: this is a strip of controls that each
        // answer for themselves, and lighting the whole thing said "click me"
        // over three chips that do different things. It also animates its own
        // width, and a plate changing under a resizing box reads as a glitch.
        color: Services.Colors.pillPlate
        border.color: Services.Colors.fillRest
        border.width: 0
        clip: true
        // Constant duration on purpose: a `takenOverByPanel ? a : b` here would
        // be read with the flag's old value, so each direction would get the
        // other one's timing. The card sits on the same rect anyway, so the
        // few frames where both are drawn are indistinguishable.
        opacity: (root.takenOverByPanel && Services.Pills.wearsFace) ? 0.0 : 1.0
        Behavior on opacity { NumberAnimation { duration: Services.Sizes.msMicro } }

        Grid {
            id: expandedRow
            visible: root.hasPlayer
            // Along the bar on a top bar, across it on a side one: cover first,
            // then transport. The title does not come along -- 44 px of column
            // is not somewhere a song name can be read, and it was the one part
            // that would have had to shrink to fit.
            // EXACTLY the three cells it has, never a big number: a Grid with
            // more columns than items still charges one `spacing` for the
            // empty one, and that phantom lands on the right -- the pill sat
            // 14 px wider past the last chip than before the cover.
            columns: root.vertical ? 1 : 3
            horizontalItemAlignment: Grid.AlignHCenter
            verticalItemAlignment: Grid.AlignVCenter
            anchors.verticalCenter: root.vertical ? undefined : parent.verticalCenter
            anchors.top: root.vertical ? parent.top : undefined
            anchors.topMargin: 10
            anchors.left: root.vertical ? undefined : parent.left
            anchors.horizontalCenter: root.vertical ? parent.horizontalCenter : undefined
            anchors.leftMargin: 10
            spacing: 8

            Rectangle {
    id: artFrame
    // Album art tracks the pill height, leaving a small margin around it
    width: Services.Sizes.pillH - 10; height: Services.Sizes.pillH - 10
    radius: Services.Sizes.innerR
    color: Services.Colors.abyss
    // Paused, the cover stands down: it was the one part of the pill that
    // looked exactly the same whether anything was playing or not.
    readonly property real playingAmt: (root.activePlayer !== null && root.activePlayer.isPlaying) ? 1.0 : 0.45
    opacity: trackSwap.fade * artFrame.playingAmt
    Behavior on opacity { NumberAnimation { duration: Services.Sizes.msStandard } }
    transform: Translate { x: trackSwap.offX }
    Image {
        id: pillArt
        anchors.fill: parent
        source: root.shownArtUrl
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: false
        layer.enabled: true
    }
    Rectangle {
        id: pillArtMask
        anchors.fill: parent
        radius: Services.Sizes.innerR
        visible: false
        layer.enabled: true
    }
    OpacityMask {
        anchors.fill: parent
        source: pillArt
        maskSource: pillArtMask
        visible: pillArt.status === Image.Ready
    }
    Text {
        anchors.centerIn: parent
        // Only when there is genuinely no cover, never while one decodes.
        visible: root.shownArtUrl === ""
        text: ""
        color: Services.Colors.ash
        font.family: "Material Symbols Rounded"
        font.pixelSize: 18
    }
}

            Column {
                visible: !root.vertical
                spacing: 3
                width: root.vertical ? 0 : 120
                opacity: trackSwap.fade
                transform: Translate { x: trackSwap.offX }

                Widgets.MarqueeText {
                    width: parent.width
                    text: root.shownTitle
                    color: Services.Colors.snow
                    pixelSize: 11
                    active: pillHover.hovered
                }
                
    Text {
        width: parent.width
        visible: root.hasPlayer
        text: root.hasPlayer ? (root.formatTime(root.activePlayer.position) + "/" + root.formatTime(root.activePlayer.length)) : ""
        color: Services.Colors.mist
        font.pixelSize: 10
        font.family: "JetBrainsMono NF"
        font.bold: true
    }
            }

            // Transport on workspace-style chips, so the bar speaks one
            // language: a dim plate means "there, but idle", a lit plate means
            // "this is the one". Playing lights the play chip the same way the
            // workspace you are standing on is lit.
            Grid {
                // Three chips, three columns: see the note above.
                columns: root.vertical ? 1 : 3
                horizontalItemAlignment: Grid.AlignHCenter
                verticalItemAlignment: Grid.AlignVCenter
                spacing: Services.Sizes.btnGap

                Widgets.CtlChip {
                    glyph: "\ue045"
                    available: root.activePlayer !== null && root.activePlayer.canGoPrevious
                    onTriggered: if (root.activePlayer) { Services.AppState.mediaStep(-1); root.activePlayer.previous() }
                }
                Widgets.CtlChip {
                    glyph: root.activePlayer !== null && root.activePlayer.isPlaying ? "\ue034" : "\ue037"
                    glyphSize: 20
                    available: root.hasPlayer
                    active: root.activePlayer !== null && root.activePlayer.isPlaying
                    onTriggered: if (root.activePlayer) root.activePlayer.togglePlaying()
                }
                Widgets.CtlChip {
                    glyph: "\ue044"
                    available: root.activePlayer !== null && root.activePlayer.canGoNext
                    onTriggered: if (root.activePlayer) { Services.AppState.mediaStep(1); root.activePlayer.next() }
                }
            }
            
}

        
    }

    // Clicking any free area of the pill opens the expanded panel. Under the
    // transport chips (z: -1), so they keep their own hover; a MouseArea on top
    // would swallow every move and the chips below would never see the pointer.
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        z: -1
        onClicked: {
            if (root.hasPlayer) Services.AppState.togglePanel("mediaVisible")
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.activePlayer !== null && root.activePlayer.isPlaying
        onTriggered: if (root.hasPlayer) root.activePlayer.positionChanged()
    }
}
