pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// What the shell says when it has a moment to say something. Every line in the
// rice that is a remark rather than a label is picked here, keyed by the moment
// it belongs to -- so the tone is decided in one place instead of drifting panel
// by panel.
//
// Dry, lowercase, more wry than funny: a line you will read a thousand times
// cannot be a joke. Anything that has to be READ to use the shell is a label
// and does not belong here.
Singleton {
    id: root

    // The bank itself lives in i18n/voice.<lang>.json, one file per language.
    // It is not translated line by line -- each language is WRITTEN in its own
    // dry register, because a joke carried across word for word stops being one.
    property var base: ({})   // English, always loaded: the fallback bank
    property var bank: ({})   // the language in use
    readonly property var lines: root.bank

    FileView {
        path: Quickshell.shellPath("i18n/voice.en.json")
        onLoaded: {
            try {
                root.base = JSON.parse(text())
                if (I18n.lang === "en") root.bank = root.base
            } catch (e) { console.warn("[Voice] could not parse voice.en.json:", e) }
        }
        onLoadFailed: console.warn("[Voice] no voice.en.json")
    }

    FileView {
        // English is already `base`; reading it twice only names it twice.
        path: I18n.lang === "en" ? "" : Quickshell.shellPath("i18n/voice." + I18n.lang + ".json")
        onLoaded: {
            try { root.bank = JSON.parse(text()) }
            catch (e) { root.bank = root.base }
        }
        // A language with no bank of its own speaks English, not silence.
        onLoadFailed: root.bank = root.base
    }

    onLangChanged: if (I18n.lang === "en") root.bank = root.base
    readonly property string lang: I18n.lang

    // Last line handed out per key, so the same one never lands twice running.
    // Written IN PLACE, never reassigned: half the shell picks its line in a
    // property initialiser, and reassigning this from inside pick() notified
    // those bindings and re-ran them -- a binding loop per remark.
    property var lastPick: ({})
    // Keys already complained about, so the warning lands once and not per call.
    property var missing: ({})

    function pick(key) {
        // The bank wins ONLY if it actually has lines for this key. An empty
        // array is truthy, so `bank[key] || base[key]` handed back the empty one
        // and every caller got silence -- a translation that lists a key without
        // filling it took the English line down with it.
        const own = root.bank[key]
        const pool = (own && own.length > 0) ? own : root.base[key]
        if (!pool || pool.length === 0) {
            // Said once, loudly: a missing line is invisible at the call site --
            // the toast just arrives with no words and looks like a dead bank.
            //
            // But only once the bank has actually landed. Before that, every key
            // is "missing" and the complaint would be about the disk, not the
            // file. A caller that picked its line in a BINDING re-runs itself
            // when `base` arrives and never notices; one that picked inside a
            // signal handler does not, and that is the case worth shouting about.
            if (Object.keys(root.base).length > 0 && !root.missing[key]) {
                root.missing[key] = true
                console.warn("[Voice] no lines for '" + key + "' in "
                             + I18n.lang + " or en -- the caller will show nothing")
            }
            return ""
        }
        if (pool.length === 1) return pool[0]
        const before = root.lastPick[key]
        let line = before
        while (line === before) line = pool[Math.floor(Math.random() * pool.length)]
        root.lastPick[key] = line
        return line
    }
}
