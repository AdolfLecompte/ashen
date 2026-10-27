import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Shapes

import "root:/services" as Services

// Rounds the screen's own corners: four small black pieces, one per corner, on
// the overlay layer, taking no input. Four tiny surfaces, never a full-screen one.
Scope {
    id: root

    required property var modelData
    readonly property int r: 18

    component Corner: PanelWindow {
        id: corner
        property bool atTop: true
        property bool atLeft: true

        screen: root.modelData
        anchors { top: corner.atTop; bottom: !corner.atTop; left: corner.atLeft; right: !corner.atLeft }
        implicitWidth: root.r
        implicitHeight: root.r
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "ashen-corners"
        mask: Region {}

        // Drawn for the top-left corner and turned for the rest.
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            rotation: corner.atTop ? (corner.atLeft ? 0 : 90) : (corner.atLeft ? 270 : 180)
            ShapePath {
                fillColor: "black"
                strokeWidth: 0
                strokeColor: "transparent"
                startX: 0; startY: 0
                PathLine { x: root.r; y: 0 }
                PathArc { x: 0; y: root.r; radiusX: root.r; radiusY: root.r; direction: PathArc.Counterclockwise }
                PathLine { x: 0; y: 0 }
            }
        }
    }

    Corner { atTop: true;  atLeft: true }
    Corner { atTop: true;  atLeft: false }
    Corner { atTop: false; atLeft: true }
    Corner { atTop: false; atLeft: false }
}
