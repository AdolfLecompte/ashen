pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import QtQuick

// Timed lyrics for whatever is playing. MPRIS carries none -- not Brave, not
// Spotify -- so they come from lrclib.net, which asks for no key and no
// account. Half of what anyone plays is not in there; that is normal, and
// having none is a state, not a failure.
Singleton {
    id: root

    // Same sticky read as everywhere else: MPRIS drops to null for a few ms
    // between tracks, and asking for the lyrics of nothing wastes a request.
    readonly property var livePlayer: {
        const live = Mpris.players.values.filter(p => p.playbackState !== MprisPlaybackState.Stopped)
        if (live.length === 0) return null
        const playing = live.find(p => p.isPlaying)
        return playing !== undefined ? playing : live[0]
    }
    property var player: null
    onLivePlayerChanged: if (root.livePlayer !== null) root.player = root.livePlayer

    readonly property string title: root.player ? (root.player.trackTitle || "") : ""
    readonly property string artist: root.player ? (root.player.trackArtist || "") : ""
    readonly property real duration: root.player ? (root.player.length || 0) : 0

    // [{ at (seconds), text }], in order. Empty means: asked, nothing there.
    property var lines: []
    property bool loading: false
    readonly property bool has: root.lines.length > 0

    // Which line belongs to a moment. Linear from the top: a song has a few
    // dozen lines, and a binary search here would be a lie about the cost.
    function indexAt(pos) {
        let idx = -1
        for (let i = 0; i < root.lines.length; i++) {
            if (root.lines[i].at <= pos) idx = i
            else break
        }
        return idx
    }
    function lineAt(pos) {
        const i = root.indexAt(pos)
        return i < 0 ? "" : root.lines[i].text
    }

    // [mm:ss.xx] text -- several stamps can share one line.
    function parseLrc(lrc) {
        const out = []
        for (const raw of String(lrc).split("\n")) {
            const text = raw.replace(/\[[0-9]{1,3}:[0-9]{2}(\.[0-9]{1,3})?\]/g, "").trim()
            const stamps = raw.match(/\[[0-9]{1,3}:[0-9]{2}(\.[0-9]{1,3})?\]/g)
            if (!stamps) continue
            for (const s of stamps) {
                const p = s.slice(1, -1).split(":")
                out.push({ at: parseInt(p[0]) * 60 + parseFloat(p[1]), text: text })
            }
        }
        out.sort((a, b) => a.at - b.at)
        return out
    }

    // One track at a time, and never the one already on the screen.
    property string wanted: ""
    onTitleChanged: askSoon.restart()
    onArtistChanged: askSoon.restart()
    Timer {
        id: askSoon
        // The title arrives before the artist, and both flicker on a track
        // change: asking on the first of them asks for a track that never was.
        interval: 900
        onTriggered: root.fetch()
    }

    function fetch() {
        const key = root.artist + "|" + root.title
        if (root.title === "" || key === root.wanted) return
        root.wanted = key
        root.lines = []
        root.loading = true
        proc.running = false
        proc.running = true
    }

    Process {
        id: proc
        running: false
        command: ["sh", "-c",
            // Cache by content, keyed on artist and title -- the same trick the
            // cover cache uses, for the same reason: the URL is not stable but
            // the song is. Written to a temp name and renamed, so a killed
            // fetch cannot leave half a file behind.
            'C="$HOME/.cache/ashen_lyrics"; mkdir -p "$C"; ' +
            'k=$(printf %s "$1|$2" | sha256sum | cut -c1-32); f="$C/$k.json"; ' +
            'if [ ! -s "$f" ]; then ' +
            '  curl -sfG --max-time 6 --data-urlencode "artist_name=$1" ' +
            '    --data-urlencode "track_name=$2" --data-urlencode "duration=$3" ' +
            '    https://lrclib.net/api/get -o "$f.tmp" 2>/dev/null ' +
            '    && mv -f "$f.tmp" "$f" || printf "{}" > "$f"; ' +
            'fi; cat "$f"; ' +
            // Keep the newest three hundred; a year of listening is not a cache.
            'ls -1t "$C" | tail -n +301 | while read -r old; do rm -f "$C/$old"; done',
            "sh", root.artist, root.title, String(Math.round(root.duration))
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                root.loading = false
                try {
                    const d = JSON.parse(text.trim() || "{}")
                    root.lines = d.syncedLyrics ? root.parseLrc(d.syncedLyrics) : []
                } catch (e) {
                    root.lines = []
                }
            }
        }
    }
}
