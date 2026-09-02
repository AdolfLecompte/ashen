import QtQuick
import "root:/services" as Services
import "root:/modules/settings/components"

// The three surfaces that talk to you: the clock chip, the music card and the
// notifications. Sections rather than one long scroll -- with everything on one
// page you were paging past the weather to reach a toast timeout.
Item {
    id: tab
    anchors.fill: parent

    property string section: "clock"

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
            { id: "clock", icon: "\uefd6", label: "Clock & Weather" },
            { id: "media", icon: "\ue405", label: "Media" },
            { id: "notify", icon: "\ue7f5", label: "Notifications" }
        ]
        current: tab.section
        onPicked: id => tab.section = id
    }

    Loader {
        anchors.top: picker.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        // The loaded page brings its own 28px margins, so it only needs the gap
        // under the switch.
        anchors.topMargin: 4
        source: tab.section === "clock" ? "PanelsClockPage.qml"
              : tab.section === "media" ? "PanelsMediaPage.qml"
              : "PanelsNotifyPage.qml"
    }
}
