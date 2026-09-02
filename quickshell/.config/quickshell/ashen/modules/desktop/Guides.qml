import QtQuick

import "root:/services" as Services

// Where a widget will land, drawn while arranging on the grid. Painted once per
// resize -- there is no clock anywhere near this.
Canvas {
    id: root

    readonly property int step: Services.Desktop.gridStep

    visible: opacity > 0
    opacity: (Services.Desktop.editMode && Services.Desktop.snap === "grid") ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: Services.Sizes.msStandard } }

    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onVisibleChanged: if (visible) requestPaint()
    Connections {
        target: Services.Colors
        function onGhostChanged() { root.requestPaint() }
    }

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        ctx.lineWidth = 1

        ctx.strokeStyle = Services.Colors.fillLine
        ctx.beginPath()
        for (let x = root.step; x < width; x += root.step) {
            ctx.moveTo(x + 0.5, 0)
            ctx.lineTo(x + 0.5, height)
        }
        for (let y = root.step; y < height; y += root.step) {
            ctx.moveTo(0, y + 0.5)
            ctx.lineTo(width, y + 0.5)
        }
        ctx.stroke()

        // The two middles, so centring something is a thing you can see.
        ctx.strokeStyle = Services.Colors.ghostAlpha(0.35)
        ctx.beginPath()
        ctx.moveTo(Math.round(width / 2) + 0.5, 0)
        ctx.lineTo(Math.round(width / 2) + 0.5, height)
        ctx.moveTo(0, Math.round(height / 2) + 0.5)
        ctx.lineTo(width, Math.round(height / 2) + 0.5)
        ctx.stroke()
    }
}
