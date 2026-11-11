import QtQuick
import QtQuick.Shapes

// The login backdrop: a flat sea at dusk, drawn rather than shipped as a
// picture, so every layer takes its colour from the palette it is given.
//
// One hue in steps of lightness: the sky is lightest beside the sun and each
// layer nearer the viewer is darker. The art is laid out in a 1000x562 box with
// the horizon at y=370, scaled to the screen's height; shapes run well past the
// box sideways so any aspect ratio is filled.
Item {
    id: sea

    property color skyTop: "#2a2630"
    property color skyMid: "#4a4150"
    property color skyHorizon: "#d8c0b8"
    property color sun: "#fff0dc"
    property color glow: "#ffe6d0"
    property color hillFar: "#a8929a"
    property color hillMid: "#806c78"
    property color hillNear: "#584a58"
    property color headland: "#2c2430"
    property color waterTop: "#b49ca4"
    property color waterBottom: "#1c1620"
    property color shoreHigh: "#6a4a50"
    property color shoreMid: "#3c2c34"
    property color shoreLow: "#241a22"

    readonly property real k: height / 562
    readonly property real horizon: 370 * k
    readonly property real sunX: 262

    Rectangle {
        width: parent.width; height: sea.horizon + 1
        gradient: Gradient {
            GradientStop { position: 0; color: sea.skyTop }
            GradientStop { position: 0.5; color: sea.skyMid }
            GradientStop { position: 1; color: sea.skyHorizon }
        }
    }

    Rectangle {
        y: sea.horizon
        width: parent.width; height: parent.height - sea.horizon
        gradient: Gradient {
            GradientStop { position: 0; color: sea.waterTop }
            GradientStop { position: 1; color: sea.waterBottom }
        }
    }

    // The sun's column of light on the water, under the art so the shore covers it.
    Shape {
        x: (parent.width - 1000 * sea.k) / 2 + (sea.sunX - 130) * sea.k
        y: sea.horizon
        width: 260 * sea.k; height: 260 * sea.k
        ShapePath {
            strokeColor: "transparent"
            fillGradient: RadialGradient {
                centerX: 130 * sea.k; centerY: 0; centerRadius: 130 * sea.k
                focalX: 130 * sea.k; focalY: 0
                GradientStop { position: 0; color: Qt.rgba(sea.glow.r, sea.glow.g, sea.glow.b, 0.5) }
                GradientStop { position: 1; color: Qt.rgba(sea.glow.r, sea.glow.g, sea.glow.b, 0) }
            }
            PathSvg { path: "M 0 0 H " + 260 * sea.k + " V " + 260 * sea.k + " H 0 Z" }
        }
    }

    // The art box, centred and scaled; everything below is in its units.
    Item {
        width: 1000; height: 562
        anchors.centerIn: parent
        scale: sea.k

        component Land: Shape {
            id: land
            property color fill
            property string d
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: "transparent"
                fillColor: land.fill
                PathSvg { path: land.d }
            }
        }

        // The sky warming around the sun, and its light on the water.
        Shape {
            x: sea.sunX - 330; y: 370 - 330
            width: 660; height: 660
            ShapePath {
                strokeColor: "transparent"
                fillGradient: RadialGradient {
                    centerX: 330; centerY: 330; centerRadius: 330
                    focalX: 330; focalY: 330
                    GradientStop { position: 0; color: Qt.rgba(sea.glow.r, sea.glow.g, sea.glow.b, 0.55) }
                    GradientStop { position: 1; color: Qt.rgba(sea.glow.r, sea.glow.g, sea.glow.b, 0) }
                }
                PathSvg { path: "M 0 0 H 660 V 330 H 0 Z" }
            }
        }

        Rectangle {
            x: sea.sunX - 85; y: 262 - 85
            width: 170; height: 170; radius: 85
            color: sea.sun
        }

        Land {
            fill: sea.hillFar
            d: "M -300 370 L -300 300 C 300 296 380 286 480 276 C 560 268 620 282 700 272 C 780 262 860 266 1700 270 L 1700 370 Z"
        }
        Land {
            fill: sea.hillMid
            d: "M -300 370 L -300 330 C 420 330 520 318 620 304 C 720 290 800 306 900 298 C 960 294 1100 300 1700 306 L 1700 370 Z"
        }
        Land {
            fill: sea.hillNear
            d: "M 380 370 C 480 352 560 350 660 338 C 760 326 820 322 900 336 C 960 346 1100 350 1700 352 L 1700 370 Z"
        }
        // The dark land on the left, running down to the water.
        Land {
            fill: sea.headland
            d: "M -700 262 C -300 262 -100 268 90 292 C 230 312 320 330 440 344 C 520 353 590 362 650 370 L -700 370 Z"
        }

        // The shore, three steps darker the nearer it is.
        Land {
            fill: sea.shoreHigh
            d: "M -700 346 L 0 346 C 60 366 190 390 320 398 C 240 410 120 418 60 428 L -700 428 Z"
        }
        Land {
            fill: sea.shoreMid
            d: "M -700 398 L 0 398 C 80 412 200 422 290 430 C 200 444 100 458 40 480 L -700 488 Z"
        }
        Land {
            fill: sea.shoreLow
            d: "M -700 466 L 0 466 C 20 496 100 534 190 562 L 240 900 L -700 900 Z"
        }
    }
}
