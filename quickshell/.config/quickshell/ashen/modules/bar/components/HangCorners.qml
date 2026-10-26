import QtQuick
import QtQuick.Shapes
import "root:/services" as Services

// The hang bar's flares: at both ends of its plate, the screen edge curves out
// into it. Drawn once for a bar on top and turned for the rest. Lives in the
// bar's content box; `start`/`len` are the plate's span along the edge.
Item {
    id: root

    property string edge: "top"
    property real start: 0
    property real len: 0
    property real thick: 56
    property real r: 12
    property color fill: Services.Colors.surfaceBar
    property color stroke: "transparent"
    property real strokeW: 0

    readonly property bool vertical: root.edge === "left" || root.edge === "right"
    readonly property real span: root.len + root.r * 2
    x: root.vertical ? (root.edge === "left" ? 0 : root.thick - root.r) : root.start - root.r
    y: root.vertical ? root.start - root.r : (root.edge === "top" ? 0 : root.thick - root.r)
    width: root.vertical ? root.r : root.span
    height: root.vertical ? root.span : root.r

    // As if on top: the screen edge along y = 0, the plate between the flares.
    Shape {
        id: shape
        width: root.span
        height: root.r
        anchors.centerIn: parent
        rotation: root.edge === "bottom" ? 180 : root.edge === "left" ? -90
                : root.edge === "right" ? 90 : 0
        preferredRendererType: Shape.CurveRenderer

        // Left flare: the square before the plate minus a quarter circle centred 0, r.
        ShapePath {
            fillColor: root.fill
            strokeWidth: 0
            strokeColor: "transparent"
            startX: root.r; startY: 0
            PathLine { x: 0; y: 0 }
            PathArc { x: root.r; y: root.r; radiusX: root.r; radiusY: root.r; direction: PathArc.Clockwise }
            PathLine { x: root.r; y: 0 }
        }
        // Right flare, mirrored.
        ShapePath {
            fillColor: root.fill
            strokeWidth: 0
            strokeColor: "transparent"
            startX: shape.width - root.r; startY: 0
            PathLine { x: shape.width; y: 0 }
            PathArc { x: shape.width - root.r; y: root.r; radiusX: root.r; radiusY: root.r; direction: PathArc.Counterclockwise }
            PathLine { x: shape.width - root.r; y: 0 }
        }
        // In outline, only the two curves are drawn.
        ShapePath {
            fillColor: "transparent"
            strokeColor: root.strokeW > 0 ? root.stroke : "transparent"
            strokeWidth: root.strokeW
            startX: 0; startY: 0
            PathArc { x: root.r; y: root.r; radiusX: root.r; radiusY: root.r; direction: PathArc.Clockwise }
        }
        ShapePath {
            fillColor: "transparent"
            strokeColor: root.strokeW > 0 ? root.stroke : "transparent"
            strokeWidth: root.strokeW
            startX: shape.width; startY: 0
            PathArc { x: shape.width - root.r; y: root.r; radiusX: root.r; radiusY: root.r; direction: PathArc.Counterclockwise }
        }
    }
}
