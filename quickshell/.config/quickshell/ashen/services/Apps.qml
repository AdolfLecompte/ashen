pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

import "root:/services" as Services

// The four programs the keybinds reach for. Nothing here launches anything:
// `ashen-app` does that, and it is the one that has to work from a lua keybind
// with no shell around it. This only writes down what the user chose, so the
// script can read it -- empty means "whatever this machine already prefers",
// which is what a fresh install should do.
Singleton {
    id: root

    readonly property var kinds: [
        { id: "terminal", label: "Terminal", glyph: "",
          hint: "kitty --single-instance" },
        { id: "browser",  label: "Browser",  glyph: "",
          hint: "the system default" },
        { id: "files",    label: "Files",    glyph: "",
          hint: "nemo" },
        { id: "editor",   label: "Editor",   glyph: "",
          hint: "codium" }
    ]

    readonly property string confPath: Services.Paths.config + "/apps.json"

    // ── Every program installed on this machine ─────────────────────────
    // The launcher used to walk the .desktop files itself. It lives here now
    // because Settings needs the same list to offer a browser or a terminal,
    // and two scans would disagree the moment one of them was stale.
    property var all: []
    readonly property bool scanned: root.all.length > 0

    // What a .desktop says it IS. The launcher's own grouping is coarse on
    // purpose (one row of categories for a person browsing); picking a terminal
    // needs the exact word, so both are kept.
    function ofKind(kind) {
        const want = kind === "terminal" ? ["TerminalEmulator"]
                   : kind === "browser"  ? ["WebBrowser"]
                   : kind === "files"    ? ["FileManager", "FileTools"]
                   : kind === "editor"   ? ["TextEditor", "IDE", "Development"]
                   : []
        return root.all.filter(a => a.cats.some(c => want.indexOf(c) !== -1))
    }

    function scan() { appLoader.running = true }

    Process {
        id: appLoader
        // Walk XDG_DATA_HOME + XDG_DATA_DIRS, not two hardcoded paths: flatpak
        // exports under dirs a fixed find never sees. Line by line, because
        // Steam's shortcuts have spaces; deduped by desktop id, earlier dirs
        // winning.
        command: ["sh", "-c",
            "seen=''; for d in \"${XDG_DATA_HOME:-$HOME/.local/share}\" $(echo \"${XDG_DATA_DIRS:-/usr/local/share:/usr/share}\" | tr ':' ' '); do [ -d \"$d/applications\" ] || continue; find \"$d/applications\" -name '*.desktop' 2>/dev/null; done | while IFS= read -r f; do id=${f##*/}; case \" $seen \" in *\" $id \"*) continue ;; esac; seen=\"$seen $id\"; echo '---'; echo \"Id=${id%.desktop}\"; grep -E '^(Name|Comment|Exec|Icon|Categories|NoDisplay)=' \"$f\" 2>/dev/null; done"
        ]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let apps = []
                const blocks = text.split("---").filter(b => b.trim().length > 0)
                for (const block of blocks) {
                    let app = { id: "", name: "", comment: "", exec: "", icon: "",
                                category: "Other", cats: [], noDisplay: false }
                    for (const line of block.trim().split("\n")) {
                        if (line.startsWith("Id=") && app.id === "") app.id = line.substring(3).trim()
                        else if (line.startsWith("Name=") && app.name === "") app.name = line.substring(5).trim()
                        else if (line.startsWith("Comment=") && app.comment === "") app.comment = line.substring(8).trim()
                        // @@u/@@ are flatpak's file-forwarding markers; with no
                        // file args left after the field codes go, they are
                        // dead weight.
                        else if (line.startsWith("Exec=") && app.exec === "")
                            app.exec = line.substring(5).trim()
                                .replace(/ %[uUfFdDnNickvm]/g, "")
                                .replace(/ @@[uU]?(?= |$)/g, "")
                        else if (line.startsWith("Icon=") && app.icon === "") app.icon = line.substring(5).trim()
                        else if (line.startsWith("Categories=") && app.cats.length === 0) {
                            const cats = line.substring(11).split(";").filter(c => c !== "")
                            app.cats = cats
                            if (cats.some(c => ["WebBrowser","Network","Email"].includes(c))) app.category = "Internet"
                            else if (cats.some(c => ["Development","IDE"].includes(c))) app.category = "Development"
                            else if (cats.some(c => ["System","Settings","PackageManager"].includes(c))) app.category = "System"
                            else if (cats.some(c => ["Utility","Accessibility"].includes(c))) app.category = "Utility"
                            else if (cats.some(c => ["Game","Games"].includes(c))) app.category = "Games"
                            else if (cats.some(c => ["Graphics","Photography"].includes(c))) app.category = "Graphics"
                            else if (cats.some(c => ["Office","Spreadsheet"].includes(c))) app.category = "Office"
                        }
                        else if (line.startsWith("NoDisplay=true")) app.noDisplay = true
                    }
                    if (app.name.length > 0 && !app.noDisplay && app.exec.length > 0) apps.push(app)
                }
                apps.sort((a, b) => a.name.localeCompare(b.name))
                root.all = apps
            }
        }
    }

    // An application by its .desktop id. The dock pins by this and nothing else:
    // a display name is a translated string and will not survive a locale change.
    function byId(id) {
        for (const a of root.all) if (a.id === id) return a
        return null
    }

    // An application by the class its WINDOW reports. Hyprland says `kitty`,
    // `Brave-browser`, `org.kde.dolphin`; a .desktop is `kitty`, `brave-browser`,
    // `org.kde.dolphin`. Neither form is canonical, so they are compared the way
    // Windows.sameApp compares them -- last dotted segment, lower-cased.
    function byClass(cls) {
        const norm = x => String(x).toLowerCase().split(".").pop()
        const want = norm(cls)
        for (const a of root.all) if (norm(a.id) === want) return a
        // Second pass on the executable: a .desktop id and a window class can
        // disagree entirely while the binary they name does not.
        for (const a of root.all) {
            const bin = String(a.exec).trim().split(/\s+/)[0].split("/").pop()
            if (norm(bin) === want) return a
        }
        return null
    }

    function commandOf(id) {
        if (id === "terminal") return Services.Prefs.appTerminal
        if (id === "browser") return Services.Prefs.appBrowser
        if (id === "files") return Services.Prefs.appFiles
        if (id === "editor") return Services.Prefs.appEditor
        return ""
    }
    function setCommand(id, cmd) {
        const v = (cmd || "").trim()
        if (id === "terminal") Services.Prefs.appTerminal = v
        else if (id === "browser") Services.Prefs.appBrowser = v
        else if (id === "files") Services.Prefs.appFiles = v
        else if (id === "editor") Services.Prefs.appEditor = v
        root.write()
    }

    // A flat object of strings, which is all `ashen-app` knows how to read --
    // it resolves it with sed so it depends on nothing.
    // The keys that open them are not kept here any more: every bind in the
    // shell is rebindable the same way now, through Services.Shortcuts, and
    // two files writing lua at Hyprland was one too many.
    function keyOf(id) { return Shortcuts.keyOf(id) }
    function setKey(id, combo) { Shortcuts.setKey(id, combo) }
    function clashOf(id, combo) { return Shortcuts.clashOf(id, combo) }

    function build() {
        let out = {}
        for (const k of root.kinds) {
            const v = root.commandOf(k.id)
            if (v !== "") out[k.id] = v
        }
        return JSON.stringify(out, null, 2) + "\n"
    }
    function write() {
        Quickshell.execDetached(["sh", "-c",
            'mkdir -p "$(dirname "$2")" && printf %s "$1" > "$2"',
            "sh", root.build(), root.confPath])
    }

    // Written once the saved values are in, never before: seeding from the
    // defaults would put an empty file over what the user chose.
    property bool ready: false
    function seed() {
        if (root.ready || !Services.Prefs.loaded) return
        root.ready = true
        root.write()
    }
    Connections {
        target: Services.Prefs
        function onLoadedChanged() { root.seed() }
    }
    Component.onCompleted: {
        root.seed()
        root.scan()
    }
}
