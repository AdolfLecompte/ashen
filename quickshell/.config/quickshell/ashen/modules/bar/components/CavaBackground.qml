import Quickshell.Io
import QtQuick
import "root:/services" as Services

Item {
    id: root
    anchors.fill: parent
    z: -1

    readonly property var barValues: Services.Cava.barValues
    readonly property bool isActive: Services.Cava.isActive
    opacity: isActive ? 1.0 : 0.0
    Behavior on opacity { NumberAnimation { duration: Services.Sizes.msPanel } }

    // Bars grow inwards from the screen edge the bar is docked to, so on a side
    // bar they lie down and run horizontally instead of standing up.
    readonly property string edge: Services.Sizes.barPosition
    readonly property bool vertical: Services.Sizes.barVertical

    // Nothing is repainted while there is nothing to see: the wave is at zero
    // opacity in silence, and a transparent Canvas costs exactly as much to
    // draw as a visible one.
    onBarValuesChanged: if (root.isActive) canvas.requestPaint()
    onIsActiveChanged: canvas.requestPaint()
    onEdgeChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent

        // One bar, drawn from (x, y) with the far end rounded
        function drawBar(ctx, x, y, w, h, r) {
            r = Math.min(r, w / 2, h / 2)
            if (h <= 0) return
            if (h <= r) {
                ctx.beginPath()
                ctx.arc(x + w / 2, y + h - h / 2, Math.min(w / 2, h / 2), 0, Math.PI * 2)
                ctx.fill()
                return
            }
            ctx.beginPath()
            ctx.moveTo(x, y)
            ctx.lineTo(x + w, y)
            ctx.lineTo(x + w, y + h - r)
            ctx.arcTo(x + w, y + h, x + w - r, y + h, r)
            ctx.lineTo(x + r, y + h)
            ctx.arcTo(x, y + h, x, y + h - r, r)
            ctx.lineTo(x, y)
            ctx.closePath()
            ctx.fill()
        }

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            if (root.barValues.length === 0) return

            var n = root.barValues.length
            // Depth: how far a bar may reach into the bar's short axis.
            var along = root.vertical ? height : width
            var depth = root.vertical ? width : height
            var boost = 2.0

            // A slot is a fixed WIDTH and however many fit, fit; dividing the
            // edge by the 96 readings made the wave thinner on a shorter edge.
            // The remainder is split at both ends to keep the row centred.
            var slot = Services.Sizes.cavaSlot
            var slots = Math.max(1, Math.floor(along / slot))
            var pad = (along - slots * slot) / 2

            ctx.fillStyle = Services.Colors.ghostAlpha(0.30)

            // The canvas is rotated so every edge can reuse the same top-down
            // bar drawing: bars always leave the origin edge downwards.
            ctx.save()
            if (root.edge === "bottom") {
                ctx.translate(width, height); ctx.rotate(Math.PI)
            } else if (root.edge === "left") {
                ctx.translate(0, height); ctx.rotate(-Math.PI / 2)
            } else if (root.edge === "right") {
                ctx.translate(width, 0); ctx.rotate(Math.PI / 2)
            }

            // Each slot takes the LOUDEST reading it covers: averaging flattened
            // the peaks, picking one dropped them at random.
            for (var i = 0; i < slots; i++) {
                var from = Math.floor(i * n / slots)
                var to = Math.max(from + 1, Math.floor((i + 1) * n / slots))
                var v = 0
                for (var k = from; k < to && k < n; k++)
                    v = Math.max(v, root.barValues[k])
                v = Math.max(0, Math.min(100, v)) / 100.0
                var h = Math.min(depth, v * depth * boost)
                canvas.drawBar(ctx, pad + i * slot, 0, Math.max(1, slot - 1), h, Math.min(3, slot / 2))
            }
            ctx.restore()
        }
    }
}
