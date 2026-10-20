import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick

import "root:/services" as Services

// Applications on an edge: the ones pinned, and the ones open. It measures
// nothing -- an icon's position is the one thing a dock has to keep still.
Scope {
    id: root

    // Which edge it ACTUALLY stands on. Settings never offers the bar's own
    // edge, but the bar can be moved onto the dock afterwards, and then two
    // surfaces claim one edge -- a fight neither wins. The dock is the one that
    // can move, so it steps across rather than stacking under the bar.
    readonly property string edge: Services.Prefs.dockEdge === Services.Sizes.barPosition
        ? root.across(Services.Sizes.barPosition)
        : Services.Prefs.dockEdge
    // Something taken off the dock by a right-click: said, or nothing happened.
    function saidOff() {
        Services.Notifications.addSystemToast(Services.Voice.pick("dock.unpinned"), "\ue6aa", false, "dock")
    }
    function across(e) {
        return e === "top" ? "bottom" : e === "bottom" ? "top"
             : e === "left" ? "right" : "left"
    }

    Variants {
        // Not Quickshell.screens: a mirrored output is in that list and would
        // get a dock nobody can see.
        model: Services.Screens.barScreens

        PanelWindow {
            id: dock
            property var modelData
            screen: modelData

            readonly property string edge: root.edge
            readonly property bool vertical: dock.edge === "left" || dock.edge === "right"
            readonly property int thick: Services.Sizes.dockIcon + Services.Sizes.dockPad * 2

            // Out of the way, or not. The zone is the whole difference: at 0 the
            // windows own the edge and the dock floats over them when asked.
            // Smart: hidden only while windows share this monitor's workspace.
            // Looked up by name: monitorFor() inside the Variants touches the list
            // its own model is built from, which loops.
            readonly property var monitor: dock.screen
                ? Hyprland.monitors.values.find(m => m.name === dock.screen.name) || null : null
            readonly property int activeWs: dock.monitor && dock.monitor.activeWorkspace
                ? dock.monitor.activeWorkspace.id : -1
            readonly property bool occupied: Hyprland.toplevels.values.some(
                t => t.workspace && t.workspace.id === dock.activeWs)
            readonly property bool peeking: Services.Prefs.dockAutohide
                && (!Services.Prefs.dockSmart || dock.occupied)
            readonly property bool revealed: Services.AppState.dockWanted
            // A minimum stay, copied from Bar.qml's `stayOut`: giving the room
            // back reflows the windows, and a reflow under the pointer can cost
            // the surface its hover for an instant, which reads as a shiver.
            Timer { id: stayOut; interval: 420 }
            // Grace after leaving: overshooting the icons by a few pixels hid it
            // at once, and only the 4 px sliver could bring it back.
            Timer { id: linger; interval: 600 }
            onRevealedChanged: revealed ? stayOut.restart() : linger.restart()

            readonly property bool out: !dock.peeking || dock.revealed || stayOut.running || linger.running
            visible: Services.Prefs.dockEnabled && dock.out

            anchors {
                top: dock.edge !== "bottom"
                bottom: dock.edge !== "top"
                left: dock.edge !== "right"
                right: dock.edge !== "left"
            }
            implicitHeight: dock.vertical ? 0 : dock.thick
            implicitWidth: dock.vertical ? dock.thick : 0

            color: "transparent"
            exclusionMode: ExclusionMode.Normal
            // Like the bar: out, it takes its room and the windows step aside;
            // hidden, the window is unmapped and the edge goes back to them.
            exclusiveZone: dock.thick
            WlrLayershell.layer: WlrLayer.Top
            // Input only on the plate: the rest of the edge-wide band ate the
            // clicks meant for the windows under it.
            mask: Region { item: plate }

            Rectangle {
                id: plate
                anchors.centerIn: parent
                width: dock.vertical ? Services.Sizes.dockIcon + Services.Sizes.dockPad
                                     : row.width + Services.Sizes.dockPad * 2
                height: dock.vertical ? row.height + Services.Sizes.dockPad * 2
                                      : Services.Sizes.dockIcon + Services.Sizes.dockPad
                radius: Services.Sizes.pillR
                // Outlined, not merely see-through: glass with a 1 px line in
                // `fillRest` is no line at all over a wallpaper, and the dock
                // read as a smudge instead of a drawn shape.
                //
                // Solid is `surfacePill`, NOT `pillPlate`: that token is
                // `barSolid ? transparent : surfacePill`, and it means "the BAR
                // is one plate, so the capsules on it do not paint a second
                // one". The dock is its own surface on another edge; borrowing
                // it left the dock with no plate at all -- bare icons floating
                // over the wallpaper -- the moment the bar went solid.
                color: Services.Prefs.dockGlass ? Services.Colors.surfaceGlass
                                                : Services.Colors.surfacePill
                border.width: Services.Prefs.dockGlass ? Services.Sizes.outlineW : 0
                border.color: Services.Colors.fillOutline

                // Keeps the dock out while the pointer is on it, not only while
                // it is on the sliver underneath.
                HoverHandler {
                    id: onDock
                    onHoveredChanged: Services.AppState.dockHovered = onDock.hovered
                }

                Grid {
                    id: row
                    anchors.centerIn: parent
                    // Exactly as many as stand in the row: spare columns are
                    // phantom spacing.
                    columns: dock.vertical ? 1 : row.entries.length
                    spacing: Services.Sizes.barGap
                    horizontalItemAlignment: Grid.AlignHCenter
                    verticalItemAlignment: Grid.AlignVCenter

                    // Pinned first, in the user's order; then whatever else has
                    // a window. A pinned application that is running shows once,
                    // with its dot lit -- never twice.
                    readonly property var items: {
                        const pins = Services.Prefs.dockPinList
                        let out = pins.slice()
                        for (const cls in Services.Windows.runningIds)
                            if (!pins.some(p => Services.Windows.sameApp(p, cls)))
                                out.push(cls)
                        return out
                    }

                    // The whole row in order: pills and shortcuts on the side of
                    // the apps each was given, shortcuts outermost, a short rule
                    // between groups.
                    readonly property var entries: {
                        const pills = Services.DockItems.pills.map(id => ({ kind: "pill", id: id }))
                        const links = Services.DockItems.links.map((l, i) => ({ kind: "link", l: l, i: i }))
                        const apps = row.items.map(id => ({ kind: "app", id: id }))
                        const before = [], after = []
                        if (Services.Prefs.dockLinksSide === "before") before.push(links)
                        if (Services.Prefs.dockPillsSide === "before") before.push(pills)
                        if (Services.Prefs.dockPillsSide !== "before") after.push(pills)
                        if (Services.Prefs.dockLinksSide !== "before") after.push(links)
                        const groups = before.concat([apps], after).filter(g => g.length > 0)
                        let out = []
                        groups.forEach((g, k) => {
                            if (k > 0) out.push({ kind: "rule" })
                            out = out.concat(g)
                        })
                        return out
                    }

                    Repeater {
                        model: row.entries
                        delegate: Loader {
                            required property var modelData
                            readonly property var e: modelData
                            sourceComponent: modelData.kind === "app" ? appTile
                                           : modelData.kind === "pill" ? pillTile
                                           : modelData.kind === "link" ? linkTile : ruleTile
                        }
                    }

                    Component {
                        id: appTile
                        DockIcon {
                            readonly property string id_: parent ? parent.e.id : ""
                            appId: id_
                            // Pinned entries are .desktop ids; the ones that
                            // joined because they are open are window classes.
                            entry: Services.Apps.byId(id_) || Services.Apps.byClass(id_)
                            running: Services.Windows.isRunning(id_)
                            windowClass: Services.Windows.classOf(id_)
                            focused: Services.Windows.isFocused(id_)
                        }
                    }
                    // A right-click takes a pill or shortcut off, the way it
                    // unpins an app.
                    Component {
                        id: pillTile
                        DockTile {
                            readonly property string id_: parent ? parent.e.id : ""
                            glyph: Services.DockItems.pillGlyph(id_)
                            text: Services.DockItems.pillText(id_, dock.vertical)
                            lit: Services.DockItems.pillLit(id_)
                            onClicked: Services.DockItems.pillClick(id_)
                            onWheeled: delta => Services.DockItems.pillWheel(id_, delta)
                            onRightClicked: {
                                Services.DockItems.togglePill(id_)
                                root.saidOff()
                            }
                        }
                    }
                    Component {
                        id: linkTile
                        DockTile {
                            readonly property var e_: parent ? parent.e : ({ l: {}, i: -1 })
                            glyph: Services.DockItems.linkGlyph(e_.l)
                            lit: Services.DockItems.linkLit(e_.l)
                            onClicked: Services.DockItems.linkClick(e_.l)
                            onRightClicked: {
                                Services.DockItems.removeLink(e_.i)
                                root.saidOff()
                            }
                        }
                    }
                    Component {
                        id: ruleTile
                        Rectangle {
                            width: dock.vertical ? Services.Sizes.dockIcon * 0.5 : 2
                            height: dock.vertical ? 2 : Services.Sizes.dockIcon * 0.5
                            radius: 1
                            color: Services.Colors.fillOutline
                        }
                    }
                }
            }
        }
    }

    // The peek. A sliver at the dock's edge that is always there and never seen:
    // rest the pointer on it and the dock comes out. Its own surface because the
    // dock itself is not on screen to be hovered when it is hidden.
    Variants {
        model: Services.Screens.barScreens

        PanelWindow {
            id: peek
            property var modelData
            screen: modelData

            readonly property string edge: root.edge
            readonly property bool vertical: peek.edge === "left" || peek.edge === "right"
            visible: Services.Prefs.dockEnabled && Services.Prefs.dockAutohide

            anchors {
                top: peek.edge !== "bottom"
                bottom: peek.edge !== "top"
                left: peek.edge !== "right"
                right: peek.edge !== "left"
            }
            implicitHeight: peek.vertical ? 0 : 4
            implicitWidth: peek.vertical ? 4 : 0
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            HoverHandler {
                id: lane
                onHoveredChanged: Services.AppState.dockPeeked = lane.hovered
            }
        }
    }
}
