// Ashen — monitor layout (Settings > Display).  by Adolf — github.com/AdolfLecompte
pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import "root:/services" as Services

// Reads the real monitor state from Hyprland, keeps the user's arrangement in
// Prefs, and applies it with hyprctl. Nothing is written to the repo's
// monitors.lua: a screen layout is per-machine, and that file is a stow symlink
// into someone's checkout. Ashen re-applies its own copy on startup instead,
// the same way the keyboard layout is restored.
Singleton {
    id: root

    // ── What Hyprland says is out there ────────────────────
    // `hyprctl monitors` lists what is lit right now; `all` adds the ones that
    // are off, which are exactly the ones you need to turn back on. But `all`
    // also keeps a cable that was pulled -- that is the phantom screen that
    // stayed in the grid after the HDMI came out. So both lists are read in ONE
    // command (two processes race, and a late live list would blank the grid)
    // and a monitor only survives if it is lit, or if the record says WE are
    // the ones holding it off.
    property var monitors: []
    property bool probed: false

    function refresh() { probe.running = true }

    Process {
        id: probe
        running: true
        command: ["sh", "-c",
                  'printf \'{"all":\'; hyprctl -j monitors all; ' +
                  'printf \',"live":\'; hyprctl -j monitors; printf "}"']
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const j = JSON.parse(text)
                    const lit = {}
                    for (const m of j.live) lit[root.keyOf(m)] = true
                    root.monitors = j.all.filter(function (m) {
                        const k = root.keyOf(m)
                        return lit[k] === true || root.record(k).disabled === true
                    })
                    root.probed = true
                } catch (e) {
                    // A half-written socket read is not worth clearing the list
                    // for: the next event asks again.
                }
            }
        }
    }

    // Monitors come and go while the shell is up. The Hyprland singleton talks
    // the event socket, so it is the reliable trigger; the binary is only how
    // we read the detail it does not carry.
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            const n = event.name
            if (n === "monitoradded" || n === "monitorremoved" || n === "monitoraddedv2")
                settle.restart()
        }
    }
    Timer {
        id: settle
        // Hyprland announces the monitor before it has finished configuring it.
        interval: 300
        onTriggered: root.refresh()
    }

    // ── Identity ─────────────────────────────────────────────────────────
    // A monitor is its DESCRIPTION, never its name: HDMI-A-1 is handed out by
    // port order and moves between reboots, so a layout keyed by name ends up
    // on the wrong screen. Hyprland takes `desc:` wherever it takes an output.
    //
    // Not everything HAS one, though -- a headless output made for testing
    // reports an empty description -- and `desc:` with nothing after it matches
    // nothing at all. Those fall back to the name, which is the only handle
    // they have.
    function keyOf(m) {
        if (!m) return ""
        return m.description && m.description !== "" ? m.description : m.name
    }
    // What the IPC hands us is whatever the user typed: a name ("eDP-1") is
    // what `hyprctl monitors` shows and what anyone reaches for, but the key
    // is the description. Without this every keybind wrote an entry under a
    // key nothing reads -- the change was silently dropped and prefs grew a
    // second, dead record of the same screen.
    function keyFor(s) {
        if (!s) return ""
        for (const m of root.monitors) if (root.keyOf(m) === s) return s
        for (const m of root.monitors) if (m.name === s) return root.keyOf(m)
        return s
    }

    function outputOf(m) {
        if (!m) return ""
        return m.description && m.description !== "" ? "desc:" + m.description : m.name
    }

    // ── Writing Lua by hand ──────────────────────────────────────────────
    // A description is a vendor string and nothing stops it holding a quote.
    // Measured: an unescaped one is a SYNTAX error, so the chunk never compiles
    // and NOTHING is applied -- not the one bad screen, the whole layout. A
    // number that arrives as NaN is worse company than it looks: Lua reads it
    // as an undefined global, so the field silently goes missing.
    function q(s) {
        return '"' + String(s === undefined || s === null ? "" : s)
            .replace(/\\/g, "\\\\").replace(/"/g, '\\"')
            .replace(/\n/g, "\\n").replace(/\r/g, "") + '"'
    }
    function num(v, fallback) {
        const n = Number(v)
        return isFinite(n) ? n : fallback
    }

    function byName(name) {
        for (const m of root.monitors) if (m.name === name) return m
        return null
    }
    function byKey(key) {
        for (const m of root.monitors) if (root.keyOf(m) === key) return m
        return null
    }

    // The one the grid puts in the middle, and the one every other position is
    // measured against. A pin wins; otherwise the machine's own panel, since
    // eDP and LVDS are the two names a built-in display ever gets. The last
    // fallback is a guess: on a desktop there is no built-in panel and list
    // order is Hyprland's, not a decision -- which is why the pin exists.
    //
    // Read through `record`, NEVER `entry`: `defaults()` asks for primaryKey to
    // place the middle cell, and entry() goes through defaults().
    readonly property string primaryKey: {
        // Named so the binding re-runs on an edit: record() reads both inside a
        // function, and a binding does not see through one.
        const saved = root.layout, edits = root.draft
        for (const m of root.monitors)
            if (root.record(root.keyOf(m)).primary === true) return root.keyOf(m)
        for (const m of root.monitors)
            if (m.name.startsWith("eDP") || m.name.startsWith("LVDS"))
                return root.keyOf(m)
        return root.monitors.length > 0 ? root.keyOf(root.monitors[0]) : ""
    }

    // Pinning the centre is moving a screen into the middle cell -- one door,
    // so the two can never disagree. The pin rides in the same per-monitor
    // record as everything else: it follows its monitor, and unplugging a
    // pinned screen falls back to the built-in panel on its own.
    function setPrimary(key) { root.moveToCell(key, 4) }

    // ── The saved arrangement ────────────────────────────────────────────
    // ONE string of JSON in Prefs, not a field per monitor: the JsonAdapter
    // drops sibling writes made in the same tick, which is the same reason
    // barLayout and weatherLoc are packed.
    readonly property var layout: {
        try {
            return Prefs.displayLayout === "" ? ({}) : JSON.parse(Prefs.displayLayout)
        } catch (e) {
            return ({})
        }
    }

    // Edits in flight, in memory only. The editor writes HERE and `commit()` is
    // the only thing that reaches Prefs: writing every control straight to
    // Prefs meant a change you abandoned by closing the panel came back at the
    // next login and was applied by `arm()`, which is the opposite of what the
    // panel says ("not live until you apply them").
    property var draft: ({})
    readonly property bool dirty: Object.keys(root.draft).length > 0

    // Every monitor anyone has an opinion about: the ones plugged in now, plus
    // the ones only a record remembers. Used wherever a rule has to hold across
    // all of them at once, like a workspace belonging to exactly one screen.
    function allKeys() {
        const seen = {}
        for (const m of root.monitors) seen[root.keyOf(m)] = true
        for (const k in root.layout) seen[k] = true
        for (const k in root.draft) seen[k] = true
        return Object.keys(seen)
    }

    // What a monitor gets when it has never been arranged: where it already is.
    function defaults(m) {
        return {
            cell: root.keyOf(m) === root.primaryKey ? 4 : -1,
            mode: "preferred",
            scale: m && m.scale ? m.scale : 1,
            transform: m && m.transform ? m.transform : 0,
            disabled: m ? !!m.disabled : false,
            mirror: "",
            ws: [],
            defaultWs: 0
        }
    }

    // What has been CHOSEN for a monitor: the draft on top of what was saved.
    // Fields nobody touched stay absent, so `entry` can go on reading them live.
    function record(key) {
        return Object.assign({}, root.layout[key] || {}, root.draft[key] || {})
    }

    function entry(key) {
        const saved = root.record(key)
        const m = root.byKey(key)
        const d = root.defaults(m)
        const mirror = saved.mirror !== undefined ? saved.mirror : d.mirror
        return {
            cell:      saved.cell      !== undefined ? saved.cell      : d.cell,
            mode:      saved.mode      !== undefined ? saved.mode      : d.mode,
            scale:     saved.scale     !== undefined ? saved.scale     : d.scale,
            transform: saved.transform !== undefined ? saved.transform : d.transform,
            disabled:  saved.disabled  !== undefined ? saved.disabled  : d.disabled,
            primary:   saved.primary === true,
            // A mirror whose target is not plugged in any longer is not a
            // mirror: left standing it sent the screen down the mirror branch of
            // specFor, which forces position="auto" and never lays the saved
            // cell down, and parked its card in the tray for good. The saved
            // value is untouched, so the mirror comes back with the target.
            mirror:    (mirror !== "" && !root.byKey(mirror)) ? "" : mirror,
            ws:        saved.ws        !== undefined ? saved.ws        : d.ws,
            defaultWs: saved.defaultWs !== undefined ? saved.defaultWs : d.defaultWs
        }
    }

    // Merge a patch into what was CHOSEN, never onto `entry()`. `entry()` fills
    // its gaps from the monitor's live state, so merging onto it freezes the
    // rotation and scale Hyprland happened to be showing at that instant into
    // settings the user never touched -- a drag across the board once wrote a
    // 90 degree rotation nobody asked for. Only chosen fields are stored; the
    // rest stay absent and keep being read live.
    function setEntry(key, patch) {
        const next = Object.assign({}, root.draft)
        next[key] = Object.assign({}, next[key] || {}, patch)
        root.draft = next
    }

    // Two monitors cannot share a cell; the one already there takes the vacated
    // one, so a drag is always a swap and never silently stacks them.
    function moveToCell(key, cell) {
        const next = Object.assign({}, root.draft)
        const wasAt = root.entry(key).cell
        // Asked of every monitor through `entry()`, not of the written records:
        // the centre screen sits in cell 4 by DEFAULT, with nothing written
        // down, so a swap that only read the records left it there and the
        // newcomer beside it -- two screens in one cell, both sent to "0x0",
        // stacked at the same origin. Displacing one writes its cell down,
        // which is why it had none to begin with.
        for (const m of root.monitors) {
            const k = root.keyOf(m)
            if (k !== key && root.entry(k).cell === cell)
                next[k] = Object.assign({}, next[k] || {}, { cell: wasAt })
        }
        next[key] = Object.assign({}, next[key] || {}, { cell: cell })
        // The middle cell IS the centre: positionFor anchors cell 4 at "0x0"
        // and measures everyone else off it. So taking that cell takes the pin
        // with it, and there is never a screen that is called the centre while
        // another one sits in the middle. Written for every key, so the one
        // that just lost the middle loses the pin in the same move.
        if (cell === 4)
            for (const k of root.allKeys())
                next[k] = Object.assign({}, next[k] || {}, { primary: k === key })
        root.draft = next
    }

    // ── Geometry ─────────────────────────────────────────────────────────
    // Hyprland positions in LOGICAL pixels: the mode divided by the scale, and
    // with the axes swapped when the screen is turned on its side.
    function modeSize(m, e) {
        let w = m ? m.width : 0
        let h = m ? m.height : 0
        if (e.mode !== "preferred") {
            const mm = e.mode.match(/^(\d+)x(\d+)/)
            if (mm) { w = parseInt(mm[1]); h = parseInt(mm[2]) }
        }
        return { w: w, h: h }
    }
    function logicalSize(m, e) {
        const s = root.modeSize(m, e)
        const sc = e.scale > 0 ? e.scale : 1
        const w = Math.round(s.w / sc)
        const h = Math.round(s.h / sc)
        const turned = e.transform === 1 || e.transform === 3
        return { w: turned ? h : w, h: turned ? w : h }
    }

    // Cell 0..8 of the 3x3 grid to an absolute position. The centre monitor is
    // the origin and everything else is glued to its edge: Hyprland allows gaps
    // between monitors, but a gap is a strip the cursor cannot cross.
    // "auto" for a screen with no slot yet: it has not been arranged, so
    // Hyprland goes on laying it out. Handing those "0x0" stacks them on top of
    // the centre monitor -- two screens at the same origin, showing the same
    // pixels, which looks exactly like a mirror nobody asked for.
    function positionFor(key) {
        const e = root.entry(key)
        const m = root.byKey(key)
        if (!m || e.cell < 0 || e.cell > 8) return "auto"
        // The ORIGIN is the centre screen, not the middle cell. They are the
        // same thing while the pinned screen is plugged in, but unplugging it
        // hands the centre to the fallback wherever that one happens to sit --
        // and measuring a screen against itself left the last one standing at
        // "-1920x0" instead of the origin. Caught with the mouse, not by
        // reading: the grid still showed it in its own cell, so nothing looked
        // wrong until Hyprland was asked.
        if (key === root.primaryKey) return "0x0"

        const centre = root.byKey(root.primaryKey)
        const cEnt = root.entry(root.primaryKey)
        const cSize = centre ? root.logicalSize(centre, cEnt) : { w: 0, h: 0 }
        const size = root.logicalSize(m, e)

        // Off the centre's cell, so the board keeps meaning what it looks like
        // whichever square the centre is standing on.
        const pc = (cEnt.cell >= 0 && cEnt.cell <= 8) ? cEnt.cell : 4
        const dc = (e.cell % 3) - (pc % 3)
        const dr = Math.floor(e.cell / 3) - Math.floor(pc / 3)
        const x = dc < 0 ? -size.w : (dc > 0 ? cSize.w : 0)
        const y = dr < 0 ? -size.h : (dr > 0 ? cSize.h : 0)
        return x + "x" + y
    }

    // Hyprland refuses a scale whose buffer is not a whole number of pixels, so
    // only the ones that divide cleanly are ever offered.
    readonly property var scaleLadder: [1, 1.25, 1.333333, 1.5, 1.75, 2, 2.5, 3]
    function validScales(w, h) {
        const out = []
        for (const s of root.scaleLadder) {
            const bw = w / s, bh = h / s
            if (Math.abs(bw - Math.round(bw)) < 0.001 && Math.abs(bh - Math.round(bh)) < 0.001)
                out.push(s)
        }
        return out.length > 0 ? out : [1]
    }

    // ── Applying ─────────────────────────────────────────────────────────
    // hyprctl keyword is dead on a Lua config ("can't work with non-legacy
    // parsers"); everything goes through eval. `mirror` MUST be written even
    // when empty -- leaving the key out merges with what was there before, so
    // an omitted mirror never comes off.
    function specFor(key) {
        const m = root.byKey(key)
        if (!m) return ""
        const e = root.entry(key)
        const out = root.outputOf(m)
        if (e.disabled)
            return 'hl.monitor({output=' + root.q(out) + ', disabled=true});'

        let s = 'hl.monitor({output=' + root.q(out)
        s += ', mode=' + root.q(e.mode === "preferred" ? "preferred" : e.mode)
        s += ', scale=' + root.num(e.scale, 1)
        s += ', transform=' + root.num(e.transform, 0)
        if (e.mirror !== "") {
            // A mirrored output has no geometry of its own: it stops being a
            // wl_output at all, so position and rotation mean nothing here.
            // The target goes through outputOf as well -- a monitor with no
            // description is named plainly, and `desc:` on it matches nothing.
            s += ', mirror=' + root.q(root.outputOf(root.byKey(e.mirror)))
            s += ', position="auto"'
        } else {
            s += ', mirror=""'
            s += ', position=' + root.q(root.positionFor(key))
        }
        return s + ', disabled=false});'
    }

    // ── Which workspaces belong to which screen ──────────────────────────
    // A workspace lives on exactly one monitor, so claiming it here gives it up
    // everywhere else.
    function assignWorkspace(key, n, on) {
        const next = Object.assign({}, root.draft)
        // Taking it away from everyone else has to be asked of `entry()`: the
        // screen that owns it may only own it in Prefs, and a draft that never
        // said otherwise would hand the same workspace to two screens.
        for (const k of root.allKeys()) {
            if (k === key) continue
            const e = root.entry(k)
            if ((e.ws || []).indexOf(n) < 0) continue
            const patch = { ws: e.ws.filter(w => w !== n) }
            if (e.defaultWs === n) patch.defaultWs = 0
            next[k] = Object.assign({}, next[k] || {}, patch)
        }
        const mine = root.entry(key)
        const list = (mine.ws || []).filter(w => w !== n)
        if (on) list.push(n)
        list.sort((a, b) => a - b)
        const patch = { ws: list }
        if (mine.defaultWs === n && !on) patch.defaultWs = 0
        if (on && mine.defaultWs === 0) patch.defaultWs = list[0]
        next[key] = Object.assign({}, next[key] || {}, patch)
        root.draft = next
    }

    function ownerOf(n) {
        for (const k of root.allKeys()) {
            const e = root.entry(k)
            if (e.ws && e.ws.indexOf(n) >= 0) return k
        }
        return ""
    }

    // A rule says where a workspace is BORN, which is why an existing one does
    // not move when the rule changes -- measured, not assumed. Empty ones are
    // destroyed the moment they lose focus and come back in the right place;
    // only the ones holding windows have to be pushed by hand.
    function occupied(id) {
        for (const t of Hyprland.toplevels.values)
            if (t.workspace && t.workspace.id === id) return true
        return false
    }

    // The workspaces this shell has claimed for a screen, so far this session.
    // Hyprland has no way to ask, and a rule cannot be taken back -- only
    // switched off -- so the only way to know what to release is to remember
    // what was handed out. A config reload wipes the rules, and this with them.
    property var emittedClaims: []

    function workspaceChunk() {
        let rules = ""
        let moves = ""
        const claimed = {}
        for (const m of root.monitors) {
            const k = root.keyOf(m)
            const e = root.entry(k)
            // A mirror is not a place windows can go, and neither is a screen
            // that is switched off.
            if (e.mirror !== "" || e.disabled) continue
            const out = root.outputOf(m)
            for (const w of (e.ws || [])) {
                claimed[w] = true
                // Enabled by hand: a rule this shell switched off earlier in the
                // session stays off, and the workspace would go on being born
                // wherever the pointer is.
                rules += 'do local r = hl.workspace_rule({workspace=' + root.q(w) + ', monitor=' + root.q(out)
                       + (w === e.defaultWs ? ', default=true' : '') + '}); r:set_enabled(true); end;'
                if (root.occupied(w))
                    moves += 'hl.dispatch(hl.dsp.workspace.move({workspace=' + root.num(w, 1)
                           + ', monitor=' + root.q(out) + '}));'
            }
        }
        // Letting a workspace go has to be SAID. Rules only ever add up, so
        // without this the screen it used to belong to kept it until the next
        // `hyprctl reload`. Measured on a virtual monitor: an empty rule does
        // not clear the old one and `enabled=false` in the spec is ignored --
        // only disabling the handle the rule hands back puts the workspace back
        // to being born wherever the focus is.
        //
        // ONLY the ones this shell handed out, never a sweep of 1..10: a rule
        // is disabled by workspace, so a blanket release switches off the user's
        // own workspace rules from workspaces.lua as well, and re-emitting ten
        // of them on every apply piles up rules for the rest of the session.
        for (const w of root.emittedClaims) {
            if (claimed[w]) continue
            rules += 'do local r = hl.workspace_rule({workspace=' + root.q(w)
                   + '}); r:set_enabled(false); end;'
        }
        root.emittedClaims = Object.keys(claimed).map(w => parseInt(w))
        return rules + moves
    }

    function applyAll() {
        let chunk = ""
        // The centre goes down first: everything else is positioned against it.
        if (root.primaryKey !== "") chunk += root.specFor(root.primaryKey)
        for (const m of root.monitors) {
            const k = root.keyOf(m)
            if (k !== root.primaryKey) chunk += root.specFor(k)
        }
        // Workspaces last: a rule pointing at a screen that is not up yet has
        // nowhere to put anything.
        chunk += root.workspaceChunk()
        if (chunk === "") return
        root.run(chunk)
        settle.restart()
    }

    // ── Saying so when it does not take ──────────────────────────────────
    // Measured on a virtual monitor, not assumed: `hyprctl eval` prints its
    // errors on STDOUT (never stderr) and exits 7. A refused field is not a Lua
    // error -- pcall does not see it and the statements after it still run --
    // so the layout lands minus the one value, and execDetached threw the only
    // word about it away. A field that does not take looked exactly like
    // nothing happening.
    property string queued: ""
    function run(chunk) {
        // One eval at a time; the last word wins. Apply, the reload timer and
        // arm() can all land together, and a half-written layout is worse than
        // a late one.
        if (evaluate.running) { root.queued = chunk; return }
        evaluate.command = ["hyprctl", "eval", chunk]
        evaluate.running = true
    }

    Process {
        id: evaluate
        stdout: StdioCollector {
            onStreamFinished: {
                const out = (text || "").trim()
                if (out !== "" && out !== "ok") root.report(out)
            }
        }
        onExited: {
            const next = root.queued
            root.queued = ""
            if (next !== "") root.run(next)
        }
    }

    // The whole chunk is echoed back inside the message, and the tail still
    // carries the Lua call that raised it. A toast has one line, so the name of
    // the field that was turned down is the only part worth the room.
    function report(out) {
        const line = out.split("\n")[0]
        const field = line.match(/field '([^']+)'/)
        if (field) {
            Services.Notifications.addSystemToast(
                "DISPLAY: " + field[1].toUpperCase() + " REFUSED", "\ueb97", false, "displays")
            return
        }
        const tail = line.match(/:\d+:\s*(.*)$/)
        Services.Notifications.addSystemToast(
            "DISPLAY: " + (tail ? tail[1] : line).slice(0, 40), "\ueb97", false, "displays")
    }

    // ── Apply and put back ───────────────────────────────────────────────
    // Apply is the one door between the draft and the machine: it writes the
    // edits down and puts them on screen in the same move.
    function commit() {
        if (root.dirty) {
            const next = Object.assign({}, root.layout)
            for (const k in root.draft)
                next[k] = Object.assign({}, next[k] || {}, root.draft[k])
            Prefs.displayLayout = JSON.stringify(next)
            root.draft = ({})
        }
        root.applyAll()
    }
    // Walking away from the editor is an answer too.
    function discard() { root.draft = ({}) }

    // ── Startup and reload ───────────────────────────────────────────────
    // Applying before the prefs are in would push the defaults over the saved
    // arrangement, so this waits the same way Idle does.
    property bool ready: false
    function arm() {
        if (root.ready || !Prefs.loaded || !root.probed) return
        root.ready = true
        if (Prefs.displayLayout !== "") root.applyAll()
    }
    onProbedChanged: root.arm()
    Component.onCompleted: root.arm()
    Connections {
        target: Prefs
        function onLoadedChanged() { root.arm() }
    }

    // `hyprctl reload` re-reads monitors.lua and throws away everything applied
    // at runtime, this included.
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name !== "configreloaded" || !root.ready) return
            // The reload threw the rules away with everything else, so there is
            // nothing left to release.
            root.emittedClaims = []
            reapply.restart()
        }
    }
    Timer {
        id: reapply
        interval: 400
        onTriggered: root.applyAll()
    }
}
