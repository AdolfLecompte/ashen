import Quickshell
import Quickshell.Wayland
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
            readonly property bool peeking: Services.Prefs.dockAutohide
            readonly property bool revealed: Services.AppState.dockWanted
            // A minimum stay, copied from Bar.qml's `stayOut`: giving the room
            // back reflows the windows, and a reflow under the pointer can cost
            // the surface its hover for an instant, which reads as a shiver.
            Timer { id: stayOut; interval: 420 }
            onRevealedChanged: if (revealed) stayOut.restart()

            readonly property bool out: !dock.peeking || dock.revealed || stayOut.running
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
            exclusiveZone: dock.peeking ? 0 : dock.thick
            WlrLayershell.layer: dock.peeking ? WlrLayer.Overlay : WlrLayer.Top

            Rectangle {
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
                    columns: dock.vertical ? 1 : items.length
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

                    Repeater {
                        model: row.items
                        delegate: DockIcon {
                            required property var modelData
                            appId: modelData
                            // Pinned entries are .desktop ids; the ones that
                            // joined because they are open are window classes.
                            entry: Services.Apps.byId(modelData)
                                   || Services.Apps.byClass(modelData)
                            running: Services.Windows.isRunning(modelData)
                            windowClass: Services.Windows.classOf(modelData)
                            focused: Services.Windows.isFocused(modelData)
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
