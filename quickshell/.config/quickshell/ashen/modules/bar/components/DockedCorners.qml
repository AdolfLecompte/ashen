import QtQuick
import QtQuick.Shapes
import "root:/services" as Services

// The docked bar's one ornament: where its inner face meets the screen's sides,
// the screen curves into it, like a rounded display corner. Two small concave
// pieces just past the strip, drawn once for a bar on top and turned for the
// rest. Lives in the bar's content box (thick x length along the edge).
Item {
    id: root

    property string edge: "top"
    property real alongLen: 0
    property real thick: 56
    property real r: 12
    property color fill: Services.Colors.surfaceBar
    property color stroke: "transparent"
    property real strokeW: 0

    readonly property bool vertical: root.edge === "left" || root.edge === "right"
    x: root.edge === "left" ? root.thick : root.edge === "right" ? -root.r : 0
    y: root.edge === "top" ? root.thick : root.edge === "bottom" ? -root.r : 0
    width: root.vertical ? root.r : root.alongLen
    height: root.vertical ? root.alongLen : root.r

    // As if docked on top: the bar's inner face along y = 0, curves below it.
    Shape {
        id: shape
        width: root.alongLen
        height: root.r
        anchors.centerIn: parent
        rotation: root.edge === "bottom" ? 180 : root.edge === "left" ? -90
                : root.edge === "right" ? 90 : 0
        preferredRendererType: Shape.CurveRenderer

        // Left piece: the corner square minus a quarter circle centred r, r.
        ShapePath {
            fillColor: root.fill
            strokeWidth: 0
            strokeColor: "transparent"
            startX: 0; startY: 0
            PathLine { x: root.r; y: 0 }
            PathArc { x: 0; y: root.r; radiusX: root.r; radiusY: root.r; direction: PathArc.Counterclockwise }
            PathLine { x: 0; y: 0 }
        }
        // Right piece, mirrored.
        ShapePath {
            fillColor: root.fill
            strokeWidth: 0
            strokeColor: "transparent"
            startX: shape.width; startY: 0
            PathLine { x: shape.width - root.r; y: 0 }
            PathArc { x: shape.width; y: root.r; radiusX: root.r; radiusY: root.r; direction: PathArc.Clockwise }
            PathLine { x: shape.width; y: 0 }
        }
        // In outline, only the two curves are drawn.
        ShapePath {
            fillColor: "transparent"
            strokeColor: root.strokeW > 0 ? root.stroke : "transparent"
            strokeWidth: root.strokeW
            startX: root.r; startY: 0
            PathArc { x: 0; y: root.r; radiusX: root.r; radiusY: root.r; direction: PathArc.Counterclockwise }
        }
        ShapePath {
            fillColor: "transparent"
            strokeColor: root.strokeW > 0 ? root.stroke : "transparent"
            strokeWidth: root.strokeW
            startX: shape.width - root.r; startY: 0
            PathArc { x: shape.width; y: root.r; radiusX: root.r; radiusY: root.r; direction: PathArc.Clockwise }
        }
    }
}
