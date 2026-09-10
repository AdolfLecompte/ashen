// Ashen — what is open, per workspace.  by Adolf — github.com/AdolfLecompte
pragma Singleton
import Quickshell
import Quickshell.Hyprland
import QtQuick

// Feeds the workspace pill: a chip can show a glyph for whatever lives on
// that workspace. The class is matched first against a short table of names
// that give themselves away, then against the desktop entry's categories,
// and only then falls back to a generic window.
Singleton {
    id: root

    // Same glyphs the launcher uses for its category rail, so a workspace with
    // a browser on it reads like the "Internet" filter does.
    readonly property string glyphInternet: ""     // public
    readonly property string glyphDevelopment: ""  // code
    readonly property string glyphSystem: ""       // memory
    readonly property string glyphUtility: ""      // build
    readonly property string glyphGames: ""        // sports_esports
    readonly property string glyphGraphics: ""     // image
    readonly property string glyphOffice: ""       // article
    readonly property string glyphOther: ""        // window

    readonly property string glyphTerminal: ""     // terminal
    readonly property string glyphChat: ""         // chat
    readonly property string glyphMusic: ""        // music_note
    readonly property string glyphVideo: ""        // movie
    readonly property string glyphFiles: ""        // folder

    // Matched as substrings of the lowercased class, first hit wins. Ordered:
    // the specific PWA ids have to be tested before the plain "brave".
    readonly property var classRules: [
        { match: ["whatsapp", "telegram", "discord", "signal", "element", "slack"], glyph: root.glyphChat },
        { match: ["youtube-music", "spotify", "music"], glyph: root.glyphMusic },
        { match: ["netflix", "mpv", "vlc", "youtube"], glyph: root.glyphVideo },
        { match: ["kitty", "alacritty", "foot", "wezterm", "ghostty", "konsole", "terminal"], glyph: root.glyphTerminal },
        { match: ["codium", "code", "vscode", "nvim", "neovim", "jetbrains", "zed"], glyph: root.glyphDevelopment },
        { match: ["nemo", "thunar", "nautilus", "dolphin", "files"], glyph: root.glyphFiles },
        { match: ["gimp", "inkscape", "krita", "blender", "darktable"], glyph: root.glyphGraphics },
        { match: ["steam", "lutris", "heroic", "gamescope", "minecraft"], glyph: root.glyphGames },
        { match: ["libreoffice", "onlyoffice", "obsidian", "zathura", "okular"], glyph: root.glyphOffice },
        { match: ["brave", "firefox", "chromium", "chrome", "zen", "librewolf", "qutebrowser"], glyph: root.glyphInternet },
    ]

    function categoryGlyph(cats) {
        if (!cats) return ""
        const has = names => names.some(n => cats.indexOf(n) !== -1)
        if (has(["WebBrowser", "Network", "Email"])) return root.glyphInternet
        if (has(["Development", "IDE"])) return root.glyphDevelopment
        if (has(["Game"])) return root.glyphGames
        if (has(["Graphics", "Photography"])) return root.glyphGraphics
        if (has(["Office", "Spreadsheet"])) return root.glyphOffice
        if (has(["TerminalEmulator"])) return root.glyphTerminal
        if (has(["AudioVideo", "Player"])) return root.glyphVideo
        if (has(["System", "Settings", "PackageManager"])) return root.glyphSystem
        if (has(["Utility", "Accessibility"])) return root.glyphUtility
        return ""
    }

    function iconForClass(cls) {
        if (!cls || cls === "") return root.glyphOther
        const c = cls.toLowerCase()
        const entry = DesktopEntries.byId(cls) || DesktopEntries.byId(c)

        // A Brave PWA calls itself "brave-<appid>-Default", so the class alone
        // would file WhatsApp and YouTube Music under "browser". The desktop
        // entry's name is what actually says which app it is, so both are
        // searched together.
        const hay = c + " " + (entry ? entry.name.toLowerCase() : "")
        for (const rule of root.classRules)
            if (rule.match.some(m => hay.indexOf(m) !== -1)) return rule.glyph

        if (entry) {
            const g = root.categoryGlyph(entry.categories)
            if (g !== "") return g
        }
        return root.glyphOther
    }

    // ── Live map: workspace id -> glyph ───────────────────────────────────
    // A plain function would not re-run when a window moves; bindings only
    // track properties, so the answer is stored in one.
    property var iconByWorkspace: ({})
    // Which applications have a window right now, keyed by the lower-cased
    // window class. Stored for the same reason iconByWorkspace is: a function
    // does not re-run when a window opens.
    property var runningIds: ({})

    function recompute() {
        let m = ({})
        let live = ({})
        for (const t of Hyprland.toplevels.values) {
            const o = t.lastIpcObject
            const cls = (o && o.class ? String(o.class) : "").toLowerCase()
            // The value is the class as Hyprland spells it: a dispatch needs
            // that spelling, and the key is lower-cased for matching.
            if (cls !== "") live[cls] = (o && o.class) ? String(o.class) : cls
            const ws = t.workspace ? t.workspace.id : 0
            if (ws === 0) continue
            m[ws] = root.iconForClass(o ? o.class : "")   // later windows win
        }
        root.runningIds = live
        // ...except the focused one, so a workspace reads as whatever you were
        // last doing on it rather than whatever opened first.
        const a = Hyprland.activeToplevel
        if (a && a.workspace) {
            const o = a.lastIpcObject
            m[a.workspace.id] = root.iconForClass(o ? o.class : "")
        }
        root.iconByWorkspace = m
    }

    // A .desktop id and a window class name the same application often enough
    // to match on, but never exactly: `org.kde.dolphin` against `dolphin`,
    // `brave-browser` against `Brave-browser`. Compared on the last dotted
    // segment, lower-cased, which is what those two forms have in common.
    function sameApp(a, b) {
        const norm = x => String(x).toLowerCase().split(".").pop()
        return norm(a) === norm(b)
    }
    function isRunning(id) {
        for (const cls in root.runningIds) if (root.sameApp(id, cls)) return true
        return false
    }
    // The class Hyprland actually reports for this application, which is what a
    // dispatch has to be given -- the .desktop id it is pinned under will not do.
    function classOf(id) {
        for (const cls in root.runningIds) if (root.sameApp(id, cls)) return root.runningIds[cls]
        return ""
    }
    // Is the window in front one of this application's?
    function isFocused(id) {
        const a = Hyprland.activeToplevel
        if (!a) return false
        const o = a.lastIpcObject
        return o && o.class ? root.sameApp(id, String(o.class)) : false
    }

    function workspaceIcon(wsId) {
        const g = root.iconByWorkspace[wsId]
        return g !== undefined ? g : ""
    }

    // Hyprland only refreshes its toplevel list when asked, and the refresh is
    // async — hence the settle timer rather than recomputing inline.
    function refresh() {
        Hyprland.refreshToplevels()
        settle.restart()
    }
    Timer { id: settle; interval: 120; onTriggered: root.recompute() }

    Component.onCompleted: root.refresh()
    readonly property int toplevelCount: Hyprland.toplevels.values.length
    onToplevelCountChanged: root.recompute()

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            const n = event.name
            if (n === "openwindow" || n === "closewindow" || n === "movewindow"
                || n === "activewindow" || n === "activewindowv2")
                root.refresh()
        }
    }
}
