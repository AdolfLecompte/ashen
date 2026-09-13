import QtQuick

import "root:/services" as Services

// The box the live clocks sit in, pushed out of the bar's edge. ONE box for
// both: two boxes side by side read as a cut down the middle. It grows sideways
// when the second clock starts and closes back up when one is done, because it
// measures itself by what is inside it.
Rectangle {
    id: drop

    // Which side it grows out of. The two corners facing that edge go square,
    // so it reads as a box pushed out of the bar rather than as a separate pill
    // parked near it.
    property string attachEdge: ""
    // A side bar is one pill wide, so the readings stack there instead.
    property bool stacked: false

    default property alias content: line.data

    // The width it must not fall short of: the pill it hangs from. Matching it
    // is what makes the join read as ONE shape -- a box narrower than the pill
    // is a tab under it, a box the same width is the pill continued, and only a
    // box WIDER than the pill grows square shoulders that stick out into
    // nothing and look broken.
    property real minWidth: 0
    // The same idea on the other axis, for a side bar: the box comes out of the
    // pill's flank and must be at least as tall as it, or one reading leaves a
    // stub against a capsule three times its height.
    property real minHeight: 0

    // Measured by what it holds. Nothing anchored to fill this may enter the
    // measurement, or the box and its contents each wait on the other.
    implicitWidth: Math.max(line.implicitWidth + (drop.stacked ? 16 : 22), drop.minWidth)
    implicitHeight: Math.max(line.implicitHeight + (drop.stacked ? 16 : 12), drop.minHeight)
    Behavior on implicitWidth { Anim { speed: Services.Sizes.msPanel } }
    Behavior on implicitHeight { Anim { speed: Services.Sizes.msPanel } }

    // Square only where the pill is actually behind it. A box that outgrows its
    // pill -- a countdown that reaches an hour -- would otherwise put square
    // shoulders out over nothing, which is the broken step this whole width
    // rule exists to avoid.
    readonly property bool covered: drop.stacked
        ? (drop.minHeight > 0 && drop.height <= drop.minHeight + 1)
        : (drop.minWidth > 0 && drop.width <= drop.minWidth + 1)

    radius: Services.Sizes.pillR
    topLeftRadius:     (drop.covered && (drop.attachEdge === "top" || drop.attachEdge === "left"))  ? 0 : drop.radius
    topRightRadius:    (drop.covered && (drop.attachEdge === "top" || drop.attachEdge === "right")) ? 0 : drop.radius
    bottomLeftRadius:  (drop.covered && (drop.attachEdge === "bottom" || drop.attachEdge === "left"))  ? 0 : drop.radius
    bottomRightRadius: (drop.covered && (drop.attachEdge === "bottom" || drop.attachEdge === "right")) ? 0 : drop.radius
    // The pill's own token, not surfacePill: they have to be the same surface,
    // and pillPlate goes transparent when the bar is solid.
    color: Services.Colors.pillPlate

    // No hover grow, for the same reason the clock pill has none: this box is
    // flush against the bar, and swelling it tears it off the edge it is meant
    // to be part of. Hover brightens the reading instead -- the other half of
    // the rule, and the half that carries the meaning.

    Grid {
        id: line
        anchors.centerIn: parent
        columns: drop.stacked ? 1 : 2
        spacing: 0
        horizontalItemAlignment: Grid.AlignHCenter
        verticalItemAlignment: Grid.AlignVCenter
    }
}
