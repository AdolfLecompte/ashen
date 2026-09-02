pragma Singleton
import Quickshell
import QtQuick

// What the shell says when it has a moment to say something. Every line in the
// rice that is a remark rather than a label lives here, keyed by the moment it
// belongs to -- so the tone is decided once, in one file, instead of drifting
// panel by panel.
//
// Dry, lowercase, more wry than funny: a line you will read a thousand times
// cannot be a joke. Anything that has to be READ to use the shell is a label
// and does not belong here.
Singleton {
    id: root

    readonly property var lines: ({
        // The pause after the password is right: the screen has a second to
        // fill, and filling it with nothing is what made the unlock feel abrupt.
        "lock.checking": [
            "checking…",
            "reading your face…",
            "asking the machine…",
            "looking you up…"
        ],
        // The second line of that pause, once it has decided.
        "lock.welcome": [
            "you're not an impostor, right?",
            "the machine remembers you",
            "close enough",
            "go on then",
            "welcome back"
        ],
        // Wrong password. Never scolding: it is a typo, not a crime.
        "lock.wrong": [
            "that's not it",
            "nope",
            "try that again",
            "the keys are all still there",
            "not quite"
        ],
        // Wrong twice or more in a row, which is worth noticing out loud.
        "lock.wrongAgain": [
            "still not it",
            "take your time",
            "caps lock, maybe?",
            "we can do this all night"
        ],

        // An empty notification history. Nothing waiting is not an error, so
        // it does not get an error's voice.
        "notify.empty": [
            "nothing over here",
            "all quiet",
            "lost something?",
            "not a peep",
            "you're all caught up",
            "clean slate"
        ],
        // No words for this track -- the normal case, not a failure.
        "lyrics.none": [
            "no lyrics — just listen",
            "nobody wrote this one down",
            "words not included",
            "not in the book",
            "hum along"
        ],
        // A track just started and the words are being looked for. A WAIT, so
        // it is typed rather than printed: see docs/DESIGN.md §6b.
        "lyrics.looking": [
            "looking for the words…",
            "asking who wrote this…",
            "reading ahead…"
        ],
        // No player at all. The media shapes said "Nothing playing" three times
        // over in their own words; one bank, one voice.
        "media.quiet": [
            "nothing playing",
            "silence, then",
            "the room is yours",
            "nothing on"
        ],
        // The launcher, open and still empty. Every line still says what to do
        // with it: a placeholder is a label first and a remark second.
        "launcher.idle": [
            "search applications…",
            "type a name…",
            "what are we opening?",
            "name it and it opens"
        ],
        // Typed something, matched nothing.
        "launcher.noHits": [
            "nothing by that name",
            "not installed, apparently",
            "no such thing here",
            "try fewer letters"
        ],
        // Nothing to install. Said once, when it turns out to be true.
        "updates.none": [
            "up to date",
            "nothing to install",
            "as new as it gets",
            "already current"
        ],
        // The charge, on the way down. The number is the label; this is the
        // aside next to it.
        "battery.low": [
            "might want a cable",
            "running on fumes soon",
            "the wall is right there"
        ],
        "battery.critical": [
            "plug it in, seriously",
            "this is the last warning",
            "about to lose you"
        ],
        // A screenshot landed on disk and on the clipboard.
        "shot.saved": [
            "got it",
            "that one's yours",
            "saved and copied",
            "framed"
        ],

        // ── Empty hands ────────────────────────────────────────────────
        // A panel with nothing in it. These are PRINTED, not typed: watching a
        // sentence be written every time a drawer opens gets old by the third.
        "usb.empty": [
            "nothing plugged in",
            "all ports free",
            "no passengers"
        ],
        "audio.noApps": [
            "nothing is playing",
            "silence, then",
            "no app is making a sound"
        ],
        "battery.noHistory": [
            "no history yet",
            "give it a while",
            "nothing to plot yet"
        ],
        // Inside a small tile, so these have to be short.
        "switcher.empty": [
            "no windows",
            "nothing open",
            "clean desk"
        ],
        "workspace.empty": [
            "empty",
            "nothing here",
            "free"
        ],
        "tray.noMenu": [
            "no menu",
            "this one is silent",
            "nothing to offer"
        ],
        "clipboard.empty": [
            "nothing copied yet",
            "the clipboard is empty",
            "copy something first"
        ],
        "clipboard.noShots": [
            "no captures kept yet",
            "nothing shot yet"
        ],
        // Any search that matched nothing, in Settings and its like.
        "search.noMatch": [
            "nothing by that name",
            "no match",
            "try fewer letters"
        ],

        // ── Moments ────────────────────────────────────────────────────
        // Something the shell just did or is about to. These ride the toast,
        // under the label that names it.
        "dnd.on": [
            "holding your calls",
            "nobody gets through",
            "the room is quiet now"
        ],
        "dnd.off": [
            "listening again",
            "back on the air"
        ],
        "awake.on": [
            "no naps",
            "eyes open",
            "it will wait up for you"
        ],
        "awake.off": [
            "it can sleep again",
            "back to normal hours"
        ],
        "record.start": [
            "rolling",
            "everything you do now is evidence",
            "the screen is watching back"
        ],
        "record.stop": [
            "that's a wrap",
            "cut",
            "saved"
        ],
        "night.on": [
            "warming the screen",
            "easier on the eyes now"
        ],
        "night.off": [
            "back to daylight",
            "colours as they were"
        ],
        "timer.done": [
            "time's up",
            "that's the time you asked for",
            "done"
        ],
        "charger.in": [
            "drinking",
            "topping up",
            "the wall is feeding it"
        ],
        "charger.out": [
            "on its own now",
            "unplugged"
        ],
        // ── Waits ──────────────────────────────────────────────────────
        // Time is passing and the shell knows it. These are TYPED: the writing
        // is the waiting.
        "wifi.scanning": [
            "listening for networks…",
            "sweeping the air…",
            "asking what's out there…"
        ],
        "bt.scanning": [
            "listening for radios…",
            "seeing who's around…",
            "sweeping…"
        ],
        "bt.pairing": [
            "shaking hands…",
            "introducing you two…",
            "agreeing on a secret…"
        ],
        "updates.checking": [
            "asking the mirrors…",
            "counting what's new…",
            "checking…"
        ],
        // The wallpaper changed and the whole palette followed it.
        "wallpaper.applied": [
            "new wall, new colours",
            "the shell took the hint",
            "repainted"
        ],

        // Held down on a power tile, while the fill climbs.
        "power.hold": [
            "still time to let go",
            "sure about this?",
            "keep holding"
        ]
    })

    // Last line handed out per key, so the same one never lands twice running.
    // Written IN PLACE, never reassigned: half the shell picks its line in a
    // property initialiser, and reassigning this from inside pick() notified
    // those bindings and re-ran them -- a binding loop per remark.
    property var lastPick: ({})

    function pick(key) {
        const pool = root.lines[key]
        if (!pool || pool.length === 0) return ""
        if (pool.length === 1) return pool[0]
        const before = root.lastPick[key]
        let line = before
        while (line === before) line = pool[Math.floor(Math.random() * pool.length)]
        root.lastPick[key] = line
        return line
    }
}
