import Quickshell
import QtQuick
import "root:/modules/bar/components"
import "root:/modules/widgets" as Widgets
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
            // In the island style the band is not there to be clicked -- only
            // the plates are, so the gaps between them belong to the wallpaper.
            // While the bar is hidden the thread at the edge is the whole
            // region in every style, which is what wakes it again.
            readonly property bool islandMask: Services.Sizes.barIsland && bar.revealed
            // A bar that does not reach the corners must not keep taking their
            // clicks. The band is still the full thickness -- only its LENGTH
            // follows the setting, which is what the setting is about.
            readonly property bool shortMask: Services.Sizes.barLength < 100 && bar.revealed
            readonly property int maskFrom: bar.shortMask
                ? (bar.vertical ? content.y + strip.y : content.x + strip.x) - Services.Sizes.plateAlong : 0
            readonly property int maskLen: bar.shortMask
                ? (bar.vertical ? strip.height : strip.width) + Services.Sizes.plateAlong * 2 : 0
            mask: Region {
                x: (bar.vertical && bar.edge === "right") ? bar.width - bar.maskThick
                   : (bar.vertical ? 0 : bar.maskFrom)
                y: (!bar.vertical && bar.edge === "bottom") ? bar.height - bar.maskThick
                   : (bar.vertical ? bar.maskFrom : 0)
                width: bar.islandMask ? 0
                       : (bar.vertical ? bar.maskThick
                          : (bar.shortMask ? bar.maskLen : bar.width))
                height: bar.islandMask ? 0
                        : (bar.vertical ? (bar.shortMask ? bar.maskLen : bar.height)
                           : bar.maskThick)

                // A plate each. Numbers, never `item:`: a region bound to an
                // item follows its SCENE position, and the strip carries the
                // auto-hide Translate -- see the note above.
                Region {
                    intersection: Intersection.Combine
                    x: bar.islandMask ? content.x + startPlate.x : 0
                    y: bar.islandMask ? content.y + startPlate.y : 0
                    width: bar.islandMask ? startPlate.width : 0
                    height: bar.islandMask ? startPlate.height : 0
                }
                Region {
                    intersection: Intersection.Combine
                    x: bar.islandMask ? content.x + centrePlate.x : 0
                    y: bar.islandMask ? content.y + centrePlate.y : 0
                    width: bar.islandMask ? centrePlate.width : 0
                    height: bar.islandMask ? centrePlate.height : 0
                }
                Region {
                    intersection: Intersection.Combine
                    x: bar.islandMask ? content.x + endPlate.x : 0
                    y: bar.islandMask ? content.y + endPlate.y : 0
                    width: bar.islandMask ? endPlate.width : 0
                    height: bar.islandMask ? endPlate.height : 0
                }
                // The sliver at the screen edge stays live so a pointer sliding
                // along the bar between two islands does not put it away.
                Region {
                    intersection: Intersection.Combine
                    x: (bar.vertical && bar.edge === "right") ? bar.width - Services.Sizes.peekPx : 0
                    y: (!bar.vertical && bar.edge === "bottom") ? bar.height - Services.Sizes.peekPx : 0
                    width: !bar.islandMask ? 0 : (bar.vertical ? Services.Sizes.peekPx : bar.width)
                    height: !bar.islandMask ? 0 : (bar.vertical ? bar.height : Services.Sizes.peekPx)
                }
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
                // Yes, this trades `fill` against the four sides it is made of,
                // which is the pattern that emptied the media capsule
                // (see MediaPill). Spelling it out as four always-answered
                // anchors -- top/bottom fixed, left/right toggling with the
                // edge -- was tried on 2026-09-09 and drew NOTHING on either
                // side bar: the window landed at the right rect and the strip
                // inside it never appeared. It works as written; leave it.
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
                    Behavior on x { Widgets.Anim { speed: Services.Sizes.msEmphasis } }
                    Behavior on y { Widgets.Anim { speed: Services.Sizes.msEmphasis } }
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
                    // What the length setting takes off each end. Half the
                    // shortfall per side, so the bar keeps its middle.
                    // Not readonly: it carries a Behavior, so the ends slide in
                    // instead of jumping when the slider moves.
                    property int shorten: Math.round(
                        (bar.vertical ? bar.height : bar.width)
                        * (100 - Services.Sizes.barLength) / 200)
                    readonly property int along: Services.Sizes.plateAlong + strip.frame + strip.shorten
                    Behavior on shorten {
                        Widgets.Anim { speed: Services.Sizes.msPronounced }
                    }
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
                    // Outline is the plate's business in this style: the whole
                    // bar becomes a frame, rather than fifteen little ones.
                    color: Services.Prefs.barOutline ? Services.Colors.surfaceGlass
                                                     : Services.Colors.surfaceBar
                    border.width: Services.Prefs.barOutline ? Services.Sizes.outlineW : 0
                    border.color: Services.Colors.fillOutline
                }

                // Full bar window, never the strip: the wave grows out of the
                // screen edge, and boxing it into the strip cut it off from the
                // edge it is supposed to be climbing out of. It sits UNDER the
                // plate (z -3 against the plate's -2), so only the tips that
                // clear the plate show. In the framed style the plate is the
                // ring, another window entirely, so the wave is drawn there.
                CavaBackground {
                    z: -3
                    // Nothing to hide behind in the island style: the wave would
                    // climb the screen edge in the gaps between the plates.
                    visible: !Services.Sizes.barFramed && !Services.Sizes.barIsland
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
                Component { id: cNetwork; NetworkPill {} }
                Component { id: cBluetooth; BluetoothPill {} }
                Component { id: cSound; SoundPill {} }
                Component { id: cBattery; BatteryPill {} }
                Component { id: cKeyboard; KeyboardPill {} }
                Component { id: cSys;         SysPill {} }
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
                    case "network":       return cNetwork
                    case "bluetooth":     return cBluetooth
                    case "volume":        return cSound
                    case "battery":       return cBattery
                    case "keyboard":      return cKeyboard
                    case "sys":           return cSys
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
                    // No padding of its own: the group's spacing is the whole
                    // rule. A block used to buy air on BOTH its sides, and two
                    // blocks in a row paid for it twice -- 4 px between two
                    // buttons, 12 next to a block, 20 between two blocks, which
                    // reads as three gaps chosen at random rather than one bar.
                    implicitWidth: holder.item ? holder.item.width : 0
                    implicitHeight: holder.item ? holder.item.height : 0
                    // A pill may name the point the bar should pivot on -- the
                    // clock centres its TIME, not its box, so the date beside
                    // it does not push the hour off the middle of the screen.
                    readonly property real pivot: (holder.item && holder.item.pivot !== undefined)
                        ? holder.item.pivot
                        : (bar.vertical ? implicitHeight / 2 : implicitWidth / 2)

                    Loader {
                        id: holder
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
                    Behavior on opacity { enabled: slot.entering; Widgets.Anim {} }
                }


                // ── Island plates ───────────────────────────────────────
                // One plate per section, each hugging its own group with the
                // same air the solid plate keeps at the ends. A section with
                // nothing in it has no plate: an empty block is not a block.
                component GroupPlate: Rectangle {
                    property Item group: null
                    readonly property int along: Services.Sizes.plateAlong
                    visible: Services.Sizes.barIsland && width > 0 && group && group.visible
                    z: -2
                    radius: Services.Sizes.barR
                    // Each island outlines as one island. Outlining the pills
                    // inside a filled block reads as a mistake; the block is
                    // the shape that is either filled or drawn.
                    color: Services.Prefs.barOutline ? Services.Colors.surfaceGlass
                                                     : Services.Colors.surfaceBar
                    border.width: Services.Prefs.barOutline ? Services.Sizes.outlineW : 0
                    border.color: Services.Colors.fillOutline
                    x: group ? (bar.vertical ? group.x : group.x - along) : 0
                    y: group ? (bar.vertical ? group.y - along : group.y) : 0
                    width: !group || group.width <= 0 ? 0
                         : (bar.vertical ? group.width : group.width + along * 2)
                    height: !group || group.height <= 0 ? 0
                          : (bar.vertical ? group.height + along * 2 : group.height)
                }
                GroupPlate { id: startPlate;  group: startGroup }
                GroupPlate { id: centrePlate; group: centreGroup }
                GroupPlate { id: endPlate;    group: endGroup }

                // ── Left ────────────────────────────────────────────────
                // In the island style each group stands on a plate that is
                // `plateAlong` WIDER than the group on both sides (GroupPlate).
                // Anchored flush to the strip, that plate hangs off the screen
                // by exactly that much -- which is what the right-hand island
                // was doing. The groups step in by the plate's own overhang.
                readonly property int islandInset: Services.Sizes.barIsland
                                                   ? Services.Sizes.plateAlong : 0

                BarGroup {
                    id: startGroup
                    x: bar.vertical ? strip.x + (strip.width - width) / 2
                                    : strip.x + content.islandInset
                    y: bar.vertical ? strip.y + content.islandInset
                                    : strip.y + (strip.height - height) / 2
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

                    // ── When the edge is not wide enough ─────────────────
                    // The three groups are placed independently -- left at the
                    // end, right at the other, centre pivoted on the clock --
                    // and nothing stopped them meeting. On a 1280-wide screen
                    // (or a 1600 one at scale 1.25, which is the same 1280) the
                    // clock was drawn straight through the system pills.
                    //
                    // The centre is the one that yields: it slides out of the
                    // way first, and stands down entirely when there is no gap
                    // left to slide into. Off-centre is a compromise; two pills
                    // sharing the same pixels is a fault.
                    readonly property real freeFrom: bar.vertical
                        ? startGroup.y + startGroup.height + Services.Sizes.barGap
                        : startGroup.x + startGroup.width + Services.Sizes.barGap
                    readonly property real freeTo: bar.vertical
                        ? endGroup.y - Services.Sizes.barGap
                        : endGroup.x - Services.Sizes.barGap
                    readonly property real span: bar.vertical ? height : width
                    readonly property bool fits: (freeTo - freeFrom) >= span

                    // Faded out and switched off, NOT `visible: false`: hiding
                    // it changes the width that `fits` is measured from, and QML
                    // reported the binding loop that makes ("Binding loop
                    // detected for property fits") -- with the right-hand group
                    // disappearing off the bar as collateral.
                    enabled: centreGroup.fits
                    opacity: centreGroup.fits ? 1 : 0
                    Behavior on opacity { Widgets.Anim {} }

                    // The strip is inset by the same amount at both ends, so its
                    // middle is still the middle of the screen -- until one of
                    // the sides reaches for it.
                    x: bar.vertical ? strip.x + (strip.width - width) / 2
                                    : Math.max(centreGroup.freeFrom,
                                        Math.min(centreGroup.freeTo - width,
                                                 strip.x + strip.width / 2 - anchorMid))
                    y: bar.vertical ? Math.max(centreGroup.freeFrom,
                                        Math.min(centreGroup.freeTo - height,
                                                 strip.y + strip.height / 2 - anchorMid))
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
                                    : strip.x + strip.width - width - content.islandInset
                    y: bar.vertical ? strip.y + strip.height - height - content.islandInset
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
