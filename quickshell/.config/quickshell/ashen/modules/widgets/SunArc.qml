import QtQuick

import "root:/services" as Services

// The sun's path across today: a curve over a horizon, the hours already spent
// drawn dim and the ones still to come lit, with a dot where the sun is now.
// A line and not a ring -- the ring this card used to have was the complaint
// that got it deleted (see docs/DESIGN.md).
Canvas {
    id: root

    // Fractions of the day (0 = midnight, 1 = the next). -1 means the forecast
    // has not landed yet.
    property real sunUp: -1
    property real sunDown: -1
    property real nowFrac: 0

    property color color_: Services.Colors.ghost
    // Opaque, mixed into the surface, not an alpha: a translucent stroke on
    // a Canvas came out as bright as the lit half.
    property color dimColor: Services.Colors.tint(Services.Colors.surface,
                                                  Services.Colors.ghost, 0.40)
    property color dotColor: Services.Colors.snow
    property int lineWidth: 2
    // Where the ground goes. Everything above it is daylight, and the night
    // dips below with a third of the height -- enough to read as the same curve
    // continuing, not enough to need half the card.
    property real horizonAt: 0.78
    property real nightScale: 0.28
    // Drawn as levels, not as a smooth curve -- the same shape the temperature
    // chart has: a plateau per slot and a rounded joint between them. Six of
    // them and no more: the day only has to read as night, climbing, high,
    // falling, night, and every extra step was a stair nobody climbs.
    property int slots: 6
    property real cornerR: 12

    readonly property bool ready: sunUp >= 0 && sunDown > sunUp

    // Where the sun sits at a given fraction of the day: 1 at solar noon, 0 at
    // both edges of the light, negative through the night.
    function elevation(t) {
        if (!ready) return 0
        if (t >= sunUp && t <= sunDown)
            return Math.sin(Math.PI * (t - sunUp) / (sunDown - sunUp))
        // The night is the rest of the circle, stretched over what is left of
        // the day on either side of the light.
        const nightLen = 1 - (sunDown - sunUp)
        const since = t > sunDown ? t - sunDown : t + (1 - sunDown)
        return -Math.sin(Math.PI * since / nightLen) * root.nightScale
    }

    // The y of an elevation, in canvas pixels. Scaled against the day's OWN
    // highest level, not against a perfect noon: a bell that only touches the
    // ceiling at one instant of one season leaves a dead band above it all the
    // rest of the time (SunCalc draws its altitude curve the same way).
    function elevationY(e) {
        const ground = height * root.horizonAt
        const cap = Math.max(0.05, root.peak)
        return ground - (e / cap) * (ground - root.lineWidth - 2)
    }
    // The day as levels: one plateau per slot, each holding the sun's average
    // height over its own stretch of hours.
    readonly property var levels: {
        const out = []
        for (let i = 0; i < slots; i++) {
            const a = i / slots, b = (i + 1) / slots
            let sum = 0
            for (let k = 0; k < 6; k++) sum += elevation(a + (b - a) * (k + 0.5) / 6)
            out.push(sum / 6)
        }
        return out
    }
    readonly property real peak: {
        let m = 0
        for (const l of levels) if (l > m) m = l
        return m
    }
    readonly property real dotX: width * nowFrac
    // The y the drawn line has at an x: flat on a plateau, on the joint's curve
    // when x falls inside one.
    function curveY(x) {
        const ls = levels
        const slot = width / ls.length
        const i = Math.max(0, Math.min(ls.length - 1, Math.floor(x / slot)))
        for (const b of [i, i + 1]) {
            if (b <= 0 || b >= ls.length) continue
            const bx = b * slot
            const y0 = elevationY(ls[b - 1]), y1 = elevationY(ls[b])
            const r = Math.min(cornerR, slot / 2, Math.abs(y1 - y0) / 2)
            if (r <= 0 || x <= bx - r || x >= bx + r) continue
            // x(t) = bx + r*(t^3 - (1-t)^3) on this symmetric joint; it only
            // grows, so bisect it.
            let lo = 0, hi = 1
            for (let k = 0; k < 24; k++) {
                const t = (lo + hi) / 2
                if (bx + r * (t * t * t - Math.pow(1 - t, 3)) < x) lo = t
                else hi = t
            }
            const t = (lo + hi) / 2, u = 1 - t
            return y0 * (u * u * u + 3 * u * u * t) + y1 * (3 * u * t * t + t * t * t)
        }
        return elevationY(ls[i])
    }
    // The dot sits ON the line, joint included -- riding the plateau instead
    // left it hanging over the climb every morning.
    readonly property real dotY: curveY(dotX)

    onSunUpChanged: requestPaint()
    onSunDownChanged: requestPaint()
    onNowFracChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    Component.onCompleted: requestPaint()
    Connections {
        target: Services.Colors
        function onGhostChanged() { root.requestPaint() }
        function onSurfaceChanged() { root.requestPaint() }
        function onSnowChanged() { root.requestPaint() }
    }

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        // Half a curve is worse than none: the weather lands a second or two
        // after the panel opens.
        if (!ready) return

        const w = width, ground = height * root.horizonAt
        const ls = root.levels

        // A stretch of the day, walked pixel by pixel. Walked by RANGE rather
        // than traced whole and clipped -- a rect clip on this Canvas was
        // ignored, so the lit half was drawn over the spent one and the line
        // came out all one colour. Starting a band at the plateau's y instead
        // of the line's own y left a loose vertical stroke whenever the cut
        // landed mid-joint.
        function pathRange(xa, xb) {
            ctx.moveTo(xa, root.curveY(xa))
            for (let x = xa + 1; x < xb; x += 1) ctx.lineTo(x, root.curveY(x))
            ctx.lineTo(xb, root.curveY(xb))
        }
        function strokeBand(from, to, colour) {
            const xa = Math.max(0, from) * w, xb = Math.min(1, to) * w
            if (xb <= xa) return
            ctx.beginPath()
            pathRange(xa, xb)
            ctx.strokeStyle = colour
            ctx.stroke()
        }
        // The sky behind the curve, in the three bands the day actually has:
        // night under the horizon, the twilight either side of it, and full
        // day above. Suntimes draws these; here they are unlabelled -- they are
        // the background, not a reading -- and they are what turns the empty
        // top of the box into something worth looking at.
        function band(yTop, yBot, mix) {
            ctx.fillStyle = Services.Colors.tint(Services.Colors.surface,
                                                 Services.Colors.ghost, mix)
            ctx.fillRect(0, yTop, w, Math.max(0, yBot - yTop))
        }
        // Only the twilight stripe and the night under it. A band over the
        // full-day sky as well turned the whole canvas into a lit rectangle --
        // a plate, which is the one thing this card does not do.
        const twilight = (ground - root.lineWidth - 2) * 0.16
        band(ground - twilight, ground + twilight * 0.5, 0.045)
        band(ground + twilight * 0.5, height, 0.02)

        // The ground under the line, opaque and mixed into the surface -- one
        // tone whatever is behind the panel, exactly as Trend does it. The
        // spent stretch keeps a fainter ground than the light still to come.
        function fillBand(from, to, mix) {
            const xa = Math.max(0, from) * w, xb = Math.min(1, to) * w
            if (xb <= xa) return
            ctx.beginPath()
            pathRange(xa, xb)
            ctx.lineTo(xb, height)
            ctx.lineTo(xa, height)
            ctx.closePath()
            ctx.fillStyle = Services.Colors.tint(Services.Colors.surface, root.color_, mix)
            ctx.fill()
        }

        // One tone for the whole day: two mixes put a hard vertical seam under
        // the number at whatever o'clock it happened to be. Which light is
        // spent and which is left is the line's job.
        fillBand(0, 1, 0.18)

        // The horizon, as thin as every other rule on this card. Drawn UNDER
        // the curve: on top it clipped a dim notch out of the line at the two
        // crossings, and a background rule has no business cutting the reading.
        ctx.beginPath()
        ctx.moveTo(0, ground)
        ctx.lineTo(w, ground)
        ctx.lineWidth = 1
        ctx.strokeStyle = Services.Colors.tint(Services.Colors.surface,
                                               Services.Colors.ghost, 0.22)
        ctx.stroke()

        ctx.lineWidth = root.lineWidth
        ctx.lineJoin = "round"
        ctx.lineCap = "round"

        // Spent, then still to come.
        strokeBand(0, root.nowFrac, root.dimColor)
        strokeBand(root.nowFrac, 1, root.color_)

    }

    // Now. Drawn as an item rather than into the canvas so it can move without
    // a repaint of the whole path.
    Rectangle {
        width: 7
        height: 7
        radius: 3.5
        visible: root.ready
        color: root.dotColor
        x: Math.max(0, Math.min(root.width - width, root.dotX - width / 2))
        y: root.dotY - height / 2
    }
}
