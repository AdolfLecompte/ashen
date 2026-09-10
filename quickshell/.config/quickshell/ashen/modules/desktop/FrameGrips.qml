import QtQuick

import "root:/modules/widgets" as Widgets
import "root:/services" as Services

// What you handle a widget WITH while arranging: the corners you pull to give
// it a size of its own, and the button that turns framing on. All of it drawn
// just OUTSIDE the frame -- a control sitting on the picture covers the very
// thing you are sizing or framing, and it reads as part of the picture.
//
// It follows its widget rather than living inside it, for the same reason
// StyleChips does: Qt delivers no mouse events to anything drawn outside its
// ancestors' bounds, so a grip parented to the frame it hangs off would be
// visible and dead.
Item {
    id: root

    required property string wid
    // The widget these belong to. Null while its loader is still empty.
    property Item target: null

    // Framing does not take the corners away: the picture slides under the
    // pointer INSIDE the frame, and these are outside it.
    readonly property bool offered: Services.Desktop.editMode
        && root.target !== null && root.target.resizable === true
    // The framing button answers to its own flag: a widget can be resizable
    // without having anything to frame.
    readonly property bool framable: Services.Desktop.editMode
        && root.target !== null && root.target.croppable === true

    // Over the widget and its shapes: an angle half under the frame it sizes
    // reads as a mistake.
    z: 6
    visible: opacity > 0
    opacity: root.offered ? 1 : 0
    Behavior on opacity { Widgets.Anim { speed: Services.Sizes.msMicro } }

    // How far off the frame the angles float.
    readonly property int gap: 6
    readonly property int span: 18

    Repeater {
        model: root.offered ? [
            { sx: -1, sy: -1 },
            { sx:  1, sy: -1 },
            { sx: -1, sy:  1 },
            { sx:  1, sy:  1 }
        ] : []

        // An angle hugging its own corner, not a dot sitting on it: a square
        // says "grab me", an L says which two edges move.
        Item {
            id: grip
            required property var modelData

            width: root.span
            height: root.span
            x: (root.target ? root.target.x : 0)
               + (grip.modelData.sx < 0 ? -root.gap - width
                                        : (root.target ? root.target.width : 0) + root.gap)
            y: (root.target ? root.target.y : 0)
               + (grip.modelData.sy < 0 ? -root.gap - height
                                        : (root.target ? root.target.height : 0) + root.gap)

            readonly property bool warm: drag_.containsMouse || drag_.pressed
            readonly property color ink: grip.warm
                ? Services.Colors.snow : Services.Colors.ghost

            // Hover grows the angle and brightens it; nothing is ever filled.
            scale: Services.Sizes.hoverScale(drag_.containsMouse, drag_.pressed)
            Behavior on scale { Widgets.Anim { speed: Services.Sizes.msMicro } }

            // The two bars point INWARDS, at the corner they move.
            Rectangle {
                width: parent.width
                height: 3
                radius: 1.5
                y: grip.modelData.sy < 0 ? 0 : parent.height - height
                color: grip.ink
                Behavior on color { Widgets.ColorAnim { speed: Services.Sizes.msMicro } }
            }
            Rectangle {
                width: 3
                height: parent.height
                radius: 1.5
                x: grip.modelData.sx < 0 ? 0 : parent.width - width
                color: grip.ink
                Behavior on color { Widgets.ColorAnim { speed: Services.Sizes.msMicro } }
            }

            MouseArea {
                id: drag_
                anchors.fill: parent
                anchors.margins: -6
                hoverEnabled: true
                cursorShape: grip.modelData.sx === grip.modelData.sy
                    ? Qt.SizeFDiagCursor : Qt.SizeBDiagCursor

                property real fromW: 0
                property real fromH: 0
                property real fromX: 0
                property real fromY: 0
                property point origin

                onPressed: mouse => {
                    fromW = root.target ? root.target.width : 0
                    fromH = root.target ? root.target.height : 0
                    const e = Services.Desktop.entry(root.wid)
                    fromX = e.x; fromY = e.y
                    origin = mapToItem(null, mouse.x, mouse.y)
                }
                // The opposite corner stays put: the record's own x/y follow
                // the side that moved, so pulling the left edge does not walk
                // the widget across the desktop.
                onPositionChanged: mouse => {
                    if (!pressed) return
                    const now = mapToItem(null, mouse.x, mouse.y)
                    const w = Math.max(Services.Desktop.minFrame,
                                       fromW + (now.x - origin.x) * grip.modelData.sx)
                    const h = Math.max(Services.Desktop.minFrame,
                                       fromH + (now.y - origin.y) * grip.modelData.sy)
                    const nx = fromX - (grip.modelData.sx < 0 ? w - fromW : 0)
                    const ny = fromY - (grip.modelData.sy < 0 ? h - fromH : 0)
                    Services.Desktop.setFrame(root.wid, Math.max(0, nx), Math.max(0, ny), w, h)
                }
            }
        }
    }

    // Framing lives here rather than among the shapes: it is not another size
    // to wear, it is a mode you go into and come out of. Above the frame and
    // hard against its right edge, clear of the corner angles.
    Widgets.IconButton {
        visible: root.framable
        opacity: root.framable ? 1 : 0
        Behavior on opacity { Widgets.Anim { speed: Services.Sizes.msMicro } }

        x: (root.target ? root.target.x + root.target.width - width : 0)
        y: (root.target ? root.target.y : 0) - root.gap - height
        size: 26
        glyph: "\ue3be"
        // Lit while it is on, so leaving the mode is the same button.
        active: Services.Desktop.cropping === root.wid
        onActivated: Services.Desktop.toggleCrop(root.wid)
    }
}
