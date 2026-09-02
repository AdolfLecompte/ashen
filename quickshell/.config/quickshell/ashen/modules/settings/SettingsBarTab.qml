import QtQuick
import "root:/services" as Services
import "root:/modules/settings/components"

// The two surfaces that are always there. Three sections rather than one very
// long page: the layout editor alone is taller than the panel, and it used to
// sit between the bar's own switches and the desktop's.
Item {
    id: tab
    anchors.fill: parent

    property string section: "shape"

    Segmented {
        id: picker
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 28
        anchors.leftMargin: 28
        anchors.rightMargin: 28
        cellHeight: 38
        options: [
            { id: "shape", icon: "\ue98c", label: "Bar" },
            { id: "layout", icon: "\ue8f1", label: "Layout" },
            { id: "desktop", icon: "\ue1bd", label: "Desktop" }
        ]
        current: tab.section
        onPicked: id => tab.section = id
    }

    Loader {
        anchors.top: picker.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.topMargin: 4
        source: tab.section === "shape" ? "BarShapePage.qml"
              : tab.section === "layout" ? "BarLayoutPage.qml"
              : "BarDesktopPage.qml"
    }
}
