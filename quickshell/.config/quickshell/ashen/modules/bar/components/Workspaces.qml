import Quickshell
import Quickshell.Hyprland
import QtQuick
import "root:/services" as Services
import "root:/modules/widgets" as Widgets

// One pill that turns into the other: entering a special swaps the numbers for
// the specials in place. The swap is staged — content out, box resizes, content
// in — because fading both rows at once left them lying on top of each other,
// which is plain to see now that the pill draws no full box around them.
Item {
    id: root
    // The bar this pill stands on (Bar.qml hands it in).
    property var spec: Services.Sizes.first

    // The bar flips the whole strip: chips stack instead of running across.
    readonly property bool vertical: Services.Sizes.barVertical
    // How many chips the row shows before it pages. Clamped here rather than at
    // the setting, so a hand-edited prefs file cannot produce an empty row.
    readonly property int shown: Math.max(2, Math.min(10, Services.Prefs.workspaceCount))
    // icons / numbers / dots. In dots the chips carry no reading at all: the one
    // you are standing on is a bar, the rest are dots, and the row says WHERE
    // you are rather than what is running.
    readonly property string wsStyle: Services.Prefs.workspaceLook
    readonly property bool dots: root.wsStyle === "dots"
    readonly property bool marks: root.dots
    readonly property bool kanji: root.wsStyle === "kanji"
    // Pac-Man eats the row: he is where you are, a ghost haunts every
    // workspace with windows, and the empty ones are pellets. No plates.
    readonly property bool pacman: root.wsStyle === "pacman"
    // Icons are bare too: the app's own glyph, the one you are on in the accent.
    readonly property bool icons: root.wsStyle === "icons"
    readonly property bool bare: root.marks || root.pacman || root.icons
    // Pac-Man and icons colour the glyph instead of drawing a plate.
    readonly property bool inked: root.pacman || root.icons
    readonly property string glyphPacman: "\udb82\udfaf"
    readonly property string glyphGhost: "\udb80\udea0"
    readonly property string glyphPellet: "\u2022"
    // A tick per window under each chip: a switch, not a style.
    readonly property bool counted: Services.Prefs.workspaceTicks
    readonly property var kanjiDigits: ["\u3007", "\u4e00", "\u4e8c", "\u4e09", "\u56db", "\u4e94",
                                        "\u516d", "\u4e03", "\u516b", "\u4e5d", "\u5341"]
    function kanjiOf(n) {
        if (n <= 10) return root.kanjiDigits[n]
        if (n < 20) return root.kanjiDigits[10] + root.kanjiDigits[n - 10]
        return String(n)
    }
    function specialKanji(name) {
        if (name === "music")   return "\u97f3"
        if (name === "discord") return "\u8a71"
        if (name === "notes")   return "\u8a18"
        if (name === "fav")     return "\u661f"
        return "\u7279"
    }
    // A chip's length along the bar: fixed, except the active dot.
    function alongOf(wsId, active) {
        if (root.marks) return active ? root.dotOnW : root.dotW
        return root.innerH
    }
    // A dot is a chip that gave up its READING, not its size: it is exactly as
    // big as the numbered chip it replaces (Sizes.innerH), so switching styles
    // changes what the row says and never how much room it takes. Grown three
    // times on the same complaint -- at 16 and then at 22 it read as dust
    // sitting on the bar rather than as a row you are meant to look at.
    readonly property int dotW: 26
    readonly property int dotOnW: 46
    // Three quarters of a chip: at the chip's full 32 px the dots crowd their
    // plate and the row stops reading as points, at 14 they were dust. This is
    // the size that reads as a dot and still carries.
    readonly property int dotH: 20
    readonly property int cellW: root.dots ? root.dotW : root.innerH
    // Only full and outline: what the chips SHOW is settled by the icons switch
    // and by how many of them there are, not by a way of drawing the plate.
    readonly property string content: Services.Pills.contentOf("workspaces")
    readonly property bool outlined: root.spec.outlined("workspaces")
    width: pill.width
    height: pill.height

    readonly property int pillH: Services.Sizes.pillH
    readonly property int innerH: Services.Sizes.innerH
    readonly property int innerR: Services.Sizes.innerR
    readonly property int pillR: Services.Sizes.pillR
    readonly property int pad: 8

    // The monitor THIS bar is on, asked of its own window. Every screen has its
    // own strip, so reading the FOCUSED monitor made both bars mark the same
    // workspace -- with eDP-1 on 2 and the second screen on 3, both said 3.
    // Same trick PillCenter uses to find its screen.
    readonly property var barMonitor: {
        const name = QsWindow.window && QsWindow.window.screen
            ? QsWindow.window.screen.name : ""
        for (const m of Hyprland.monitors.values)
            if (m.name === name) return m
        return Hyprland.focusedMonitor
    }
    readonly property var barIpc: root.barMonitor ? root.barMonitor.lastIpcObject : null

    // Hyprland does not emit the `workspace` event when entering a special, so
    // focusedWorkspace is useless: the monitor is what knows which one is shown.
    readonly property string shownSpecial: {
        const sw = root.barIpc ? root.barIpc.specialWorkspace : null
        return (sw && sw.name) ? sw.name : ""
    }
    readonly property bool inSpecial: shownSpecial !== ""

    // Every special that exists (has windows), not just the one being shown.
    readonly property var specials: Hyprland.workspaces.values
        .filter(w => w.id < 0)
        .sort((a, b) => b.id - a.id)

    // Everything this strip reads comes off the monitor object, and that object
    // is only as fresh as the last refresh -- so anything that can move a
    // workspace has to ask for one.
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            const n = event.name
            if (n.startsWith("activespecial") || n.startsWith("workspace") || n === "focusedmon")
                Hyprland.refreshMonitors()
        }
    }

    // The workspace THIS monitor is showing. `activeWorkspace` stays on the
    // normal one while a special is up (the special has its own field), so the
    // group-of-5 calculation never sees a negative id.
    readonly property int lastNormalId: {
        const aw = root.barIpc ? root.barIpc.activeWorkspace : null
        return (aw && aw.id > 0) ? aw.id : 1
    }

    // With an automatic spread, this bar shows its own screen's workspaces only.
    readonly property var ownIds: Services.Displays.autoSpread && root.barMonitor
        ? Services.Displays.wsFor(Services.Displays.keyFor(root.barMonitor.name)) : []
    readonly property bool owned: root.ownIds.length > 0
    // The ids the chips stand for, in order.
    readonly property var chipIds: {
        // Paged by the chip count the user chose, around the active workspace.
        if (root.owned) {
            const at = Math.max(0, root.ownIds.indexOf(root.lastNormalId))
            const start = Math.floor(at / root.shown) * root.shown
            return root.ownIds.slice(start, start + root.shown)
        }
        const base = Math.floor((root.lastNormalId - 1) / root.shown) * root.shown
        const out = []
        for (let i = 1; i <= root.shown; i++) out.push(base + i)
        return out
    }

    // Workspace ids that hold at least one window.
    readonly property var occupied: Hyprland.toplevels.values
        .map(t => t.workspace ? t.workspace.id : -1).filter(id => id > 0)
    function chipShown(id) {
        return !Services.Prefs.workspaceHideEmpty || id === root.lastNormalId
            || root.occupied.indexOf(id) !== -1
    }

    // The "count" style: one tick per window under the number, up to three.
    component Ticks: Row {
        id: tk
        property int wins: 0
        property color ink
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 5
        visible: tk.wins > 0
        spacing: 3
        Repeater {
            model: tk.wins
            Rectangle { width: 3; height: 3; radius: 1.5; color: tk.ink }
        }
    }

    // A named special has its own glyph; any other -- the scratchpad -- holds
    // whatever app you put there, so it shows that app's, like a normal chip.
    // Idea from RchrdAriza's PR #2.
    function specialGlyph(id, name) {
        if (["music", "discord", "notes", "fav"].indexOf(name) !== -1) return root.specialIcon(name)
        const app = Services.Windows.workspaceIcon(id)
        return app !== "" ? app : root.specialIcon(name)
    }
    function specialIcon(name) {
        if (name === "music")   return ""
        if (name === "discord") return ""
        if (name === "notes")   return ""
        if (name === "fav")     return ""
        return ""
    }


    // The chip a preview is growing out of steps aside -- plate, label, marks
    // and the active indicator -- the way a pill does for its panel. Hiding
    // only the label left its plate (lit, and grown under the pointer)
    // showing around the card's first frames.
    function covered(id) {
        return Services.AppState.wsPreviewMorphing && Services.AppState.wsPreviewId === id
    }

    // Hold the pointer still on a chip and that workspace opens a preview of
    // itself. 600 ms: long enough that sweeping across the strip never trips
    // it, short enough that it does not feel like waiting.
    component PreviewHover: MouseArea {
        id: ph
        property int wsId: 0
        property string label: ""
        // Nothing to preview on an empty workspace, so it never opens
        property bool previewable: false
        // Wearing the accent: the workspace you are on, or the special open.
        property bool lit: false
        signal activated()

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        z: 10
        onClicked: ph.activated()

        onEntered: if (ph.previewable) dwell.restart()
        onExited: {
            dwell.stop()
            if (Services.AppState.wsPreviewId === ph.wsId)
                Services.AppState.wsPreviewId = 0
        }

        Timer {
            id: dwell
            interval: 600
            onTriggered: {
                // Same two corrections as PillCenter: the bar's own origin (a
                // bottom or right bar reported a chip near the top-left without
                // it), and the SCREEN's, because mapToGlobal answers in the
                // layout -- on a second monitor at x=1920 that is 1920 too far,
                // and the preview grew off the side of the screen.
                const g = ph.mapToGlobal(0, 0)
                const s = QsWindow.window ? QsWindow.window.screen : null
                // As drawn: grown under the pointer, the chip is a little
                // larger than its slot, and a card born at the slot's size
                // left the grown edge showing around it.
                const k = ph.parent && ph.parent.scale ? ph.parent.scale : 1
                Services.AppState.setWsPreview(ph.wsId, ph.label,
                    root.spec.originX(s) + g.x - (s ? s.x : 0) - ph.width * (k - 1) / 2,
                    root.spec.originY(s) + g.y - (s ? s.y : 0) - ph.height * (k - 1) / 2,
                    ph.width * k, ph.height * k,
                    // What the chip shows: the accent is the indicator's, under
                    // the one you are on; any other chip shows the bar.
                    ph.lit ? (root.spec.rings ? "transparent" : Services.Colors.ghost) : "transparent")
            }
        }
    }

    // Workspaces normales
    Rectangle {
        id: pill
        radius: root.pillR
        color: root.outlined ? Services.Colors.surfaceGlass
                                          : root.spec.pillPlate
        border.width: root.outlined ? Services.Sizes.outlineW : 0
        border.color: Services.Colors.fillOutline

        // What the pill is showing right now. It lags `root.inSpecial` on
        // purpose: the swap only lands once the old row is gone, so the two
        // never share the pill for a single frame.
        property bool showSpecial: root.inSpecial
        property real contentOpacity: 1

        readonly property Item shownRow: showSpecial ? specialRow : wsRow
        width: root.vertical ? root.pillH : shownRow.width + root.pad * 2
        height: root.vertical ? shownRow.height + root.pad * 2 : root.pillH
        // The box travels to its new size while it is empty — same order as the
        // media island: box first, content after.
        Behavior on width { Widgets.Anim { curve: Services.Sizes.easeBox } }
        Behavior on height { Widgets.Anim { curve: Services.Sizes.easeBox } }

        Connections {
            target: root
            function onInSpecialChanged() { swap.restart() }
        }

        SequentialAnimation {
            id: swap
            NumberAnimation { target: pill; property: "contentOpacity"; to: 0; duration: 120 }
            ScriptAction { script: pill.showSpecial = root.inSpecial }
            // Long enough for the width Behavior above to land.
            PauseAnimation { duration: 180 }
            NumberAnimation { target: pill; property: "contentOpacity"; to: 1; duration: 160 }
        }

        Rectangle {
            id: slideIndicator
            readonly property real along: root.alongOf(root.lastNormalId, true)
            width: root.vertical ? root.innerH : along
            height: root.vertical ? along : root.innerH
            Behavior on width { Widgets.Anim { speed: Services.Sizes.msPronounced } }
            Behavior on height { Widgets.Anim { speed: Services.Sizes.msPronounced } }
            radius: root.innerR
            // Only in OUTLINE is the indicator a ring: a filled block inside a
            // drawn edge is what undoes the outline. On a solid, island or
            // framed bar the plate is the surface these numbers live on, so the
            // indicator fills there exactly as it always did -- ringing it drew
            // an outline the bar had not asked for. See Pills.rings.
            color: root.spec.rings ? "transparent" : Services.Colors.ghost
            border.width: root.spec.rings ? Services.Sizes.outlineW : 0
            border.color: Services.Colors.ghost
            gradient: (Services.Prefs.useGradients && !root.spec.rings)
                      ? Services.Colors.accentGradient : null
            // Part of the numbers, so it leaves and comes back with them.
            // In dots the chips carry their own fill, so the indicator that
            // would slide under them has nothing left to say.
            opacity: root.bare || pill.showSpecial || root.covered(root.lastNormalId) ? 0 : pill.contentOpacity
            readonly property real slot: {
                let at = root.pad
                for (const id of root.chipIds) {
                    if (id === root.lastNormalId) break
                    if (root.chipShown(id)) at += root.alongOf(id, false) + 4
                }
                return at
            }
            readonly property real centred: (root.pillH - root.innerH) / 2
            x: root.vertical ? centred : slot
            y: root.vertical ? slot : centred
            Behavior on x { SmoothedAnimation { duration: Services.Sizes.msPronounced } }
            Behavior on y { SmoothedAnimation { duration: Services.Sizes.msPronounced } }
        }

        // Pac-Man is the indicator in his style: ONE of him, riding the
        // indicator's own sliding position.
        Text {
            id: pac
            z: 2
            visible: root.pacman && !pill.showSpecial
            opacity: root.covered(root.lastNormalId) ? 0 : pill.contentOpacity
            textFormat: Text.PlainText
            text: root.glyphPacman
            color: Services.Colors.ghost
            font.pixelSize: 18
            font.family: "JetBrainsMono NF"
            readonly property bool ticked: root.counted && Services.Windows.windowCount(root.lastNormalId) > 0
            x: slideIndicator.x + (slideIndicator.width - width) / 2
            y: slideIndicator.y + (slideIndicator.height - height) / 2 + (pac.ticked ? -3 : 0)
        }

        BarStrip {
            id: wsRow
            anchors.centerIn: parent
            spacing: 4
            // Only one row is ever alive: `visible` is what keeps the hidden
            // one from catching the pointer meant for the other.
            visible: !pill.showSpecial
            opacity: pill.contentOpacity
            scale: 0.92 + 0.08 * pill.contentOpacity

            Repeater {
                model: root.chipIds.length
                delegate: Item {
                    required property int index
                    property int wsId: root.chipIds[index] || 0
                    opacity: root.covered(wsId) ? 0 : 1
                    property bool isActive: root.lastNormalId === wsId
                    visible: root.chipShown(wsId)
                    property bool hasWindows: Hyprland.workspaces.values.find(w => w.id === wsId) !== undefined
                    // Hyprland lists the workspace you are standing on even when
                    // it is empty, so `hasWindows` says yes for the one you are
                    // on and the preview opened onto nothing. Count real windows.
                    readonly property int winCount:
                        Hyprland.toplevels.values.filter(t => t.workspace && t.workspace.id === wsId).length
                    // A dot stretches ALONG the bar. On a side bar that is its
                    // height: stretching the width made the one you stand on a
                    // bar lying across a column only one pill wide.
                    readonly property int along: root.alongOf(wsId, isActive)
                    readonly property int wins: (root.counted && !root.marks) ? Math.min(3, Services.Windows.windowCount(wsId)) : 0
                    readonly property color ink: root.inked
                        ? (isActive ? Services.Colors.ghost : warm ? Services.Colors.snow
                           : winCount > 0 ? Services.Colors.mist : Services.Colors.ash)
                        : isActive
                                 ? (!root.spec.rings ? Services.Colors.accentText : Services.Colors.ghost)
                             : warm ? Services.Colors.snow
                             : (!root.spec.rings ? Services.Colors.ash : Services.Colors.mist)
                    width: root.vertical ? root.innerH : along
                    height: root.vertical ? along : root.innerH
                    Behavior on width { NumberAnimation { duration: Services.Sizes.msStandard
                                                          easing.type: Services.Sizes.easeOut } }
                    Behavior on height { NumberAnimation { duration: Services.Sizes.msStandard
                                                           easing.type: Services.Sizes.easeOut } }
                    // Guarded: the MouseArea is declared further down, so on the
                    // first evaluation the id is not resolved yet and a bare
                    // `.containsMouse` throws.
                    readonly property bool warm: chipHover && chipHover.containsMouse
                    scale: Services.Sizes.hoverScale(warm, chipHover && chipHover.pressed)
                    Behavior on scale { Widgets.Anim { speed: Services.Sizes.pillHoverMs } }

                    Rectangle {
                        anchors.fill: parent
                        radius: root.innerR
                        visible: !root.bare
                        // The plate says whether the workspace has anything on it, nothing else.
                        // Active chips are carried by the sliding indicator, so they stay bare.
                        color: Services.Colors.fillRest
                        opacity: parent.isActive ? 0 : parent.hasWindows ? 1 : 0
                        Behavior on opacity { Widgets.Anim {} }
                    }

                    // The dot itself. Fully round, so growing into the active
                    // bar is the same shape stretched rather than a new one.
                    Rectangle {
                        visible: root.marks
                        anchors.centerIn: parent
                        // A line is a dot drawn as a stick: thin across, short along.
                        readonly property int cross: root.dotH
                        readonly property int rest: root.dotH
                        // A CIRCLE when it is only a dot, a capsule when it is
                        // the one you are standing on. Taking the cell's whole
                        // width made every dot an oval, which reads as a short
                        // bar rather than as a point.
                        width: root.vertical ? cross : (parent.isActive ? parent.width : rest)
                        height: root.vertical ? (parent.isActive ? parent.height : rest) : cross
                        radius: Math.min(width, height) / 2
                        // Outlined, a dot is a RING: a row of filled circles on
                        // a drawn plate is the same filled-blob-inside-an-
                        // outline the rest of the bar just stopped doing. The
                        // one you are standing on stays solid -- it is the
                        // thing the row exists to point at.
                        border.width: (root.spec.rings && !parent.isActive)
                                      ? Services.Sizes.outlineW : 0
                        border.color: Services.Colors.fillOutline
                        // On a glass plate `ash` and `fillRest` are two shades
                        // of nothing: the row of dots disappeared and only the
                        // active one showed. Outlined, they read at the same
                        // strength as the border around them.
                        color: parent.isActive ? Services.Colors.ghost
                             : parent.warm ? Services.Colors.snow
                             : root.spec.rings
                                 // A ring, so the inside is the wallpaper. What
                                 // says "this one has windows" is the ring's
                                 // own strength, not a fill.
                                 ? "transparent"
                             : parent.hasWindows ? Services.Colors.ash
                                                 : Services.Colors.fillRest
                        Behavior on color { Widgets.ColorAnim {} }
                    }

                    // A workspace with something on it shows what that is; an
                    // empty one is a dot.
                    readonly property string appIcon: root.icons ? Services.Windows.workspaceIcon(wsId) : ""

                    Text {
                        textFormat: Text.PlainText
                        visible: !root.marks
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: parent.wins > 0 ? -3 : 0
                        // The active chip is empty: Pac-Man himself slides over it.
                        // Real windows, not Hyprland's list: it keeps the workspace you
                        // just left for a moment, and that read as a ghost there.
                        text: root.pacman ? (parent.isActive ? ""
                                             : parent.winCount > 0 ? root.glyphGhost : root.glyphPellet)
                            : parent.appIcon !== "" ? parent.appIcon
                            : root.icons ? root.glyphPellet
                            : root.kanji ? root.kanjiOf(wsId) : wsId
                        color: parent.ink
                        font.pixelSize: root.inked && parent.appIcon === "" ? 18 : parent.appIcon !== "" ? 15 : root.kanji ? 14 : 13
                        font.family: parent.appIcon !== "" ? "Material Symbols Rounded"
                                   : root.kanji ? "Noto Sans CJK JP" : "JetBrainsMono NF"
                        font.bold: true
                        z: 1
                        // The preview flies this very label into its caption, so
                        // the chip lets go of it: two copies at once would give
                        // the trick away.
                        opacity: Services.AppState.wsPreviewMorphing
                            && Services.AppState.wsPreviewId === parent.wsId ? 0 : 1
                        Behavior on opacity { Widgets.Anim { speed: Services.Sizes.msMicro } }
                        Behavior on color { Widgets.ColorAnim {} }
                    }

                    Ticks { wins: parent.wins; ink: parent.ink }

                    PreviewHover {
                        id: chipHover
                        wsId: parent.wsId
                        lit: parent.isActive && !root.bare
                        // What the chip itself shows, so the caption it flies
                        // into matches: a ghost (only a workspace with windows
                        // is previewed), its app, its kanji, or its number.
                        label: root.pacman ? root.glyphGhost
                             : parent.appIcon !== "" ? parent.appIcon
                             : root.kanji ? root.kanjiOf(parent.wsId) : String(parent.wsId)
                        previewable: parent.winCount > 0
                        onActivated: {
                            var id = parent.wsId
                            Quickshell.execDetached(["sh", "-c", "hyprctl dispatch 'hl.dsp.focus({ workspace = " + id + " })'"])
                        }
                    }
                }
            }
        }

        // The specials take the pill over while one of them is on screen. The
        // shown one is filled; the rest are dimmed.
        BarStrip {
            id: specialRow
            anchors.centerIn: parent
            spacing: 4
            visible: pill.showSpecial
            opacity: pill.contentOpacity
            scale: 0.92 + 0.08 * pill.contentOpacity

            Repeater {
                model: root.specials

                delegate: Item {
                    required property var modelData
                    opacity: root.covered(modelData.id) ? 0 : 1
                    readonly property string shortName: modelData.name.replace("special:", "")
                    readonly property bool isShown: modelData.name === root.shownSpecial
                    // Same style as the numbered row: a glyph, an initial, or a dot.
                    // Every style shows the special's own icon, so it can be told
                    // apart -- a dot or a number would not say which one it is.
                    // Pac-Man stands on the one that is open.
                    readonly property bool eaten: root.pacman && isShown
                    readonly property string label: eaten ? root.glyphPacman
                        : root.kanji ? root.specialKanji(shortName) : root.specialGlyph(modelData.id, shortName)
                    readonly property int along: root.innerH
                    readonly property int wins: root.counted ? Math.min(3, Services.Windows.windowCount(modelData.id)) : 0
                    readonly property color ink: root.inked
                        ? (isShown ? Services.Colors.ghost : warm ? Services.Colors.snow : Services.Colors.mist)
                        : isShown
                                 ? (!root.spec.rings ? Services.Colors.accentText : Services.Colors.ghost)
                             : warm ? Services.Colors.snow
                             : (!root.spec.rings ? Services.Colors.ash : Services.Colors.mist)
                    width: root.vertical ? root.innerH : along
                    height: root.vertical ? along : root.innerH
                    Behavior on width { NumberAnimation { duration: Services.Sizes.msStandard
                                                          easing.type: Services.Sizes.easeOut } }
                    Behavior on height { NumberAnimation { duration: Services.Sizes.msStandard
                                                           easing.type: Services.Sizes.easeOut } }
                    readonly property bool warm: spHover && spHover.containsMouse
                    scale: Services.Sizes.hoverScale(warm, spHover && spHover.pressed)
                    Behavior on scale { Widgets.Anim { speed: Services.Sizes.pillHoverMs } }

                    Rectangle {
                        anchors.fill: parent
                        radius: root.innerR
                        // Pac-Man and icons draw no blocks, not even under a special.
                        visible: !root.inked
                        color: root.spec.rings ? "transparent"
                             : parent.isShown ? Services.Colors.ghost : Services.Colors.fillRest
                        border.width: (root.spec.rings && parent.isShown)
                                      ? Services.Sizes.outlineW : 0
                        border.color: Services.Colors.ghost
                        gradient: (Services.Prefs.useGradients && !root.spec.rings && parent.isShown)
                                  ? Services.Colors.accentGradient : null
                        Behavior on color { Widgets.ColorAnim {} }
                    }

                    Text {
                        textFormat: Text.PlainText
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: parent.wins > 0 ? -3 : 0
                        text: parent.label
                        color: parent.ink
                        font.pixelSize: root.kanji ? 14 : 18
                        font.family: parent.eaten ? "JetBrainsMono NF"
                                   : root.kanji ? "Noto Sans CJK JP" : "Material Symbols Rounded"
                        font.bold: root.kanji
                        z: 1
                        // Handed over to the preview's caption while it is open
                        opacity: Services.AppState.wsPreviewMorphing
                            && Services.AppState.wsPreviewId === parent.modelData.id ? 0 : 1
                        Behavior on opacity { Widgets.Anim { speed: Services.Sizes.msMicro } }
                        Behavior on color { Widgets.ColorAnim {} }
                    }

                    Ticks { wins: parent.wins; ink: parent.ink }

                    PreviewHover {
                        id: spHover
                        wsId: parent.modelData.id
                        lit: parent.isShown && !root.bare
                        label: parent.label
                        previewable: Hyprland.toplevels.values.filter(
                            t => t.workspace && t.workspace.id === parent.modelData.id).length > 0
                        onActivated: {
                            var n = parent.shortName
                            Quickshell.execDetached(["sh", "-c", "hyprctl dispatch 'hl.dsp.workspace.toggle_special(\"" + n + "\")'"])
                        }
                    }
                }
            }
        }
    }
}
