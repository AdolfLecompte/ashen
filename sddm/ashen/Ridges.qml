import QtQuick
import QtQuick.Shapes

// The login backdrop: ridges of mountains in layers, drawn rather than shipped
// as a picture, so every layer takes its colour from the palette it is given.
//
// Depth is the whole trick: six ridges from far to near, each darker than the
// one behind it, and each filled top to bottom from its own colour into the
// haze, so the valleys between them read as mist. The two nearest carry pines.
// The terrain is a sum of folded sines, not random numbers: the login looks the
// same every time it comes up.
Item {
    id: land

    property color skyTop: "#2a2630"
    property color skyMid: "#4a4150"
    property color skyHorizon: "#d8c0b8"
    property color sun: "#fff0dc"
    property color glow: "#ffe6d0"
    property color haze: "#d8c0b8"
    // Far to near.
    property var ridgeColors: ["#a8929a", "#94808a", "#806c78", "#6a5866", "#584a58", "#2c2430"]

    function mixc(a, b, t) { return Qt.tint(a, Qt.rgba(b.r, b.g, b.b, t)) }

    // 1 on a peak, 0 in a valley; peaks sharp, valleys round.
    function fold(t) { return 1 - Math.abs(Math.sin(t)) }
    function relief(x, seed) {
        const v = 0.50 * fold(x * 0.0041 + seed)
                + 0.32 * fold(x * 0.0107 + seed * 2.1)
                + 0.18 * fold(x * 0.0263 + seed * 3.7)
        return Math.pow(v, 1.45)   // pull the valleys down, keep the peaks
    }
    function ridgeY(x, seed, base, amp) { return land.height * base - land.height * amp * relief(x, seed) }

    // One ridge as an SVG path closed along the bottom, plus its pines.
    function ridge(seed, base, amp, pines, pineSize) {
        const w = land.width, h = land.height
        let d = "M -40 " + (h + 4)
        for (let x = -40; x <= w + 40; x += 14)
            d += " L " + x + " " + ridgeY(x, seed, base, amp).toFixed(1)
        d += " L " + (w + 40) + " " + (h + 4) + " Z"
        for (let i = 0; i < pines; i++) {
            const x = ((i * 0.6180339 + seed * 0.13) % 1) * w
            const y = ridgeY(x, seed, base, amp) + 4
            const s = pineSize * (0.7 + 0.6 * ((i * 0.7548776) % 1)) * h / 1080
            // Three tiers, each a triangle narrower than the one below.
            for (let t = 0; t < 3; t++) {
                const top = y - s * (1.0 + t * 0.78)
                const bot = y - s * (0.28 + t * 0.78)
                const half = s * (0.46 - t * 0.11)
                d += " M " + (x - half).toFixed(1) + " " + bot.toFixed(1)
                  + " L " + x.toFixed(1) + " " + top.toFixed(1)
                  + " L " + (x + half).toFixed(1) + " " + bot.toFixed(1) + " Z"
            }
            d += " M " + (x - s * 0.05).toFixed(1) + " " + (y + 2).toFixed(1)
              + " L " + (x - s * 0.05).toFixed(1) + " " + (y - s * 0.3).toFixed(1)
              + " L " + (x + s * 0.05).toFixed(1) + " " + (y - s * 0.3).toFixed(1)
              + " L " + (x + s * 0.05).toFixed(1) + " " + (y + 2).toFixed(1) + " Z"
        }
        return d
    }

    // Seeds, bases and heights of the six ridges, far to near.
    readonly property var specs: [
        { seed: 1.3, base: 0.50, amp: 0.24, pines: 0,  size: 0 },
        { seed: 2.9, base: 0.57, amp: 0.22, pines: 0,  size: 0 },
        { seed: 4.1, base: 0.64, amp: 0.20, pines: 0,  size: 0 },
        { seed: 5.7, base: 0.71, amp: 0.17, pines: 0,  size: 0 },
        { seed: 7.3, base: 0.79, amp: 0.13, pines: 24, size: 40 },
        { seed: 9.1, base: 0.89, amp: 0.10, pines: 10, size: 74 }
    ]

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: land.skyTop }
            GradientStop { position: 0.38; color: land.skyMid }
            GradientStop { position: 0.62; color: land.skyHorizon }
        }
    }

    // The sun, and the light it throws: one radial falloff, not stacked discs.
    Shape {
        x: land.width * 0.68 - width / 2; y: land.height * 0.30 - height / 2
        width: land.height * 1.3; height: width
        ShapePath {
            strokeWidth: -1
            fillGradient: RadialGradient {
                centerX: land.height * 0.65; centerY: land.height * 0.65
                centerRadius: land.height * 0.65
                focalX: centerX; focalY: centerY
                GradientStop { position: 0.0; color: Qt.rgba(land.glow.r, land.glow.g, land.glow.b, 0.55) }
                GradientStop { position: 0.25; color: Qt.rgba(land.glow.r, land.glow.g, land.glow.b, 0.20) }
                GradientStop { position: 1.0; color: Qt.rgba(land.glow.r, land.glow.g, land.glow.b, 0) }
            }
            startX: 0; startY: 0
            PathLine { x: land.height * 1.3; y: 0 }
            PathLine { x: land.height * 1.3; y: land.height * 1.3 }
            PathLine { x: 0; y: land.height * 1.3 }
        }
    }
    Rectangle {
        readonly property real r: land.height * 0.055
        x: land.width * 0.68 - r; y: land.height * 0.30 - r
        width: r * 2; height: r * 2; radius: r
        color: land.sun
    }

    Repeater {
        model: land.specs.length
        Shape {
            id: layer
            required property int index
            readonly property var spec: land.specs[index]
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeWidth: -1
                fillRule: ShapePath.WindingFill
                fillGradient: LinearGradient {
                    x1: 0; y1: land.height * (layer.spec.base - layer.spec.amp)
                    x2: 0; y2: land.height
                    GradientStop { position: 0.0; color: land.ridgeColors[layer.index] }
                    // The nearest ridges stay solid; the far ones sink into the haze.
                    GradientStop {
                        position: 1.0
                        color: land.mixc(land.ridgeColors[layer.index], land.haze, layer.index < 4 ? 0.62 - layer.index * 0.12 : 0)
                    }
                }
                PathSvg { path: land.ridge(layer.spec.seed, layer.spec.base, layer.spec.amp, layer.spec.pines, layer.spec.size) }
            }
        }
    }
}
