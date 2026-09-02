import Quickshell
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts
import "root:/services" as Services
import "root:/modules/widgets" as Widgets
import "root:/modules/settings/components"
import "root:/modules/net" as Net

Item {
    id: tab
    anchors.fill: parent

    property var adapter: Bluetooth.defaultAdapter

    // Split the way Wi-Fi splits. BlueZ hands back one list with the mouse you
    // have owned for a year next to a stranger's headphones walking past, and
    // the thing you came here for is the one you already own. Same test the
    // row itself uses for its forget button: BlueZ remembers a device as
    // paired, bonded or trusted, and controllers are often trusted-only.
    readonly property var allDevices: tab.adapter ? tab.adapter.devices.values : []
    readonly property var knownDevices:
        tab.allDevices.filter(d => d.paired || d.bonded || d.trusted)
    readonly property var newDevices:
        tab.allDevices.filter(d => !(d.paired || d.bonded || d.trusted))

    function startScan() {
        if (adapter && adapter.enabled && !adapter.discovering) {
            adapter.discovering = true
            scanTimer.restart()
        }
    }

    Timer {
        id: scanTimer
        interval: 15000
        onTriggered: if (tab.adapter) tab.adapter.discovering = false
    }

    // Bluetooth.defaultAdapter arrives asynchronously over DBus: it is still null
    // when the tab is created, so it has to be retried once it shows up.
    onAdapterChanged: if (adapter) Qt.callLater(startScan)
    Component.onCompleted: Qt.callLater(startScan)
    Component.onDestruction: {
        scanTimer.stop()
        if (adapter && adapter.discovering) adapter.discovering = false
    }

    Connections {
        target: tab.adapter
        function onEnabledChanged() {
            if (tab.adapter && tab.adapter.enabled) Qt.callLater(tab.startScan)
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 28
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            Text {
                visible: false   // the drawer header carries the section name
                text: "Bluetooth"
                color: Services.Colors.snow
                font.pixelSize: Services.Sizes.fsPanelTitle
                font.bold: true
                font.family: "JetBrainsMono NF"
                Layout.fillWidth: true
            }
            Widgets.IconButton {
                glyph: ""
                active: tab.adapter && tab.adapter.discovering
                onActivated: tab.startScan()
            }
            Item { Layout.fillWidth: true }
            Toggle {
                checked: tab.adapter !== null && tab.adapter.enabled
                enabled: tab.adapter !== null
                onToggled: if (tab.adapter) tab.adapter.enabled = !tab.adapter.enabled
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: Services.Network.btDevice !== "" ? 64 : 0
            visible: Services.Network.btDevice !== ""
            radius: Services.Sizes.innerR
            // Filled, not outlined: the accent border read as a glow and
            // nothing else in the shell outlines a selection.
            color: Services.Colors.fillRest
            border.width: 0
            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10
                Text { text: ""; color: Services.Colors.ghost; font.pixelSize: 22; font.family: "Material Symbols Rounded" }
                Column {
                    Layout.fillWidth: true
                    spacing: 2
                    Text { text: Services.Network.btDevice; color: Services.Colors.snow; font.pixelSize: Services.Sizes.fsCardTitle; font.family: "JetBrainsMono NF"; font.bold: true }
                    Text { text: "Connected"; color: Services.Colors.ghost; font.pixelSize: Services.Sizes.fsBody; font.family: "JetBrainsMono NF" }
                }
                Text { text: ""; color: Services.Colors.ghost; font.pixelSize: 22; font.family: "Material Symbols Rounded" }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            visible: tab.knownDevices.length > 0
            Text {
                text: "Known Devices"
                color: Services.Colors.mist
                font.pixelSize: Services.Sizes.fsMeta
                font.family: "JetBrainsMono NF"
                leftPadding: 4
            }
            Repeater {
                model: tab.knownDevices
                delegate: Net.BtDeviceRow {
                    required property var modelData
                    Layout.fillWidth: true
                    device: modelData
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 4
            visible: tab.newDevices.length > 0
            Text {
                text: tab.adapter && tab.adapter.discovering ? "Scanning..." : "Available"
                color: Services.Colors.mist
                font.pixelSize: Services.Sizes.fsMeta
                font.family: "JetBrainsMono NF"
                leftPadding: 4
            }
            Repeater {
                model: tab.newDevices
                delegate: Net.BtDeviceRow {
                    required property var modelData
                    Layout.fillWidth: true
                    device: modelData
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 60
            radius: Services.Sizes.innerR
            color: Services.Colors.fillInset
            visible: !tab.adapter || tab.allDevices.length === 0
            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10
                Text {
                    text: tab.adapter && tab.adapter.discovering ? "" : ""
                    color: Services.Colors.ash
                    font.pixelSize: 22
                    font.family: "Material Symbols Rounded"
                }
                Text {
                    text: tab.adapter && tab.adapter.discovering ? "Scanning..." : (tab.adapter ? "No devices found" : "No adapter")
                    color: Services.Colors.ash
                    font.pixelSize: Services.Sizes.fsInput
                    font.family: "JetBrainsMono NF"
                    Layout.fillWidth: true
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
