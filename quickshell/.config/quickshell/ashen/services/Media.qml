pragma Singleton
import Quickshell
import Quickshell.Services.Mpris
import QtQuick

// Transport for the media keys, and the one cover every surface draws.
Singleton {
    id: root

    readonly property var player: {
        const live = Mpris.players.values.filter(p => p.playbackState !== MprisPlaybackState.Stopped)
        if (live.length === 0) return null
        const playing = live.find(p => p.isPlaying)
        return playing !== undefined ? playing : live[0]
    }

    // The cover, held on the last player through the few ms MPRIS drops to
    // nothing between tracks, so no surface ever blinks empty. Straight from
    // the player: the lyrics widget always read it this way and was the one
    // surface that never showed a wrong cover.
    property var held: null
    onPlayerChanged: {
        if (root.player !== null) { drop.stop(); root.held = root.player }
        else drop.restart()
    }
    Component.onCompleted: root.held = root.player
    Timer { id: drop; interval: 400; onTriggered: root.held = null }
    readonly property string art: root.held ? (root.held.trackArtUrl || "") : ""

    // Saying which way it goes before jumping is the whole point of routing the
    // keys through here: the sweep reads the same flag the buttons set.
    function next() {
        if (root.player === null) return
        AppState.mediaStep(1)
        if (root.player.canGoNext) root.player.next()
    }
    function previous() {
        if (root.player === null) return
        AppState.mediaStep(-1)
        if (root.player.canGoPrevious) root.player.previous()
    }
    function playPause() {
        if (root.player !== null) root.player.togglePlaying()
    }
}
