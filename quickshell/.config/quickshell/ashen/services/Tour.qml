// Ashen — the guided tour the welcome offers.  by Adolf — github.com/AdolfLecompte
pragma Singleton
import Quickshell
import QtQuick
import "root:/services" as Services

// A walk through the real shell: each step opens the panel it talks about, and
// the card (modules/intro/TourCard) sits at the screen edge away from the bar so
// it never covers what it points at. Opening a step closes the one before it
// (AppState.closeOthers), so the tour never leaves things lying open.
Singleton {
    id: root

    property bool active: false
    property int index: 0
    // What the spotlight leaves lit, in screen coordinates. The panel a step
    // opens publishes its own (PanelHost, MorphCard, Launcher); empty = no dim.
    property rect target: Qt.rect(0, 0, 0, 0)

    // `key` is a Shortcuts id shown as a chip; "SUPER" is the launcher's tap.
    readonly property var steps: [
        { id: "bar",       glyph: "", key: "" },
        { id: "launcher",  glyph: "", key: "SUPER" },
        { id: "dock",      glyph: "\uf7e6", key: "" },
        { id: "volume",    glyph: "", key: "" },
        { id: "clock",     glyph: "", key: "" },
        { id: "timer",     glyph: "", key: "timer" },
        { id: "widgets",   glyph: "", key: "widgets" },
        { id: "wallpaper", glyph: "", key: "wallpaper" },
        { id: "settings",  glyph: "", key: "settings" },
        { id: "done",      glyph: "", key: "" }
    ]
    readonly property var step: root.steps[root.index]
    // The dock hides itself when auto-hide is on; during its step it stays out.
    readonly property bool dockOut: root.active && root.step.id === "dock"
    // A dock the user turned off has nothing to show.
    function usable(i) { return root.steps[i].id !== "dock" || Services.Prefs.dockEnabled }
    readonly property bool last: root.index === root.steps.length - 1

    // What the chip shows: the real bind, so a rebind shows here too.
    function keyText(k) { return k === "" || k === "SUPER" ? k : Services.Shortcuts.keyOf(k) }

    // Put the shell in the state this step talks about, and nothing else.
    function enter() {
        Services.AppState.closeOthers("")
        Services.Desktop.editMode = false
        switch (root.step.id) {
        case "bar":       root.target = root.barRect(); break
        case "launcher":  Services.AppState.launcherVisible = true; break
        case "volume":    Services.AppState.volumeVisible = true; break
        case "clock":     Services.AppState.calendarVisible = true; break
        case "timer":     Services.AppState.timerMode = 0; Services.AppState.timerVisible = true; break
        case "widgets":
            // Edit mode first: leaving it is what shuts the tray.
            Services.Desktop.editMode = true
            Services.Desktop.trayOpen = true
            break
        case "wallpaper": Services.AppState.wallpaperVisible = true; break
        case "settings":  Services.AppState.settingsVisible = true; break
        }
    }

    // The strip the bar occupies on the active screen, whichever edge it is on.
    function barRect() {
        const sc = Services.Screens.active
        if (!sc) return Qt.rect(0, 0, 0, 0)
        const h = Services.Sizes.barH
        switch (Services.Prefs.barPosition) {
        case "bottom": return Qt.rect(0, sc.height - h, sc.width, h)
        case "left":   return Qt.rect(0, 0, h, sc.height)
        case "right":  return Qt.rect(sc.width - h, 0, h, sc.height)
        default:       return Qt.rect(0, 0, sc.width, h)
        }
    }

    // Emptied BEFORE the step changes: the dock publishes its box the instant
    // its step becomes current, which is earlier than enter() runs.
    function clearTarget() { root.target = Qt.rect(0, 0, 0, 0) }

    function start() {
        Services.Release.markSeen()
        Services.AppState.introVisible = false
        root.clearTarget()
        root.index = 0
        root.active = true
        root.enter()
    }
    function next() {
        if (root.last) { root.stop(); return }
        root.clearTarget()
        do root.index++; while (!root.usable(root.index))
        root.enter()
    }
    function prev() {
        if (root.index === 0) return
        root.clearTarget()
        do root.index--; while (!root.usable(root.index))
        root.enter()
    }
    function stop() {
        root.active = false
        root.target = Qt.rect(0, 0, 0, 0)
        Services.AppState.closeOthers("")
        Services.Desktop.editMode = false
    }
}
