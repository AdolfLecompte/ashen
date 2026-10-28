import Quickshell
import QtQuick

// An application icon by name or path, rasterised at twice its size and
// mipmapped down: sharp at any size, and while it grows on hover.
// An Item around the Image: callers always size it, and the Image's implicit
// size following sourceSize made a binding loop inside layouts.
Item {
    id: root

    property string icon: ""
    readonly property alias status: img.status

    Image {
        id: img
        anchors.fill: parent
        source: !root.icon ? Quickshell.iconPath("application-x-executable")
              : root.icon.startsWith("/") ? "file://" + root.icon
              : Quickshell.iconPath(root.icon, "application-x-executable")
        sourceSize: Qt.size(Math.ceil(root.width * 2), Math.ceil(root.height * 2))
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
    }
}
