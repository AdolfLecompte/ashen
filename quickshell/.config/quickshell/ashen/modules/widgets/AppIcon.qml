import Quickshell
import QtQuick

// An application icon by name or path, rasterised at twice its size and
// mipmapped down: sharp at any size, and while it grows on hover.
Image {
    id: root

    property string icon: ""

    source: !root.icon ? Quickshell.iconPath("application-x-executable")
          : root.icon.startsWith("/") ? "file://" + root.icon
          : Quickshell.iconPath(root.icon, "application-x-executable")
    sourceSize: Qt.size(Math.ceil(root.width * 2), Math.ceil(root.height * 2))
    fillMode: Image.PreserveAspectFit
    smooth: true
    mipmap: true
}
