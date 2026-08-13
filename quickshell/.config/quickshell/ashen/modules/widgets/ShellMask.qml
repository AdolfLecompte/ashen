import Quickshell
import QtQuick

import "root:/services" as Services

// The input region of a full-screen panel: everything EXCEPT the strip the bar
// lives on. A layer surface takes input over its whole area by default, so a
// panel spread across the screen swallows the clicks meant for the pills it is
// hanging from -- which is why changing panels used to cost two clicks, one to
// dismiss and one to open. Cutting the bar's strip out lets that click through
// to the pill, and AppState closes whatever was open.
// NotificationToast has said the same thing since it was written; this is that
// fix, made shareable.
Region {
    id: root

    // The window's size, as numbers. NOT the window itself and not `item:`:
    // a PanelWindow is not an Item, so binding one here silently left the
    // region 0x0 and the panel took no clicks at all. And a region bound to an
    // item follows its scene position, which Bar.qml warns about.
    property real winW: 0
    property real winH: 0
    // A card that reaches INTO the bar's strip and still has to be clickable.
    // Added back after the cut, so it wins over it.
    property Item keep: null

    readonly property int barH: Services.Sizes.barH
    readonly property string edge: Services.Sizes.barPosition

    x: 0
    y: 0
    width: root.winW
    height: root.winH

    Region {
        intersection: Intersection.Subtract
        x: root.edge === "right" ? root.width - root.barH : 0
        y: root.edge === "bottom" ? root.height - root.barH : 0
        width: (root.edge === "left" || root.edge === "right") ? root.barH : root.width
        height: (root.edge === "top" || root.edge === "bottom") ? root.barH : root.height
    }

    Region {
        intersection: Intersection.Combine
        item: root.keep
    }
}
