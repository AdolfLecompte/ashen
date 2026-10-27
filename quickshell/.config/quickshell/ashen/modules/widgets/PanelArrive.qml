import QtQuick

import "root:/services" as Services

// Arrival for a panel with no pill to grow out of: it appears where it lives,
// already its own size, and unfolds from its centre -- fade, box out, contents
// assemble -- and runs backwards to close. Publishes numbers only, so panels
// with different layouts share one arrival. See DropCard for the pill version.
Item {
    id: root

    property bool shown: false

    // "Plain" is the other half of the Appearance setting: the panel simply
    // appears at its final size, opacity only. Nothing unfolds, nothing rises,
    // nothing is staggered -- a window, not a transformation.
    readonly property bool plain: Services.Prefs.panelStyle === "plain"

    // How folded the box starts, as a fraction of its final size.
    property real foldFrom: root.plain ? 1.0 : 0.96
    // Pixels below its resting place to come up from, 0 for none. The rise
    // runs on the same beat as the unfold, so arriving and opening are one
    // movement.
    property int rise: 0
    // Kept for callers; panels no longer rise -- one movement, the box's.
    readonly property real offY: 0

    // The drivers, in the order they run.
    property real boxAmt: 0
    property real contentAmt: 0
    property real fade: 0
    // Contents wait for the box to have most of its room; a plateless panel has no box to wait for.
    property bool waitForBox: true

    readonly property int openMs: root.plain ? 280 : Services.Sizes.panelFlowInMs
    readonly property int closeMs: root.plain ? 210 : Services.Sizes.panelFadeMs + Services.Sizes.panelFlowOutMs
    // How long the panel must stay mapped after `shown` goes false.
    readonly property int holdMs: closeMs + 60

    // Plain unrolls away from this edge: the bar's, unless the panel says otherwise.
    property string from: Services.Sizes.barPosition
    readonly property bool sideways: root.from === "left" || root.from === "right"
    readonly property real unroll: 0.06 + 0.94 * root.boxAmt

    // Size now, given the size when open. Plain keeps its cross size and
    // unrolls along one axis; the contents are laid out at the final size from
    // the first frame and the box simply reveals more of them.
    function boxW(full) {
        if (root.plain) return root.sideways ? full * root.unroll : full
        return full * (root.foldFrom + (1 - root.foldFrom) * root.boxAmt)
    }
    function boxH(full) {
        if (root.plain) return root.sideways ? full : full * root.unroll
        return full * (root.foldFrom + (1 - root.foldFrom) * root.boxAmt)
    }
    // Centred while it unfolds; pinned to its source edge while it unrolls.
    function boxX(fullX, full) {
        if (!root.plain) return fullX + (full - root.boxW(full)) / 2
        return root.from === "right" ? fullX + full - root.boxW(full) : fullX
    }
    function boxY(fullY, full) {
        if (!root.plain) return fullY + (full - root.boxH(full)) / 2
        return root.from === "bottom" ? fullY + full - root.boxH(full) : fullY
    }
    // Where open-size contents sit inside the box so they stay still on screen.
    function innerX(full) { return root.plain && root.from === "right" ? root.boxW(full) - full : 0 }
    function innerY(full) { return root.plain && root.from === "bottom" ? root.boxH(full) - full : 0 }

    // Per-piece stagger out of the single content driver: piece i starts a
    // little after piece i-1 and they all land together.
    // The contents come in together, where they belong: staggered pieces
    // rising into place read as the panel assembling itself on screen.
    function stage(i) { return root.contentAmt }
    function riseOf(i) { return 0 }

    // Explicit animations, not Behaviors: open and close are asymmetric, and
    // the other one has to be stopped rather than left to fight over the same
    // properties.
    // A layer surface is not on screen in the frame it is asked for, and how
    // long it takes depends on whether the window was just built, already up,
    // or still closing -- so an animation started at once lost a different
    // slice each time, and the panel opened differently depending on when.
    // Same wait as the panels that grow out of a pill; nothing is drawn while
    // it lasts (fade is 0).
    Timer { id: arm; interval: Services.Sizes.panelArmMs; onTriggered: openAnim.restart() }
    onShownChanged: {
        // Reopened on its way out it is already on screen: carry on from there.
        if (shown) { closeAnim.stop(); if (root.fade > 0.01) openAnim.restart(); else arm.restart() }
        else { arm.stop(); openAnim.stop(); closeAnim.restart() }
    }
    // A panel can be built with `shown` already true (LazyPanel preloads), and
    // a property born with its new value never emits a change.
    Component.onCompleted: if (shown) arm.restart()

    // Window: a quick fade and unroll. Otherwise the shell's one movement:
    // the box fades in growing slightly on the flow curve, and the contents
    // fade in once it has most of its room; closing fades them out first.
    ParallelAnimation {
        id: openAnim
        NumberAnimation {
            target: root; property: "fade"; to: 1
            duration: root.plain ? 150 : Services.Sizes.panelFlowInMs / 2
            easing.type: Services.Sizes.easeOut
        }
        NumberAnimation {
            target: root; property: "boxAmt"; to: 1
            duration: root.plain ? 260 : Services.Sizes.panelFlowInMs
            easing.type: root.plain ? Services.Sizes.easeOut : Easing.BezierSpline
            easing.bezierCurve: Services.Sizes.panelFlowCurve
        }
        SequentialAnimation {
            PauseAnimation { duration: root.plain || !root.waitForBox ? 0 : Services.Sizes.panelFlowInMs / 2 }
            NumberAnimation {
                target: root; property: "contentAmt"; to: 1
                duration: root.plain ? root.openMs : Services.Sizes.panelFlowInMs / 2
                easing.type: Easing.OutCubic
            }
        }
    }

    ParallelAnimation {
        id: closeAnim
        NumberAnimation {
            target: root; property: "contentAmt"; to: 0
            duration: root.plain ? root.closeMs : Services.Sizes.panelFadeMs
            easing.type: Services.Sizes.easeIn
        }
        SequentialAnimation {
            PauseAnimation { duration: root.plain ? 0 : Services.Sizes.panelShrinkDelayMs }
            ParallelAnimation {
                NumberAnimation {
                    target: root; property: "boxAmt"; to: 0
                    duration: root.plain ? 190 : Services.Sizes.panelFlowOutMs
                    easing.type: root.plain ? Services.Sizes.easeIn : Easing.BezierSpline
                    easing.bezierCurve: Services.Sizes.panelFlowCurve
                }
                NumberAnimation {
                    target: root; property: "fade"; to: 0
                    duration: root.plain ? root.closeMs : Services.Sizes.panelFlowOutMs
                    easing.type: Services.Sizes.easeIn
                }
            }
        }
    }
}
