// Ashen — Pomodoro cycle on top of the Countdown service.
pragma Singleton
import Quickshell
import QtQuick
import "root:/services" as Services

// Focus 25 / short break 5, a long break 15 after every fourth focus. It owns
// no clock: each phase is a Countdown run, and Countdown.rang advances it.
Singleton {
    id: root

    // "focus" | "short" | "long"
    property string phase: "focus"
    // Focus blocks finished in the current set of four
    property int done: 0
    // True from the first start until reset; keeps Countdown's end from being
    // taken for a plain timer finishing.
    property bool engaged: false

    // ── Setup, saved as "focus,short,long,auto" ─────────────────────────
    readonly property var setup: {
        const p = (Services.Prefs.pomodoroSetup || "").split(",").map(Number)
        const ok = (v, d) => (v >= 1 && v <= 180) ? Math.round(v) : d
        return { focus: ok(p[0], 25), short: ok(p[1], 5), long: ok(p[2], 15), auto: p.length > 3 ? p[3] !== 0 : true }
    }
    readonly property var minutes: ({ "focus": root.setup.focus, "short": root.setup.short, "long": root.setup.long })
    readonly property bool auto: root.setup.auto
    function save(s) { Services.Prefs.pomodoroSetup = [s.focus, s.short, s.long, s.auto ? 1 : 0].join(",") }
    // Step one phase's length. What is on the clock follows it only while
    // nothing is counting: changing the rules must not eat a run in progress.
    function bumpMinutes(which, delta) {
        const s = Object.assign({}, root.setup)
        s[which] = Math.max(1, Math.min(180, s[which] + delta))
        root.save(s)
        if (which === root.phase && !root.engaged && !Services.Countdown.active)
            Services.Countdown.setPreset(s[which] * 60000)
    }
    function setAuto(on) { const s = Object.assign({}, root.setup); s.auto = on; root.save(s) }
    // Jump to a phase from its chip, parked and ready, not started.
    function goTo(p) {
        if (p === root.phase) return
        root.phase = p
        root.engaged = true
        Services.Countdown.reset()
        Services.Countdown.setPreset(root.minutes[p] * 60000)
    }

    // ── Focus done today: "day|blocks|secs", reset when the day turns ───
    function dayKey() { return Qt.formatDate(new Date(), "yyyy-MM-dd") }
    readonly property var today: {
        const p = (Services.Prefs.pomodoroToday || "").split("|")
        return p[0] === root.dayKey() ? { blocks: +p[1] || 0, secs: +p[2] || 0 } : { blocks: 0, secs: 0 }
    }
    function book(blocks, secs) {
        const t = root.today
        Services.Prefs.pomodoroToday = [root.dayKey(), t.blocks + blocks, t.secs + Math.round(secs)].join("|")
    }

    function begin() {
        if (!engaged) { engaged = true; Services.Countdown.startFor(minutes[phase] * 60000) }
        else Services.Countdown.start()
    }
    function toggle() { Services.Countdown.running ? Services.Countdown.pause() : begin() }

    // Move to the phase that follows the current one. `finished` = the clock ran
    // out (and so may stop there when auto is off); a skip always starts it.
    function next(finished) {
        if (phase === "focus") {
            // A skipped focus books what was actually spent; a finished one books it whole.
            const spent = finished ? minutes.focus * 60 : Math.max(0, (Services.Countdown.preset - Services.Countdown.remaining) / 1000)
            root.book(finished ? 1 : 0, spent)
            done++
            if (done >= 4) { done = 0; phase = "long" } else phase = "short"
        } else phase = "focus"
        engaged = true
        if (finished && !root.auto) {
            Services.Countdown.reset()
            Services.Countdown.setPreset(minutes[phase] * 60000)
        } else Services.Countdown.startFor(minutes[phase] * 60000)
    }
    function reset() {
        engaged = false
        phase = "focus"
        done = 0
        Services.Countdown.reset()
        Services.Countdown.setPreset(minutes.focus * 60000)
    }

    Connections {
        target: Services.Countdown
        function onRang() { if (root.engaged) root.next(true) }
    }
}
