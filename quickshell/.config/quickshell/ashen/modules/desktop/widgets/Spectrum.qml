import QtQuick

import "root:/services" as Services

// The sound as a wall of bars mirrored about a centre line -- the shape a music
// video wears. The bar's column version reads top to bottom in 130 px; this one
// runs the full width of the widget, so it gets its own file rather than a flag.
Canvas {
    id: root

    // Painting stops dead when the desktop is not being looked at: this is the
    // only thing here that runs on a clock.
    property bool live: true
    property color color_: Services.Colors.ghost

    // A fixed slot, never "width / number of readings": the wave has to keep
    // the same weight whatever the widget measures.
    readonly property real slot: Services.Sizes.cavaSlot
    readonly property real barW: root.slot * 0.5
    readonly property int slots: Math.max(1, Math.floor(width / root.slot))

    // No fade when the room goes quiet: silence is the bars collapsing onto
    // their caps. Dimming as well said it twice and washed the colour out.
    opacity: 1

    Connections {
        target: Services.Cava
        enabled: root.live
        function onBarValuesChanged() { root.requestPaint() }
    }

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        const src = Services.Cava.barValues
        if (!root.live || !src || src.length === 0) return

        const n = root.slots
        const per = src.length / n
        const cy = height / 2
        const maxLen = height / 2 - 1

        ctx.fillStyle = root.color_
        for (let i = 0; i < n; i++) {
            // The loudest reading the slot covers, never the average: averaging
            // flattens exactly the peaks the eye is watching for.
            let v = 0
            const from = Math.floor(i * per)
            const to = Math.max(from + 1, Math.floor((i + 1) * per))
            for (let k = from; k < to; k++) v = Math.max(v, src[k] || 0)
            const half = Math.max(root.barW / 2, Math.min(1, v / 100) * maxLen)
            const x = (width - n * root.slot) / 2 + i * root.slot + (root.slot - root.barW) / 2
            ctx.beginPath()
            ctx.roundedRect(x, cy - half, root.barW, half * 2, root.barW / 2, root.barW / 2)
            ctx.fill()
        }
    }
}
