// ══════════════════════════════════════════════════════════════════════════
//   Ashen — a Hyprland + Quickshell rice.   by Adolf — github.com/AdolfLecompte
//   Root of the shell: wires every module (bar, lock, launcher, …) together.
// ══════════════════════════════════════════════════════════════════════════
import Quickshell
import Quickshell.Io
import QtQuick

import "root:/modules"
import "root:/modules/bar"
import "root:/modules/dock"
// The panels that hang off it. They used to live in modules/bar/ alongside
// Bar.qml itself, so "the bar" meant both the strip and the fifteen windows
// that grow out of it.
import "root:/modules/panels"
import "root:/modules/lock"
import "root:/modules/launcher"
import "root:/modules/picker"
import "root:/modules/wallpaper"
import "root:/modules/settings"
import "root:/modules/clipboard"
import "root:/modules/intro"
import "root:/modules/desktop"
import "root:/modules/widgets" as Widgets
import "root:/services" as Services

ShellRoot {
    // ── IPC ───────────────────────────────────────────────────────────────
    // Handlers live here, not inside the panels: a lazily loaded panel does not
    // exist while it is closed and its handler would vanish with it. All they do
    // is flip state; panels react in their own onShownChanged.
    IpcHandler {
        target: "volume"
        function toggle() { Services.AppState.toggleOverlay("volumeVisible") }
    }
    IpcHandler {
        target: "battery"
        function toggle() { Services.AppState.toggleOverlay("batteryVisible") }
    }

    IpcHandler {
        target: "launcher"
        function toggle() { Services.AppState.toggleOverlay("launcherVisible") }
    }

    // Monitors. `apply` is the one worth a keybind: plugging a screen in leaves
    // Hyprland with its own idea of the layout, and this puts ours back.
    IpcHandler {
        target: "displays"
        function apply() { Services.Displays.applyAll() }
        function refresh() { Services.Displays.refresh() }
        // A keybind has no Apply button in front of it, so every one of these
        // commits: the change is written down and put on screen at once.
        function place(monitor: string, cell: int) {
            Services.Displays.moveToCell(Services.Displays.keyFor(monitor), cell)
            Services.Displays.commit()
        }
        function mirror(monitor: string, target: string) {
            Services.Displays.setEntry(Services.Displays.keyFor(monitor), { mirror: Services.Displays.keyFor(target) })
            Services.Displays.commit()
        }
        function assign(monitor: string, workspace: int, on: bool) {
            Services.Displays.assignWorkspace(Services.Displays.keyFor(monitor), workspace, on)
            Services.Displays.commit()
        }
        // 0 / 1 / 2 / 3 = normal, 90, 180, 270. Worth a keybind on a machine
        // whose screen folds over.
        function rotate(monitor: string, transform: int) {
            Services.Displays.setEntry(Services.Displays.keyFor(monitor), { transform: transform })
            Services.Displays.commit()
        }
        // Which screen the 3x3 grid puts in the middle. Everything else is
        // positioned against it, and on a desktop it cannot be guessed.
        function primary(monitor: string) {
            Services.Displays.setPrimary(Services.Displays.keyFor(monitor))
            Services.Displays.commit()
        }
        function scale(monitor: string, factor: string) {
            Services.Displays.setEntry(Services.Displays.keyFor(monitor), { scale: parseFloat(factor) })
            Services.Displays.commit()
        }
        function list(): string {
            let out = []
            for (const m of Services.Displays.monitors) {
                const k = Services.Displays.keyOf(m)
                const e = Services.Displays.entry(k)
                out.push(m.name + " key=" + k + (k === Services.Displays.primaryKey ? " CENTRE" : "")
                         + " cell=" + e.cell + " scale=" + e.scale
                         + " transform=" + e.transform + " mirror=" + (e.mirror || "-")
                         + " pos=" + Services.Displays.positionFor(k)
                         + " ws=" + ((e.ws || []).join(",") || "-"))
            }
            // Says out loud when what you are reading is not what is on screen.
            if (Services.Displays.dirty) out.push("(unapplied edits pending)")
            return out.join("\n")
        }
    }
    IpcHandler {
        target: "settings"
        function toggle() {
            Services.AppState.toggleOverlay("settingsVisible")
        }
        // Jump straight to a section:
        // system|bar|desktop|display|sound|network|input|notifications|theme|about
        function tab(name: string) {
            // Passed through as given, even for a name that is no longer a row
            // of its own: the rail lights whichever row swallowed it, and the
            // page it opens uses the exact name to pick its own side. Rewriting
            // "bluetooth" to "network" here is what made that deep link land on
            // Wi-Fi.
            Services.AppState.settingsTab = name
            Services.AppState.settingsVisible = true
        }
    }
    // The desktop widgets. `edit` is the only way to move one: the layer takes
    // no clicks otherwise.
    // The dock. Pinning is a right-click on the icon, but a keybind wants the
    // same verbs, and so does anyone scripting their own layout.
    IpcHandler {
        target: "dock"
        function toggle() { Services.Prefs.dockEnabled = !Services.Prefs.dockEnabled }
        function edge(side: string) {
            if (["top", "bottom", "left", "right"].indexOf(side) === -1) return
            Services.Prefs.dockEdge = side
        }
        function pin(id: string) { Services.Prefs.dockPin(id) }
        function unpin(id: string) { Services.Prefs.dockUnpin(id) }
        // What is pinned, in order, so a script can put it back.
        function list(): string {
            return "enabled=" + Services.Prefs.dockEnabled
                 + " edge=" + Services.Prefs.dockEdge
                 + " pins=" + Services.Prefs.dockPinList.join(",")
        }
    }

    IpcHandler {
        target: "widgets"
        function edit() { Services.Desktop.editMode = !Services.Desktop.editMode }
        // The tray of widgets inside arranging. Opening it puts you in the mode
        // that owns it: asking for the tray is asking to arrange.
        function tray() {
            if (!Services.Desktop.editMode) Services.Desktop.editMode = true
            Services.Desktop.trayOpen = !Services.Desktop.trayOpen
        }
        function toggle(name: string) { Services.Desktop.toggle(name) }
        function style(name: string, shape: string) { Services.Desktop.setStyle(name, shape) }
        // The second axis, for the widgets that have one.
        function skin(name: string, which: string) { Services.Desktop.setSkin(name, which) }
        function snap(mode: string) { Services.Desktop.setSnap(mode) }
        // The one you can have several of: add, point at a file, take away.
        function add(type: string): string { return Services.Desktop.add(type) }
        function drop(name: string) { Services.Desktop.remove(name) }
        function src(name: string, path: string) { Services.Desktop.setSrc(name, path) }
        function list(): string {
            let out = ["editing=" + Services.Desktop.editMode
                       + " snap=" + Services.Desktop.snap]
            // The copies, not the template they came from.
            let ids = []
            for (const w of Services.Desktop.catalogue) {
                if (w.multi) ids = ids.concat(Services.Desktop.idsOf(w.id))
                else ids.push(w.id)
            }
            for (const id of ids) {
                const e = Services.Desktop.entry(id)
                out.push(id + " on=" + e.on + " x=" + e.x + " y=" + e.y
                         + " style=" + e.style + (e.skin ? " skin=" + e.skin : "")
                         + (e.src ? " src=" + e.src.split("/").pop() : ""))
            }
            return out.join("\n")
        }
    }

    // The theme, from a keybind. Light/dark is the one worth binding: it is a
    // thing you do at a time of day, not a thing you go looking for.
    IpcHandler {
        target: "theme"
        function scheme(name: string) { Services.Theme.setScheme(name) }
        function mode(which: string) { Services.Theme.setMode(which) }
        function style(name: string) { Services.Theme.setDynamicType(name); Services.Theme.recolor() }
        function recolor() { Services.Theme.recolor() }
        function state(): string {
            return "scheme=" + Services.Theme.schemeId
                 + " style=" + Services.Theme.dynamicType
                 + " mode=" + Services.Prefs.themeMode
        }
    }

    // The look a wallpaper remembers. `remember` is the whole switch: on, and
    // everything listed in Looks.keys follows this wallpaper from now on.
    IpcHandler {
        target: "looks"
        function remember() { Services.Looks.remember(true) }
        function forget() { Services.Looks.remember(false) }
        // What every wallpaper nobody remembered gets: whatever is on screen now.
        function baseline() { Services.Looks.saveBaseline() }
        function state(): string {
            return "wallpaper=" + Services.Looks.current
                 + " remembering=" + Services.Looks.remembering
                 + " profiles=" + Object.keys(Services.Looks.profiles).length
                 + " baseline=" + JSON.stringify(Services.Looks.defaultLook.keys)
        }
        function list(): string {
            let out = ["current=" + Services.Looks.current,
                       "remembering=" + Services.Looks.remembering]
            for (const path in Services.Looks.profiles) {
                const p = Services.Looks.profiles[path]
                out.push(path.split("/").pop() + " -> " + JSON.stringify(p.keys)
                         + " theme=" + JSON.stringify(p.theme))
            }
            return out.join("\n")
        }
    }

    IpcHandler {
        target: "clipboard"
        function toggle() {
            Services.AppState.toggleOverlay("clipboardVisible")
        }
    }
    IpcHandler {
        target: "process"
        function toggle() {
            Services.AppState.toggleOverlay("processVisible")
        }
    }
    // Alt-tab: the same call opens it and steps through it, so one keybind is
    // the whole switcher. `prev` is the shifted twin.
    IpcHandler {
        target: "switcher"
        function next() {
            if (!Services.AppState.switcherVisible) {
                Services.AppState.switcherIndex = 0
                Services.AppState.switcherVisible = true
            }
            Services.AppState.stepSwitcher(1)
        }
        function prev() {
            if (!Services.AppState.switcherVisible) {
                Services.AppState.switcherIndex = 0
                Services.AppState.switcherVisible = true
            }
            Services.AppState.stepSwitcher(-1)
        }
        function close() { Services.AppState.switcherVisible = false }
    }
    IpcHandler {
        target: "power"
        function toggle() { Services.AppState.togglePanel("powerMenuVisible") }
    }
    // The first-run screen and the what-changed screen, on demand. Same card,
    // and `notes` is the only way to read them again once they have been shown.
    IpcHandler {
        target: "welcome"
        // `open`, not `show`: `qs ipc show` is the CLI's own subcommand, and a
        // function by that name is swallowed before it ever reaches the shell.
        function open() {
            Services.AppState.introMode = "welcome"
            Services.AppState.introPage = "home"
            Services.AppState.introVisible = true
        }
        function notes() {
            Services.AppState.introMode = "notes"
            Services.AppState.introVisible = true
        }
        // The page behind the title card: the keys and the two commands.
        function about() {
            Services.AppState.introMode = "welcome"
            Services.AppState.introPage = "about"
            Services.AppState.introVisible = true
        }
        // Closing it from outside counts as having been told, same as the
        // button: otherwise a script could dismiss it into coming back.
        function dismiss() {
            Services.Release.markSeen()
            Services.AppState.introVisible = false
        }
        function state(): string {
            return "version=" + Services.Release.version
                 + " seen=" + Services.Release.seenVersion
                 + " everRun=" + Services.Release.everRun
                 + " notes=" + Services.Release.notes.length
        }
    }

    // On the way in, once, and only if there is something to say. The wait is
    // for the bar to be up: a card that lands before the shell it belongs to
    // reads as an installer, not as a greeting.
    Timer {
        running: true
        interval: 2600
        onTriggered: {
            if (!Services.Release.loaded) { restart(); return }
            if (Services.Release.needsWelcome) {
                Services.AppState.introMode = "welcome"
                Services.AppState.introVisible = true
            } else if (Services.Release.needsNotes) {
                Services.AppState.introMode = "notes"
                Services.AppState.introVisible = true
            }
        }
    }

    IpcHandler {
        target: "media"
        function toggle() { Services.AppState.togglePanel("mediaVisible") }
        // The keyboard's transport keys. Hyprland hands XF86Audio* to nobody
        // unless something is bound to them, so without these three they do
        // nothing at all.
        function next() { Services.Media.next() }
        function prev() { Services.Media.previous() }
        function playPause() { Services.Media.playPause() }
        // No lyric toggle any more: the words are a column of the card and
        // stand there whenever the track has any.
        function state(): string {
            return "has=" + Services.Lyrics.has
                 + " lines=" + Services.Lyrics.lines.length
                 + " loading=" + Services.Lyrics.loading
                 + " artist=[" + Services.Lyrics.artist + "]"
                 + " title=[" + Services.Lyrics.title + "]"
        }
    }
    IpcHandler {
        target: "calendar"
        function toggle() { Services.AppState.togglePanel("calendarVisible") }
    }
    // The interface language, from a keybind or a script.
    IpcHandler {
        target: "language"
        function set(id: string) { Services.I18n.setLang(id) }
        function get(): string { return Services.I18n.lang }
        function list(): string {
            return Services.I18n.languages.map(l => l.id + " " + l.label).join("\n")
        }
    }
    // The two clocks, from a keybind or a script. They also make the drops that
    // hang under the bar testable without a pointer: everything else on screen
    // can be brought up by IPC, and these were the last thing that could not.
    IpcHandler {
        target: "clock"
        function stopwatch(action: string) {
            if (action === "start") Services.Stopwatch.start()
            else if (action === "pause") Services.Stopwatch.pause()
            else if (action === "reset") Services.Stopwatch.reset()
            else if (action === "lap") Services.Stopwatch.lap()
            else Services.Stopwatch.toggle()
        }
        // Minutes, because that is how a countdown is asked for out loud.
        function timer(minutes: string) {
            const m = parseFloat(minutes)
            if (isFinite(m) && m > 0) Services.Countdown.startFor(m * 60000)
            else Services.Countdown.toggle()
        }
        function stop() { Services.Countdown.reset() }
        function state(): string {
            return "stopwatch " + Services.Stopwatch.display
                 + (Services.Stopwatch.running ? " running" : " paused")
                 + " | timer " + Services.Countdown.display
                 + (Services.Countdown.running ? " running" : " paused")
        }
    }
    IpcHandler {
        target: "bluetooth"
        function toggle() { Services.AppState.togglePanel("bluetoothVisible") }
    }
    IpcHandler {
        target: "network"
        function toggle() { Services.AppState.togglePanel("networkVisible") }
    }
    IpcHandler {
        target: "notifications"
        function toggle() { Services.AppState.togglePanel("notificationsVisible") }
        function screenshot() { Services.Notifications.screenshotToast() }
        // Emptying the history without opening the panel to do it -- worth a
        // key, and the only way a script can tidy up after itself.
        function clear() { Services.Notifications.clearAll() }
        function clearApp(app: string) { Services.Notifications.clearApp(app) }
    }
    IpcHandler {
        target: "bar"
        // Moving the bar is animated by Sizes, so a keybind gets the same
        // slide-out/slide-in as the Settings picker.
        function position(edge: string) {
            if (["top", "bottom", "left", "right"].indexOf(edge) === -1) return
            Services.Prefs.barPosition = edge
        }
        function cycle() {
            const order = ["top", "right", "bottom", "left"]
            const i = order.indexOf(Services.Prefs.barPosition)
            Services.Prefs.barPosition = order[(i + 1) % order.length]
        }
        // The look, from a keybind. Same four the Bar tab offers.
        // How much of the edge it takes, 50-100 %.
        function length(pct: int) {
            Services.Prefs.barLength = Math.max(50, Math.min(100, pct))
        }
        // The outline is one switch for the whole bar, so it is one verb.
        function outline() { Services.Prefs.barOutline = !Services.Prefs.barOutline }
        // The panels have their own, and it is a different switch on purpose.
        function panelOutline() { Services.Prefs.panelOutline = !Services.Prefs.panelOutline }
        // …and the widgets on the wallpaper.
        function widgetOutline() { Services.Prefs.widgetOutline = !Services.Prefs.widgetOutline }
        // What a single capsule shows: full | compact | icon. The Bar tab offers
        // the same three, and only to the pills that have something to trim.
        function content(pill: string, mode: string) {
            if (["full", "compact", "icon"].indexOf(mode) === -1) return
            Services.Prefs.setContent(pill, mode)
        }
        function style(name: string) {
            if (["pills", "solid", "framed", "island"].indexOf(name) === -1) return
            Services.Prefs.barStyle = name
        }
    }
    IpcHandler {
        target: "game"
        function on() { Services.Game.enter() }
        function off() { Services.Game.leave() }
        function toggle() { Services.Game.toggle() }
        function status(): string { return Services.Game.on ? "on" : "off" }
    }
    IpcHandler {
        target: "wallpaper"
        // Scanning and positioning are driven by the picker's onShownChanged, so
        // both entry points (this keybind and the Settings tab) behave the same.
        function open() {
            Services.AppState.closeBigOverlays()
            Services.AppState.wallpaperVisible = true
        }
        function close() { Services.AppState.wallpaperVisible = false }
        function toggle() {
            if (Services.AppState.wallpaperVisible) close()
            else open()
        }
    }

    // ── Always resident ───────────────────────────────────────────────────
    // The bar is the shell; the rest of this list has to answer a key press or
    // a system event instantly, so none of it can be built on demand.
    Bar {}
    Dock {}
    BarFrame {}
    DesktopLayer {}
    OsdPanel {}
    NotificationToast {}
    LockScreen {}

    // Everything that has to be awake at login, in one named place.
    ServiceLoader {}

    // ── Built on demand ───────────────────────────────────────────────────
    Widgets.LazyPanel { preloadMs: 1320; shown: Services.AppState.volumeVisible;        panel: Component { VolumePanel {} } }
    Widgets.LazyPanel { preloadMs: 1560; shown: Services.AppState.batteryVisible;       panel: Component { BatteryPanel {} } }
    Widgets.LazyPanel { preloadMs: 1680; shown: Services.AppState.mediaVisible;         panel: Component { MediaPanel {} } }
    Widgets.LazyPanel { preloadMs: 1800; shown: Services.AppState.notificationsVisible; panel: Component { NotificationPanel {} } }
    Widgets.LazyPanel { preloadMs: 1920; shown: Services.AppState.settingsVisible;      panel: Component { SettingsPanel {} } }
    Widgets.LazyPanel { preloadMs: 2040; shown: Services.AppState.powerMenuVisible;     panel: Component { PowerMenu {} } }
    Widgets.LazyPanel { preloadMs: 2160; shown: Services.AppState.calendarVisible;      panel: Component { Calendar {} } }
    Widgets.LazyPanel { preloadMs: 2400; shown: Services.AppState.wsPreviewId !== 0;   panel: Component { WorkspacePreview {} } }
    Widgets.LazyPanel { preloadMs: 2520; shown: !Services.Stopwatch.idle || Services.Countdown.active; panel: Component { TimerDrops {} } }
    Widgets.LazyPanel { preloadMs: 2280; shown: Services.AppState.networkVisible;       panel: Component { NetworkPanel {} } }
    Widgets.LazyPanel { preloadMs: 2640; shown: Services.Picker.visible;                panel: Component { ImagePicker {} } }
    Widgets.LazyPanel { preloadMs: 2400; shown: Services.AppState.bluetoothVisible;     panel: Component { BluetoothPanel {} } }
    Widgets.LazyPanel { preloadMs: 2520; shown: Services.AppState.usbVisible;           panel: Component { USBPanel {} } }
    Widgets.LazyPanel { preloadMs: 2640; shown: Services.AppState.trayMenuVisible;      panel: Component { TrayMenu {} } }
    Widgets.LazyPanel { preloadMs: 2760; shown: Services.AppState.processVisible;       panel: Component { ProcessPanel {} } }
    Widgets.LazyPanel { preloadMs: 2880; shown: Services.AppState.switcherVisible;     panel: Component { Switcher {} } }
    Widgets.LazyPanel { preloadMs: 3000; shown: Services.AppState.introVisible;        panel: Component { IntroPanel {} } }
    Widgets.LazyPanel { preloadMs: 2880; shown: Services.AppState.launcherVisible;      panel: Component { Launcher {} } }
    Widgets.LazyPanel { preloadMs: 3000; shown: Services.AppState.wallpaperVisible;     panel: Component { WallpaperPicker {} } }
    Widgets.LazyPanel { preloadMs: 3360; shown: Services.AppState.clipboardVisible;     panel: Component { Clipboard {} } }
}
