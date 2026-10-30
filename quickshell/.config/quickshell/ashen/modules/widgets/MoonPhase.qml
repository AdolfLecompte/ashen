import QtQuick

import "root:/services" as Services

// The moon as it is tonight, flat: a faint disc with its lit part in a muted
// white. Worked out from the date (no network). Set `frac` to draw another phase -- the cycle row does.
Canvas {
    id: root

    property real size: 96
    width: size
    height: size

    // Hourly is plenty: the phase moves 0.14% an hour, and a canvas repaint
    // a second would cost for nothing.
    readonly property real hourStamp: Math.floor(Services.Time.now.getTime() / 3600000)
    // Days into the synodic month, from a known new moon (2000-01-06 18:14 UTC).
    readonly property real synodic: 29.530588853
    readonly property real age: {
        const d = (root.hourStamp * 3600000 - Date.UTC(2000, 0, 6, 18, 14)) / 86400000
        return ((d % root.synodic) + root.synodic) % root.synodic
    }
    property real frac: root.age / root.synodic

    readonly property real illum: (1 - Math.cos(2 * Math.PI * root.frac)) / 2
    readonly property int daysToFull: Math.round(((0.5 - root.frac + 1) % 1) * root.synodic)
    readonly property int daysToNew: Math.round((1 - root.frac) % 1 * root.synodic)
    // Eight names, each owning the eighth of the month centred on it.
    readonly property string phaseKey: ["new", "waxingCrescent", "firstQuarter", "waxingGibbous",
                                        "full", "waningGibbous", "lastQuarter", "waningCrescent"]
                                       [Math.round(root.frac * 8) % 8]

    onFracChanged: requestPaint()
    onWidthChanged: requestPaint()
    Component.onCompleted: requestPaint()
    Connections {
        target: Services.Colors
        function onSnowChanged() { root.requestPaint() }
        function onSurfaceChanged() { root.requestPaint() }
        function onGhostChanged() { root.requestPaint() }
    }

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        const cx = width / 2, cy = height / 2
        const r = width / 2 - 1
        const C = Services.Colors
        const waxing = root.frac < 0.5
        // Where the terminator crosses: k·r right of centre. Waxing runs
        // +1 → -1 (nothing → all lit), waning +1 → -1 (all → nothing).
        const k = Math.cos(2 * Math.PI * (waxing ? root.frac : root.frac - 0.5))

        // The whole disc, unlit.
        ctx.beginPath()
        ctx.arc(cx, cy, r, 0, Math.PI * 2)
        ctx.fillStyle = C.tint(C.surface, C.ghost, 0.20)
        ctx.fill()

        // The lit part: the limb on the sunny side, then back along the
        // terminator (a half-ellipse squeezed by k).
        ctx.beginPath()
        ctx.arc(cx, cy, r, -Math.PI / 2, Math.PI / 2, !waxing)
        for (let i = 0; i <= 48; i++) {
            const a = Math.PI / 2 - Math.PI * i / 48
            const x = cx + k * r * Math.cos(a)
            ctx.lineTo(x, cy + r * Math.sin(a))
        }
        ctx.closePath()
        ctx.fillStyle = C.tint(C.surface, C.snow, 0.78)
        ctx.fill()
    }
}
