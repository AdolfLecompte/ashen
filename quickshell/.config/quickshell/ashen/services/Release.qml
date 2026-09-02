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

    // Markdown leaves **bold** in the text; the panel draws rich text, so the
    // stars become tags rather than being read out loud.
    function rich(s) {
        return String(s).replace(/\*\*(.+?)\*\*/g, "<b>$1</b>")
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
