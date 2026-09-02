pragma Singleton
import Quickshell
import QtQuick

// Which keys do what. Hyprland reads its binds from lua, so changing one from
// Settings means writing lua -- but never the file that HOLDS the binds: this
// writes a table of overrides that keybinds.lua asks before it binds anything.
// One truth about what is bound, instead of a file that binds and another that
// unbinds it a moment later.
Singleton {
    id: root

    // ~/.config/hypr is a symlink into the checkout, so this generated file
    // lands in the tree and is gitignored -- a dirty tree makes the installer
    // skip its own update.
    readonly property string confPath:
        Paths.home + "/.config/hypr/conf/userkeys.lua"

    // id -> combination, only for the ones that have been changed. Kept as one
    // JSON string for the same reason the widget layout is: the adapter drops
    // sibling writes made in one tick.
    readonly property var map: {
        if (Prefs.keyOverrides === "") return ({})
        try { return JSON.parse(Prefs.keyOverrides) || ({}) }
        catch (e) { return ({}) }
    }

    // What the shipped file binds, read back out of it: the defaults live in
    // one place, and that place is the file Hyprland actually reads.
    function defaultOf(id) {
        for (const b of Keybinds.binds) if (b.id === id) return b.fallback
        return ""
    }
    function keyOf(id) {
        const v = root.map[id]
        return (v !== undefined && v !== "") ? v : root.defaultOf(id)
    }
    function changed(id) { return root.map[id] !== undefined && root.map[id] !== "" }

    function setKey(id, combo) {
        let next = Object.assign({}, root.map)
        const v = (combo || "").trim()
        if (v === "" || v === root.defaultOf(id)) delete next[id]
        else next[id] = v
        Prefs.keyOverrides = JSON.stringify(next)
        root.write()
    }
    function reset(id) { root.setKey(id, "") }

    // Already spoken for. Said rather than refused: Hyprland keeps the first
    // bind, so a second one on the same keys simply never fires and nothing
    // explains why.
    function clashOf(id, combo) {
        const norm = s => String(s).replace(/\s+/g, "").toUpperCase()
        const want = norm(combo)
        if (want === "") return ""
        for (const b of Keybinds.binds) {
            if (b.id === id) continue
            if (norm(root.keyOf(b.id !== "" ? b.id : "")) === want
                || (b.id === "" && norm(b.keys) === want))
                return b.action || "another shortcut"
        }
        return ""
    }

    function build() {
        let out = "-- Written by Ashen (Settings > Input). Edit it there, not here.\n"
        out += "return {\n"
        for (const id in root.map)
            out += '    ["' + id + '"] = "' + root.map[id] + '",\n'
        out += "}\n"
        return out
    }
    function write() {
        Quickshell.execDetached(["sh", "-c",
            'mkdir -p "$(dirname "$2")" && printf %s "$1" > "$2" && hyprctl reload >/dev/null 2>&1',
            "sh", root.build(), root.confPath])
    }

    // Written once the saved values are in, never before: seeding from the
    // defaults would put an empty table over what was chosen.
    property bool ready: false
    function seed() {
        if (root.ready || !Prefs.loaded) return
        root.ready = true
        root.write()
    }
    Connections {
        target: Prefs
        function onLoadedChanged() { root.seed() }
    }
    Component.onCompleted: root.seed()
}
