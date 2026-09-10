// Ashen — persisted user prefs (prefs.json).  by Adolf — github.com/AdolfLecompte
pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// User choices that have to survive a shell restart. Everything runtime-only
// (panel visibility, current tab...) belongs in AppState instead.
Singleton {
    id: root

    // Clock
    property bool clockSeconds: true
    property bool clock24h: false
    // Weather: the API only ever returns celsius, so this is display-only
    // ("C" | "F" | "K") and every consumer goes through Weather.tempString().
    property string tempUnit: "C"
    // Legacy single weather location ("lat|lon|City"). Kept only so old prefs.json
    // still parses and Weather can migrate it into weatherLocs once. Do not write.
    property string weatherLoc: ""
    // Saved weather locations, packed into ONE field because JsonAdapter drops
    // sibling writes made in the same tick. Line 0 = active index, then one
    // "lat|lon|City" per line. Empty -> Weather geolocates by IP.
    property string weatherLocs: ""

    // FileView loads async: without gating on this, singletons that read a pref in
    // Component.onCompleted (Weather) see "" and clobber the saved value. Consumers
    // wait for loaded before acting on persisted state.
    property bool loaded: false

    // Night light (blue-light filter, driven by wlsunset via the NightLight
    // service). `Scheduled` makes it warm the screen only between From and To;
    // otherwise it holds Temp constant while enabled. Temp in kelvin (lower=warmer).
    property bool nightLightEnabled: false
    property bool nightLightScheduled: false
    property int nightLightTemp: 4000
    property string nightLightFrom: "19:00"
    property string nightLightTo: "07:00"

    // Which screen edge the bar lives on: "top", "bottom", "left" or "right".
    // Left/right make the bar vertical and every pill switches to its compact
    // stacked layout (see Sizes.barVertical).
    property string barPosition: "top"

    // "pills" | "solid" | "framed"
    property string barStyle: "pills"
    // How much of its edge the bar takes, as a percentage. 100 is the whole
    // side; anything less pulls both ends in and leaves the corners to the
    // windows. The framed style ignores it: its plate IS the screen border.
    property int barLength: 100

    // Bar hides itself and comes back on hover; while hidden it reserves no room.
    property bool barAutohide: false

    // Audio visualiser. Off stops cava itself, not just the drawing.
    property bool visualizer: true

    // The sung line on the media card. Kept because it is a thing you turn
    // off for a while (someone is reading over your shoulder, the words are
    // wrong) and want to find still off next time.
    property bool mediaLyrics: true

    // Light or dark. Applies to the seven fixed schemes and to what matugen is
    // asked for when the palette comes from the wallpaper.
    property string themeMode: "dark"

    // Interface language, as an i18n/*.json name ("en", "es", "ru", "de").
    // Empty or unknown reads as English. Read through Services.I18n, never
    // straight from here: it is the one that knows which files ship.
    property string language: "en"

    // How panels open. "morph": they come out of the capsule you pressed and
    // transform into the panel. "plain": they simply appear, like a window.
    property string panelStyle: "morph"

    // Subtle gradient on active/interactive accents (buttons, pills) when on.
    // Backgrounds never use it. See Colors.accentGradient.
    property bool useGradients: false


    // Quick toggles that a shell restart used to reset. AppState still owns the
    // live value every consumer reads; these two are only the seed it restores
    // from and writes back to.
    property bool doNotDisturb: false
    property bool keepAwake: false

    // LEGACY, read once at load to seed the first arrangement and never written
    // again: being somewhere on the bar IS being visible now.
    property string hiddenPills: ""

    // The legacy field, parsed. Only syncBarLayout reads it.
    property var hiddenPillList: []
    function syncHiddenPills() {
        root.hiddenPillList = root.hiddenPills.split(",").filter(x => x !== "")
    }

    // A pill exists exactly when the layout gives it a place.
    function pillVisible(id) {
        return root.barSectionOf(id) !== ""
    }

    // ── Bar layout ──────────────────────────────────────────────────────
    // "v2|left;centre;right;parked", ids comma separated. ONE packed string:
    // the adapter drops writes made in the same tick. The 4th part (dragged off
    // the bar) tells a pill nobody has seen from one that was thrown away.
    // Only trust it behind the "v2|" mark: older layouts had a 4th part too,
    // holding the utility pill's tools.
    property string barLayout: ""

    // Runtime truth. Same reason as hiddenPillList: reading the string back in
    // the tick it was written returns the old value.
    property var barSections: ({ left: [], centre: [], right: [] })
    // Pills the user took off the bar. Not "hidden": off the bar IS off.
    property var barParked: []

    // ── Monitor layout ──────────────────────────────────────────────────
    // Settings > Display, keyed by monitor DESCRIPTION so it survives a port
    // swap. JSON in one string for the same reason barLayout is packed, and
    // because the record per monitor has eight fields. Read through
    // Services.Displays, never parsed by hand. Empty = never arranged, so
    // whatever Hyprland worked out on its own stands.
    property string displayLayout: ""

    // ── The four programs the keybinds open ─────────────────────────────
    // Empty means "whatever this machine already prefers": the browser is the
    // system default, the rest are the first of their kind that is installed.
    // Naming one here is an override, not a requirement. Read and written
    // through Services.Apps, which is what hands them to `ashen-app`.
    property string appTerminal: ""
    property string appBrowser: ""
    property string appFiles: ""
    property string appEditor: ""

    // And which keys open them. Empty means the shipped combo; anything else is
    // written back out as a Hyprland bind, because a keybind cannot be changed
    // from inside the shell any other way.
    // Which keys do what, for the ones that have been changed: JSON in one
    // string, same reason as the widget layout. Read through Services.Shortcuts.
    property string keyOverrides: ""

    // ── Desktop widgets ─────────────────────────────────────────────────
    // Which widgets sit on the wallpaper and where. JSON in one string, same
    // reason as displayLayout: the adapter drops sibling writes made in one
    // tick, and a widget is four fields. Read through Services.Desktop.
    property string desktopLayout: ""

    // The arrangement the bar shipped with, used until the user moves anything.
    readonly property var defaultSections: ({
        left: ["launcher", "notifications", "workspaces", "media"],
        centre: ["usb", "clock", "recording"],
        right: ["tray", "network", "bluetooth", "volume", "battery", "keyboard", "power"]
    })

    // How many workspace chips the bar shows at once. A quantity, not a way of
    // drawing itself, so it is not one of the pill's looks.
    property int workspaceCount: 5

    // WHAT a pill shows, and HOW it is drawn, are two questions: a pill can be
    // compact and made of glass at the same time. Two packed strings, beside the
    // order and for the same reason it is packed -- the adapter drops sibling
    // writes made in the same tick.
    //
    // barContent  id:full|compact|icon   (only what differs from full)
    property string barContent: ""

    // Outline is ONE switch for the whole bar, not one per capsule. Fifteen of
    // them was fifteen chances to end up with a bar that is half glass and half
    // plate, which reads as a mistake rather than as a choice -- and nobody
    // opened that panel wanting to outline the battery but not the clock.
    property bool barOutline: false

    // The same idea for the panels, and DELIBERATELY a second switch: the bar
    // is a strip you look past all day and a panel is a room you opened on
    // purpose. Wanting one drawn and the other filled is a real preference,
    // and one flag for both would have made it unsayable.
    property bool panelOutline: false

    // And the widgets, which are the third surface: they sit ON the wallpaper
    // rather than over it, so wanting them drawn while the bar stays filled is
    // its own choice again.
    property bool widgetOutline: false

    readonly property var contentMap: {
        let out = ({})
        for (const pair of (root.barContent || "").split(",")) {
            const kv = pair.split(":")
            if (kv.length === 2 && kv[0] !== "") out[kv[0]] = kv[1]
        }
        return out
    }

    function contentOf(id) { return root.contentMap[id] || "full" }
    function setContent(id, v) {
        let next = ({})
        for (const k in root.contentMap) next[k] = root.contentMap[k]
        // "full" is the default and is not written down: an absent key IS full.
        if (v === "full") delete next[id]
        else next[id] = v
        let out = []
        for (const k in next) out.push(k + ":" + next[k])
        root.barContent = out.join(",")
    }

    // The id is still taken so every caller reads the same way it always did;
    // the answer just no longer depends on which capsule is asking.
    function isOutlined(id) { return root.barOutline }

    // Dock pins, in the user's order, by .desktop id. One packed string for the
    // same reason barLayout is one: the adapter drops sibling writes made in the
    // same tick.
    property string dockPins: ""
    readonly property var dockPinList: (root.dockPins || "").split(",").filter(x => x !== "")

    function dockPin(id) {
        if (root.dockPinList.indexOf(id) !== -1) return
        root.dockPins = root.dockPinList.concat([id]).join(",")
    }
    function dockUnpin(id) {
        root.dockPins = root.dockPinList.filter(x => x !== id).join(",")
    }
    function dockMovePin(id, index) {
        let next = root.dockPinList.filter(x => x !== id)
        const at = Math.max(0, Math.min(index === undefined ? next.length : index, next.length))
        next.splice(at, 0, id)
        root.dockPins = next.join(",")
    }

    // Which edge the dock takes, and whether it stays out of the way.
    property string dockEdge: "bottom"
    property bool dockAutohide: true
    // Off entirely. Not the same as having no pins: a dock with nothing in it
    // still shows the windows you have open, and that is a thing to be able to
    // say no to.
    property bool dockEnabled: true
    // Frosted rather than a solid plate, the same choice the bar's pills have.
    property bool dockGlass: false
    // The icon box. Clamped where it is read, so a hand-edited file cannot
    // produce a dock with no room for an icon.
    property int dockIconSize: 44

    // The five pills the system plate became, in the order they sat in it.
    readonly property string sysSplit: "network,bluetooth,volume,battery,keyboard"

    function syncBarLayout() {
        // The plate became five pills. A saved layout naming it is rewritten in
        // place, so the five inherit its seat AND its parked mark -- without
        // this, someone who had dragged the plate off the bar would get all five
        // back, because the rule below hands a factory seat to any pill that is
        // in neither list.
        const raw = (root.barLayout || "").replace(
            /(^|[|;,])system([;,]|$)/g, "$1" + root.sysSplit + "$2")
        if (raw === "") {
            // First run, or an upgrade from when only visibility existed: start
            // from the shipped order minus whatever was switched off back then,
            // and remember those as parked so they stay off.
            const hidden = root.hiddenPillList
            const keep = list => list.filter(id => hidden.indexOf(id) === -1)
            root.barSections = {
                left: keep(root.defaultSections.left),
                centre: keep(root.defaultSections.centre),
                right: keep(root.defaultSections.right)
            }
            root.barParked = hidden.slice()
            return
        }
        const v2 = raw.indexOf("v2|") === 0
        const parts = (v2 ? raw.slice(3) : raw).split(";")
        const cut = i => (parts[i] || "").split(",").filter(x => x !== "")
        let next = { left: cut(0), centre: cut(1), right: cut(2) }
        // Before v2 there was nowhere to record a pill dragged off the bar, so
        // the old visibility field stands in for it.
        let parked = v2 ? cut(3) : root.hiddenPillList.slice()

        // A pill shipped after this string was written is in neither list, so
        // it takes its factory seat instead of hiding in Available for ever.
        const known = id => root.sectionIds.some(s => next[s].indexOf(id) !== -1)
        for (const s of root.sectionIds) {
            const shipped = root.defaultSections[s]
            for (let i = 0; i < shipped.length; i++) {
                const id = shipped[i]
                if (known(id) || parked.indexOf(id) !== -1) continue
                next[s].splice(Math.min(i, next[s].length), 0, id)
            }
        }
        root.barSections = next
        root.barParked = parked
    }

    readonly property var sectionIds: ["left", "centre", "right"]
    function barPills(section) { return root.barSections[section] || [] }

    function barSectionOf(id) {
        for (const s of root.sectionIds)
            if (root.barSections[s].indexOf(id) !== -1) return s
        return ""
    }

    // Drop `id` into `section` at `index`; section "" parks it as available.
    function moveBarPill(id, section, index) {
        const from = root.barSectionOf(id)
        let next = {}
        for (const s of root.sectionIds)
            next[s] = root.barSections[s].filter(x => x !== id)
        const placed = root.sectionIds.indexOf(section) !== -1
        if (placed) {
            let at = (index === undefined || index < 0) ? next[section].length : index
            // The index was read with the chip still in the row, so inside its
            // own section every slot past it is counted one too high.
            if (from === section && root.barSections[section].indexOf(id) < at) at--
            at = Math.max(0, Math.min(at, next[section].length))
            next[section].splice(at, 0, id)
        }
        root.barSections = next
        root.barParked = placed ? root.barParked.filter(x => x !== id)
                                : root.barParked.filter(x => x !== id).concat([id])
        barWriteTimer.restart()
    }

    function resetBarLayout() {
        let next = {}
        let shipped = []
        for (const s of root.sectionIds) {
            next[s] = root.defaultSections[s].slice()
            shipped = shipped.concat(next[s])
        }
        // Known pills the shipped arrangement has no seat for stay off the bar
        // (`window`); the rest lose their parked mark or the next load would
        // throw them out again.
        let known = root.barParked.slice()
        for (const s of root.sectionIds)
            known = known.concat(root.barSections[s])
        root.barSections = next
        root.barParked = known.filter((id, i) => shipped.indexOf(id) === -1
                                                 && known.indexOf(id) === i)
        barWriteTimer.restart()
    }

    Timer {
        id: barWriteTimer
        interval: 0
        onTriggered: root.barLayout = "v2|"
            + root.sectionIds.map(s => root.barSections[s].join(",")).join(";")
            + ";" + root.barParked.join(",")
    }

    // Screen recording. An empty dir means "wherever Paths.recordings points".
    property bool recordAudio: true
    property string recordDir: ""

    // Where the picker looks for wallpapers. Empty means Paths.wallpapers.
    property string wallpaperDir: ""


    // Workspace chips show a glyph for whatever is open on them instead of the
    // number. Empty workspaces always keep their number.
    // What a workspace chip shows: the app's icon, its number, or a dot. Was a
    // bool (icons on/off); a third answer needed a third value, not a second
    // switch beside the first.
    //   "icons"   the running app's glyph, falling back to the number
    //   "numbers" the number, always
    //   "dots"    no reading at all -- a dot, and the one you are on is a bar
    property string workspaceStyle: "icons"
    // Kept so a saved `false` still means numbers on the first run after this.
    property bool workspaceIcons: true

    // Idle timeouts in seconds, 0 = never. The Idle service turns these into
    // hypridle.conf; nothing else may write that file.
    property int idleLockSecs: 300
    property int idleScreenOffSecs: 600
    property int idleSuspendSecs: 900

    // Lock screen: the clock and the login are the screen itself; every card
    // around them is a reading you may not want a stranger to have, so each
    // one is its own switch.
    property bool lockShowMedia: true
    property bool lockShowWeather: true
    property bool lockShowMachine: true
    property bool lockShowSystem: true
    // The lock's notification list. Off by default is the wrong default here:
    // the whole point of a lock screen is reading what happened while you were
    // gone, and anything private is already the notification's own business.
    property bool lockShowNotifications: true

    // Toasts: how long a normal one stays on screen (seconds) and how many may
    // stack before the rest collapse into the "+N" row. System toasts keep their
    // own short dwell — they are an acknowledgement, not a message.
    // A sound when something arrives. Empty file = the shipped default.
    property bool notifySound: false
    property string notifySoundFile: ""
    // Urgency 2 only, for people who want the room quiet otherwise.
    property bool notifySoundCriticalOnly: false
    // 0..1, applied to everything the shell plays.
    property real soundVolume: 0.5

    property int toastSeconds: 6
    property int maxToasts: 5

    // Active keyboard layout, by code ("latam"). switchxkblayout is runtime-only
    // and only the ORDER of kb_layout decides what login starts on. Storing the
    // pick here lets the list order stay put -- the cards must not jump around
    // under the cursor -- and the shell re-applies the choice on startup.
    property string keyboardLayout: ""

    // Every clock in the shell (bar, calendar, lock) formats through these, so
    // the three can't drift apart.
    readonly property string hourToken: clock24h ? "HH" : "hh"
    readonly property string ampmToken: clock24h ? "" : " AP"
    readonly property string timeFormat: hourToken + ":mm" + (clockSeconds ? ":ss" : "") + ampmToken

    readonly property string configDir: Paths.config

    FileView {
        id: prefsFile
        path: root.configDir + "/prefs.json"
        // Deliberately NOT watchChanges: this file has no writer but us, and
        // reload()-ing our own writeAdapter() re-reads it mid-flight and reverts
        // whatever was set a moment earlier.
        // Any write to the adapter lands on disk immediately
        // Never before the read: the adapter starts on the code defaults, and a
        // reload landing mid-read wrote those over the saved ones.
        onAdapterUpdated: if (root.loaded) writeAdapter()
        // File on disk is now the source of truth: let consumers act on it.
        onLoaded: { root.syncHiddenPills(); root.syncBarLayout(); root.loaded = true }
        // First run: no file yet, so seed it with the defaults above. Still
        // "loaded" -- the empty state IS the loaded state (Weather will geolocate).
        onLoadFailed: function(error) { writeAdapter(); root.syncHiddenPills(); root.syncBarLayout(); root.loaded = true }

        JsonAdapter {
            id: adapter
            property alias clockSeconds: root.clockSeconds
            property alias clock24h: root.clock24h
            property alias tempUnit: root.tempUnit
            property alias weatherLoc: root.weatherLoc
            property alias weatherLocs: root.weatherLocs
            property alias keyboardLayout: root.keyboardLayout
            property alias useGradients: root.useGradients
            property alias panelStyle: root.panelStyle
            property alias themeMode: root.themeMode
            property alias language: root.language
            property alias doNotDisturb: root.doNotDisturb
            property alias keepAwake: root.keepAwake
            property alias notifySound: root.notifySound
            property alias notifySoundFile: root.notifySoundFile
            property alias notifySoundCriticalOnly: root.notifySoundCriticalOnly
            property alias soundVolume: root.soundVolume
            property alias toastSeconds: root.toastSeconds
            property alias maxToasts: root.maxToasts
            property alias hiddenPills: root.hiddenPills
            property alias barLayout: root.barLayout
            property alias barContent: root.barContent
            property alias barOutline: root.barOutline
            property alias panelOutline: root.panelOutline
            property alias widgetOutline: root.widgetOutline
            property alias dockPins: root.dockPins
            property alias dockEdge: root.dockEdge
            property alias dockAutohide: root.dockAutohide
            property alias dockEnabled: root.dockEnabled
            property alias dockGlass: root.dockGlass
            property alias dockIconSize: root.dockIconSize
            property alias workspaceCount: root.workspaceCount
            property alias displayLayout: root.displayLayout
            property alias desktopLayout: root.desktopLayout
            property alias appTerminal: root.appTerminal
            property alias appBrowser: root.appBrowser
            property alias appFiles: root.appFiles
            property alias appEditor: root.appEditor
            property alias keyOverrides: root.keyOverrides
            property alias recordAudio: root.recordAudio
            property alias recordDir: root.recordDir
            property alias wallpaperDir: root.wallpaperDir
            property alias lockShowMedia: root.lockShowMedia
            property alias lockShowWeather: root.lockShowWeather
            property alias lockShowMachine: root.lockShowMachine
            property alias lockShowSystem: root.lockShowSystem
            property alias lockShowNotifications: root.lockShowNotifications
            property alias workspaceIcons: root.workspaceIcons
            property alias workspaceStyle: root.workspaceStyle
            property alias idleLockSecs: root.idleLockSecs
            property alias idleScreenOffSecs: root.idleScreenOffSecs
            property alias idleSuspendSecs: root.idleSuspendSecs
            property alias barPosition: root.barPosition
            property alias barStyle: root.barStyle
            property alias barLength: root.barLength
            property alias barAutohide: root.barAutohide
            property alias visualizer: root.visualizer
            property alias mediaLyrics: root.mediaLyrics
            property alias nightLightEnabled: root.nightLightEnabled
            property alias nightLightScheduled: root.nightLightScheduled
            property alias nightLightTemp: root.nightLightTemp
            property alias nightLightFrom: root.nightLightFrom
            property alias nightLightTo: root.nightLightTo
        }
    }
}
