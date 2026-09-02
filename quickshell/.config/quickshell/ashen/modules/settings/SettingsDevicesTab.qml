import QtQuick
import "root:/services" as Services
import "root:/modules/settings/components"

// Everything the machine talks to, in one place: what it plays through, what
// you type on, and what it is connected to. They were four rail slots asking
// the same question, and the rail was the longest thing in the drawer.
Item {
    id: tab
    anchors.fill: parent

    // Deep-linked from an ipc call or the launcher: `settings tab bluetooth`
    // still has to land on Bluetooth, not on the first section.
    property string section: {
        const t = Services.AppState.settingsTab
        if (t === "wifi" || t === "network") return "wifi"
        if (t === "bluetooth") return "bluetooth"
        if (t === "input") return "input"
        return "sound"
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
        // Flat, not a switch inside a switch: Wi-Fi and Bluetooth used to sit
        // behind a second row of their own, which is one press too many for
        // the two things people come here to change.
        options: [
            { id: "sound", icon: "\ue050", label: "Sound" },
            { id: "input", icon: "\ue312", label: "Keyboard" },
            { id: "wifi", icon: "\ue1ba", label: "Wi-Fi" },
            { id: "bluetooth", icon: "\ue1a7", label: "Bluetooth" }
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
        source: tab.section === "sound" ? "SettingsSoundTab.qml"
              : tab.section === "input" ? "SettingsInputTab.qml"
              : tab.section === "wifi" ? "SettingsWifiTab.qml"
              : "SettingsBluetoothTab.qml"
    }
}
