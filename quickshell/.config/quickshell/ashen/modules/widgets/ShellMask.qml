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
    // The edge the utility pill is standing on, for a panel that came out of
    // it: its chips need the same right of way the bar's capsules have.
    property string utilEdge: ""

    readonly property int barH: Services.Sizes.barH
    readonly property string edge: Services.Sizes.barPosition
    readonly property bool utilVertical: root.utilEdge === "left" || root.utilEdge === "right"

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

    // The utility pill itself, never the whole 62 px lane: a bigger cut would
    // leave dead air where no chip ever appears.
    Region {
        intersection: Intersection.Subtract
        x: root.utilEdge === "" ? 0
           : root.utilVertical ? (root.utilEdge === "right" ? root.width - Services.Sizes.utilPillThick : 0)
                               : (root.width - Services.Sizes.utilPillLen) / 2
        y: root.utilEdge === "" ? 0
           : root.utilVertical ? (root.height - Services.Sizes.utilPillLen) / 2
                               : (root.utilEdge === "bottom" ? root.height - Services.Sizes.utilPillThick : 0)
        width: root.utilEdge === "" ? 0
               : (root.utilVertical ? Services.Sizes.utilPillThick : Services.Sizes.utilPillLen)
        height: root.utilEdge === "" ? 0
                : (root.utilVertical ? Services.Sizes.utilPillLen : Services.Sizes.utilPillThick)
    }

    Region {
        intersection: Intersection.Combine
        item: root.keep
    }
}
