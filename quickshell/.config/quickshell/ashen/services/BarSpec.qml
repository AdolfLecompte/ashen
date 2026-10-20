import QtQuick
import Quickshell

// The bar's own settings and everything that follows from them (Sizes.first);
// the bar, and every pill on it, reads them through here.
QtObject {
    id: root

    property int index: 1
    property bool on: true
    // Where it is docked, and the style it wears (the APPLIED one, which only
    // changes behind the fade).
    property string edge: "top"
    property string style: "pills"
    property int lengthPref: 100
    property bool autohide: false
    property bool outline: false

    readonly property bool vertical: root.edge === "left" || root.edge === "right"
    // Docked: the whole edge, flush, no air around it.
    readonly property bool docked: root.style === "docked"
    readonly property bool island: root.style === "island"
    readonly property bool plate: root.style === "solid"
    // On a plate of some kind, rather than loose capsules on the wallpaper.
    readonly property bool solid: root.plate || root.island || root.docked
    readonly property int length: root.docked ? 100 : Math.max(50, Math.min(100, root.lengthPref))

    // How a capsule on this bar paints itself: see Pills.qml for the reasons.
    readonly property bool fills: !root.solid && !root.outline
    readonly property bool rings: root.outline && !root.solid
    function outlined(id) { return root.outline && !root.solid }
    readonly property color pillPlate: root.solid ? "transparent" : Colors.surfacePill

    readonly property int gap: root.solid ? 2 : (root.vertical ? 10 : 6)
    // Air between the plate and the long sides; none when docked.
    // How deep the bar is. Docked fills its band edge to edge, so it keeps
    // only a sliver of air round the pills: at the full 56 it read as a slab.
    readonly property int thick: root.docked ? Sizes.pillH + 4 : Sizes.barH
    readonly property int plateCross: root.docked ? 0 : (Sizes.barH - Sizes.pillH) / 2

    // Where this bar's window starts on screen `s` (see Sizes.barOriginX).
    function originX(s) { return (s && root.edge === "right") ? s.width - root.thick - Sizes.barSpill : 0 }
    // Docked, a horizontal bar's window is deeper by its curves (Bar.curveRoom).
    function originY(s) {
        return (s && root.edge === "bottom") ? s.height - root.thick - (root.docked ? Sizes.dockedR : 0) : 0
    }
}
