pragma Singleton
import Quickshell
import Quickshell.Io
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

    // Is anything playing right now, on any player.
    readonly property bool playing: Mpris.players.values.some(p => p.isPlaying)

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
    // Browsers hand MPRIS a 150 px thumbnail; a full-size cover is looked up
    // on Deezer by artist and title, cached, and used when it is found.
    readonly property string art: root.hiArt !== "" ? root.hiArt
        : root.held ? (root.held.trackArtUrl || "") : ""

    // ── Full-size covers ────────────────────────────────────────────────
    property string hiArt: ""
    readonly property string artist: root.held ? (root.held.trackArtist || "") : ""
    // YouTube titles carry "(Official Video)" and the like: drop the brackets.
    readonly property string title: root.held
        ? String(root.held.trackTitle || "").replace(/\s*[\(\[][^\)\]]*[\)\]]/g, "").trim() : ""
    readonly property string coverKey: root.title === "" ? "" : root.artist + "\u0001" + root.title
    readonly property string coverDir: Paths.cache + "/ashen_art"
    // Computed from the key, never read back from a binding: inside
    // onCoverKeyChanged a derived property may still hold the previous track.
    function fileFor(key) { return key === "" ? "" : root.coverDir + "/" + Qt.md5(key) + ".jpg" }
    // MPRIS updates artist and title one at a time: wait for the pair to settle.
    onCoverKeyChanged: {
        root.hiArt = ""
        coverSettle.restart()
    }
    Timer {
        id: coverSettle
        interval: 400
        onTriggered: root.lookUp()
    }
    function lookUp() {
        if (root.coverKey === "") return
        // Every step carries the file it was started for, so a track that
        // changes mid-search can never file its cover under the next one.
        root.reqFile = root.fileFor(root.coverKey)
        root.reqArtist = root.artist
        root.reqQuery = root.artist + " " + root.title
        coverFind.running = false
        coverSearch.running = false
        coverFind.command = ["sh", "-c", 'test -s "$1" && printf %s "$1"', "sh", root.reqFile]
        coverFind.running = true
    }
    property string reqFile: ""
    property string reqArtist: ""
    property string reqQuery: ""
    function showIfCurrent(file) {
        if (file !== "" && file === root.fileFor(root.coverKey)) root.hiArt = "file://" + file
    }
    // Cached already, or ask Deezer.
    Process {
        id: coverFind
        stdout: StdioCollector {
            onStreamFinished: {
                if (text !== "") { root.showIfCurrent(text); return }
                coverSearch.command = ["sh", "-c",
                    'curl -s --max-time 8 -G https://api.deezer.com/search --data-urlencode "q=$2"; printf "\\n%s" "$1"',
                    "sh", root.reqFile, root.reqQuery]
                coverSearch.running = true
            }
        }
    }
    // First hit by the same artist; a different one means a wrong cover.
    Process {
        id: coverSearch
        stdout: StdioCollector {
            onStreamFinished: {
                // The last line is the file this search was started for.
                const cut = text.lastIndexOf("\n")
                const file = text.slice(cut + 1)
                if (file === "" || file !== root.reqFile) return
                let url = ""
                try {
                    const a = root.reqArtist.toLowerCase()
                    for (const d of (JSON.parse(text.slice(0, cut)).data || [])) {
                        const n = (d.artist && d.artist.name || "").toLowerCase()
                        if (a !== "" && !n.includes(a) && !a.includes(n)) continue
                        if (d.album && d.album.cover_xl) { url = d.album.cover_xl; break }
                    }
                } catch (e) {}
                if (url === "") return
                coverGet.command = ["sh", "-c",
                    'mkdir -p "$(dirname "$1")" && curl -s --max-time 10 -o "$1.part" "$2" && mv "$1.part" "$1" && printf %s "$1"',
                    "sh", file, url]
                coverGet.running = false
                coverGet.running = true
            }
        }
    }
    Process {
        id: coverGet
        stdout: StdioCollector {
            // Filed under its own track; shown only if that track still plays.
            onStreamFinished: root.showIfCurrent(text)
        }
    }

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
