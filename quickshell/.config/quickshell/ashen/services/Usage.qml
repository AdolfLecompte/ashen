pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick

// How long each application had you, per day. Nothing is polled: the time runs
// from one change to the next -- focus moving, going idle, locking, the day
// turning -- and each change books what ran before it to the app that had it.
//
// What counts is time IN FRONT of the machine: a window left focused while you
// are away is not use, so idle and the lock screen stop the clock. Idle waits
// for input and respects inhibitors, so a film playing full screen still counts.
Singleton {
    id: root

    // "YYYY-MM-DD" -> { total: seconds, apps: { class: seconds }, hours: [24] }
    property var days: ({})
    property bool loaded: false
    // Moves whenever a total does, so bindings over the functions below re-run.
    property int revision: 0
    // A month of history is a trend; a year of it is a file nobody reads.
    readonly property int keepDays: 35

    // ── What is running now ──────────────────────────────────────────────
    // The focused window's class, lower-cased; "" when nothing has focus. From
    // Hyprland's own event rather than activeToplevel, which keeps handing back
    // the last window when focus lands on an empty workspace.
    property string focused: ""
    readonly property bool away: idle.isIdle || AppState.sessionLocked
    // What the clock is booking to right now ("" = nothing counts).
    readonly property string counting: (root.away || !root.loaded) ? "" : root.focused

    IdleMonitor {
        id: idle
        timeout: 120
        respectInhibitors: true
    }

    // Asked, not inferred. The event stream is not enough on its own: the
    // shell's own layers mapping at login send an `activewindow` with no class
    // after the real one, and nothing corrects it until focus moves again -- the
    // clock sat stopped with a terminal in front of it. So anything that can
    // move focus asks Hyprland which window is active, a beat later so a burst
    // of events is one question.
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            const n = event.name
            if (n === "activewindow" || n === "workspace" || n === "focusedmon"
                || n === "openwindow" || n === "closewindow" || n === "movewindow")
                askSoon.restart()
        }
    }
    Timer { id: askSoon; interval: 150; onTriggered: ask.running = true }
    // A slow backstop for whatever the events miss.
    Timer { interval: 30000; running: true; repeat: true; onTriggered: ask.running = true }
    Process {
        id: ask
        command: ["hyprctl", "activewindow", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                let cls = ""
                try {
                    const o = JSON.parse(text)
                    if (o && o.class) cls = String(o.class).toLowerCase()
                } catch (e) {}
                root.focused = cls
            }
        }
    }

    // ── Booking ──────────────────────────────────────────────────────────
    property string bookedKey: ""
    property double bookedSince: 0

    function dayKey(d) {
        const p = n => (n < 10 ? "0" : "") + n
        return d.getFullYear() + "-" + p(d.getMonth() + 1) + "-" + p(d.getDate())
    }

    // Everything since the last change goes to the app that had it, split at
    // midnight. A gap longer than the flush interval with nothing in between is
    // a suspend the shell slept through, and is not use.
    function book(now) {
        const key = root.bookedKey
        let from = root.bookedSince
        root.bookedSince = now
        if (key === "" || from <= 0 || now <= from) return
        if (now - from > flush.interval * 3) return
        const next = Object.assign({}, root.days)
        while (from < now) {
            const d = new Date(from)
            const midnight = new Date(d.getFullYear(), d.getMonth(), d.getDate() + 1).getTime()
            const to = Math.min(now, midnight)
            const dk = root.dayKey(d)
            const day = next[dk] ? Object.assign({}, next[dk]) : { total: 0, apps: {}, hours: [] }
            day.apps = Object.assign({}, day.apps)
            day.hours = day.hours && day.hours.length === 24 ? day.hours.slice() : new Array(24).fill(0)
            // Hours get their share by walking the span an hour at a time.
            let t = from
            while (t < to) {
                const h = new Date(t)
                const hourEnd = new Date(h.getFullYear(), h.getMonth(), h.getDate(), h.getHours() + 1).getTime()
                const chunk = Math.min(to, hourEnd) - t
                day.hours[h.getHours()] += chunk / 1000
                t += chunk
            }
            const secs = (to - from) / 1000
            day.total += secs
            day.apps[key] = (day.apps[key] || 0) + secs
            next[dk] = day
            from = to
        }
        root.days = next
        root.revision++
        root.dirty = true
    }

    // The clock changes hands: book what ran, start the new one.
    function turn() {
        const now = Date.now()
        root.book(now)
        root.bookedKey = root.counting
        root.bookedSince = now
    }
    onCountingChanged: root.turn()

    // Books the running span now and then, so a crash loses a minute at most and
    // the panel's numbers move while you look at them.
    Timer {
        id: flush
        interval: 60000
        running: root.loaded
        repeat: true
        onTriggered: {
            root.book(Date.now())
            root.prune()
            if (root.dirty) root.save()
        }
    }

    function prune() {
        const cutoff = root.dayKey(new Date(Date.now() - root.keepDays * 86400000))
        let changed = false
        const next = Object.assign({}, root.days)
        for (const k in next) if (k < cutoff) { delete next[k]; changed = true }
        if (changed) { root.days = next; root.dirty = true }
    }

    // ── Reading ──────────────────────────────────────────────────────────
    // Today's seconds with the span still running added in, for a surface that
    // wants to be live without waiting for the next flush.
    function liveExtra(dk) {
        if (root.bookedKey === "" || root.bookedSince <= 0) return 0
        if (dk !== root.dayKey(new Date())) return 0
        return Math.max(0, (Date.now() - root.bookedSince) / 1000)
    }

    // { total, apps: [{ key, secs }] biggest first } for one day.
    function day(dk) {
        root.revision
        const d = root.days[dk] || { total: 0, apps: {} }
        const extra = root.liveExtra(dk)
        const apps = []
        for (const k in d.apps) apps.push({ key: k, secs: d.apps[k] + (k === root.bookedKey ? extra : 0) })
        if (extra > 0 && d.apps[root.bookedKey] === undefined) apps.push({ key: root.bookedKey, secs: extra })
        apps.sort((a, b) => b.secs - a.secs)
        return { total: (d.total || 0) + extra, apps: apps, hours: d.hours || [] }
    }
    function today() { return root.day(root.dayKey(new Date())) }

    // The last seven days, oldest first: { key, date, total }.
    function week() {
        root.revision
        const out = []
        const now = new Date()
        for (let i = 6; i >= 0; i--) {
            const d = new Date(now.getFullYear(), now.getMonth(), now.getDate() - i)
            const dk = root.dayKey(d)
            const rec = root.days[dk]
            out.push({ key: dk, date: d, total: (rec ? rec.total : 0) + root.liveExtra(dk) })
        }
        return out
    }

    // "3h 12m", "45m", "under a minute" -- short, and never seconds.
    function span(secs) {
        const m = Math.floor(secs / 60)
        if (m < 1) return I18n.t("usage.underMinute")
        const h = Math.floor(m / 60)
        return h > 0 ? h + "h " + (m % 60) + "m" : m + "m"
    }

    // The application behind a class, for a name and an icon.
    function appOf(key) { return Apps.byClass(key) }
    function nameOf(key) {
        const a = root.appOf(key)
        return a && a.name ? a.name : key
    }

    // ── Storage ──────────────────────────────────────────────────────────
    property bool dirty: false
    function save() {
        root.dirty = false
        adapter.data = JSON.stringify({ v: 1, days: root.days })
    }
    FileView {
        id: file
        path: Paths.config + "/usage.json"
        // Nothing else writes it, and re-reading our own write would land the
        // old value on top of the new one.
        onAdapterUpdated: if (root.loaded) writeAdapter()
        onLoaded: root.read()
        // First run: seed the file so the next start reads it instead of
        // logging a failed read.
        onLoadFailed: function(error) { root.loaded = true; root.save(); root.turn() }
        JsonAdapter {
            id: adapter
            property string data: ""
        }
    }
    function read() {
        try {
            const parsed = JSON.parse(adapter.data || "{}")
            root.days = parsed && parsed.days ? parsed.days : ({})
        } catch (e) {
            root.days = ({})
        }
        root.loaded = true
        root.prune()
        root.turn()
    }

    // Built at login by ServiceLoader: time is only counted while it is awake.
    function arm() { ask.running = true }
    Component.onDestruction: { root.book(Date.now()); root.save() }
}
