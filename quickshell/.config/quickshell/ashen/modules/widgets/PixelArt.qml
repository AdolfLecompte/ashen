import QtQuick
import "root:/services" as Services

// A sprite from Services.Sprites drawn as square cells. Rectangles, not a
// Canvas: a few hundred static nodes cost nothing to keep on screen.
Item {
    id: root

    property var rows: []
    property real cell: 3
    property color color: Services.Colors.ash
    readonly property int cols: root.rows.length > 0 ? root.rows[0].length : 0
    implicitWidth: root.cols * root.cell
    implicitHeight: root.rows.length * root.cell

    // Lit cells only, as [x, y] pairs.
    readonly property var lit: {
        let out = []
        for (let y = 0; y < root.rows.length; y++)
            for (let x = 0; x < root.rows[y].length; x++)
                if (root.rows[y][x] === "#") out.push([x, y])
        return out
    }

    Item {
        width: root.implicitWidth
        height: root.implicitHeight

        Repeater {
            model: root.lit
            Rectangle {
                required property var modelData
                x: modelData[0] * root.cell
                y: modelData[1] * root.cell
                width: root.cell
                height: root.cell
                color: root.color
            }
        }
    }
}
