// Ashen — keybind cheatsheet, read from the real config.  by Adolf — github.com/AdolfLecompte
pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Parses hypr/conf/keybinds.lua so Settings can list the shortcuts without a
// second copy of them: a duplicated table would drift the first time a bind
// changes. Anything the humaniser does not recognise is shown raw rather than
// dropped — a shortcut missing from the list is worse than an ugly one.
Singleton {
    id: root

    readonly property string confPath: Paths.home + "/.config/hypr/conf/keybinds.lua"

    // [{ section, keys, action }], worded in the shell's language.
    property string raw: ""
    readonly property var binds: { I18n.lang; I18n.dict; return root.raw === "" ? [] : root.parse(root.raw) }

    // A phrase in the shell's language; English and its {vars} as fallback.
    function say(key, en, vars) {
        let s = I18n.tr("kb." + key, en)
        for (const k in vars || {}) s = s.split("{" + k + "}").join(vars[k])
        return s
    }
    readonly property var sections: {
        let out = []
        for (const b of root.binds) {
            let s = out.find(x => x.name === b.section)
            if (!s) { s = { name: b.section, items: [] }; out.push(s) }
            s.items.push(b)
        }
        return out
    }

    // ── Parsing ───────────────────────────────────────────────────────────
    // Splits `hl.bind(a, b, c)` on the commas that sit at depth 1, ignoring the
    // ones inside strings or nested calls.
    function splitArgs(inner) {
        let args = [], depth = 0, quote = "", current = ""
        for (let i = 0; i < inner.length; i++) {
            const ch = inner[i]
            if (quote !== "") {
                current += ch
                if (ch === quote && inner[i - 1] !== "\\") quote = ""
                continue
            }
            if (ch === '"' || ch === "'") { quote = ch; current += ch; continue }
            if (ch === "(" || ch === "{") depth++
            if (ch === ")" || ch === "}") depth--
            if (ch === "," && depth === 0) { args.push(current.trim()); current = ""; continue }
            current += ch
        }
        if (current.trim() !== "") args.push(current.trim())
        return args
    }

    // "mod .. \" + SHIFT + W\"" -> "SUPER + SHIFT + W"
    function keysOf(expr, mod) {
        let out = ""
        for (const part of expr.split("..")) {
            const p = part.trim()
            if (p === "mod") out += mod
            else if (p === "i") out += "1…9"
            else {
                const m = p.match(/^"(.*)"$/)
                out += m ? m[1] : p
            }
        }
        return out.replace(/\s+/g, " ").trim()
            .replace("mouse:272", root.say("leftDrag", "left drag"))
            .replace("mouse:273", root.say("rightDrag", "right drag"))
    }

    // The shell's own IPC calls are the ones worth naming properly.
    function ipcLabel(cmd) {
        const m = cmd.match(/call\s+(\w+)\s+(\w+)/)
        if (!m) return ""
        const target = m[1], fn = m[2]
        const names = {
            "settings": "Settings", "notifications": "Notifications", "wallpaper": "Wallpaper picker",
            "clipboard": "Clipboard",
            "process": "Process monitor", "launcher": "Launcher", "lockscreen": "Lock screen",
            "power": "Power menu", "osd": "On-screen display", "media": "Media",
            "switcher": "Window switcher", "game": "Game mode", "record": "Screen recording",
            "usage": "Screen time"
        }
        const label = names[target] !== undefined ? root.say("ipc." + target, names[target]) : target
        if (target === "switcher") {
            // One call both opens it and steps: naming it after the step is
            // what the bind actually does from the keyboard's side.
            if (fn === "next") return root.say("ipc.switcher", "Window switcher")
            if (fn === "prev") return root.say("switcherBack", "Window switcher (backwards)")
        }
        if (target === "media") {
            if (fn === "next") return root.say("nextTrack", "Next track")
            if (fn === "prev") return root.say("prevTrack", "Previous track")
            if (fn === "playPause") return root.say("playPause", "Play / pause")
        }
        if (fn === "toggle") return label
        if (target === "lockscreen") return label
        if (target === "widgets" && fn === "edit") return root.say("arrange", "Arrange desktop widgets")
        if (target === "notifications" && fn === "screenshot") return root.say("shot", "Screenshot (area)")
        return label + " — " + fn
    }

    function actionOf(expr) {
        let m = expr.match(/^hl\.dsp\.exec_cmd\(\s*"([\s\S]*)"\s*\)$/)
        if (m) {
            const cmd = m[1]
            // What the bind DOES comes first: the media keys also fire an OSD
            // ipc call, and naming them after that would call them all "volume".
            if (cmd.indexOf("grimblast") !== -1) return root.say("shot", "Screenshot (area)")
            if (cmd.indexOf("wpctl set-mute") !== -1 && cmd.indexOf("toggle") !== -1) return root.say("mute", "Mute")
            if (cmd.indexOf("5%+") !== -1) return cmd.indexOf("brightnessctl") !== -1 ? root.say("brightUp", "Brightness up") : root.say("volUp", "Volume up")
            if (cmd.indexOf("5%-") !== -1) return cmd.indexOf("brightnessctl") !== -1 ? root.say("brightDown", "Brightness down") : root.say("volDown", "Volume down")
            const ipc = root.ipcLabel(cmd)
            if (ipc !== "") return ipc
            // Bare app launches read fine as they are
            const bare = cmd.replace(/^sh -c '/, "").replace(/'$/, "")
            return bare.split(" ")[0]
        }
        if (expr.indexOf("window.close") !== -1) return root.say("close", "Close window")
        if (expr.indexOf("window.fullscreen") !== -1) return root.say("fullscreen", "Fullscreen")
        if (expr.indexOf("window.float") !== -1) return root.say("float", "Toggle floating")
        if (expr.indexOf("window.pseudo") !== -1) return root.say("pseudo", "Pseudo tile")
        if (expr.indexOf("window.drag") !== -1) return root.say("drag", "Move window with the mouse")
        if (expr.indexOf("window.resize") !== -1) return root.say("resize", "Resize window with the mouse")

        m = expr.match(/^app\(\s*"(\w+)"\s*\)$/)
        if (m) return root.say("open", "Open {app}", { app: I18n.tr("apps." + m[1], m[1]) })
        m = expr.match(/window\.move\(\s*\{\s*workspace\s*=\s*"special:(\w+)"/)
        if (m) return root.say("sendSpecial", "Send window to special workspace: {name}", { name: m[1] })
        m = expr.match(/window\.move\(\s*\{\s*workspace\s*=\s*"?([\w+-]+)"?/)
        if (m) return root.say("moveTo", "Move window to {ws}", { ws: root.workspaceLabel(m[1]) })
        m = expr.match(/focus\(\s*\{\s*workspace\s*=\s*"?([\w+-]+)"?/)
        if (m) return root.say("goTo", "Go to {ws}", { ws: root.workspaceLabel(m[1]) })
        m = expr.match(/focus\(\s*\{\s*direction\s*=\s*"(\w+)"/)
        if (m) return root.say("focus", "Focus {dir}", { dir: root.say("dir." + m[1], m[1]) })
        m = expr.match(/workspace\.toggle_special\(\s*"(\w+)"/)
        if (m) return root.say("special", "Special workspace: {name}", { name: m[1] })

        return expr   // shown raw rather than dropped
    }

    function workspaceLabel(v) {
        if (v === "e+1") return root.say("ws.next", "the next workspace")
        if (v === "e-1") return root.say("ws.prev", "the previous workspace")
        if (v === "i") return root.say("ws.that", "that workspace")
        return root.say("ws.n", "workspace {n}", { n: v })
    }

    function parse(text) {
        const lines = text.split("\n")
        let mod = "SUPER", section = "General", out = []
        // A heading is the FIRST comment after a blank line; the comment lines
        // under it explain. Taking every comment as a heading named sections
        // "two-step autostart.lua uses. A session d" and "and -d prints the size
        // while you drag" -- whatever line of explanation came last.
        let afterBlank = true
        // The capture submap binds Escape for the shell's own use: not a
        // shortcut anyone presses on purpose.
        let inSubmap = false

        for (let raw of lines) {
            const line = raw.trim()
            const wasBlank = afterBlank
            afterBlank = line === ""

            const modMatch = line.match(/^local\s+mod\s*=\s*"(\w+)"/)
            if (modMatch) { mod = modMatch[1]; continue }

            if (line.startsWith("hl.define_submap")) { inSubmap = true; continue }
            if (inSubmap) { if (line.startsWith("end)")) inSubmap = false; continue }

            if (line.startsWith("--")) {
                const body = line.replace(/^--+/, "").replace(/─+/g, "").trim()
                if (wasBlank && body !== "" && body.indexOf("═") === -1 && body.indexOf("Ashen") === -1)
                    section = body.split(":")[0].replace(/\s*\(.*\)\s*$/, "").trim()
                continue
            }

            if (line.indexOf("hl.bind(") !== 0) continue
            const inner = line.substring("hl.bind(".length, line.lastIndexOf(")"))
            const args = root.splitArgs(inner)
            if (args.length < 2) continue

            // A rebindable one is written K("id", <shipped keys>): the id is
            // what Settings writes an override under, and the second half is
            // still the default to show and to fall back to.
            let expr = args[0], id = ""
            const k = expr.match(/^K\(\s*"([A-Za-z]+)"\s*,([\s\S]*)\)$/)
            if (k) { id = k[1]; expr = k[2].trim() }

            // A lid, not a key: it locks, but nobody looks it up to press it.
            if (expr.indexOf("switch:") !== -1) continue
            const fallback = root.keysOf(expr, mod)
            out.push({
                section: root.say("sec." + I18n.slug(section), section),
                id: id,
                // What the file ships with, and what is in force right now --
                // which are the same until someone changes it in Settings.
                fallback: fallback,
                keys: id !== "" && Shortcuts.changed(id) ? Shortcuts.keyOf(id) : fallback,
                action: root.actionOf(args[1])
            })
        }
        return out
    }

    FileView {
        path: root.confPath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.raw = text()
        onLoadFailed: root.raw = ""
    }
}
