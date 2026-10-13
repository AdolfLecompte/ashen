import QtQuick
import "root:/services" as Services

// The shell's mark, drawn with the same characters the terminal prints. One
// artifact in both places: install/lib/logo.sh and fastfetch/ashen.txt carry
// these exact rows, and two drawings of one logo is how the old one drifted
// into being malformed.
Item {
    id: root

    property int pixelSize: 16
    // The faces take the scheme's accent, brightening down the smoke ramp; the
    // 3D edges sit a step darker so the two read as one lit shape.
    property color face: Services.Colors.ghost
    property color edge: Services.Colors.shade

    // The rows have to TOUCH. With default leading the background shows between
    // them and the blocks stop being one shape, so the line height is pinned to
    // the cell and nothing else decides it.
    readonly property real cell: Math.round(root.pixelSize * 1.18)
    readonly property var rows: [
        " ░░░░░╗ ░░░░░░░╗░░╗  ░░╗░░░░░░░╗░░░╗   ░░╗",
        "░░╔══░░╗░░╔════╝░░║  ░░║░░╔════╝░░░░╗  ░░║",
        "▒▒▒▒▒▒▒║▒▒▒▒▒▒▒╗▒▒▒▒▒▒▒║▒▒▒▒▒╗  ▒▒╔▒▒╗ ▒▒║",
        "▓▓╔══▓▓║╚════▓▓║▓▓╔══▓▓║▓▓╔══╝  ▓▓║╚▓▓╗▓▓║",
        "██║  ██║███████║██║  ██║███████╗██║ ╚████║",
        "╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝"
    ]

    implicitWidth: col.implicitWidth
    implicitHeight: col.implicitHeight

    Column {
        id: col
        Repeater {
            model: root.rows
            // Faces and edges are two layers of one monospace row, so each
            // can carry its own colour without breaking the grid.
            Item {
                required property string modelData
                required property int index
                implicitWidth: faces.implicitWidth
                implicitHeight: root.cell
                Text {
                    id: faces
                    textFormat: Text.PlainText
                    font.pixelSize: root.pixelSize
                    font.family: "JetBrainsMono NF"
                    lineHeight: root.cell
                    lineHeightMode: Text.FixedHeight
                    text: parent.modelData.replace(/[^░▒▓█]/g, " ")
                    color: Services.Colors.tint(root.face, Services.Colors.snow, parent.index / 6)
                }
                Text {
                    textFormat: Text.PlainText
                    font.pixelSize: root.pixelSize
                    font.family: "JetBrainsMono NF"
                    lineHeight: root.cell
                    lineHeightMode: Text.FixedHeight
                    text: parent.modelData.replace(/[░▒▓█]/g, " ")
                    color: root.edge
                }
            }
        }
    }
}
