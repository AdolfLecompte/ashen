import Quickshell
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts
import "root:/services" as Services
import "root:/modules/widgets" as Widgets
import "root:/modules/settings/components"
import "root:/modules/net" as Net

// Bluetooth as cards, the way Wi-Fi is: the radio and what is connected, the
// devices you own, and the ones nearby.
TabPage {
    id: tab

    property var adapter: Bluetooth.defaultAdapter
    readonly property bool radioOn: tab.adapter !== null && tab.adapter.enabled
    readonly property bool scanning: tab.adapter !== null && tab.adapter.discovering
    readonly property bool connected: Services.Network.btDevice !== ""

    // BlueZ remembers a device as paired, bonded or trusted, and controllers
    // are often trusted-only -- the same test the row uses for its forget button.
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

    // ── The radio, and what is connected ─────────────────────────────────
    Card {
        glyph: ""
        title: Services.I18n.t("settings.tab.bluetooth")

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            RowGlyph { glyph: !tab.radioOn ? "" : tab.connected ? "" : "" }
            ColumnLayout {
                spacing: 0
                Layout.fillWidth: true
                Text {
                    textFormat: Text.PlainText
                    Layout.fillWidth: true
                    text: !tab.adapter ? Services.I18n.t("settings.bt.noAdapter")
                        : tab.connected ? Services.Network.btDevice
                        : tab.radioOn ? Services.I18n.t("settings.net.notConnected")
                        : Services.I18n.t("settings.net.off")
                    color: tab.connected ? Services.Colors.snow : Services.Colors.mist
                    font.pixelSize: Services.Sizes.fsInput
                    font.bold: tab.connected
                    font.family: "JetBrainsMono NF"
                    elide: Text.ElideRight
                }
                Text {
                    textFormat: Text.PlainText
                    visible: tab.connected
                    text: Services.I18n.t("settings.net.connected")
                    color: Services.Colors.ghost
                    font.pixelSize: Services.Sizes.fsMeta
                    font.family: "JetBrainsMono NF"
                }
            }
            Toggle {
                checked: tab.radioOn
                enabled: tab.adapter !== null
                onToggled: if (tab.adapter) tab.adapter.enabled = !tab.adapter.enabled
            }
        }
    }

    // ── Devices you own ──────────────────────────────────────────────────
    Card {
        visible: tab.radioOn && tab.knownDevices.length > 0
        glyph: ""
        title: Services.I18n.t("settings.bt.known")

        Repeater {
            model: tab.knownDevices
            delegate: Net.BtDeviceRow {
                required property var modelData
                Layout.fillWidth: true
                device: modelData
            }
        }
    }

    // ── Nearby ───────────────────────────────────────────────────────────
    Card {
        visible: tab.radioOn
        glyph: ""
        title: Services.I18n.t("settings.bt.available")

        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Text {
                textFormat: Text.PlainText
                Layout.fillWidth: true
                text: tab.scanning ? Services.I18n.t("common.scanning")
                    : tab.newDevices.length === 0 ? Services.I18n.t("settings.bt.noDevices")
                    : Services.I18n.t("settings.net.found", { n: tab.newDevices.length })
                color: Services.Colors.ash
                font.pixelSize: Services.Sizes.fsMeta
                font.family: "JetBrainsMono NF"
            }
            Widgets.IconButton {
                glyph: ""
                tip: Services.I18n.t("tip.refresh")
                active: tab.scanning
                onActivated: tab.startScan()
            }
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
}
