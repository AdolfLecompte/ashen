import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

import "root:/modules/bar/components"
import "root:/services" as Services

Scope {
    id: root

    Variants {
        // Not Quickshell.screens: a mirrored output is in that list and would
        // get a bar nobody can see. Services.Screens does the filtering, next
        // to the rest of the reasoning about which screen is which.
        model: Services.Screens.barScreens

        PanelWindow {
            id: bar
            property var modelData
            screen: modelData

            readonly property bool vertical: Services.Sizes.barVertical
            readonly property int pad: 12
            readonly property string edge: Services.Sizes.barPosition

            // The bar claims one screen edge; which anchors are on decides both
            // where it sits and which way it stretches.
            anchors {
                top: bar.edge !== "bottom"
                bottom: bar.edge !== "top"
                left: bar.edge !== "right"
                right: bar.edge !== "left"
            }
            // Exactly the bar: moving it is a fade now, so there is no travel
            // to leave room for.
            implicitHeight: bar.vertical ? 0 : Services.Sizes.barH
            // Wider than the bar on a side edge: see Sizes.barSpill. The strip
            // below still measures barH and stays pinned to the docked edge, so
            // nothing on the bar moves because of it.
            implicitWidth: bar.vertical ? Services.Sizes.barH + Services.Sizes.barSpill : 0

            color: "transparent"
            exclusionMode: ExclusionMode.Normal
            // The room it takes follows the bar itself: away, the windows get
            // that edge back; out, they step aside as they always did. The room
            // is only given back once the bar has finished leaving, or the
            // windows grow into a bar that is still on its way out.
            exclusiveZone: (bar.revealed || zoneHold.running) ? Services.Sizes.barDepth
                                                              : Services.Sizes.barZoneAway

            // ── Auto-hide ───────────────────────────────────────────────
            // Whether this screen's bar is the one panels are opening on.
            readonly property bool panelHere: Services.AppState.barPanelOpen
                && (!bar.screen || bar.screen.name === Services.Screens.activeName)
            // `stayOut` is the anti-flicker floor: reserving room reflows the
            // windows, and a reflow under the pointer can cost the bar its hover
            // for an instant. Without a minimum stay that reads as a shiver.
            readonly property bool revealed: !Services.Sizes.autohide
                || bar.pointerOn || hideDelay.running || stayOut.running || bar.panelHere
            // Told to the frame, which gives up its side while the bar is out.
            readonly property string screenName: bar.screen ? bar.screen.name : ""
            onRevealedChanged: {
                Services.AppState.setBarRevealed(bar.screenName, bar.revealed)
                if (bar.revealed) stayOut.restart()
                else zoneHold.restart()
            }
            Component.onCompleted: Services.AppState.setBarRevealed(bar.screenName, bar.revealed)
            Timer {
                id: hideDelay
                interval: Services.Sizes.peekHideMs
            }
            Timer {
                id: stayOut
                interval: Services.Sizes.peekStayMs
            }
            Timer {
                id: zoneHold
                interval: Services.Sizes.msEmphasis
            }

            // How far the bar walks off screen, and which way.
            readonly property int peekOff: bar.revealed ? 0 : Services.Sizes.barH
            readonly property int peekX: bar.vertical
                ? (bar.edge === "right" ? bar.peekOff : -bar.peekOff) : 0
            readonly property int peekY: bar.vertical ? 0
                : (bar.edge === "bottom" ? bar.peekOff : -bar.peekOff)

            // Spelled out rather than `item: content`: a Region bound to an item
            // follows its scene position, and anything that moves the content
            // would drag the input region off the surface. Hidden, only a thread
            // at the screen edge stays live -- the rest belongs to the windows.
            readonly property int maskThick: bar.revealed ? Services.Sizes.barH
                                                          : Services.Sizes.peekPx
            mask: Region {
                x: (bar.vertical && bar.edge === "right") ? bar.width - bar.maskThick : 0
                y: (!bar.vertical && bar.edge === "bottom") ? bar.height - bar.maskThick : 0
                width: bar.vertical ? bar.maskThick : bar.width
                height: bar.vertical ? bar.height : bar.maskThick
            }

            // A row on a horizontal bar, a column on a vertical one. Everything
            // inside a group only has to know its own order, never the edge.
            component BarGroup: Grid {
                id: grp
                // As many columns as there are things WITH A WIDTH, counted
                // rather than guessed at with a big number: a Grid given more
                // columns than items still charges one `spacing` for the empty
                // one, and that phantom hangs off the group's right end. Zero-
                // width children (a Repeater, a pill that has collapsed) do not
                // take a column, so they must not be counted either.
                readonly property int laid: {
                    let n = 0
                    for (let i = 0; i < grp.children.length; i++)
                        if (grp.children[i].visible && grp.children[i].width > 0) n++
                    return Math.max(1, n)
                }
                columns: bar.vertical ? 1 : grp.laid
                spacing: Services.Sizes.barGap
                horizontalItemAlignment: Grid.AlignHCenter
                verticalItemAlignment: Grid.AlignVCenter
            }

            // Is the pointer on the bar? Two sources, because neither can answer
            // it alone: `peekHover` is a sliver at the screen edge that never
            // moves, so it can wake a bar that has walked off screen; `barHover`
            // rides the strip itself and is an ANCESTOR of the pills, which a
            // sibling item is not -- a sibling under them never hears the hover
            // and the bar hid with the pointer sitting on it.
            readonly property bool pointerOn: peekHover.hovered || barHover.hovered
            onPointerOnChanged: pointerOn ? hideDelay.stop() : hideDelay.restart()

            Item {
                id: peek
                readonly property int thick: Services.Sizes.peekPx
                width: bar.vertical ? peek.thick : bar.width
                height: bar.vertical ? bar.height : peek.thick
                x: (bar.vertical && bar.edge === "right") ? bar.width - peek.thick : 0
                y: (!bar.vertical && bar.edge === "bottom") ? bar.height - peek.thick : 0
                HoverHandler { id: peekHover }
            }

            Item {
                id: content
                // Bar-sized strip pinned to the docked edge of a window that may
                // be deeper than the bar itself -- while it is moving, and on a
                // side bar always (Sizes.barSpill). Everything on the bar is laid
                // out against THIS, so the extra width changes nothing; a chip
                // that paints past it simply is not clipped.
                anchors.fill: bar.vertical ? undefined : parent
                anchors.top: bar.vertical ? parent.top : undefined
                anchors.bottom: bar.vertical ? parent.bottom : undefined
                anchors.left: (bar.vertical && bar.edge !== "right") ? parent.left : undefined
                anchors.right: (bar.vertical && bar.edge === "right") ? parent.right : undefined
                width: bar.vertical ? Services.Sizes.barH : parent.width

                // Moving the bar just hides it: it goes, the edge changes while
                // nothing is on screen, and it comes back. Same duration both
                // ways, so no conditional-duration Behavior reading a stale flag.
                opacity: Services.Sizes.hidden ? 0 : 1
                Behavior on opacity {
                    NumberAnimation { duration: 240; easing.type: Services.Sizes.easeInOut }
                }

                // Auto-hide is a slide, not a fade: the strip walks out through
                // the screen edge and the surface clips what is already past it.
                transform: Translate {
                    x: bar.peekX
                    y: bar.peekY
                    Behavior on x { NumberAnimation { duration: Services.Sizes.msEmphasis; easing.type: Services.Sizes.easeOut } }
                    Behavior on y { NumberAnimation { duration: Services.Sizes.msEmphasis; easing.type: Services.Sizes.easeOut } }
                }

                // On the strip itself, above every pill in the tree: a handler
                // hears the pointer even when a child MouseArea takes it too.
                HoverHandler { id: barHover }




                // Where the capsules actually live: the bar's window is deeper
                // than the strip, and everything on the bar is placed against
                // this, not against the window. The plate is exactly this
                // rectangle, so the solid style takes up the room the loose
                // capsules already took -- same air above, below and at the
                // ends -- and switching style moves nothing.
                Item {
                    id: strip
                    // Room the frame needs on the outer side, and along both
                    // ends where its side bands run.
                    readonly property int frame: Services.Sizes.barFramed ? Services.Sizes.frameW : 0
                    readonly property int along: Services.Sizes.plateAlong + strip.frame
                    readonly property int cross: Services.Sizes.plateCross

                    anchors.fill: parent
                    // The capsules sit exactly where they sit in every other
                    // style. Only the two ENDS clear the border, which really
                    // does run past them; on the long sides there is nothing to
                    // clear, because the bar is that side of the frame.
                    readonly property int outer: strip.cross
                    readonly property int inner: strip.cross

                    anchors.topMargin: bar.vertical ? strip.along
                                     : (bar.edge === "bottom" ? strip.inner : strip.outer)
                    anchors.bottomMargin: bar.vertical ? strip.along
                                        : (bar.edge === "bottom" ? strip.outer : strip.inner)
                    anchors.leftMargin: bar.vertical
                                        ? (bar.edge === "right" ? strip.inner : strip.outer)
                                        : strip.along
                    anchors.rightMargin: bar.vertical
                                         ? (bar.edge === "right" ? strip.outer : strip.inner)
                                         : strip.along
                }

                // The solid style's plate. It stands where the strip stands but
                // is NOT inside it: the cava has to draw over the plate, and a
                // child of the strip would be under it. The framed style has no
                // plate of its own -- there the frame draws the bar as its top
                // side, and a plate here would be a second one on top of it.
                Rectangle {
                    anchors.fill: strip
                    z: -2
                    visible: Services.Sizes.barPlate
                    radius: Services.Sizes.barR
                    color: Services.Colors.surfaceBar
                }

                // Full bar window, never the strip: the wave grows out of the
                // screen edge, and boxing it into the strip cut it off from the
                // edge it is supposed to be climbing out of. It sits UNDER the
                // plate (z -3 against the plate's -2), so only the tips that
                // clear the plate show. In the framed style the plate is the
                // ring, another window entirely, so the wave is drawn there.
                CavaBackground {
                    z: -3
                    visible: !Services.Sizes.barFramed
                }
                // ── Layout ──────────────────────────────────────────────
                // Which pill goes where is Prefs.barLayout's business: each id maps to
                // the thing that builds it, and nothing here knows what a clock is.
                Component { id: cLauncher;      LauncherPill {} }
                Component { id: cNotifications; NotificationPill {} }
                Component { id: cWorkspaces;    Workspaces {} }
                Component { id: cMedia;         MediaPill {} }
                Component { id: cClock;         Clock {} }
                Component { id: cUsb;           USBPill {} }
                Component { id: cRecording;     RecordingPill {} }
                Component { id: cTray;          TrayPill {} }
                Component { id: cSystem;        SystemPill {} }
                Component { id: cPower;         PowerPill {} }
                Component { id: cWindow;        WindowPill {} }

                // What a section actually shows. Almost always what the layout
                // says -- but a pill taken OFF the bar can still be the only
                // thing able to report a state that is running, so it claims a
                // slot while that lasts and gives it back, the way USB does.
                function pillsIn(section) {
                    const base = Services.Prefs.barPills(section)
                    if (section !== "left") return base
                    if (!Services.AppState.recording) return base
                    if (Services.Prefs.barSectionOf("recording") !== "") return base
                    // FIRST on the bar, always: the start of the left section,
                    // which is the top one on a side bar. A recording running is
                    // the loudest thing the shell has to say, and the corner it
                    // is read from should not depend on where the pill happened
                    // to be parked.
                    return ["recording"].concat(base)
                }

                function pillFor(id) {
                    switch (id) {
                    case "launcher":      return cLauncher
                    case "notifications": return cNotifications
                    case "workspaces":    return cWorkspaces
                    case "media":         return cMedia
                    case "clock":         return cClock
                    case "usb":           return cUsb
                    case "recording":     return cRecording
                    case "tray":          return cTray
                    case "system":        return cSystem
                    case "power":         return cPower
                    case "window":        return cWindow
                    }
                    return null
                }

                // Which pills are already standing on this bar. Any change to
                // the layout hands all three Repeaters a new array, so every
                // delegate is destroyed and rebuilt -- without this the whole
                // bar replayed its entrance because one pill moved.
                property var seen: []
                function markSeen(id) {
                    if (content.seen.indexOf(id) === -1) content.seen.push(id)
                }
                // Run after the rebuild, never during it: a pill that only moved
                // is destroyed and recreated in the same tick, and forgetting it
                // the moment it dies would make it new again on arrival.
                function forgetLater() { sweepSeen.restart() }
                Timer {
                    id: sweepSeen
                    interval: 0
                    onTriggered: content.seen = content.seen.filter(
                        id => Services.Prefs.barSectionOf(id) !== ""
                              || (id === "recording" && Services.AppState.recording))
                }

                // A pill arriving swells into place instead of blinking in; a
                // pill leaving is destroyed by the Repeater, so what sells the
                // removal is the `move` transition closing the gap behind it.
                component PillSlot: Item {
                    id: slot
                    property string pillId: ""
                    // A pill that hides itself -- an empty tray, no player, no
                    // disk -- must not leave its slot behind: the Grid spaces
                    // around anything visible, and the tray's own 16 px of
                    // padding alone opened a hole in the row. The pill says so
                    // with `wanted`, never with `visible`: reading an item's
                    // `visible` gives its EFFECTIVE state, parents included, so
                    // binding the slot to it is a loop that latches shut and
                    // empties the whole bar. A pill with no opinion is wanted.
                    visible: holder.item
                        ? (holder.item.wanted === undefined || holder.item.wanted)
                        : false
                    // A block breathes, a button does not -- see Sizes.barGap.
                    // Read off the pill's own height so a column that grows or
                    // shrinks keeps the rule without naming itself here.
                    readonly property int air: (bar.vertical && holder.item
                        && holder.item.height > Services.Sizes.barBlockAt)
                        ? Services.Sizes.barBlockAir : 0
                    implicitWidth: holder.item ? holder.item.width : 0
                    implicitHeight: holder.item ? holder.item.height + slot.air * 2 : 0
                    // A pill may name the point the bar should pivot on -- the
                    // clock centres its TIME, not its box, so the date beside
                    // it does not push the hour off the middle of the screen.
                    readonly property real pivot: (holder.item && holder.item.pivot !== undefined)
                        ? holder.item.pivot
                        : (bar.vertical ? implicitHeight / 2 : implicitWidth / 2)

                    Loader {
                        id: holder
                        y: slot.air
                        sourceComponent: content.pillFor(parent.pillId)
                    }

                    // Only a pill that was not on the bar a moment ago makes an
                    // entrance; one rebuilt around a neighbour's move does not.
                    property bool entering: true
                    scale: 0
                    opacity: 0
                    Component.onCompleted: {
                        slot.entering = content.seen.indexOf(slot.pillId) === -1
                        content.markSeen(slot.pillId)
                        scale = 1
                        opacity = 1
                    }
                    Component.onDestruction: content.forgetLater()
                    Behavior on scale { enabled: slot.entering; NumberAnimation { duration: Services.Sizes.msPronounced; easing.type: Easing.OutBack; easing.overshoot: Services.Sizes.overshoot } }
                    Behavior on opacity { enabled: slot.entering; NumberAnimation { duration: Services.Sizes.msStandard } }
                }

                // ── Left ────────────────────────────────────────────────
                BarGroup {
                    id: startGroup
                    x: bar.vertical ? strip.x + (strip.width - width) / 2 : strip.x
                    y: bar.vertical ? strip.y : strip.y + (strip.height - height) / 2
                    move: Transition { NumberAnimation { properties: "x,y"; duration: Services.Sizes.msPronounced; easing.type: Services.Sizes.easeOut } }

                    Repeater {
                        model: content.pillsIn("left")
                        delegate: PillSlot { required property var modelData; pillId: modelData }
                    }
                }

                // ── Centre ──────────────────────────────────────────────
                // Pivoted, not centred as a block: the anchor pill holds the exact middle
                // and its neighbours fall either side. Centring the group would shove the
                // clock off centre the moment anything joined it.
                BarGroup {
                    id: centreGroup
                    move: Transition { NumberAnimation { properties: "x,y"; duration: Services.Sizes.msPronounced; easing.type: Services.Sizes.easeOut } }

                    property Item anchorItem: null
                    readonly property real anchorMid: anchorItem
                        ? (bar.vertical ? anchorItem.y + anchorItem.pivot
                                        : anchorItem.x + anchorItem.pivot)
                        : (bar.vertical ? height / 2 : width / 2)

                    // The strip is inset by the same amount at both ends, so its
                    // middle is still the middle of the screen.
                    x: bar.vertical ? strip.x + (strip.width - width) / 2
                                    : strip.x + strip.width / 2 - anchorMid
                    y: bar.vertical ? strip.y + strip.height / 2 - anchorMid
                                    : strip.y + (strip.height - height) / 2

                    Repeater {
                        model: content.pillsIn("centre")
                        delegate: PillSlot {
                            required property var modelData
                            pillId: modelData
                            readonly property bool isAnchor: modelData === "clock"
                            onIsAnchorChanged: if (isAnchor) centreGroup.anchorItem = this
                            Component.onCompleted: if (isAnchor) centreGroup.anchorItem = this
                            Component.onDestruction: if (centreGroup.anchorItem === this) centreGroup.anchorItem = null
                        }
                    }
                }

                // ── Right ───────────────────────────────────────────────
                BarGroup {
                    id: endGroup
                    x: bar.vertical ? strip.x + (strip.width - width) / 2
                                    : strip.x + strip.width - width
                    y: bar.vertical ? strip.y + strip.height - height
                                    : strip.y + (strip.height - height) / 2
                    move: Transition { NumberAnimation { properties: "x,y"; duration: Services.Sizes.msPronounced; easing.type: Services.Sizes.easeOut } }

                    Repeater {
                        model: content.pillsIn("right")
                        delegate: PillSlot { required property var modelData; pillId: modelData }
                    }
                }
            }
        }
    }
}
