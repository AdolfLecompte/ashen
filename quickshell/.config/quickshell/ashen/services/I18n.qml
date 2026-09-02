// Ashen — interface language (i18n/*.json).  by Adolf — github.com/AdolfLecompte
pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// What the shell says, in the language the user reads. English is the source:
// every key is written in English, every other file answers the same keys, and
// anything a translation has not answered yet falls back to English rather
// than to a blank.
//
// Qt's own machinery (qsTr + .ts + lrelease) is not what this uses: it needs a
// build step for the .qm files and a QTranslator installed from C++, which
// Quickshell does not expose -- so the language could only change by
// restarting the shell. A dictionary in a property changes it live, because a
// binding that called t() is re-evaluated the moment the dictionary does.
Singleton {
    id: root

    // The languages that ship. A name is written in its OWN language: you pick
    // yours by recognising it, not by translating the list first.
    readonly property var languages: [
        { id: "en", label: "English",  locale: "en_US" },
        { id: "es", label: "Español",  locale: "es_ES" },
        { id: "ru", label: "Русский",  locale: "ru_RU" },
        { id: "de", label: "Deutsch",  locale: "de_DE" },
    ]

    function known(id) {
        return root.languages.some(l => l.id === id)
    }
    function entry(id) {
        for (const l of root.languages) if (l.id === id) return l
        return root.languages[0]
    }

    // A pref naming a language that no longer ships reads as English rather
    // than as an empty shell.
    readonly property string lang: root.known(Prefs.language) ? Prefs.language : "en"
    readonly property string langLabel: root.entry(root.lang).label

    // Dates and numbers go through this, never through the system locale: the
    // shell has to speak one language, not two.
    readonly property var locale: Qt.locale(root.entry(root.lang).locale)

    // English, always loaded: it is the fallback for every other file.
    property var base: ({})
    // The language in use. Same object as `base` while English is picked.
    property var dict: ({})

    // The one way anything in the shell asks for a word.
    //   t("settings.language.title")
    //   t("lock.updates", { n: 4 })   ->  "{n} updates"
    // An unanswered key returns the key itself: a missing string has to be
    // visible in the interface, not silently blank.
    function t(key, vars) {
        // Both are read on every call so a binding depends on BOTH: a string
        // answered by the dictionary would otherwise never notice English
        // arriving, and one answered by English would never notice the
        // dictionary being swapped.
        const d = root.dict
        const b = root.base
        let s = d[key]
        if (s === undefined) s = b[key]
        if (s === undefined) return key
        if (vars)
            for (const k in vars)
                s = s.split("{" + k + "}").join(vars[k])
        return s
    }

    function setLang(id) {
        if (!root.known(id) || id === Prefs.language) return
        Prefs.language = id
    }

    function fileOf(id) {
        return Quickshell.shellPath("i18n/" + id + ".json")
    }

    FileView {
        id: baseFile
        path: root.fileOf("en")
        onLoaded: {
            try {
                root.base = JSON.parse(text())
                if (root.lang === "en") root.dict = root.base
            } catch (e) {
                console.warn("[I18n] could not parse en.json:", e)
            }
        }
        onLoadFailed: console.warn("[I18n] no en.json at", baseFile.path)
    }

    FileView {
        id: langFile
        // English is already in `base`; loading it twice would only give the
        // same object a second name.
        path: root.lang === "en" ? "" : root.fileOf(root.lang)
        onLoaded: {
            try {
                root.dict = JSON.parse(text())
            } catch (e) {
                console.warn("[I18n] could not parse", root.lang + ".json:", e)
                root.dict = root.base
            }
        }
        // A language whose file is missing or broken is English, not silence.
        onLoadFailed: root.dict = root.base
    }

    // The old dictionary is held until the new one has actually been read.
    // Blanking it at the moment of the pick made the whole interface flash
    // through English on its way between two other languages -- a stale word
    // for one frame reads as nothing at all, a flash reads as a fault.
    onLangChanged: if (root.lang === "en") root.dict = root.base
}
