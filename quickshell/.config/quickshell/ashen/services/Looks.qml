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
        "panelStyle", "themeMode", "desktopLayout",
        "barLength", "barOutline", "workspaceStyle", "barContent",
        "dockEnabled", "dockEdge",
        "workspaceCount", "workspaceHideEmpty", "barAutohide", "panelOutline", "widgetOutline",
        "dockAutohide", "dockSmart", "dockGlass", "dockIconSize"
    ]

    // Every key as the shell ships it: Prefs' own defaults, written once more
    // here because a Prefs property cannot be asked what it started as. The
    // standard look is exactly this, and a profile saved before a key joined
    // the list takes that key from here. Carrying it over from the PREVIOUS
    // wallpaper instead is what made the bar keep the last one's length, count
    // and dock. Theme mode is not in it: switching somebody's light mode off
    // because a wallpaper is new would be going too far.
    readonly property var shipped: ({
        barStyle: "pills", barPosition: "top", barLayout: "", useGradients: false,
        visualizer: true, panelStyle: "morph", desktopLayout: "",
        barLength: 100, barOutline: false, workspaceStyle: "icons", barContent: "",
        dockEnabled: true, dockEdge: "bottom",
        workspaceCount: 5, workspaceHideEmpty: false, barAutohide: false, panelOutline: false, widgetOutline: false,
        dockAutohide: true, dockSmart: false, dockGlass: false, dockIconSize: 44
    })

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
        barLength: Prefs.barLength,
        barOutline: Prefs.barOutline,
        workspaceStyle: Prefs.workspaceStyle,
        barContent: Prefs.barContent,
        dockEnabled: Prefs.dockEnabled,
        dockEdge: Prefs.dockEdge,
        workspaceCount: Prefs.workspaceCount,
        workspaceHideEmpty: Prefs.workspaceHideEmpty,
        barAutohide: Prefs.barAutohide,
        panelOutline: Prefs.panelOutline,
        widgetOutline: Prefs.widgetOutline,
        dockAutohide: Prefs.dockAutohide,
        dockSmart: Prefs.dockSmart,
        dockGlass: Prefs.dockGlass,
        dockIconSize: Prefs.dockIconSize,
        scheme: Theme.schemeId,
        dynamicType: Theme.dynamicType
    })

    // path -> { on, keys: {...}, theme: { scheme, dynamicType } }
    property var profiles: ({})

    // What a wallpaper NOBODY has remembered gets. Without this, putting on a
    // plain wallpaper left the last one's widgets and bar sitting there, and
    // the whole thing read as "it does not remember anything".
    property var baseline: ({})
    // Until one is saved: the shell as it ships, every key of it. It used to be
    // seven keys, so everything else -- the dock, the workspace count, the
    // outlines -- stayed as the last wallpaper had left it, which is no
    // standard at all.
    readonly property var classic: root.shipped
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
    // Off is remembered too, as a record that says so: a wallpaper with no
    // record at all is adopted the first time it is worn, which is what makes
    // following the wallpaper the default, and deleting the record on "off"
    // would have adopted it straight back.
    function remember(on) {
        if (root.current === "") return
        const next = Object.assign({}, root.profiles)
        next[root.current] = on ? root.snapshot() : { on: false }
        root.profiles = next
        root.save()
    }

    // A wallpaper no one has decided about starts following its own look: it
    // takes the look it is wearing once that look has landed.
    property string adoptPath: ""
    function adopt(path) {
        if (!root.loaded || path === "" || root.profiles[path] !== undefined) return
        const next = Object.assign({}, root.profiles)
        next[path] = root.snapshot()
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
    function applyKeys(p, fillMissing) {
        const k = p.keys || {}
        for (const name of root.keys) {
            let v = k[name]
            if (v === undefined && fillMissing) v = root.shipped[name]
            if (v === undefined) continue
            if (name === "themeMode") Theme.stageMode(v)
            else Prefs[name] = v
        }
        // barLayout is a packed string; the sections the bar actually reads are
        // rebuilt from it, and nothing else does that for us.
        if (k.barLayout !== undefined || fillMissing) Prefs.syncBarLayout()
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
        root.applyKeys(look, root.pendingFills)
        root.dressedFor = root.pendingPath
        settle.restart()
    }

    // What a path is owed: its own profile, or the default look.
    function lookFor(path) {
        return root.has(path) ? root.profiles[path] : root.defaultLook
    }

    // Put a wallpaper's look on around the change itself: the widgets leave,
    // the picture crosses, and the new arrangement arrives with them.
    property var pending: null
    // Whether putting `pending` on should fill the keys an old profile has no
    // word on. Only on a real CHANGE of wallpaper: at startup the shell also
    // dresses for the wallpaper already on screen, and filling there reset the
    // workspace style and the bar length of the look you were wearing.
    property bool pendingFills: false
    // The wallpaper the shell last dressed for. Empty until the first one.
    property string dressedFor: ""
    property string pendingPath: ""
    // The wallpaper we are waiting to see land, and whether WE are the ones who
    // asked for it. The difference matters: our own switch knows what is
    // coming, so a different one landing meanwhile is an older script
    // finishing late. A switch from outside knows nothing, so the newest one
    // always wins.
    property string waitingFor: ""
    property bool asked: false

    function swap(path, repaint) {
        // Its own look if it has one; otherwise the standard -- a wallpaper
        // nobody has designed for wears the shell as it ships (or the saved
        // default) and starts remembering THAT, not the last wallpaper's bar.
        const look = root.lookFor(path)
        root.pendingFills = root.dressedFor !== "" && root.dressedFor !== path
        root.pendingPath = path
        root.adoptPath = path
        root.applying = true
        Desktop.hushed = true
        // The bar goes with the widgets, but only if the look changes it: a
        // wallpaper wearing the same bar has nothing to hide it for.
        if (root.changesSomething(look)) { reveal.stop(); Sizes.held = true }
        root.wearTheme(look, repaint)
        root.pending = look
        root.waitingFor = path
        ceiling.restart()
    }

    // Would wearing `look` change anything on screen?
    function changesSomething(look) {
        if (!look || !look.keys) return false
        for (const name of root.keys) {
            let v = look.keys[name]
            if (v === undefined) v = root.shipped[name]
            if (v !== undefined && v !== root.live[name]) return true
        }
        return false
    }

    // The picture is there: dress the desktop while it is still away, and let
    // the bar and the widgets back in together once the new layout has landed.
    function dressUp() {
        ceiling.stop()
        afterCross.stop()
        root.waitingFor = ""
        root.asked = false
        // Nothing to put on (a wallpaper keeping the current look) still has to
        // let `applying` go, or nothing would ever be captured again.
        if (root.pending) root.wearKeys(root.pending)
        else { root.dressedFor = root.pendingPath; settle.restart() }
        root.pending = null
        reveal.restart()
    }

    // Long enough for an edge or style swap the look set off to finish its own
    // fade (240 + 320 in Sizes) and for the pills and widgets to be rebuilt,
    // so they come back already in their new places instead of moving there.
    Timer {
        id: reveal
        interval: 620
        onTriggered: {
            Sizes.held = false
            Desktop.hushed = false
        }
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
        root.applyKeys(p, false)
        root.dressedFor = path
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
        onTriggered: {
            root.applying = false
            if (root.adoptPath !== "") {
                root.adopt(root.adoptPath)
                root.adoptPath = ""
            }
        }
    }
    // At login the look on screen came from the saved preferences, which may
    // still be loading when this file is read: wait for them before adopting.
    Timer {
        id: adoptAtLogin
        interval: 1500
        onTriggered: root.adopt(Wallpaper.path)
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
        root.migrate()
        // Whatever is already on screen at login was put there by the restore
        // script, which knows nothing about profiles.
        if (Wallpaper.path === "") return
        root.dressedFor = Wallpaper.path
        if (root.has(Wallpaper.path)) root.apply(Wallpaper.path, true)
        else if (root.profiles[Wallpaper.path] === undefined) adoptAtLogin.restart()
        // NOT the default at startup: the shell has just read its own prefs,
        // and wearing the classic here would undo the desktop somebody left set
        // up on a wallpaper they simply never asked to remember.
    }

    // A profile saved before a key joined the list takes that key from what
    // you have NOW, once, when it is read: the best guess at what that
    // wallpaper was worn with. Filling it from the shipped look instead would
    // have reset somebody's three workspaces to five the first time they came
    // back to a wallpaper. Needs Prefs on disk first, or `live` is defaults.
    function migrate() {
        if (!root.loaded || !Prefs.loaded) return
        let changed = false
        const next = Object.assign({}, root.profiles)
        for (const path in next) {
            const p = next[path]
            if (!p || p.on !== true || !p.keys) continue
            const missing = root.keys.filter(k => p.keys[k] === undefined && k !== "themeMode")
            if (missing.length === 0) continue
            const keys = Object.assign({}, p.keys)
            for (const k of missing) keys[k] = root.live[k]
            next[path] = Object.assign({}, p, { keys: keys })
            changed = true
        }
        if (root.baseline && root.baseline.keys) {
            const b = root.baseline
            const missing = root.keys.filter(k => b.keys[k] === undefined && k !== "themeMode")
            if (missing.length > 0) {
                const keys = Object.assign({}, b.keys)
                for (const k of missing) keys[k] = root.shipped[k]
                root.baseline = Object.assign({}, b, { keys: keys })
                changed = true
            }
        }
        if (!changed) return
        root.profiles = next
        root.save()
    }
    Connections {
        target: Prefs
        function onLoadedChanged() { root.migrate() }
    }

    // Nothing builds a singleton until someone reads it, and no panel reads
    // this one until Settings is opened -- by which time a wallpaper has come
    // and gone with its profile ignored.
    function arm() {}
}
