pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// A look, remembered per wallpaper. Putting a wallpaper on can bring back the
// widgets that belong with it, its scheme, its bar -- because a profile is
// nothing but a photograph of the handful of settings listed in `keys`, plus
// the two the theme keeps outside Prefs.
//
// Opt-in: a wallpaper nobody asked to remember has no profile, and putting it
// on changes nothing.
Singleton {
    id: root

    // The only list. Adding a setting to what a wallpaper remembers is one
    // line here, and nothing else in the file has to know its name.
    readonly property var keys: [
        "barStyle", "barPosition", "barLayout", "useGradients", "visualizer",
        "panelStyle", "themeMode", "desktopLayout"
    ]

    // What the shell looks like right now. Every key is read straight out of
    // its service: a binding only re-runs for what it can see, so this cannot
    // be a function call.
    readonly property var live: ({
        barStyle: Prefs.barStyle,
        barPosition: Prefs.barPosition,
        barLayout: Prefs.barLayout,
        useGradients: Prefs.useGradients,
        visualizer: Prefs.visualizer,
        panelStyle: Prefs.panelStyle,
        themeMode: Prefs.themeMode,
        desktopLayout: Prefs.desktopLayout,
        scheme: Theme.schemeId,
        dynamicType: Theme.dynamicType
    })

    // path -> { on, keys: {...}, theme: { scheme, dynamicType } }
    property var profiles: ({})

    // What a wallpaper NOBODY has remembered gets. Without this, putting on a
    // plain wallpaper left the last one's widgets and bar sitting there, and
    // the whole thing read as "it does not remember anything".
    property var baseline: ({})
    // Until one is saved: the shell as it ships -- no widgets on the desktop,
    // pills on the bar. Only these two, deliberately: turning somebody's light
    // mode off because they never saved a default would be going too far.
    readonly property var classic: ({ desktopLayout: "", barStyle: "pills" })
    readonly property var defaultLook: (root.baseline && root.baseline.keys)
        ? root.baseline : { on: true, keys: root.classic, theme: {} }

    // Take the look on screen as the one every unremembered wallpaper gets.
    function saveBaseline() {
        root.baseline = root.snapshot()
        root.save()
    }
    property bool loaded: false

    // True while a profile is being put on screen. Everything it writes would
    // otherwise come straight back as "the user changed something".
    property bool applying: false

    readonly property string current: Wallpaper.path
    readonly property bool remembering: root.has(root.current)

    function has(path) {
        const p = root.profiles[path]
        return p !== undefined && p.on === true
    }

    function snapshot() {
        let out = {}
        for (const k of root.keys) out[k] = root.live[k]
        return { on: true, keys: out, theme: { scheme: root.live.scheme, dynamicType: root.live.dynamicType } }
    }

    // Start (or stop) remembering the wallpaper on screen. Turning it on takes
    // the picture immediately: what is on screen IS the look being kept.
    function remember(on) {
        if (root.current === "") return
        const next = Object.assign({}, root.profiles)
        if (on) next[root.current] = root.snapshot()
        else delete next[root.current]
        root.profiles = next
        root.save()
    }

    function forget(path) {
        const next = Object.assign({}, root.profiles)
        delete next[path]
        root.profiles = next
        root.save()
    }

    // Re-take the picture for the wallpaper on screen. Called whenever anything
    // in `live` moves, so the profile is always what you last had.
    function capture() {
        if (!root.loaded || root.applying || !root.remembering) return
        const next = Object.assign({}, root.profiles)
        next[root.current] = root.snapshot()
        root.profiles = next
        root.save()
    }

    // The settings half of putting a profile on: no scripts, no repaint.
    function applyKeys(p) {
        const k = p.keys || {}
        for (const name of root.keys) {
            if (k[name] === undefined) continue
            if (name === "themeMode") Theme.stageMode(k[name])
            else Prefs[name] = k[name]
        }
        // barLayout is a packed string; the sections the bar actually reads are
        // rebuilt from it, and nothing else does that for us.
        if (k.barLayout !== undefined) Prefs.syncBarLayout()
    }

    // The half that has to be on disk BEFORE the wallpaper script starts: it
    // runs matugen itself and reads the mode and the style from there.
    function wearTheme(look, repaint) {
        if (!look) return
        const t = look.theme || {}
        if (t.dynamicType !== undefined && t.dynamicType !== Theme.dynamicType)
            Theme.setDynamicType(t.dynamicType)
        if (t.scheme === "dynamic") {
            Theme.stageDynamic()
            if (repaint) Theme.recolor()
        } else if (t.scheme !== undefined) {
            // A fixed palette has no matugen run to hang off: it paints itself.
            Theme.setScheme(t.scheme)
        }
    }

    // The half that waits: the bar and the desktop widgets. Landing them while
    // the picture is still crossing puts two animations on top of each other.
    function wearKeys(look) {
        if (!look || !look.keys) return
        root.applying = true
        root.applyKeys(look)
        settle.restart()
    }

    // What a path is owed: its own profile, or the default look.
    function lookFor(path) {
        return root.has(path) ? root.profiles[path] : root.defaultLook
    }

    // Put a wallpaper's look on around the change itself: the widgets leave,
    // the picture crosses, and the new arrangement arrives with them.
    property var pending: null
    // The wallpaper we are waiting to see land, and whether WE are the ones who
    // asked for it. The difference matters: our own switch knows what is
    // coming, so a different one landing meanwhile is an older script
    // finishing late. A switch from outside knows nothing, so the newest one
    // always wins.
    property string waitingFor: ""
    property bool asked: false

    function swap(path, repaint) {
        const look = root.lookFor(path)
        root.applying = true
        Desktop.hushed = true
        root.wearTheme(look, repaint)
        root.pending = look
        root.waitingFor = path
        ceiling.restart()
    }

    // The picture is there: dress the desktop and let it back in.
    function dressUp() {
        ceiling.stop()
        afterCross.stop()
        root.waitingFor = ""
        root.asked = false
        root.wearKeys(root.pending)
        root.pending = null
        Desktop.hushed = false
    }

    // What the transition itself takes once the file says the switch is done.
    // The script writes that file LAST, so this is the tail of the crossfade,
    // not a guess at the whole thing.
    Timer {
        id: afterCross
        interval: 420
        onTriggered: root.dressUp()
    }

    // A ceiling, never the plan: if the script dies, or the path was bad, or
    // mpvpaper never comes up, the desktop must not stay dark waiting for a
    // signal that is not coming.
    Timer {
        id: ceiling
        interval: 3000
        onTriggered: root.dressUp()
    }

    // Everything a profile says, put on screen at once -- for the times there
    // is no wallpaper crossing to wait for.
    function apply(path, repaint) {
        if (!root.has(path)) return
        const p = root.profiles[path]
        root.applying = true
        root.applyKeys(p)
        root.wearTheme(p, repaint)
        settle.restart()
    }

    // Called with the wallpaper about to be put on, by the picker.
    function prepare(path) {
        root.swap(path, false)
        root.asked = true
    }

    // Long enough for everything the apply set off to come back: a profile
    // writes Prefs, Prefs tells the widgets, the widgets write their own
    // string. At zero that echo landed after the flag cleared and was taken for
    // the user changing something -- which overwrote the profile just applied.
    Timer {
        id: settle
        interval: 400
        onTriggered: root.applying = false
    }

    onLiveChanged: root.capture()

    // A wallpaper that arrives without passing through prepare() came from
    // outside the shell -- the script by hand, or the one that restores the
    // last wallpaper at login.
    Connections {
        target: Wallpaper
        function onPathChanged() {
            if (!root.loaded || Wallpaper.path === "") return
            // The one we asked for has landed: the file is written after
            // matugen, so from here it is only the transition playing out.
            if (Wallpaper.path === root.waitingFor) { afterCross.restart(); return }
            // We asked for a different one and it has not landed: this is an
            // older script finishing late (click twice in the picker and both
            // run). Dressing for it would put the wrong look on and take it
            // off again a moment later.
            if (root.asked && root.waitingFor !== "") return
            // Somebody else changed it -- the script by hand, or the one that
            // restores the last wallpaper at login. Same walk out and back in,
            // and the colours have to be asked for again.
            root.swap(Wallpaper.path, true)
            afterCross.restart()
        }
    }

    // ── Storage ─────────────────────────────────────────────────────────
    // Its own file, not a Prefs key: this grows with every wallpaper, and the
    // adapter drops sibling writes made in the same tick. One string holds the
    // JSON for the same reason displayLayout does.
    function save() { saveSoon.restart() }
    Timer {
        id: saveSoon
        interval: 250
        onTriggered: adapter.data = JSON.stringify({
            v: 1, profiles: root.profiles, baseline: root.baseline
        })
    }

    FileView {
        id: file
        path: Paths.config + "/looks.json"
        // No watchChanges: nothing else writes this, and re-reading our own
        // write lands the old value back on top of the new one.
        onAdapterUpdated: if (root.loaded) writeAdapter()
        onLoaded: root.read()
        // Seed the file rather than living with a failed read in every log:
        // there is nothing to lose to a race, the file does not exist yet.
        onLoadFailed: function(error) { root.loaded = true; writeAdapter() }

        JsonAdapter {
            id: adapter
            property string data: ""
        }
    }

    function read() {
        try {
            const parsed = JSON.parse(adapter.data || "{}")
            root.profiles = (parsed && parsed.profiles) ? parsed.profiles : ({})
            root.baseline = (parsed && parsed.baseline) ? parsed.baseline : ({})
        } catch (e) {
            root.profiles = ({})
        }
        root.loaded = true
        // Whatever is already on screen at login was put there by the restore
        // script, which knows nothing about profiles.
        if (Wallpaper.path === "") return
        if (root.has(Wallpaper.path)) root.apply(Wallpaper.path, true)
        // NOT the default at startup: the shell has just read its own prefs,
        // and wearing the classic here would undo the desktop somebody left set
        // up on a wallpaper they simply never asked to remember.
    }

    // Nothing builds a singleton until someone reads it, and no panel reads
    // this one until Settings is opened -- by which time a wallpaper has come
    // and gone with its profile ignored.
    function arm() {}
}
