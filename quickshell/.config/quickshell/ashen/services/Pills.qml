pragma Singleton
import Quickshell
import QtQuick

// What a pill IS, in one place: name, compact face, and what it opens.
// `glyph` is the compact face the utility pill's tools wear; a bar pill
// draws its full self and only needs the label.
Singleton {
    id: root

    // Does a panel take its capsule's face when it opens? In "window" style it
    // never does, so a capsule that steps aside anyway leaves a hole and half an
    // animation. Written here once: five capsules each spelled out the
    // preference check, and a sixth (the lock screen's) got it wrong.
    readonly property bool wearsFace: Prefs.panelStyle === "morph"

    // key: what it is called in Prefs.barLayout and in the drag-and-drop UI.
    //   label — the human name, shown in Settings > Bar
    //   glyph — its compact face, for the utility pill
    //   opens — AppState flag its chip toggles there; "" means a readout
    readonly property var meta: ({
        launcher:      { label: "Launcher",      glyph: "", opens: "launcherVisible" },
        notifications: { label: "Notifications", glyph: "", opens: "notificationsVisible" },
        workspaces:    { label: "Workspaces",    glyph: "", opens: "" },
        media:         { label: "Media",         glyph: "", opens: "mediaVisible" },
        clock:         { label: "Clock & Weather", glyph: "", opens: "calendarVisible" },
        usb:           { label: "USB",           glyph: "", opens: "usbVisible" },
        recording:     { label: "Recording",     glyph: "", opens: "" },
        tray:          { label: "Tray",          glyph: "", opens: "" },
        network:       { label: "Network",       glyph: "", opens: "networkVisible" },
        bluetooth:     { label: "Bluetooth",     glyph: "", opens: "bluetoothVisible" },
        volume:        { label: "Sound",         glyph: "", opens: "volumeVisible" },
        battery:       { label: "Battery",       glyph: "", opens: "batteryVisible" },
        keyboard:      { label: "Keyboard",      glyph: "", opens: "" },
        window:        { label: "Active window", glyph: "\ue8f5", opens: "" },
        power:         { label: "Power",         glyph: "", opens: "powerMenuVisible" },

    })

    // Everything the user may arrange on the bar, in the order Settings
    // offers them. The tools are not here: they are fixed to the utility pill.
    readonly property var arrangeable: [
        "launcher", "notifications", "workspaces", "media", "clock",
        "usb", "recording", "tray", "network", "bluetooth", "volume",
        "battery", "keyboard", "window", "power"
    ]

    // Has this panel got a capsule on screen to come out of?
    // Has this panel got a capsule on screen to come out of? Since the utility
    // pill went, the answer is simply "is it standing on the bar": a panel with
    // no capsule arrives from the screen edge instead, which is the path the
    // launcher and the power menu have always used.
    function onScreen(key) {
        if (key === "") return false
        return root.arrangeable.indexOf(key) !== -1 && Prefs.barSectionOf(key) !== ""
    }

    // WHAT a pill shows. How it is DRAWN is a separate question -- a pill can be
    // compact and made of glass at once -- so the outline is not one of these.
    readonly property var contents: [
        { id: "full",    label: "Full" },
        { id: "compact", label: "Compact" },
        { id: "icon",    label: "Icon only" }
    ]
    // What a pill SHOWS, and never a reading it is no longer offered: a saved
    // `volume:compact` outlives the backlight it was chosen on, and a pill left
    // drawing an option Settings has stopped listing is a state with no way out.
    function contentOf(id) {
        const want = Prefs.contentOf(id)
        return root.contentsFor(id).some(v => v.id === want) ? want : "full"
    }
    // May a capsule PAINT ITSELF to say it is on?
    //
    // Only when it is a capsule on a wallpaper. On a solid or island bar the
    // plate underneath is already a filled surface, and a second fill on top of
    // it is a block inside a block; in outline the fill is the one thing that
    // undoes the outline -- a drawn edge with a solid middle is not an outline,
    // it is a button. In both cases "on" is carried by the LETTERS taking the
    // accent, which is the language hover already speaks here.
    readonly property bool fills: !Sizes.barSolid && !Prefs.barOutline

    // Does a pill draw an EDGE where the fill was? Only the outline style does.
    // On a solid, island or framed bar the fill also goes -- but a ring there
    // would draw a frame around every pill inside a filled plate, which is the
    // look the user rejected. There "on" is carried by the letters alone.
    readonly property bool rings: Prefs.barOutline && !Sizes.barSolid

    // Only in the `pills` style does a capsule carry the outline itself. In
    // solid, island and framed the plate IS the bar's surface, so outlining the
    // capsules on top of it drew a frame around every pill inside a filled
    // block -- the opposite of what "outline" means there. The plate takes it.
    function isOutlined(id) { return Prefs.barOutline && !Sizes.barSolid }

    // Settings only offers a pill the readings it actually honours: an option
    // that visibly does nothing is worse than a missing one.
    //
    // compactable — has a shorter reading to fall back on. The rest carry one
    // number or one word and have nothing to trim.
    //
    // Computed, not a literal, because of the sound pill: its compact drops the
    // BRIGHTNESS half, and a machine with no backlight never had that half to
    // drop -- compact there draws precisely what full draws. The rule is the
    // same one that took notifications and usb out of `iconable`; what is new is
    // that this one is only true on some machines, so the option has to go away
    // on those and stay on the others rather than be deleted for everybody.
    readonly property var compactable: {
        let out = ["network", "bluetooth", "clock", "media", "window"]
        if (Brightness.icon(Brightness.level) !== "") out.push("volume")
        return out
    }
    // iconable — has a label that dropping would actually change. A pill that is
    // already just a glyph would draw "icon" exactly as it draws "full".
    // Workspaces is deliberately out: what it shows is settled by its own two
    // controls, the icons switch and how many chips are on screen. So is the
    // clock: the time is the one thing a clock cannot give up.
    // Notifications and USB are OUT: both are a glyph in a square and nothing
    // else, so "icon" would draw exactly what "full" draws -- an option that
    // changes nothing is worse than no option, because it makes you test it.
    readonly property var iconable: ["media", "recording", "window",
                                     "network", "bluetooth", "volume", "battery", "keyboard"]
    function contentsFor(id) {
        return root.contents.filter(v =>
            (v.id !== "compact" || root.compactable.indexOf(id) !== -1) &&
            (v.id !== "icon"    || root.iconable.indexOf(id) !== -1))
    }
    // A pill with one reading has no choice to offer, so its row shows only the
    // glass switch.
    function hasContentChoice(id) { return root.contentsFor(id).length > 1 }

    function label(id) { const m = meta[id]; return m ? m.label : id }
    function glyph(id) { const m = meta[id]; return m ? m.glyph : "" }
    function opens(id) { const m = meta[id]; return m ? m.opens : "" }
}
