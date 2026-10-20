pragma Singleton
import Quickshell
import QtQuick

// What the dock carries past the applications: bar pills drawn as icons, and
// shortcuts -- a shell action, or a command of your own. Settings > Dock picks
// them; the dock draws them; this is the one place that knows what each does.
Singleton {
    id: root

    // ── Pills ──────────────────────────────────────────────────────────
    // The ones that read as a single icon. Workspaces, the tray, the player and
    // the window title are rows of things, not a tile.
    readonly property var dockablePills: [
        "launcher", "notifications", "clock", "volume", "mic", "battery",
        "network", "bluetooth", "keyboard", "usb", "clipboard", "screenshot",
        "recording", "sys", "usage", "power"
    ]
    readonly property var pills: (Prefs.dockPills || "").split(",")
        .filter(id => id !== "" && root.dockablePills.indexOf(id) !== -1)

    function hasPill(id) { return root.pills.indexOf(id) !== -1 }
    function togglePill(id) {
        Prefs.dockPills = (root.hasPill(id) ? root.pills.filter(x => x !== id)
                                            : root.pills.concat([id])).join(",")
    }

    // Live glyph: the same ladders the bar's pills climb.
    function pillGlyph(id) {
        switch (id) {
        case "volume": return Audio.icon(Audio.volume, Audio.muted, Audio.headphones)
        case "mic": return Audio.micMuted ? "\ue02b" : "\ue029"
        case "battery": return Battery.icon(Battery.level, Battery.charging)
        default: return Pills.glyph(id)
        }
    }
    // A pill that says something in words rather than a glyph. Stacked on a
    // side dock, whose tiles are no wider than an icon.
    function pillText(id, stacked) {
        if (id !== "clock") return ""
        return stacked ? Time.fmt(Prefs.hourToken) + "\n" + Time.fmt("mm")
                       : Time.fmt(Prefs.hourToken + ":mm")
    }
    // Lit: something is on, or waiting.
    function pillLit(id) {
        switch (id) {
        case "notifications": return Notifications.unreadCount > 0
        case "recording": case "screenshot": return AppState.recording
        default: {
            const f = Pills.opens(id)
            return f !== "" && AppState[f] === true
        }
        }
    }
    // The pill's own click. A panel opened from here arrives from the edge:
    // its capsule is not on the bar to grow out of.
    function pillClick(id) {
        switch (id) {
        case "mic": Audio.toggleMicMute(); return
        case "screenshot": AppState.screenshotArea(); return
        case "recording": AppState.toggleRecording(); return
        default: {
            const f = Pills.opens(id)
            if (f !== "") AppState.togglePanel(f)
        }
        }
    }
    function pillWheel(id, delta) {
        const step = delta > 0 ? 5 : -5
        if (id === "volume") Audio.setVolume(Audio.volume + step)
        else if (id === "mic") Audio.setMicVolume(Audio.micVolume + step)
    }

    // ── Shortcuts ──────────────────────────────────────────────────────
    // Shell actions with no pill of their own.
    readonly property var actions: [
        { id: "lock",       glyph: "\ue88d" },
        { id: "wallpaper",  glyph: "\ue1bc" },
        { id: "settings",   glyph: "\ue8b8" },
        { id: "processes",  glyph: "\uf190" },
        { id: "widgets",    glyph: "\ue1bd" },
        { id: "game",       glyph: "\uea28" },
        { id: "nightlight", glyph: "\uef5e" }
    ]
    // What a command of your own may wear.
    readonly property var linkGlyphs: ["\ueb8e", "\ue2c7", "\ue80b", "\ue86f",
                                       "\ue838", "\uea0b", "\ue3a1", "\ue0be"]

    readonly property var links: {
        try {
            const v = JSON.parse(Prefs.dockLinks || "[]")
            return Array.isArray(v) ? v.filter(l => l && (root.actionOf(l.a) || l.c)) : []
        } catch (e) { return [] }
    }
    function actionOf(id) { return id ? root.actions.find(a => a.id === id) || null : null }
    function hasAction(id) { return root.links.some(l => l.a === id) }
    function write(list) { Prefs.dockLinks = JSON.stringify(list) }

    function toggleAction(id) {
        root.write(root.hasAction(id) ? root.links.filter(l => l.a !== id)
                                      : root.links.concat([{ a: id }]))
    }
    function addCommand(label, cmd, glyph) {
        if (cmd.trim() === "") return
        root.write(root.links.concat([{ l: label.trim() || cmd.trim(), c: cmd.trim(), g: glyph }]))
    }
    function removeLink(i) { root.write(root.links.filter((_, k) => k !== i)) }

    function linkGlyph(l) { const a = root.actionOf(l.a); return a ? a.glyph : (l.g || root.linkGlyphs[0]) }
    function linkLabel(l) { return l.a ? I18n.t("dock.action." + l.a) : l.l }
    function linkLit(l) {
        switch (l.a) {
        case "game": return Game.on
        case "nightlight": return NightLight.enabled
        case "widgets": return Desktop.editMode
        case "processes": return AppState.processVisible === true
        case "settings": return AppState.settingsVisible === true
        case "wallpaper": return AppState.wallpaperVisible === true
        default: return false
        }
    }
    function linkClick(l) {
        switch (l.a) {
        case "lock": Quickshell.execDetached(["qs", "-c", "ashen", "ipc", "call", "lockscreen", "lock"]); return
        case "wallpaper": Quickshell.execDetached(["qs", "-c", "ashen", "ipc", "call", "wallpaper", "toggle"]); return
        case "settings": AppState.toggleOverlay("settingsVisible"); return
        case "processes": AppState.togglePanel("processVisible"); return
        case "widgets": Desktop.editMode = !Desktop.editMode; return
        case "game": Game.toggle(); return
        case "nightlight": NightLight.toggle(); return
        }
        if (l.c) Quickshell.execDetached(["sh", "-c", l.c])
    }
}
