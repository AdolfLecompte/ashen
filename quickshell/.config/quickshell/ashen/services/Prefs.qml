// Ashen — persisted user prefs (prefs.json).  by Adolf — github.com/AdolfLecompte
pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// User choices that have to survive a shell restart. Everything runtime-only
// (panel visibility, current tab...) belongs in AppState instead.
Singleton {
    id: root

    // Clock
    property bool clockSeconds: true
    property bool clock24h: false
    // Weather: the API only ever returns celsius, so this is display-only
    // ("C" | "F" | "K") and every consumer goes through Weather.tempString().
    property string tempUnit: "C"
    // Legacy single weather location ("lat|lon|City"). Kept only so old prefs.json
    // still parses and Weather can migrate it into weatherLocs once. Do not write.
    property string weatherLoc: ""
    // Saved weather locations, MANY now (like keyboard layouts). Packed into ONE
    // field because JsonAdapter drops intermediate values when several props are
    // written in the same tick -- so the whole list AND the active index ride in
    // one string. Format: line 0 = active index, each following line = "lat|lon|City".
    // Empty -> Weather geolocates by IP. See Weather.qml for the codec.
    property string weatherLocs: ""

    // FileView loads async: without gating on this, singletons that read a pref in
    // Component.onCompleted (Weather) see "" and clobber the saved value. Consumers
    // wait for loaded before acting on persisted state.
    property bool loaded: false

    // Active keyboard layout, by code ("latam"). switchxkblayout is runtime-only
    // and Hyprland has no "default index" setting -- only the order of kb_layout
    // decides what login starts on. Storing the pick here means the list order
    // can stay put (the cards must not jump around under the cursor) and the
    // shell re-applies the choice on startup instead.
    property string keyboardLayout: ""

    // Every clock in the shell (bar, calendar, lock) formats through these, so
    // the three can't drift apart.
    readonly property string hourToken: clock24h ? "HH" : "hh"
    readonly property string ampmToken: clock24h ? "" : " AP"
    readonly property string timeFormat: hourToken + ":mm" + (clockSeconds ? ":ss" : "") + ampmToken

    readonly property string configDir: (Quickshell.env("HOME") || "/home/adolf") + "/.config/ashen"

    FileView {
        id: prefsFile
        path: root.configDir + "/prefs.json"
        // Deliberately NOT watchChanges: this file has no writer but us, and
        // reload()-ing our own writeAdapter() re-reads the file mid-flight and
        // reverts whatever was set a moment earlier -- flip two settings quickly
        // and the first one silently snaps back.
        // Any write to the adapter lands on disk immediately
        onAdapterUpdated: writeAdapter()
        // File on disk is now the source of truth: let consumers act on it.
        onLoaded: root.loaded = true
        // First run: no file yet, so seed it with the defaults above. Still
        // "loaded" -- the empty state IS the loaded state (Weather will geolocate).
        onLoadFailed: function(error) { writeAdapter(); root.loaded = true }

        JsonAdapter {
            id: adapter
            property alias clockSeconds: root.clockSeconds
            property alias clock24h: root.clock24h
            property alias tempUnit: root.tempUnit
            property alias weatherLoc: root.weatherLoc
            property alias weatherLocs: root.weatherLocs
            property alias keyboardLayout: root.keyboardLayout
        }
    }
}
