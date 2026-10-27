import Quickshell.Widgets
import QtQuick

import "root:/services" as Services

// Press feedback: a circle born where the press landed, swelling to cover the
// control and fading. Clipped to the control's rounded shape. Never on hover.
ClippingRectangle {
    id: root

    property color tint: Services.Colors.snow

    function burst(px, py) {
        if (!Services.Sizes.motion) return
        dot.cx = px
        dot.cy = py
        grow.restart()
    }

    color: "transparent"

    Rectangle {
        id: dot
        property real cx: 0
        property real cy: 0
        property real amt: 0
        // Far enough to reach the farthest corner from the press.
        readonly property real reach: Math.hypot(Math.max(cx, root.width - cx), Math.max(cy, root.height - cy))
        width: reach * 2 * amt
        height: width
        radius: width / 2
        x: cx - width / 2
        y: cy - height / 2
        color: root.tint
        opacity: 0
    }

    ParallelAnimation {
        id: grow
        NumberAnimation { target: dot; property: "amt"; from: 0; to: 1; duration: 400; easing.type: Easing.OutCubic }
        NumberAnimation { target: dot; property: "opacity"; from: 0.22; to: 0; duration: 400; easing.type: Easing.InQuad }
    }
}
