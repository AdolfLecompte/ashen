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

    // The bar flips the whole strip: chips stack instead of running across.
    readonly property bool vertical: Services.Sizes.barVertical
    // How many chips the row shows before it pages. Clamped here rather than at
    // the setting, so a hand-edited prefs file cannot produce an empty row.
    readonly property int shown: Math.max(2, Math.min(10, Services.Prefs.workspaceCount))
    // icons / numbers / dots. In dots the chips carry no reading at all: the one
    // you are standing on is a bar, the rest are dots, and the row says WHERE
    // you are rather than what is running.
    readonly property string wsStyle: Services.Prefs.workspaceStyle
    readonly property bool dots: root.wsStyle === "dots"
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
    readonly property bool outlined: Services.Pills.isOutlined("workspaces")
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

    function specialIcon(name) {
        if (name === "music")   return ""
        if (name === "discord") return ""
        if (name === "notes")   return ""
        if (name === "fav")     return ""
        return ""
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
                Services.AppState.setWsPreview(ph.wsId, ph.label,
                    Services.Sizes.barOriginX(s) + g.x - (s ? s.x : 0),
                    Services.Sizes.barOriginY(s) + g.y - (s ? s.y : 0),
                    ph.width, ph.height)
            }
        }
    }

    // Workspaces normales
    Rectangle {
        id: pill
        radius: root.pillR
        color: root.outlined ? Services.Colors.surfaceGlass
                                          : Services.Colors.pillPlate
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
            width: root.innerH; height: root.innerH
            radius: root.innerR
            // Only in OUTLINE is the indicator a ring: a filled block inside a
            // drawn edge is what undoes the outline. On a solid, island or
            // framed bar the plate is the surface these numbers live on, so the
            // indicator fills there exactly as it always did -- ringing it drew
            // an outline the bar had not asked for. See Pills.rings.
            color: Services.Pills.rings ? "transparent" : Services.Colors.ghost
            border.width: Services.Pills.rings ? Services.Sizes.outlineW : 0
            border.color: Services.Colors.ghost
            gradient: (Services.Prefs.useGradients && !Services.Pills.rings)
                      ? Services.Colors.accentGradient : null
            // Part of the numbers, so it leaves and comes back with them.
            // In dots the chips carry their own fill, so the indicator that
            // would slide under them has nothing left to say.
            opacity: root.dots ? 0 : (pill.showSpecial ? 0 : pill.contentOpacity)
            readonly property real slot: {
                let base = Math.floor((root.lastNormalId - 1) / root.shown) * root.shown
                let idx = root.lastNormalId - base - 1
                return root.pad + idx * (root.innerH + 4)
            }
            readonly property real centred: (root.pillH - root.innerH) / 2
            x: root.vertical ? centred : slot
            y: root.vertical ? slot : centred
            Behavior on x { SmoothedAnimation { duration: Services.Sizes.msPronounced } }
            Behavior on y { SmoothedAnimation { duration: Services.Sizes.msPronounced } }
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
                model: root.shown
                delegate: Item {
                    required property int index
                    property int wsId: {
                        let base = Math.floor((root.lastNormalId - 1) / root.shown) * root.shown
                        return base + index + 1
                    }
                    property bool isActive: root.lastNormalId === wsId
                    property bool hasWindows: Hyprland.workspaces.values.find(w => w.id === wsId) !== undefined
                    // Hyprland lists the workspace you are standing on even when
                    // it is empty, so `hasWindows` says yes for the one you are
                    // on and the preview opened onto nothing. Count real windows.
                    readonly property int winCount:
                        Hyprland.toplevels.values.filter(t => t.workspace && t.workspace.id === wsId).length
                    // A dot stretches ALONG the bar. On a side bar that is its
                    // height: stretching the width made the one you stand on a
                    // bar lying across a column only one pill wide.
                    readonly property int along: root.dots ? (isActive ? root.dotOnW : root.dotW) : root.innerH
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
                        visible: !root.dots
                        // The plate says whether the workspace has anything on it, nothing else.
                        // Active chips are carried by the sliding indicator, so they stay bare.
                        color: Services.Colors.fillRest
                        opacity: parent.isActive ? 0 : parent.hasWindows ? 1 : 0
                        Behavior on opacity { Widgets.Anim {} }
                    }

                    // The dot itself. Fully round, so growing into the active
                    // bar is the same shape stretched rather than a new one.
                    Rectangle {
                        visible: root.dots
                        anchors.centerIn: parent
                        // A CIRCLE when it is only a dot, a capsule when it is
                        // the one you are standing on. Taking the cell's whole
                        // width made every dot an oval, which reads as a short
                        // bar rather than as a point.
                        width: (parent.isActive && !root.vertical) ? parent.width : root.dotH
                        height: (parent.isActive && root.vertical) ? parent.height : root.dotH
                        radius: Math.min(width, height) / 2
                        // Outlined, a dot is a RING: a row of filled circles on
                        // a drawn plate is the same filled-blob-inside-an-
                        // outline the rest of the bar just stopped doing. The
                        // one you are standing on stays solid -- it is the
                        // thing the row exists to point at.
                        border.width: (Services.Pills.rings && !parent.isActive)
                                      ? Services.Sizes.outlineW : 0
                        border.color: Services.Colors.fillOutline
                        // On a glass plate `ash` and `fillRest` are two shades
                        // of nothing: the row of dots disappeared and only the
                        // active one showed. Outlined, they read at the same
                        // strength as the border around them.
                        color: parent.isActive ? Services.Colors.ghost
                             : parent.warm ? Services.Colors.snow
                             : Services.Pills.rings
                                 // A ring, so the inside is the wallpaper. What
                                 // says "this one has windows" is the ring's
                                 // own strength, not a fill.
                                 ? "transparent"
                             : parent.hasWindows ? Services.Colors.ash
                                                 : Services.Colors.fillRest
                        Behavior on color { Widgets.ColorAnim {} }
                    }

                    // A workspace with something on it shows what that is; an
                    // empty one keeps its number, which is the only thing left
                    // to identify it by.
                    readonly property string appIcon: root.wsStyle === "icons"
                        ? Services.Windows.workspaceIcon(wsId) : ""

                    Text {
                        visible: !root.dots
                        anchors.centerIn: parent
                        text: parent.appIcon !== "" ? parent.appIcon : wsId
                        color: parent.isActive
                                 ? (!Services.Pills.rings ? Services.Colors.accentText
                                                         : Services.Colors.ghost)
                             : parent.warm ? Services.Colors.snow
                             : (!Services.Pills.rings ? Services.Colors.ash : Services.Colors.mist)
                        font.pixelSize: parent.appIcon !== "" ? 15 : 13
                        font.family: parent.appIcon !== "" ? "Material Symbols Rounded" : "JetBrainsMono NF"
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

                    PreviewHover {
                        id: chipHover
                        wsId: parent.wsId
                        label: parent.appIcon !== "" ? parent.appIcon : String(parent.wsId)
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
                    readonly property string shortName: modelData.name.replace("special:", "")
                    readonly property bool isShown: modelData.name === root.shownSpecial
                    width: root.innerH; height: root.innerH
                    readonly property bool warm: spHover && spHover.containsMouse
                    scale: Services.Sizes.hoverScale(warm, spHover && spHover.pressed)
                    Behavior on scale { Widgets.Anim { speed: Services.Sizes.pillHoverMs } }

                    Rectangle {
                        anchors.fill: parent
                        radius: root.innerR
                        color: Services.Pills.rings ? "transparent"
                             : parent.isShown ? Services.Colors.ghost : Services.Colors.fillRest
                        border.width: (Services.Pills.rings && parent.isShown)
                                      ? Services.Sizes.outlineW : 0
                        border.color: Services.Colors.ghost
                        gradient: (Services.Prefs.useGradients && !Services.Pills.rings && parent.isShown)
                                  ? Services.Colors.accentGradient : null
                        Behavior on color { Widgets.ColorAnim {} }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: root.specialIcon(parent.shortName)
                        color: parent.isShown
                                 ? (!Services.Pills.rings ? Services.Colors.accentText
                                                         : Services.Colors.ghost)
                             : parent.warm ? Services.Colors.snow
                             : (!Services.Pills.rings ? Services.Colors.ash : Services.Colors.mist)
                        font.pixelSize: 18
                        font.family: "Material Symbols Rounded"
                        z: 1
                        // Handed over to the preview's caption while it is open
                        opacity: Services.AppState.wsPreviewMorphing
                            && Services.AppState.wsPreviewId === parent.modelData.id ? 0 : 1
                        Behavior on opacity { Widgets.Anim { speed: Services.Sizes.msMicro } }
                        Behavior on color { Widgets.ColorAnim {} }
                    }

                    PreviewHover {
                        id: spHover
                        wsId: parent.modelData.id
                        label: root.specialIcon(parent.shortName)
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
