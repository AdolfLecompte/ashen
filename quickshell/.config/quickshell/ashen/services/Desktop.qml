pragma Singleton
import Quickshell
import QtQuick

// The widgets that live on the wallpaper: which ones are out, and where each
// one sits. The layer only draws what this says; nothing about a widget's
// position is stored in the widget itself, so a wallpaper profile can put a
// whole arrangement back by writing one string.
Singleton {
    id: root

    // Every widget the desktop can show: its face, where it lands the first
    // time it is turned on (its own record answers after that), and the shapes
    // it can take. `styles` are
    // the shapes it can take; the first one is what it wears until asked
    // otherwise, and a widget with one shape gets no chips to choose from.
    readonly property var catalogue: [
        { id: "clock", group: "time", label: "Clock", glyph: "\ue8ae", x: 80, y: 120, styles: [
            { id: "digital", label: "Digital" },
            { id: "analog", label: "Analog" },
            { id: "stack", label: "Stacked" }],
          // How it tells the hour. The first follows the bar's own clock, so a
          // widget arranged before this existed keeps reading the way it did.
          skins: [
            { id: "bar", label: "Bar" },
            { id: "12", label: "12h" },
            { id: "12s", label: "12h:ss" },
            { id: "24", label: "24h" },
            { id: "24s", label: "24h:ss" }] },
        { id: "weather", group: "time", label: "Weather", glyph: "\uf172", x: 80, y: 420, styles: [
            { id: "full", label: "Full" },
            { id: "compact", label: "Compact" },
            { id: "hourly", label: "Curve" }] },
        { id: "media", group: "media", label: "Music", glyph: "\ue405", x: 80, y: 640, styles: [
            { id: "full", label: "Full" },
            { id: "compact", label: "Compact" },
            { id: "wave", label: "Wave" },
            { id: "lyrics", label: "Lyrics" }] },
        // Two axes: how much it shows, and how it draws a level. Wanting the
        // big one without water is exactly what one axis cannot say.
        { id: "system", group: "machine", label: "System", glyph: "\ueaa2", x: 80, y: 880,
          styles: [
            { id: "large", label: "Large" },
            { id: "medium", label: "Medium" },
            { id: "compact", label: "Compact" }] },
        { id: "battery", group: "machine", label: "Battery", glyph: "\ue1a4", x: 460, y: 120, styles: [
            { id: "vessel", label: "Ticks" },
            { id: "ring", label: "Ring" },
            { id: "plain", label: "Plain" }] },
        { id: "calendar", group: "time", label: "Calendar", glyph: "\uebcc", x: 460, y: 300, styles: [
            { id: "month", label: "Month" },
            { id: "week", label: "Week" }] },
        // One shape, so it is never offered a row of chips.
        { id: "sun", group: "time", label: "Daylight", glyph: "\ue518", x: 460, y: 700, styles: [
            { id: "arc", label: "Arc" }] },
        // Both clocks the shell already keeps running: the panel closes, the
        // count does not stop, and out here you can see it without opening it.
        { id: "timer", group: "time", label: "Timer", glyph: "\ue425", x: 460, y: 880, styles: [
            { id: "timer", label: "Timer" },
            { id: "stopwatch", label: "Stopwatch" },
            { id: "both", label: "Both" }] },
        { id: "notify", group: "machine", label: "Notifications", glyph: "\ue7f4", x: 1100, y: 120, styles: [
            { id: "list", label: "List" },
            { id: "count", label: "Count" }] },
        { id: "updates", group: "machine", label: "Updates", glyph: "\ue8d7", x: 1100, y: 400, styles: [
            { id: "list", label: "List" },
            { id: "count", label: "Count" }] },
        { id: "disks", group: "machine", label: "Disks", glyph: "\ue1db", x: 1100, y: 660, styles: [
            { id: "full", label: "All" },
            { id: "compact", label: "Root" }] },
        { id: "machine", group: "machine", label: "Machine", glyph: "\ue30a", x: 700, y: 600, styles: [
            { id: "card", label: "Card" },
            { id: "session", label: "Session" },
            { id: "compact", label: "Compact" }] },
        // Two axes: the shape it takes, and how much wall it is given.
        { id: "visualizer", group: "media", label: "Visualizer", glyph: "\ue1b8", x: 700, y: 120,
          styles: [
            { id: "ring", label: "Ring" },
            { id: "bars", label: "Bars" }],
          skins: [
            { id: "medium", label: "M" },
            { id: "small", label: "S" },
            { id: "large", label: "L" }] },
        // The one you can have several of. Its records are keyed "image:1",
        // "image:2"... and its sizes are fixed on purpose: two pictures at
        // whatever size each never line up, and lining up is the point of
        // having a grid and a magnet.
        { id: "image", group: "picture", label: "Image", glyph: "\ue3f4", x: 700, y: 200, multi: true, styles: [
            { id: "small", label: "Small" },
            { id: "medium", label: "Medium" },
            { id: "large", label: "Large" }] },
    ]

    // The order the tray offers them in: like next to like, so the palette
    // reads as three short lists rather than thirteen unrelated tiles. The
    // catalogue's own order is where a fresh desktop puts them, and the two are
    // not the same question.
    readonly property var groupOrder: ["time", "media", "machine", "picture"]
    readonly property var trayOrder: {
        let out = []
        for (const g of root.groupOrder)
            for (const w of root.catalogue)
                if (w.group === g && !w.multi) out.push(w)
        return out
    }

    // "image:3" is an image. Everything else is itself.
    function typeOf(id) {
        const cut = String(id).indexOf(":")
        return cut < 0 ? id : String(id).slice(0, cut)
    }

    function widget(id) {
        const type = root.typeOf(id)
        for (const w of root.catalogue) if (w.id === type) return w
        return null
    }

    // Everything on the desktop right now: the one-of-a-kind widgets, plus
    // however many copies exist of the ones you can have several of.
    function idsOf(type) {
        let out = []
        for (const key in root.layout) if (root.typeOf(key) === type && key !== type) out.push(key)
        out.sort()
        return out
    }

    // A new copy, placed a little off the last one so it does not land exactly
    // on top of it.
    function add(type) {
        const w = root.widget(type)
        if (!w || !w.multi) return ""
        const taken = root.idsOf(type)
        let n = 1
        while (taken.indexOf(type + ":" + n) !== -1) n++
        const id = type + ":" + n
        root.write(id, { on: true, x: w.x + (n - 1) * 24, y: w.y + (n - 1) * 24 })
        return id
    }

    function remove(id) {
        const next = Object.assign({}, root.layout)
        delete next[id]
        root.layout = next
        root.dropRect(id)
        saveSoon.restart()
    }
    function styleLabel(id) {
        const cur = root.entry(id).style
        for (const st of root.stylesOf(id)) if (st.id === cur) return st.label
        return ""
    }
    function stylesOf(id) {
        const w = root.widget(id)
        return (w && w.styles) ? w.styles : []
    }
    // The second axis, for the widgets that have one. Everything else sees an
    // empty list and never hears about it again.
    function skinsOf(id) {
        const w = root.widget(id)
        return (w && w.skins) ? w.skins : []
    }

    // Nothing is on until asked for: a fresh install keeps the desktop it had.
    property var layout: ({})

    property bool editMode: false
    // The tray of widgets, open while you are arranging. Not saved, like
    // editMode and snap: it is how you are editing right now, not part of the
    // look -- and it closes with the mode that owns it.
    property bool trayOpen: false
    onEditModeChanged: {
        if (root.editMode) return
        root.trayOpen = false
        root.cropping = ""
    }

    // Held down while a wallpaper is crossing. The widgets go out before the
    // picture moves and come back once it has settled -- landing a new
    // arrangement on top of a transition reads as two things fighting.
    property bool hushed: false

    // Free hand, or landing on a grid. Not saved, like editMode itself: it is
    // how you are arranging right now, not part of the look. The guides only
    // show in grid -- a line you cannot land on is decoration.
    property string snap: "free"
    readonly property int gridStep: 48
    // Magnet: how close two edges have to be before one takes the other, and
    // the distance it always leaves between them. Nothing can end up closer.
    readonly property int magnetGap: 16
    readonly property int magnetRange: 44
    function setSnap(mode) {
        if (mode === "free" || mode === "grid" || mode === "magnet") root.snap = mode
    }

    // Where each widget on screen actually is. Written by the widgets as they
    // move and measure; read only at the moment one is dropped, so it does not
    // need to tell anybody when it changes.
    property var rects: ({})
    function setRect(id, x, y, w, h) {
        root.rects[id] = { x: x, y: y, w: w, h: h }
    }
    function dropRect(id) { delete root.rects[id] }

    // The same boxes again, but only for the widgets with something to press,
    // and REASSIGNED rather than written in place: the desktop's input region
    // is bound to this, and a map mutated in place never tells it to re-cut.
    // Nothing else reads it, so the extra copy costs a widget move.
    property var inputMap: ({})
    function setInputRect(id, x, y, w, h) {
        const was = root.inputMap[id]
        if (was && was.x === x && was.y === y && was.w === w && was.h === h) return
        const next = Object.assign({}, root.inputMap)
        next[id] = { x: x, y: y, w: w, h: h }
        root.inputMap = next
    }
    function dropInputRect(id) {
        if (!(id in root.inputMap)) return
        const next = Object.assign({}, root.inputMap)
        delete next[id]
        root.inputMap = next
    }
    // Zero where the widget is off: a region of no size takes no clicks, which
    // is exactly what a widget that is not there should do.
    function inputRect(id) {
        return root.inputMap[id] || { x: 0, y: 0, w: 0, h: 0 }
    }

    function defaults(id) {
        const w = root.widget(id)
        if (!w) return { on: false, x: 0, y: 0, style: "", src: "" }
        return {
            on: false, x: w.x, y: w.y, src: "",
            style: w.styles ? w.styles[0].id : "",
            skin: w.skins ? w.skins[0].id : "",
            // A frame sized by hand, and which part of the picture it shows.
            // Zero size means "whatever the shape says", so every record
            // written before there was a handle to pull still reads right.
            w: 0, h: 0, zoom: 1, ox: 0, oy: 0
        }
    }

    // Everything reads a widget through this: saved record over defaults.
    function entry(id) {
        const d = root.defaults(id)
        const e = root.layout[id] || {}
        return {
            on: e.on === undefined ? d.on : e.on,
            x: e.x === undefined ? d.x : e.x,
            y: e.y === undefined ? d.y : e.y,
            // A shape saved before it was renamed (or removed) would leave the
            // widget drawing nothing at all.
            style: root.stylesOf(id).some(s => s.id === e.style) ? e.style : d.style,
            skin: root.skinsOf(id).some(s => s.id === e.skin) ? e.skin : d.skin,
            // Only an image has one, and it is part of the record so a
            // wallpaper profile carries the picture with everything else.
            src: e.src === undefined ? d.src : e.src,
            w: e.w === undefined ? d.w : e.w,
            h: e.h === undefined ? d.h : e.h,
            zoom: e.zoom === undefined ? d.zoom : e.zoom,
            ox: e.ox === undefined ? d.ox : e.ox,
            oy: e.oy === undefined ? d.oy : e.oy
        }
    }

    function shown(id) { return root.entry(id).on }

    function write(id, patch) {
        const next = Object.assign({}, root.layout)
        next[id] = Object.assign({}, root.entry(id), patch)
        root.layout = next
        saveSoon.restart()
    }

    function setPos(id, x, y) { root.write(id, { x: Math.round(x), y: Math.round(y) }) }
    function setOn(id, on) { root.write(id, { on: on }) }
    function toggle(id) { root.setOn(id, !root.entry(id).on) }
    function setSrc(id, path) { root.write(id, { src: path }) }

    // A frame pulled out by its corner. Never smaller than something you can
    // still grab, and on the grid when that is how you are arranging.
    readonly property int minFrame: 96
    // A corner drag moves two things at once -- the size, and the side that
    // did not move. Two writes would leave the picture walking across the
    // desktop between them.
    function setFrame(id, x, y, w, h) {
        const snap = v => root.snap === "grid"
            ? Math.round(v / root.gridStep) * root.gridStep : Math.round(v)
        root.write(id, {
            x: Math.round(x), y: Math.round(y),
            w: Math.max(root.minFrame, snap(w)),
            h: Math.max(root.minFrame, snap(h))
        })
    }

    // Which part of the picture the frame shows: how far in it is zoomed, and
    // where it has been slid, each -1..1 of the room the zoom left over.
    function setCrop(id, ox, oy, zoom) {
        root.write(id, {
            zoom: Math.max(1, Math.min(3, zoom)),
            ox: Math.max(-1, Math.min(1, ox)),
            oy: Math.max(-1, Math.min(1, oy))
        })
    }

    // The shape a widget is WEARING, as opposed to the one last picked: a frame
    // pulled to a size of its own is no longer Small, and a chip still lit
    // would be saying it is.
    function activeStyle(id) {
        const e = root.entry(id)
        return (root.typeOf(id) === "image" && e.w > 0) ? "" : e.style
    }

    // The picture being cropped right now, if any. Like editMode itself this is
    // how you are arranging, not part of the look, so it is never saved.
    property string cropping: ""
    function toggleCrop(id) { root.cropping = (root.cropping === id) ? "" : id }

    // Choosing the file lives here, not in the widget: Settings picks for a
    // record it has no instance of, and both roads have to end the same way.
    // The picker is the shell's own -- zenity was a GTK dialog dragged over a
    // desktop that looks nothing like it.
    function pickInto(id) {
        if (!id) return
        Picker.open("widget:" + id, "")
    }
    Connections {
        target: Picker
        function onPicked(purpose, path) {
            if (purpose.indexOf("widget:") !== 0) return
            root.setSrc(purpose.slice(7), path)
        }
    }

    function setStyle(id, style) {
        if (!root.stylesOf(id).some(s => s.id === style)) return
        // Picking a shape is asking for its size back: a hand-pulled frame that
        // ignored the chip you just pressed would make the row of chips inert.
        root.write(id, root.typeOf(id) === "image"
            ? { style: style, w: 0, h: 0 } : { style: style })
    }
    function setSkin(id, skin) {
        if (!root.skinsOf(id).some(s => s.id === skin)) return
        root.write(id, { skin: skin })
    }

    // Where a widget lands when it is let go. The decision lives here and not
    // in the widget: it is the same for all of them, and the mode can change
    // while one is being dragged.
    function place(id, x, y, fieldW, fieldH) {
        if (root.snap === "grid") {
            const g = root.gridStep
            root.setPos(id, Math.round(x / g) * g, Math.round(y / g) * g)
        } else if (root.snap === "magnet") {
            const p = root.magnetise(id, x, y, fieldW, fieldH)
            root.setPos(id, p.x, p.y)
        } else {
            root.setPos(id, x, y)
        }
    }

    // Snap a widget beside its nearest neighbour, always leaving `magnetGap`,
    // and line the two of them up on the other axis so they read as one row --
    // which is the whole point of asking for it.
    function magnetise(id, x, y, fieldW, fieldH) {
        const me = root.rects[id]
        if (!me) return { x: Math.round(x), y: Math.round(y) }
        const w = me.w
        const h = me.h
        const gap = root.magnetGap
        const range = root.magnetRange
        let bestX = { d: range, v: x }
        let bestY = { d: range, v: y }
        const take = (best, target, value) => {
            const d = Math.abs(target - value)
            if (d < best.d) { best.d = d; best.v = target }
        }

        for (const other in root.rects) {
            // Only widgets that exist publish a rect, and they take it back
            // when they go: there is nothing here to snap to that is not on
            // screen right now.
            if (other === id) continue
            const r = root.rects[other]

            // Side by side, and level with it.
            take(bestX, r.x + r.w + gap, x)
            take(bestX, r.x - w - gap, x)
            take(bestY, r.y, y)
            take(bestY, r.y + r.h - h, y)

            // Stacked, and flush with it.
            take(bestY, r.y + r.h + gap, y)
            take(bestY, r.y - h - gap, y)
            take(bestX, r.x, x)
            take(bestX, r.x + r.w - w, x)
        }

        // The screen's own edges pull with the same strength.
        if (fieldW > 0) {
            take(bestX, gap, x)
            take(bestX, fieldW - w - gap, x)
        }
        if (fieldH > 0) {
            take(bestY, gap, y)
            take(bestY, fieldH - h - gap, y)
        }
        return { x: Math.round(bestX.v), y: Math.round(bestY.v) }
    }

    // One write per burst: turning three widgets on in a row is one line on
    // disk, and Prefs persists on every adapter change.
    Timer {
        id: saveSoon
        interval: 0
        onTriggered: Prefs.desktopLayout = JSON.stringify(root.layout)
    }

    function load() {
        if (Prefs.desktopLayout === "") { root.layout = ({}); return }
        try {
            const parsed = JSON.parse(Prefs.desktopLayout)
            root.layout = (parsed && typeof parsed === "object") ? parsed : ({})
        } catch (e) {
            root.layout = ({})
        }
    }

    // Nothing builds a singleton until someone reads it, and the layer needs
    // this one before anything on screen has asked for a widget.
    function arm() {}

    Component.onCompleted: if (Prefs.loaded) root.load()
    Connections {
        target: Prefs
        function onLoadedChanged() { if (Prefs.loaded) root.load() }
        // A wallpaper profile puts a whole arrangement back by writing the
        // string; the live map has to follow it.
        function onDesktopLayoutChanged() {
            if (Prefs.loaded && Prefs.desktopLayout !== JSON.stringify(root.layout)) root.load()
        }
    }
}
