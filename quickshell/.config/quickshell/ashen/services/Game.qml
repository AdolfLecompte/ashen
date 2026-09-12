// Ashen — game mode.  by Adolf — github.com/AdolfLecompte
pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import "root:/services" as Services

// Flat compositor, quiet shell. Turned on by hand and never by itself: a mode
// that guesses when you are playing is a mode that turns your effects off in
// the middle of a film.
//
// Two halves, and they are kept apart on purpose.
//
// The COMPOSITOR half is a real edit to Hyprland's live config, so it has to be
// undone by hand. Not with `hyprctl reload`: the config here is Lua and a
// reload re-applies monitors.lua, which would throw away whatever layout
// Displays put down -- you would lose your screen arrangement every time you
// stopped playing. What the seven options held is read first and written to
// the cache, so leaving works even if the shell was restarted in between. That
// snapshot is the ONLY thing game mode persists: the mode itself is not a
// preference and does not survive a reboot.
//
// The SHELL half is not stored at all. Every switch reads `Game.on` live --
// Sizes.motion, Cava, Idle, the desktop layer, the notification gate -- so
// nothing has to be restored and a crash mid-game cannot leave a preference
// turned off behind your back.
Singleton {
    id: root

    property bool on: false
    // What Hyprland had before we flattened it. Empty means we never took it.
    property var saved: ({})
    readonly property bool armed: Object.keys(root.saved).length > 0

    readonly property string snapPath: Services.Paths.home + "/.cache/ashen_game.json"

    // The options game mode flattens, with the flat value and the type the
    // reader has to pull out of `hyprctl getoption`. `css` gaps come back as
    // "top right bottom left" and only go back in as a table -- a string is
    // refused outright.
    readonly property var opts: [
        { key: "animations:enabled",       lua: "animations.enabled",       type: "bool", flat: false },
        { key: "decoration:blur:enabled",  lua: "decoration.blur.enabled",  type: "bool", flat: false },
        { key: "decoration:shadow:enabled", lua: "decoration.shadow.enabled", type: "bool", flat: false },
        { key: "decoration:rounding",      lua: "decoration.rounding",      type: "int",  flat: 0 },
        { key: "general:border_size",      lua: "general.border_size",      type: "int",  flat: 1 },
        { key: "general:gaps_in",          lua: "general.gaps_in",          type: "css",  flat: 0 },
        { key: "general:gaps_out",         lua: "general.gaps_out",         type: "css",  flat: 0 }
    ]

    // ── Talking to Hyprland ──────────────────────────────────────────────
    // A Lua value for one option. Booleans and numbers write themselves; a css
    // gap has four sides and only the table form is accepted.
    function luaVal(o, v) {
        if (o.type === "css") {
            const p = String(v).trim().split(/\s+/)
            if (p.length < 4) return "{top=" + root.n(p[0]) + ",right=" + root.n(p[0])
                                   + ",bottom=" + root.n(p[0]) + ",left=" + root.n(p[0]) + "}"
            return "{top=" + root.n(p[0]) + ",right=" + root.n(p[1])
                 + ",bottom=" + root.n(p[2]) + ",left=" + root.n(p[3]) + "}"
        }
        if (o.type === "bool") return v ? "true" : "false"
        return String(root.n(v))
    }
    function n(v) {
        const x = Number(v)
        return isFinite(x) ? x : 0
    }

    // "a.b.c = v" pairs folded back into the nested table hl.config wants.
    function chunkFor(valueOf) {
        const tree = {}
        for (const o of root.opts) {
            const path = o.lua.split(".")
            let node = tree
            for (let i = 0; i < path.length - 1; i++) {
                if (!node[path[i]]) node[path[i]] = {}
                node = node[path[i]]
            }
            node[path[path.length - 1]] = valueOf(o)
        }
        function render(node) {
            const parts = []
            for (const k in node)
                parts.push(k + "=" + (typeof node[k] === "object" ? render(node[k]) : node[k]))
            return "{" + parts.join(",") + "}"
        }
        return "hl.config(" + render(tree) + ");"
    }

    Process {
        id: evaluate
        stdout: StdioCollector {
            onStreamFinished: {
                const out = (text || "").trim()
                // `hyprctl eval` prints its errors on STDOUT, never stderr.
                if (out !== "" && out !== "ok") console.warn("Game: " + out.split("\n")[0])
            }
        }
    }
    function run(chunk) {
        evaluate.command = ["hyprctl", "eval", chunk]
        evaluate.running = true
    }

    // ── The snapshot ─────────────────────────────────────────────────────
    // Read every option in ONE command: seven processes racing is seven ways
    // for the snapshot to come out half written.
    Process {
        id: probe
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const rows = JSON.parse(text)
                    const snap = {}
                    for (let i = 0; i < root.opts.length; i++) {
                        const o = root.opts[i], r = rows[i]
                        if (!r) continue
                        snap[o.key] = o.type === "bool" ? !!r.bool
                                    : o.type === "int"  ? r.int
                                    : r.css
                    }
                    root.saved = snap
                    root.write()
                    root.run(root.chunkFor(o => root.luaVal(o, o.flat)))
                    root.on = true
                    root.say(true)
                } catch (e) {
                    console.warn("Game: could not read the compositor, staying put")
                }
            }
        }
    }

    function write() {
        Quickshell.execDetached(["sh", "-c",
            'mkdir -p "$(dirname "$2")" && printf %s "$1" > "$2"',
            "sh", JSON.stringify(root.saved), root.snapPath])
    }
    function forget() {
        root.saved = ({})
        Quickshell.execDetached(["rm", "-f", root.snapPath])
    }

    // The snapshot outlives the shell on purpose: restarted mid-game, this is
    // the only thing that knows what the compositor looked like before.
    FileView {
        id: snapFile
        path: root.snapPath
        // No file is the normal case -- it only exists while a game is on --
        // so its absence is not worth a line in the log every login.
        printErrors: false
        onLoaded: {
            try {
                const snap = JSON.parse(text())
                if (Object.keys(snap).length === 0) return
                root.saved = snap
                root.on = true
            } catch (e) {
                // A half-written file is not a mode. Leaving it would make the
                // shell believe in a game mode it cannot undo.
                root.forget()
            }
        }
        onLoadFailed: root.on = false
    }

    // ── The door ─────────────────────────────────────────────────────────
    function enter() {
        if (root.on) return
        probe.command = ["sh", "-c",
            'printf "["; first=1; for k in ' + root.opts.map(o => o.key).join(" ") + '; do '
            + '[ $first -eq 1 ] || printf ","; first=0; hyprctl -j getoption "$k"; done; printf "]"']
        probe.running = true
    }

    function leave() {
        if (!root.on) return
        if (root.armed)
            root.run(root.chunkFor(o => root.luaVal(o, root.saved[o.key])))
        root.on = false
        root.forget()
        root.say(false)
    }

    function toggle() {
        if (root.on) root.leave()
        else root.enter()
    }

    // Said plainly, not through Voice: the bank is loaded late and a phrase
    // that is not in it yet comes out as an empty toast.
    function say(entering) {
        Services.Notifications.addSystemToast(
            Services.I18n.t(entering ? "game.onBody" : "game.offBody"),
            "\uf135", false, "game",
            { title: Services.I18n.t(entering ? "game.onTitle" : "game.offTitle") })
    }

    // Built by ServiceLoader at login, so a mode left on across a restart is
    // picked back up instead of stranding a flat compositor with no way out.
    function arm() { snapFile.reload() }
}
