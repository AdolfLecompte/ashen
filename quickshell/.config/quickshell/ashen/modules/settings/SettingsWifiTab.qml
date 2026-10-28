import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "root:/services" as Services
import "root:/modules/settings/components"
import "root:/modules/net" as Net
import "root:/modules/widgets" as Widgets

// Wi-Fi as cards: the radio and the network you are on, the saved ones in
// range, and the rest. One scroll for the page; a password opens under its row.
TabPage {
    id: tab

    property var networks: []
    readonly property var knownNetworks: Services.Network.knownSsids
    // The secured network whose password row is open, "" for none.
    property string connectingTo: ""
    property string password: ""
    property bool showPassword: false

    // Saved networks currently in range (not the active one).
    readonly property var knownRows: tab.networks.filter(n => !n.active && tab.knownNetworks.includes(n.ssid))
    readonly property var availRows: tab.networks.filter(n => !n.active && !tab.knownNetworks.includes(n.ssid))
    readonly property bool connected: Services.Network.wifiSsid !== ""

    function refreshNetworks() {
        scanProc.running = true
        Services.Network.refreshKnown()
    }

    function forgetSsid(ssid) { Services.Network.forget(ssid) }

    // argv, not a shell string: an SSID or password holding a quote would
    // otherwise close it and run the rest as shell.
    function connect(ssid, pass) {
        const cmd = ["nmcli", "dev", "wifi", "connect", ssid]
        if (pass.length > 0) cmd.push("password", pass)
        Quickshell.execDetached(cmd)
        tab.connectingTo = ""
    }

    function pick(net) {
        if (!net.secure) { tab.connect(net.ssid, ""); return }
        tab.password = ""
        tab.showPassword = false
        tab.connectingTo = tab.connectingTo === net.ssid ? "" : net.ssid
    }

    function wifiGlyph(signal) {
        return signal >= 75 ? "" : signal >= 50 ? "" : signal >= 25 ? "" : ""
    }

    Component.onCompleted: refreshNetworks()

    Process {
        id: scanProc
        command: ["nmcli", "-t", "-f", "active,ssid,signal,security", "dev", "wifi"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = text.trim().split("\n").filter(l => l.length > 0)
                let nets = []
                for (let line of lines) {
                    let parts = line.split(":")
                    if (parts.length >= 3 && parts[1].length > 0) {
                        nets.push({
                            active: parts[0] === "yes",
                            ssid: parts[1],
                            signal: parseInt(parts[2]) || 0,
                            secure: parts[3] !== "" && parts[3] !== "--",
                        })
                    }
                }
                nets.sort((a, b) => b.active - a.active || b.signal - a.signal)
                let unique = []
                let seen = new Set()
                for (let n of nets) {
                    if (!seen.has(n.ssid)) {
                        seen.add(n.ssid)
                        unique.push(n)
                    }
                }
                tab.networks = unique
            }
        }
    }

    Timer {
        interval: 15000
        running: true
        repeat: true
        onTriggered: tab.refreshNetworks()
    }

    // After a radio toggle, re-poll once nmcli has actually flipped the radio, so
    // the optimistic state is confirmed (or corrected) and, on turn-on, networks
    // reappear without waiting for the 15s scan.
    Timer {
        id: wifiSettleTimer
        interval: 1500
        onTriggered: { Services.Network.refresh(); tab.refreshNetworks() }
    }

    // ── The radio, and the network you are on ────────────────────────────
    Card {
        glyph: ""
        title: Services.I18n.t("settings.tab.wifi")

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            RowGlyph {
                glyph: !Services.Network.wifiEnabled ? ""
                     : tab.connected ? tab.wifiGlyph(Services.Network.wifiSignal) : ""
            }
            ColumnLayout {
                spacing: 0
                Layout.fillWidth: true
                Text {
                    textFormat: Text.PlainText
                    Layout.fillWidth: true
                    text: tab.connected ? Services.Network.wifiSsid
                        : Services.Network.wifiEnabled ? Services.I18n.t("settings.net.notConnected")
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
                    text: Services.I18n.t("settings.net.connected") + "  ·  " + Services.Network.wifiSignal + "%"
                    color: Services.Colors.ghost
                    font.pixelSize: Services.Sizes.fsMeta
                    font.family: "JetBrainsMono NF"
                }
            }
            Widgets.IconButton {
                visible: tab.connected
                glyph: ""
                tip: Services.I18n.t("tip.forget")
                onActivated: tab.forgetSsid(Services.Network.wifiSsid)
            }
            Toggle {
                checked: Services.Network.wifiEnabled
                onToggled: {
                    let turnOn = !Services.Network.wifiEnabled
                    // Optimistic: flip the pill/panel and empty the list NOW so
                    // there's no ~6s lag waiting for the service's 10s poll.
                    Services.Network.wifiEnabled = turnOn
                    if (!turnOn) {
                        tab.networks = []
                        tab.connectingTo = ""
                        Services.Network.wifiSsid = ""
                        Services.Network.wifiSignal = 0
                    }
                    Quickshell.execDetached(["sh", "-c", turnOn ? "nmcli radio wifi on" : "nmcli radio wifi off"])
                    wifiSettleTimer.restart()   // reconcile with reality shortly
                }
            }
        }
    }

    // ── Saved networks in range ──────────────────────────────────────────
    Card {
        visible: Services.Network.wifiEnabled && tab.knownRows.length > 0
        glyph: ""
        title: Services.I18n.t("settings.wifi.known")

        Repeater {
            model: tab.knownRows
            delegate: Net.WifiNetworkRow {
                required property var modelData
                Layout.fillWidth: true
                net: modelData
                known: true
                onActivate: Services.Network.connectSaved(modelData.ssid)
                onForget: tab.forgetSsid(modelData.ssid)
            }
        }
    }

    // ── Everything else in range ─────────────────────────────────────────
    Card {
        visible: Services.Network.wifiEnabled
        glyph: ""
        title: Services.I18n.t("settings.wifi.available")

        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Text {
                textFormat: Text.PlainText
                Layout.fillWidth: true
                text: scanProc.running ? Services.I18n.t("common.scanning")
                    : Services.I18n.t("settings.net.found", { n: tab.availRows.length })
                color: Services.Colors.ash
                font.pixelSize: Services.Sizes.fsMeta
                font.family: "JetBrainsMono NF"
            }
            Widgets.IconButton {
                glyph: ""
                tip: Services.I18n.t("tip.refresh")
                active: scanProc.running
                onActivated: tab.refreshNetworks()
            }
        }

        Repeater {
            model: tab.availRows
            delegate: ColumnLayout {
                id: netItem
                required property var modelData
                readonly property bool asking: tab.connectingTo === modelData.ssid
                Layout.fillWidth: true
                spacing: 6

                Net.WifiNetworkRow {
                    Layout.fillWidth: true
                    net: netItem.modelData
                    known: false
                    onActivate: tab.pick(netItem.modelData)
                }

                // The password, under the row it belongs to.
                Collapse {
                    open: netItem.asking
                    onOpenChanged: if (open) passInput.forceActiveFocus()

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                        radius: Services.Sizes.innerR
                        color: Services.Colors.fillLine
                        border.color: passInput.activeFocus ? Services.Colors.ghost : Services.Colors.fillStrong
                        border.width: 1
                        Behavior on border.color { Widgets.ColorAnim { speed: Services.Sizes.msMicro } }
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 6
                            spacing: 8
                            Text {
                                textFormat: Text.PlainText
                                text: ""
                                color: Services.Colors.ghost
                                font.pixelSize: 16
                                font.family: "Material Symbols Rounded"
                            }
                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Text {
                                    textFormat: Text.PlainText
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: Services.I18n.t("settings.wifi.password")
                                    color: Services.Colors.ash
                                    font.pixelSize: Services.Sizes.fsInput
                                    font.family: "JetBrainsMono NF"
                                    visible: passInput.text.length === 0
                                }
                                TextInput {
                                    id: passInput
                                    anchors.fill: parent
                                    Keys.onPressed: e => { if (Services.Readline.handle(e, passInput)) e.accepted = true }
                                    text: netItem.asking ? tab.password : ""
                                    echoMode: tab.showPassword ? TextInput.Normal : TextInput.Password
                                    color: Services.Colors.snow
                                    font.pixelSize: Services.Sizes.fsInput
                                    font.family: "JetBrainsMono NF"
                                    verticalAlignment: TextInput.AlignVCenter
                                    onTextChanged: if (netItem.asking) tab.password = text
                                    Keys.onReturnPressed: tab.connect(netItem.modelData.ssid, tab.password)
                                    Keys.onEscapePressed: tab.connectingTo = ""
                                }
                            }
                            Widgets.IconButton {
                                glyph: tab.showPassword ? "" : ""
                                tip: Services.I18n.t("tip.showPassword")
                                onActivated: tab.showPassword = !tab.showPassword
                            }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        ActionBtn {
                            Layout.fillWidth: true
                            label: Services.I18n.t("common.cancel")
                            onGo: tab.connectingTo = ""
                        }
                        ActionBtn {
                            Layout.fillWidth: true
                            accent: true
                            label: Services.I18n.t("common.connect")
                            onGo: tab.connect(netItem.modelData.ssid, tab.password)
                        }
                    }
                }
            }
        }
    }
}
