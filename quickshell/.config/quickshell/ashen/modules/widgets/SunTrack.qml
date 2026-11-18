import QtQuick
import QtQuick.Shapes

import "root:/services" as Services

// The sun's path as a thin arch: sunrise on the left foot, sunset on the right,
// the part already travelled lit, a dot where the sun is. At night the dot rests
// on the foot it last touched and the whole arch recedes.
//
// Fed the sun's two times as minutes past midnight (Weather's numbers, never its
// printed strings, which follow the language).
Item {
    id: root

    property int riseMin: -1
    property int setMin: -1
    // Minutes past midnight now.
    property real nowMin: 0
    property real stroke: 2

    readonly property bool known: riseMin >= 0 && setMin > riseMin
    readonly property bool daytime: known && nowMin >= riseMin && nowMin < setMin
    // 0 at sunrise, 1 at sunset; held at the ends outside the day.
    readonly property real t: !known ? 0
        : Math.max(0, Math.min(1, (nowMin - riseMin) / (setMin - riseMin)))

    // The arch is the top half of an ellipse whose feet sit on the item's floor.
    readonly property real rx: (width - stroke * 2) / 2
    readonly property real ry: height - stroke * 2 - dot.height / 2
    readonly property real cx: width / 2
    readonly property real cy: height - stroke

    visible: known
    opacity: daytime ? 1 : 0.45
    Behavior on opacity { NumberAnimation { duration: Services.Sizes.motion ? 300 : 0 } }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        // The whole path, faint.
        ShapePath {
            strokeColor: Services.Colors.fillLine
            strokeWidth: root.stroke
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: root.cx; centerY: root.cy
                radiusX: root.rx; radiusY: root.ry
                startAngle: 180
                sweepAngle: 180
            }
        }
        // The part the sun has already crossed.
        ShapePath {
            strokeColor: Services.Colors.ghost
            strokeWidth: root.stroke
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: root.cx; centerY: root.cy
                radiusX: root.rx; radiusY: root.ry
                startAngle: 180
                sweepAngle: 180 * root.t
            }
        }
    }

    Rectangle {
        id: dot
        width: 9
        height: 9
        radius: 4.5
        antialiasing: true
        color: Services.Colors.snow
        x: root.cx - root.rx * Math.cos(Math.PI * root.t) - width / 2
        y: root.cy - root.ry * Math.sin(Math.PI * root.t) - height / 2
    }
}
