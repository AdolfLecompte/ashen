import QtQuick
import "root:/services" as Services

// The shell's mark, drawn with the same characters the terminal prints. One
// artifact in both places: install/lib/logo.sh and fastfetch/ashen.txt carry
// these exact rows, and two drawings of one logo is how the old one drifted
// into being malformed.
Item {
    id: root

    property int pixelSize: 16
    property color color: Services.Colors.snow

    // The rows have to TOUCH. With default leading the background shows between
    // them and the blocks stop being one shape, so the line height is pinned to
    // the cell and nothing else decides it.
    readonly property real cell: Math.round(root.pixelSize * 1.18)

    implicitWidth: art.implicitWidth
    implicitHeight: art.implicitHeight

    Text {
        id: art
        color: root.color
        font.pixelSize: root.pixelSize
        font.family: "JetBrainsMono NF"
        lineHeight: root.cell
        lineHeightMode: Text.FixedHeight
        textFormat: Text.PlainText
        text: " ░░░░░╗ ░░░░░░░╗░░╗  ░░╗░░░░░░░╗░░░╗   ░░╗\n"
            + "░░╔══░░╗░░╔════╝░░║  ░░║░░╔════╝░░░░╗  ░░║\n"
            + "▒▒▒▒▒▒▒║▒▒▒▒▒▒▒╗▒▒▒▒▒▒▒║▒▒▒▒▒╗  ▒▒╔▒▒╗ ▒▒║\n"
            + "▓▓╔══▓▓║╚════▓▓║▓▓╔══▓▓║▓▓╔══╝  ▓▓║╚▓▓╗▓▓║\n"
            + "██║  ██║███████║██║  ██║███████╗██║ ╚████║\n"
            + "╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝"
    }
}
