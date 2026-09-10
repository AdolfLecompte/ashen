pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

import "root:/services" as Services

Singleton {
    id: root

    // Prefs may already be loaded by the time this singleton is built, in which
    // case onLoadedChanged never fires — so try the restore here too.
    Component.onCompleted: {
        recordingCheckProc.running = true
        root.restoreQuickToggles()
    }

    Process {
        id: recordingCheckProc
        command: ["sh", "-c", "PID=$(cat \"$HOME\"/.cache/ashen_recording.pid 2>/dev/null); if [ -n \"$PID\" ] && kill -0 \"$PID\" 2>/dev/null; then cat \"$HOME\"/.cache/ashen_recording_start 2>/dev/null; else rm -f \"$HOME\"/.cache/ashen_recording.pid \"$HOME\"/.cache/ashen_recording_start; fi"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let t = text.trim()
                if (t.length > 0) {
                    let startMs = parseFloat(t)
                    if (!isNaN(startMs)) {
                        root.recording = true
                        root.recordingStartTime = startMs
                    }
                }
            }
        }
    }
    // Screen recording: the pid/start files are the source of truth, so a
    // shell restart picks an ongoing recording back up (recordingCheckProc).
    function startRecording() {
        let startMs = Date.now()
        // Settings > Sound > Screen Recording may point somewhere else
        let dir = Prefs.recordDir !== "" ? Prefs.recordDir : Paths.recordings
        let path = dir + "/ashen_" + startMs + ".mp4"
        // Desktop audio is opt-out: the sink monitor is what makes a recording
        // of a video usable, but a silent capture must stay possible.
        let audio = Prefs.recordAudio ? " --audio=\"$(pactl get-default-sink).monitor\"" : ""
        Quickshell.execDetached(["sh", "-c",
            "mkdir -p '" + dir + "'; wf-recorder" + audio + " -c libx264 -x yuv420p -p color_range=tv -p colorspace=bt709 -p color_primaries=bt709 -p color_trc=bt709 -f '" + path + "' & echo $! > \"$HOME\"/.cache/ashen_recording.pid; echo " + startMs + " > \"$HOME\"/.cache/ashen_recording_start"
        ])
        root.recording = true
        root.recordingStartTime = startMs
    }
    function stopRecording() {
        Quickshell.execDetached(["sh", "-c",
            "PID=$(cat \"$HOME\"/.cache/ashen_recording.pid 2>/dev/null); [ -n \"$PID\" ] && kill -INT \"$PID\"; rm -f \"$HOME\"/.cache/ashen_recording.pid \"$HOME\"/.cache/ashen_recording_start"
        ])
        root.recording = false
    }
    function toggleRecording() {
        if (root.recording) root.stopRecording()
        else root.startRecording()
    }

    property bool clipboardVisible: false

    property var bigOverlays: ["launcherVisible", "settingsVisible", "wallpaperVisible", "clipboardVisible", "processVisible", "utilitiesVisible"]
    // Reactive read of a panel's own flag by name, for anything driven from
    // the pill catalogue rather than wired to one panel.
    function overlayOpen(name) { return name !== "" && root[name] === true }

    // Every panel that opens on a click. One at a time is not a nicety here:
    // the panels mask the bar's strip out of their input region so the click
    // reaches the pill, which means nothing else is left to close the panel
    // that was already up. `wsPreviewId` is not on the list -- it follows the
    // pointer, it is not something you open.
    readonly property var panelFlags: ["volumeVisible", "batteryVisible", "mediaVisible",
        "notificationsVisible", "settingsVisible", "powerMenuVisible", "calendarVisible",
        "networkVisible", "bluetoothVisible", "usbVisible", "processVisible",
        "clipboardVisible", "launcherVisible", "wallpaperVisible", "utilitiesVisible",
        "trayMenuVisible", "switcherVisible"]
    // Which screens have their auto-hiding bar out right now. The frame reads it
    // to hand that side over to the bar, so framed looks the same either way.
    property var barRevealed: ({})
    function setBarRevealed(name, on) {
        let m = Object.assign({}, root.barRevealed)
        m[name] = on
        root.barRevealed = m
    }
    function barRevealedOn(name) { return root.barRevealed[name] === true }

    // Whether something hanging off a BAR capsule is up: an auto-hiding bar
    // stays out for those, or the panel is left dangling off a bar that walked
    // away. The utility pill's tools are not the bar's business, and neither is
    // a pill the user has taken off it.
    readonly property bool barPanelOpen: {
        for (let id of Pills.arrangeable) {
            const f = Pills.opens(id)
            if (f !== "" && root[f] === true && Prefs.barSectionOf(id) !== "") return true
        }
        return root.trayMenuVisible === true && Prefs.barSectionOf("tray") !== ""
    }
    function closeOthers(name) {
        for (let n of root.panelFlags) if (n !== name && root[n] === true) root[n] = false
    }
    // What every pill and every keybind goes through: the one already open
    // steps down, and the one asked for takes its place in a single click.
    function togglePanel(name) {
        const wasOpen = root[name] === true
        root.closeOthers(name)
        root[name] = !wasOpen
    }
    // Which tool the clock panel opens on: 0 clock, 1 stopwatch, 2 timer. Out
    // here so the bar's readout can aim it, and so the panel comes back to the
    // tab you left it on instead of always to the clock.
    // Is the timer box out under the bar? Asked by TimerDrops, which draws it,
    // and by the clock pill, which has to square the corners it meets so the
    // two read as one taller capsule instead of two surfaces with a seam.
    // ONE place, because the day the rule changes it must change for both.
    readonly property bool timerBoxOut:
        (!Services.Stopwatch.idle || Services.Countdown.active) && !root.calendarVisible

    property int clockTab: 0
    function openClockAt(tab) {
        root.clockTab = tab
        root.togglePanel("calendarVisible")
    }

    // Kept as the name the overlays were written against; the reach is wider now.
    function toggleOverlay(name) { root.togglePanel(name) }
    function closeBigOverlays() {
        for (let n of bigOverlays) root[n] = false
    }
    // Asked for by anything in-process that wants the session locked, so it
    // does not have to shell out to `qs ipc call lockscreen lock`. The lock
    // surface listens; nothing else needs to know it exists.
    signal lockRequested()

    property bool recording: false
    property real recordingStartTime: 0
    // How long it has been running, as mm:ss. Here rather than in the pill:
    // the pill is a control and can be taken off the bar, but the recording
    // carries on, and whatever is showing it then needs the same number.
    property string recordingElapsed: "00:00"
    Timer {
        interval: 1000
        running: root.recording
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            const secs = Math.max(0, Math.floor((Date.now() - root.recordingStartTime) / 1000))
            const m = Math.floor(secs / 60)
            const s = secs % 60
            root.recordingElapsed = (m < 10 ? "0" + m : m) + ":" + (s < 10 ? "0" + s : s)
        }
    }
    property bool keepAwake: false

    // The pointer is on the dock's edge, or on the dock itself. Two surfaces
    // report into one flag: the sliver cannot see the dock's own hover and the
    // dock is not on screen to be hovered while it is hidden.
    property bool dockPeeked: false
    property bool dockHovered: false
    readonly property bool dockWanted: root.dockPeeked || root.dockHovered
    property real faceVersion: 0

    // Identity, resolved once at startup: nothing here may be hardcoded, the
    // shell has to follow a rename of the user or the host.
    property string userName: ""
    property string hostName: ""
    property string homeDir: ""
    readonly property string userLabel: userName === "" ? "" : userName + "@" + hostName
    // faceVersion busts Qt's image cache: the path never changes, the file does
    readonly property string facePath: homeDir === ""
        ? "" : "file://" + homeDir + "/.face?" + faceVersion

    Process {
        id: identityProc
        command: ["sh", "-c", "echo \"$(id -un)|$(hostnamectl hostname 2>/dev/null || hostname)|$HOME\""]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let p = text.trim().split("|")
                if (p.length < 3 || p[0] === "") return
                root.userName = p[0]
                root.hostName = p[1]
                root.homeDir = p[2]
            }
        }
    }
    property bool doNotDisturb: false

    // ── Quick toggles that outlive a restart ──────────────────────────────
    // The live value stays here (everything reads AppState), Prefs only holds
    // the seed. Prefs loads async, so restoring before `loaded` would hand back
    // the default and write that default straight over the saved one.
    property bool prefsRestored: false
    function restoreQuickToggles() {
        if (root.prefsRestored || !Prefs.loaded) return
        root.doNotDisturb = Prefs.doNotDisturb
        root.keepAwake = Prefs.keepAwake
        // Set last: the change handlers below key on it to tell a restore from
        // a user flip, and a restore must not write back over what it just read.
        root.prefsRestored = true
    }
    Connections {
        target: Prefs
        function onLoadedChanged() { root.restoreQuickToggles() }
    }
    onDoNotDisturbChanged: if (root.prefsRestored) Prefs.doNotDisturb = root.doNotDisturb
    // hypridle is what actually blanks the screen, so the toggle has to reach it
    // no matter where it was flipped (settings, launcher, IPC). Storing it is
    // enough: Idle watches Prefs.keepAwake and rewrites its config from there.
    // The daemon is never killed — it also locks the session before a suspend,
    // and that must survive Keep Awake.
    onKeepAwakeChanged: if (root.prefsRestored) Prefs.keepAwake = root.keepAwake

    property bool settingsVisible: false
    property string settingsTab: "system"
    property bool notificationsVisible: false
    property real volumePillCenterX: 400
    property real batteryPillCenterX: 520
    // Vertical twins, used when the bar sits on a side edge
    property real volumePillCenterY: 60
    property real batteryPillCenterY: 60
    property real mediaPillCenterY: 60
    property real networkPillCenterY: 60
    property real bluetoothPillCenterY: 60
    property real usbPillCenterY: 60
    property real clockPillCenterX: 960
    property real clockPillCenterY: 60
    property real notificationPillCenterX: 80
    property real notificationPillCenterY: 60
    property bool volumeVisible: false
    property bool batteryVisible: false
    property real mediaPillCenterX: 200
    // Media pill footprint, published by the pill itself: MediaPanel morphs out
    // of this exact rect instead of just scaling from its centre point.
    property real mediaPillW: 200
    property real mediaPillH: 44

    // Same story for the clock pill: the calendar panel morphs out of it
    property real clockPillW: 200
    property real clockPillH: 44
    property bool mediaVisible: false
    // True from the frame the morph actually starts drawing (a layer surface is
    // mapped a few frames after the flag flips) until it is home again. The
    // pill hides off this, not off mediaVisible, so the handover has no gap.
    property bool mediaMorphing: false
    property bool clockMorphing: false

    // Which way the next track change sweeps: +1 forwards, -1 back. Set by
    // whichever transport button was pressed -- pill, panel or lock screen all
    // drive the same two swaps, so the direction cannot live in either of them.
    // A track that simply ends sweeps forwards, which is why it resets.
    property int mediaDir: 1
    function mediaStep(dir) { root.mediaDir = dir }

    // ── Workspace hover preview ─────────────────────────────────────────
    // Only one chip can be previewed at a time, so one set of fields covers
    // every workspace instead of a pair per chip. 0 = nothing showing.
    property int wsPreviewId: 0
    property string wsPreviewLabel: ""
    property real wsPreviewX: 0
    property real wsPreviewY: 0
    property real wsPreviewW: 32
    property real wsPreviewH: 32
    property bool wsPreviewMorphing: false

    function setWsPreview(id, label, x, y, w, h) {
        root.wsPreviewLabel = label
        root.wsPreviewX = x
        root.wsPreviewY = y
        root.wsPreviewW = w
        root.wsPreviewH = h
        root.wsPreviewId = id
    }
    // The first-run screen, and the same surface showing what changed after an
    // update. Not in `panelFlags`: it is not one of the bar's panels and must
    // not be swept away by opening one.
    property bool introVisible: false
    // "welcome" or "notes"
    property string introMode: "welcome"
    // Which face of the welcome card: "home" or "about". Here rather than in
    // the panel because it can be asked for before the panel is built.
    property string introPage: "home"

    property bool powerMenuVisible: false
    // The window switcher. It has no pill of its own: the keybind opens it and
    // the same keybind steps through it, so the index lives here too.
    property bool switcherVisible: false
    property int switcherIndex: 0
    // How many windows the panel found. Zero means it has not been built yet:
    // the keybind that OPENS the switcher also asks for a step, and that ask
    // arrives before the panel exists, so it is held here until it does.
    property int switcherCount: 0
    property int switcherPending: 0
    function stepSwitcher(d) {
        if (root.switcherCount <= 0) { root.switcherPending += d; return }
        const n = root.switcherCount
        root.switcherIndex = ((root.switcherIndex + d) % n + n) % n
    }
    property bool calendarVisible: false
    property bool networkVisible: false
    property real volumePillW: 44
    property real volumePillH: 32
    property real batteryPillW: 44
    property real batteryPillH: 32
    property real usbPillW: 44
    property real usbPillH: 32
    property real networkPillW: 44
    property real networkPillH: 32
    property real bluetoothPillW: 44
    property real bluetoothPillH: 32
    property real networkPillCenterX: 700
    property bool bluetoothVisible: false
    property real powerPillCenterX: 1800
    property real powerPillCenterY: 28
    property real powerPillW: 44
    property real powerPillH: 44
    property real bluetoothPillCenterX: 760
    property bool usbVisible: false
    property real usbPillCenterX: 500
    // DBusMenuHandle of the tray item whose menu is open (null = none)
    property var trayMenuHandle: null
    property bool trayMenuVisible: false
    // Written by PillCenter reporters in the bar
    // What each chip is showing right now, so the panel falling out of it can
    // wear the same face for the first few frames of the drop. Replaced whole
    // rather than mutated: a map edited in place emits no change signal.
    property var pillFaces: ({})
    function setPillFace(key, glyph, label) {
        const f = pillFaces[key]
        if (f && f.glyph === glyph && f.label === label)
            return
        const next = Object.assign({}, pillFaces)
        next[key] = { glyph: glyph, label: label }
        root.pillFaces = next
    }
    function pillGlyph(key) { const f = pillFaces[key]; return f ? f.glyph : "" }
    function pillLabel(key) { const f = pillFaces[key]; return f ? f.label : "" }

    function setPillSize(key, w, h) {
        if (key === "network")        { root.networkPillW = w;   root.networkPillH = h }
        else if (key === "bluetooth") { root.bluetoothPillW = w; root.bluetoothPillH = h }
        else if (key === "media")     { root.mediaPillW = w;     root.mediaPillH = h }
        else if (key === "clock")     { root.clockPillW = w;     root.clockPillH = h }
        else if (key === "volume")     { root.volumePillW = w;     root.volumePillH = h }
        else if (key === "battery")    { root.batteryPillW = w;    root.batteryPillH = h }
        else if (key === "usb")        { root.usbPillW = w;        root.usbPillH = h }
        else if (key === "power")      { root.powerPillW = w;      root.powerPillH = h }
        else if (key === "process")    { root.processPillW = w;    root.processPillH = h }
        else if (key === "settings")   { root.settingsPillW = w;   root.settingsPillH = h }
        else if (key === "clipboard")  { root.clipboardPillW = w;  root.clipboardPillH = h }
    }


    // Where a tool's chip is: an edge name while it lives on the utility pill,
    // "" once it has been moved onto the bar.

    function setPillCenter(key, x, y) {
        if (key === "volume")            { root.volumePillCenterX = x;        root.volumePillCenterY = y }
        else if (key === "battery")      { root.batteryPillCenterX = x;       root.batteryPillCenterY = y }
        else if (key === "media")        { root.mediaPillCenterX = x;         root.mediaPillCenterY = y }
        else if (key === "network")      { root.networkPillCenterX = x;       root.networkPillCenterY = y }
        else if (key === "bluetooth")    { root.bluetoothPillCenterX = x;     root.bluetoothPillCenterY = y }
        else if (key === "usb")          { root.usbPillCenterX = x;           root.usbPillCenterY = y }
        else if (key === "clock")        { root.clockPillCenterX = x;         root.clockPillCenterY = y }
        else if (key === "notification") { root.notificationPillCenterX = x;  root.notificationPillCenterY = y }
        else if (key === "power")        { root.powerPillCenterX = x;         root.powerPillCenterY = y }
    }

    property real trayMenuCenterX: 900
    property real trayMenuCenterY: 60
    function openTrayMenu(item, centerX, centerY) {
        if (root.trayMenuVisible && root.trayMenuHandle === item.menu) {
            root.closeTrayMenu()
            return
        }
        root.closeOthers("trayMenuVisible")
        root.trayMenuHandle = item.menu
        root.trayMenuCenterX = centerX
        root.trayMenuCenterY = centerY !== undefined ? centerY : root.trayMenuCenterY
        root.trayMenuVisible = true
    }
    function closeTrayMenu() {
        root.trayMenuVisible = false
        root.trayMenuHandle = null
    }
    property bool launcherVisible: false
    property bool processVisible: false
    // Where the utility pill's Process chip was when clicked, so the panel can
    // grow out of it. Published by UtilityTriggers at click time -- the chip
    // only reacts while its pill is fully revealed, so the geometry read there
    // is always settled, never mid-animation.
    // Which screen edge that chip was on: the pill can turn up on any of the
    // three the bar is not currently sitting on.

    // Same four numbers for the clipboard chip on the same pill. A set each
    // rather than one shared set: both panels can be mid-animation at once
    // (one closing while the other opens) and they would fight over it.


    // Settings joins the other two on the utility pill.

    // The utility drawer: where every utility chip sits, keyed "edge|id",
    // published continuously by the pill rather than written on click -- a
    // panel opened by a keybind was never told where to grow from and used
    // whatever the last click left, or (0, 0).
    // Falls back to the middle of the edge, so a panel whose chip has not been
    // laid out yet still leaves from the right side of the screen.



    property bool utilitiesVisible: false
    // The button stands down while the panel wears its face.
    property bool processTakenOver: false
    property bool wallpaperVisible: false
    property string networkTab: "wifi"
}
