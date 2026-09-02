import Quickshell
import Quickshell.Wayland
import QtQuick

import "root:/services" as Services
import "root:/modules/widgets" as Widgets

// The stopwatch and the countdown hang UNDER the clock instead of riding inside
// its pill. Inside, they made the widest pill on the bar wider still -- and the
// clock is what the centre group pivots on, so the whole strip shifted every
// time a reading grew a digit. Out here they cost the bar nothing.
//
// One window for both, on the focused screen: `PillCenter` only lets the bar of
// the focused monitor publish the clock's position, so that is the only screen
// with anything true to say about where "under the clock" is.
PanelWindow {
    id: root
    anchors { top: true; left: true; right: true; bottom: true }
    screen: Services.Screens.active
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    // Alive, not merely running: a stopwatch paused halfway is still something
    // you have open and will come back to.
    readonly property bool swOn: !Services.Stopwatch.idle
    readonly property bool tmOn: Services.Countdown.active
    // Not while the clock panel is up: it shows both clocks full size, and the
    // box was left poking out from behind it saying the same thing twice.
    readonly property bool wanted: Services.AppState.timerBoxOut
    // The window has to outlive the last drop or the shrink is never drawn.
    visible: root.wanted || leaving.running
    onWantedChanged: if (!root.wanted) leaving.restart()
    Timer { id: leaving; interval: Services.Sizes.msPanel + 80 }

    readonly property string edge: Services.Sizes.barPosition
    readonly property bool vertical: Services.Sizes.barVertical

    // The line the drops hang from is the PILL's inner edge, not the bar
    // window's: the window is `plateCross` taller than the capsules on it, so a
    // neck starting at the window edge began six pixels clear of the pill and
    // read as a floating stub.
    readonly property real barEdge: {
        const cross = Services.Sizes.plateCross
        if (root.edge === "bottom") return root.height - Services.Sizes.barH + cross
        if (root.edge === "right") return root.width - Services.Sizes.barH + cross
        return Services.Sizes.barH - cross
    }
    readonly property bool fromBelow: root.edge === "bottom"
    // The side of the drop that meets the bar: the opposite of the bar's edge.
    readonly property string attachEdge: {
        if (root.edge === "bottom") return "bottom"
        if (root.edge === "left") return "left"
        if (root.edge === "right") return "right"
        return "top"
    }

    // ── The box ──────────────────────────────────────────────────────────
    // It arrives by being LET OUT of the bar, never by widening into place: the
    // slot clips, and it opens across the bar's own edge, so the box is uncovered
    // starting at the side that touches the pill. Growing sideways is what the
    // box does LATER, when the second clock starts -- two different motions, and
    // reading them as one made the arrival look like it slid in from the left.
    //
    // Perpendicular to the bar whichever edge it is on, which is the whole
    // reason this is a fraction and not a hand-written slide per edge.
    property real reveal: root.wanted ? 1 : 0
    Behavior on reveal { NumberAnimation { duration: Services.Sizes.msPanel; easing.type: Services.Sizes.easeOut } }

    Item {
        id: block
        clip: true
        width: root.vertical ? box.width * root.reveal : box.width
        height: root.vertical ? box.height : box.height * root.reveal

        // Pinned to the bar's edge: the side that grows is the far one, so the
        // box is always hinged on the pill rather than drifting off it.
        x: root.vertical
            ? (root.edge === "left" ? root.barEdge : root.barEdge - block.width)
            : Services.AppState.clockPillCenterX - block.width / 2
        // Hung from the pill's TOP edge, not centred on it: the two share that
        // line, so a second reading grows DOWNWARD past the pill instead of
        // pushing the whole box off centre and breaking the join.
        y: root.vertical
            ? Services.AppState.clockPillCenterY - Services.AppState.clockPillH / 2
            : (root.fromBelow ? root.barEdge - block.height : root.barEdge)

        // Sliding to the new centre as the box grows, never jumping.
        Behavior on x { NumberAnimation { duration: Services.Sizes.msPanel; easing.type: Services.Sizes.easeOut } }
        Behavior on y { NumberAnimation { duration: Services.Sizes.msPanel; easing.type: Services.Sizes.easeOut } }

        Widgets.TimerDrop {
            id: box
            // Held against the edge the slot opens FROM, so what the clip eats
            // is always the far end.
            x: root.edge === "right" ? block.width - box.width : 0
            y: root.fromBelow ? block.height - box.height : 0
            attachEdge: root.attachEdge
            stacked: root.vertical
            // Flush with the capsule it comes out of, on the axis that shows:
            // under a top bar that is the width, out of a side bar the height.
            minWidth: root.vertical ? 0 : Services.AppState.clockPillW
            minHeight: root.vertical ? Services.AppState.clockPillH : 0

            Widgets.TimerReadout {
                on: root.swOn && root.wanted
                stacked: root.vertical
                glyph: "\ue01b"
                value: Services.Stopwatch.displayShort
                live: Services.Stopwatch.running
                playing: Services.Stopwatch.running
                canReset: !Services.Stopwatch.idle
                tab: 1
                onToggled: Services.Stopwatch.toggle()
                onCleared: Services.Stopwatch.reset()
            }
            Widgets.TimerReadout {
                on: root.tmOn && root.wanted
                stacked: root.vertical
                // The hairline only exists between two things.
                showRule: root.swOn && root.tmOn
                glyph: "\ue425"
                value: Services.Countdown.display
                live: Services.Countdown.running
                playing: Services.Countdown.running
                canReset: Services.Countdown.active
                tab: 2
                onToggled: Services.Countdown.toggle()
                onCleared: Services.Countdown.reset()
            }
        }
    }

    // ── What the pointer may reach ───────────────────────────────────────
    // A layer surface takes input over its whole area by default, and this one
    // covers the screen: without cutting it down to the drops it would swallow
    // every click meant for the desktop. Same lesson as ShellMask.
    mask: Region {
        Region {
            intersection: Intersection.Combine
            item: block
        }
    }
}
