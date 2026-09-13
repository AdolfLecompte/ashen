pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// What version this is, what changed in it, and whether you have been told.
// The notes are not written twice: they are the CHANGELOG the repo already
// ships, parsed at startup. A release that forgets to update the changelog
// simply has nothing to announce, which is the right punishment.
Singleton {
    id: root

    // ── The file ────────────────────────────────────────────────────────
    property string raw: ""
    FileView {
        path: Paths.changelog
        onLoaded: root.raw = text()
        onLoadFailed: root.raw = ""
    }

    // ── What the changelog says ─────────────────────────────────────────
    // The newest numbered heading. "Unreleased" is skipped on purpose: work in
    // the tree is not a release, and announcing it would fire on every edit.
    readonly property var sections: {
        const out = []
        if (root.raw === "") return out
        const lines = root.raw.split("\n")
        let cur = null
        for (const ln of lines) {
            const head = ln.match(/^##\s+(.+?)\s*$/)
            if (head) {
                if (cur) out.push(cur)
                cur = { title: head[1], entries: [] }
                continue
            }
            if (!cur) continue
            const group = ln.match(/^###\s+(.+?)\s*$/)
            if (group) { cur.entries.push({ group: group[1], text: "" }); continue }
            const item = ln.match(/^-\s+(.+?)\s*$/)
            if (item) { cur.entries.push({ group: "", text: item[1] }); continue }
            // A wrapped bullet: it belongs to the line above it.
            const cont = ln.match(/^\s{2,}(\S.*?)\s*$/)
            if (cont && cur.entries.length > 0) {
                const last = cur.entries[cur.entries.length - 1]
                if (last.text !== "") last.text += " " + cont[1]
            }
        }
        if (cur) out.push(cur)
        return out
    }
    readonly property var current: {
        for (const s of root.sections)
            if (/^\d+\.\d+/.test(s.title)) return s
        return null
    }
    readonly property string version: root.current ? root.current.title : ""
    readonly property var notes: root.current ? root.current.entries : []

    // ── Is there a newer Ashen? ──────────────────────────────────────────
    // NOT services/Updates: that runs checkupdates and an AUR helper and answers
    // "are my PACKAGES out of date", which is a different question. This one
    // asks the repository, on a button -- a shell that phones home on a timer is
    // a different thing from one that answers when asked.
    //
    // Two traps, both covered by docs/probes/run-version-probe.sh:
    //   the tag is `v2.1.0` and the CHANGELOG heading is `2.1.0`
    //   comparing as strings claims 2.10.0 < 2.9.0
    function newer(a, b) {
        const pa = String(a).replace(/^v/, "").split(".").map(Number)
        const pb = String(b).replace(/^v/, "").split(".").map(Number)
        for (let i = 0; i < Math.max(pa.length, pb.length); i++) {
            const x = pa[i] || 0, y = pb[i] || 0
            if (x !== y) return x > y
        }
        return false
    }

    property string latest: ""
    property bool checking: false
    // idle · checking · current · available · ahead · failed
    property string checkState: "idle"

    function check() {
        if (root.checking) return
        root.checking = true
        root.checkState = "checking"
        checkProc.running = true
    }

    Process {
        id: checkProc
        running: false
        // --max-time so a panel never hangs on a network that is merely slow.
        command: ["sh", "-c",
            "curl -fsSL --max-time 8 https://api.github.com/repos/AdolfLecompte/ashen/releases/latest"
            + " | grep -m1 '\"tag_name\"' | cut -d'\"' -f4"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.checking = false
                const tag = text.trim()
                if (tag === "") { root.checkState = "failed"; return }
                root.latest = tag
                // A checkout can be AHEAD of the newest tag. That is not an
                // error and must not be offered as an update.
                root.checkState = root.newer(tag, root.version) ? "available"
                                : root.newer(root.version, tag) ? "ahead"
                                : "current"
            }
        }
        onExited: (code) => { if (code !== 0) { root.checking = false; root.checkState = "failed" } }
    }

    // What the row SAYS about all that. Not a label -- a remark, so it comes
    // from the phrase bank like every other line the shell offers rather than
    // states. A binding, deliberately: the bank arrives asynchronously and a
    // binding re-runs when it does, where a signal handler would have fired
    // once against an empty bank and left the row blank forever.
    readonly property string statusKey:
          root.checkState === "checking"  ? "about.checking"
        : root.checkState === "current"   ? "about.current"
        : root.checkState === "ahead"     ? "about.ahead"
        : root.checkState === "failed"    ? "about.failed"
        : root.checkState === "available" ? "about.available"
        : "about.idle"
    readonly property string statusLine: Voice.pick(root.statusKey)

    // Markdown leaves **bold** in the text; the panel draws rich text, so the
    // stars become tags rather than being read out loud.
    //
    // Escaped FIRST: this is the one piece of text in the shell drawn as rich
    // text, and a `<tag>` written in the changelog would otherwise be parsed --
    // an <img> in rich text is how a clipboard entry took the whole shell down.
    function rich(s) {
        return String(s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
                        .replace(/\*\*(.+?)\*\*/g, "<b>$1</b>")
                        .replace(/`(.+?)`/g, "<font face='JetBrainsMono NF'>$1</font>")
    }

    // ── What the user has already been shown ────────────────────────────
    property string seenVersion: ""
    property bool everRun: false
    property bool loaded: false

    // Never before the file has been read, or a fresh install would be
    // announced to someone who has been running this for months.
    readonly property bool needsWelcome: root.loaded && !root.everRun
    readonly property bool needsNotes: root.loaded && root.everRun
        && root.version !== "" && root.seenVersion !== root.version

    function markSeen() {
        root.everRun = true
        // The changelog is read asynchronously: closing the card in the first
        // second of a session would otherwise store an empty version and the
        // notes would come back at the next login.
        if (root.version !== "") root.seenVersion = root.version
        seenFile.writeAdapter()
    }
    // …and if it was still empty when that happened, the version adopts it as
    // soon as it is known. Somebody who was just welcomed does not also need to
    // be told what changed since a release they never ran.
    onVersionChanged: {
        if (root.loaded && root.everRun && root.seenVersion === "" && root.version !== "") {
            root.seenVersion = root.version
            seenFile.writeAdapter()
        }
    }

    FileView {
        id: seenFile
        path: Paths.config + "/intro.json"
        onAdapterUpdated: if (root.loaded) writeAdapter()
        onLoaded: root.loaded = true
        // No file at all IS the first run: that is the whole signal.
        onLoadFailed: root.loaded = true

        JsonAdapter {
            property alias seenVersion: root.seenVersion
            property alias everRun: root.everRun
        }
    }
}
