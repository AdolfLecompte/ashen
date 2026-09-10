import QtQuick
import "root:/services" as Services
import "root:/modules/settings/components"

// The two radios. One at a time behind a switch rather than side by side: both
// are live lists that want the whole height, and two half-height lists means
// scrolling in both to find anything. The rest of Settings has no switch like
// this -- these two earn it by being lists rather than rows of settings.
Item {
    id: page
    anchors.fill: parent

    // Deep-linked from an ipc call or the launcher: `settings tab bluetooth`
    // still has to land on Bluetooth. Assigned rather than bound: the switch
    // writes this too, and the first press would kill a binding.
    property string section: "wifi"
    function adopt() {
        const t = Services.AppState.settingsTab
        if (t === "bluetooth" || t === "wifi") page.section = t
    }
    Component.onCompleted: page.adopt()
    Connections {
        target: Services.AppState
        function onSettingsTabChanged() { page.adopt() }
    }

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
            { id: "wifi", icon: "\ue1ba", label: Services.I18n.t("settings.tab.wifi") },
            { id: "bluetooth", icon: "\ue1a7", label: Services.I18n.t("settings.tab.bluetooth") }
        ]
        current: page.section
        onPicked: id => page.section = id
    }

    Loader {
        anchors.top: picker.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.topMargin: 4
        source: page.section === "bluetooth" ? "SettingsBluetoothTab.qml"
                                             : "SettingsWifiTab.qml"
    }
}
