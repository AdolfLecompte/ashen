import QtQuick

import "root:/modules/desktop"
import "root:/modules/widgets" as Widgets
import "root:/services" as Services

// The hour on the wallpaper, in three shapes.
DesktopWidget {
    id: root
    wid: "clock"

    // ── Digital: the shell's own clock face, seconds written small ──────
    component Digital: Column {
        spacing: 2

        Widgets.ClockText {
            time: Services.Time.fmt(Services.Prefs.timeFormat)
            px: 64
            secRatio: 0.30
            color_: Services.Colors.snow
        }
        Text {
            text: Services.Time.fmt("dddd, d MMMM").toUpperCase()
            color: Services.Colors.mist
            font.pixelSize: Services.Sizes.fsInput
            font.family: "JetBrainsMono NF"
            font.letterSpacing: 2
        }
    }

    // ── Stacked: the lock screen's face, hour over minute ───────────────
    component Stack: Column {
        spacing: -14

        Text {
            text: Services.Time.fmt(Services.Prefs.clock24h ? "HH" : "hh")
            color: Services.Colors.snow
            font.pixelSize: 96
            font.bold: true
            font.family: "JetBrainsMono NF"
        }
        Text {
            text: Services.Time.fmt("mm")
            color: Services.Colors.ghost
            font.pixelSize: 96
            font.bold: true
            font.family: "JetBrainsMono NF"
        }
        Text {
            text: Services.Time.fmt("ddd d MMM").toUpperCase()
            color: Services.Colors.mist
            font.pixelSize: Services.Sizes.fsBody
            font.family: "JetBrainsMono NF"
            font.letterSpacing: 2
            topPadding: 12
        }
    }

    // ── Analog: dots for the hours, three straight hands ────────────────
    // No numbers on the dial: the rice has no surface anywhere that writes
    // twelve of anything, and the hands say enough.
    component Analog: Canvas {
        id: dial
        width: 196
        height: 196
        antialiasing: true

        // A second is the only thing here that moves on its own.
        readonly property int tick: Services.Time.seconds
        onTickChanged: requestPaint()
        Connections {
            target: Services.Colors
            function onGhostChanged() { dial.requestPaint() }
            function onSnowChanged() { dial.requestPaint() }
        }

        function hand(ctx, angle, len, w, colour) {
            const cx = width / 2
            const cy = height / 2
            ctx.strokeStyle = colour
            ctx.lineWidth = w
            ctx.lineCap = "round"
            ctx.beginPath()
            // A stub the other way, so a hand reads as pinned at the middle
            // rather than growing out of it.
            ctx.moveTo(cx - Math.sin(angle) * len * 0.18, cy + Math.cos(angle) * len * 0.18)
            ctx.lineTo(cx + Math.sin(angle) * len, cy - Math.cos(angle) * len)
            ctx.stroke()
        }

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            const cx = width / 2
            const cy = height / 2
            const r = Math.min(width, height) / 2 - 4
            const now = Services.Time.now

            // The hour marks. The quarters are the accent, the rest recede.
            for (let i = 0; i < 12; i++) {
                const a = i * Math.PI / 6
                const quarter = i % 3 === 0
                ctx.fillStyle = quarter ? Services.Colors.ghost : Services.Colors.mist
                ctx.beginPath()
                ctx.arc(cx + Math.sin(a) * (r - 10), cy - Math.cos(a) * (r - 10),
                        quarter ? 3 : 2, 0, Math.PI * 2)
                ctx.fill()
            }

            const h = now.getHours() % 12
            const m = now.getMinutes()
            const s = now.getSeconds()
            dial.hand(ctx, (h + m / 60) * Math.PI / 6, r * 0.50, 5, Services.Colors.snow)
            dial.hand(ctx, (m + s / 60) * Math.PI / 30, r * 0.74, 3.5, Services.Colors.snow)
            dial.hand(ctx, s * Math.PI / 30, r * 0.80, 1.5, Services.Colors.ghost)

            ctx.fillStyle = Services.Colors.ghost
            ctx.beginPath()
            ctx.arc(cx, cy, 4, 0, Math.PI * 2)
            ctx.fill()
        }
    }

    Component { id: digitalShape; Digital {} }
    Component { id: stackShape; Stack {} }
    Component { id: analogShape; Analog {} }

    Loader {
        sourceComponent: root.style === "analog" ? analogShape
                       : root.style === "stack" ? stackShape
                       : digitalShape
    }
}
