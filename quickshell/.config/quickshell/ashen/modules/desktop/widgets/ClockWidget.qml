import QtQuick

import "root:/modules/desktop"
import "root:/modules/widgets" as Widgets
import "root:/services" as Services

// The hour on the wallpaper, in three shapes.
DesktopWidget {
    id: root
    wid: "clock"

    // 12 or 24 hours, with or without seconds -- its own, or the bar's.
    readonly property bool h24: root.skin === "24" || root.skin === "24s"
                                || ((root.skin === "bar" || root.skin === "") && Services.Prefs.clock24h)
    readonly property bool secs: root.skin === "12s" || root.skin === "24s"
                                 || ((root.skin === "bar" || root.skin === "") && Services.Prefs.clockSeconds)
    readonly property string hourFmt: root.h24 ? "HH" : "hh"
    readonly property string timeFmt: root.hourFmt + ":mm" + (root.secs ? ":ss" : "") + (root.h24 ? "" : " AP")

    // ── Digital: the shell's own clock face, seconds written small ──────
    component Digital: Column {
        spacing: 2

        Widgets.ClockText {
            time: Services.Time.fmt(root.timeFmt)
            px: 64
            secRatio: 0.30
            color_: Services.Colors.snow
        }
        Text {
            textFormat: Text.PlainText
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
            textFormat: Text.PlainText
            text: Services.Time.fmt(root.hourFmt)
            color: Services.Colors.snow
            font.pixelSize: 96
            font.bold: true
            font.family: "JetBrainsMono NF"
        }
        Text {
            textFormat: Text.PlainText
            text: Services.Time.fmt("mm")
            color: Services.Colors.ghost
            font.pixelSize: 96
            font.bold: true
            font.family: "JetBrainsMono NF"
        }
        Text {
            textFormat: Text.PlainText
            text: Services.Time.fmt("ddd d MMM").toUpperCase()
            color: Services.Colors.mist
            font.pixelSize: Services.Sizes.fsBody
            font.family: "JetBrainsMono NF"
            font.letterSpacing: 2
            topPadding: 12
        }
    }

    // A hand pinned at (px, py): `len` out, a stub of 0.18 of that the other
    // way so it reads as pinned rather than growing out of the pivot, and half
    // its width past each end, which is what a round cap drew. Top level on
    // purpose: an inline component cannot be declared inside another one.
    component Hand: Rectangle {
        property real px: 0
        property real py: 0
        property real len: 0
        property real deg: 0
        height: len * 1.18 + width
        radius: width / 2
        antialiasing: true
        x: px - width / 2
        y: py - len - width / 2
        transform: Rotation {
            origin.x: width / 2
            origin.y: len + width / 2
            angle: deg
        }
    }

    // ── Analog: dots for the hours, three straight hands ────────────────
    // No numbers on the dial: the rice has no surface anywhere that writes
    // twelve of anything, and the hands say enough.
    //
    // The hands are rotated rectangles, not strokes on the canvas. The whole
    // dial used to be one Canvas repainted every second -- twelve dots that
    // never move rasterised on the CPU and uploaded again, once a second, for
    // good. On the desktop that tick was most of the shell's idle cost. Now the
    // canvas holds only the dots and repaints when the colours change; a second
    // going by is three rotations the GPU does for nothing.
    component Analog: Item {
        id: dial
        width: 196
        height: 196

        readonly property real cx: width / 2
        readonly property real cy: height / 2
        readonly property real r: Math.min(width, height) / 2 - 4
        readonly property int h: Services.Time.hours % 12
        readonly property int m: Services.Time.minutes
        readonly property int s: Services.Time.seconds

        Canvas {
            id: marks
            anchors.fill: parent
            antialiasing: true
            Connections {
                target: Services.Colors
                function onGhostChanged() { marks.requestPaint() }
                function onMistChanged() { marks.requestPaint() }
            }
            onPaint: {
                const ctx = getContext("2d")
                ctx.reset()
                // The hour marks. The quarters are the accent, the rest recede.
                for (let i = 0; i < 12; i++) {
                    const a = i * Math.PI / 6
                    const quarter = i % 3 === 0
                    ctx.fillStyle = quarter ? Services.Colors.ghost : Services.Colors.mist
                    ctx.beginPath()
                    ctx.arc(dial.cx + Math.sin(a) * (dial.r - 10), dial.cy - Math.cos(a) * (dial.r - 10),
                            quarter ? 3 : 2, 0, Math.PI * 2)
                    ctx.fill()
                }
            }
        }

        Hand { px: dial.cx; py: dial.cy; width: 5;   len: dial.r * 0.50
               color: Services.Colors.snow; deg: (dial.h + dial.m / 60) * 30 }
        Hand { px: dial.cx; py: dial.cy; width: 3.5; len: dial.r * 0.74
               color: Services.Colors.snow; deg: (dial.m + dial.s / 60) * 6 }
        Hand { px: dial.cx; py: dial.cy; width: 1.5; len: dial.r * 0.80
               color: Services.Colors.ghost; deg: dial.s * 6 }

        Rectangle {
            width: 8; height: 8; radius: 4
            x: dial.cx - 4; y: dial.cy - 4
            color: Services.Colors.ghost
            antialiasing: true
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
