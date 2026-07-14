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
    Behavior on opacity { NumberAnimation { duration: 400 } }

    onBarValuesChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent
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
            var barW = width / n
            ctx.fillStyle = Services.Colors.ghostAlpha(0.18)
            var heightBoost = 2.0
            for (var i = 0; i < n; i++) {
                var v = Math.max(0, Math.min(100, root.barValues[i])) / 100.0
                var h = Math.min(height, v * height * heightBoost)
                canvas.drawBar(ctx, i * barW, 0, Math.max(1, barW - 1), h, Math.min(3, barW / 2))
            }
        }
    }

}
