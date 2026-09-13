import Quickshell
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts

import "root:/services" as Services
import "root:/modules/widgets" as Widgets

PanelWindow {
    id: root

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }
    screen: Services.Screens.active

    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    // Everything but the bar's strip: a click on a pill has to reach it,
    // or changing panels costs two. See widgets/ShellMask.qml.
    mask: Widgets.ShellMask { winW: root.width; winH: root.height }
    // stays mapped through the close animation, so the exit plays in reverse
    readonly property bool shown: Services.AppState.bluetoothVisible
    visible: shown || closeDelay.running
    // Mapped until the drop is all the way home; see DropCard.closeMs.
    Timer { id: closeDelay; interval: btCard.closeMs }

    property var adapter: Bluetooth.defaultAdapter

    // The two things this card waits on, and the one line that says which.
    // Pairing outranks the sweep: it is the one you asked for.
    readonly property bool pairing: Services.BtLink.pendingAddr !== ""
    readonly property bool sweeping: root.adapter ? root.adapter.discovering : false
    property string waitLine: ""
    function retune() {
        root.waitLine = root.pairing ? Services.Voice.pick("bt.pairing")
            : root.sweeping ? Services.Voice.pick("bt.scanning") : ""
    }
    onPairingChanged: root.retune()
    onSweepingChanged: root.retune()

    function startScan() {
        if (adapter && adapter.enabled && !adapter.discovering) {
            adapter.discovering = true
            scanTimer.restart()
        }
    }

    // The scan window is the panel's; what happens when you press a device is
    // Services.BtLink's, so the ring and the rows in Settings behave alike.
    function stopScan() {
        scanTimer.stop()
        Services.BtLink.stopScan()
    }

    Timer {
        id: scanTimer
        interval: 15000
        onTriggered: if (root.adapter) root.adapter.discovering = false
    }

    onShownChanged: {
        if (shown) Qt.callLater(startScan)
        else {
            closeDelay.restart()
            root.stopScan()
        }
    }

    // Bluetooth.defaultAdapter arrives asynchronously over DBus: if the panel is
    // already open when it shows up, the scan has to start right then.
    onAdapterChanged: if (adapter && shown) Qt.callLater(startScan)

    Connections {
        target: root.adapter
        function onEnabledChanged() {
            if (root.adapter && root.adapter.enabled) {
                Qt.callLater(root.startScan)
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        // Off while the panel is closing: the window stays mapped for the
        // animation, and a live dismiss layer ate the next click.
        enabled: Services.AppState.bluetoothVisible
        onClicked: Services.AppState.bluetoothVisible = false
    }

    // Falls out of the bluetooth chip like a drop, same as the network card.
    Widgets.PanelHost {
        id: btCard
        shown: Services.AppState.bluetoothVisible
        pillCX: Services.AppState.bluetoothPillCenterX
        pillCY: Services.AppState.bluetoothPillCenterY
        pillActive: Services.Network.btEnabled
        pillGlyph: Services.AppState.pillGlyph("bluetooth")
        pillLabel: Services.AppState.pillLabel("bluetooth")
        pillW: Services.AppState.bluetoothPillW
        pillH: Services.AppState.bluetoothPillH
        openW: 680
        openH: Math.min((btCard.bodyItem ? btCard.bodyItem.contentH : 0) + 28, root.height - 80)

        pillKey: "bluetooth"
        restSide: "center"

        body: Component {
            Item {
                // The host sizes the card off this.
                readonly property real contentH: panelCol.implicitHeight
                readonly property Item glyphTarget: graph.hubGlyphItem
                readonly property Item labelTarget: graph.hubLabelItem

                Column {
                    id: panelCol
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 14
                    spacing: 10

                    // Header
                    RowLayout {
                        width: parent.width

                        Text {
                            text: ""
                            color: Services.Colors.ghost
                            font.pixelSize: 20
                            font.family: "Material Symbols Rounded"
                        }
                        Text {
                            text: Services.I18n.t("settings.tab.bluetooth")
                            color: Services.Colors.snow
                            font.pixelSize: 14
                            font.family: "JetBrainsMono NF"
                            font.bold: true
                            Layout.fillWidth: true
                            leftPadding: 8
                        }

                        // No refresh icon up here: the scan button at the foot of
                        // the card is the only place a scan starts from. Two
                        // buttons doing the same thing just made you wonder how
                        // they differed.
                        Rectangle {
                            width: 52; height: 28; radius: 14
                            color: (root.adapter && root.adapter.enabled) ? Services.Colors.ghost : Services.Colors.fillRest
                            gradient: Services.Prefs.useGradients && ((root.adapter && root.adapter.enabled)) ? Services.Colors.accentGradient : null
                            Behavior on color { Widgets.ColorAnim {} }

                            Rectangle {
                                width: 20; height: 20; radius: 10
                                color: Services.Colors.snow
                                anchors.verticalCenter: parent.verticalCenter
                                x: (root.adapter && root.adapter.enabled) ? parent.width - width - 4 : 4
                                Behavior on x { Widgets.Anim {} }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                enabled: root.adapter !== null
                                onClicked: {
                                    if (root.adapter) root.adapter.enabled = !root.adapter.enabled
                                }
                            }
                        }
                    }

                    // ── The ring ────────────────────────────────────────────
                    // Connected in the middle, everything paired orbiting it. Six slots and
                    // nothing under them: what the ring cannot hold is reached from
                    // Settings > Bluetooth, not from a list bolted to the card.
                    Widgets.NodeGraph {
                        id: graph
                        width: parent.width
                        // Fixed. The ring keeps its room whether six networks are
                        // in range or none: a card that shrinks to fit whatever the
                        // radio happens to see reads as cut off, and the wires to
                        // the top and bottom slots had nowhere to run.
                        height: 360
                        // Radio off folds the ring into the hub instead of blanking it.
                        live: root.adapter !== null && root.adapter.enabled
                        handOverGlyph: btCard.morphingGlyph
                        handOverLabel: btCard.morphingLabel

                        // Trusted counts as remembered, same as the rows in
                        // Settings: a controller often shows up trusted-only
                        // (paired:no bonded:no) and had no ring at all. Safe to
                        // key off now that nothing marks a device trusted
                        // BEFORE it has actually paired.
                        readonly property var known: root.adapter
                            ? root.adapter.devices.values.filter(
                                d => d.paired || d.bonded || d.trusted || d.connected)
                            : []
                        readonly property var linked: graph.known.find(d => d.connected) || null

                        hubActive: graph.linked !== null
                        // With nothing paired the hub has to wear the chip's face,
                        // or its icon and word have nowhere to land. It was showing
                        // the struck-through icon and "Not connected" while the bar
                        // said the plain one and "Scanning": two different pieces.
                        hubGlyph: graph.linked ? "\ue1a8"
                                : (Services.Network.btEnabled ? "\ue1a7" : "\ue1a9")
                        // Connected, prefer the exact string the chip is showing — the
                        // graph's own name for the device usually matches it but is not
                        // the same source, and a piece only flies on an exact match.
                        hubLabel: graph.linked
                                ? (Services.Network.btDevice !== "" ? Services.Network.btDevice
                                                                    : Services.BtLink.displayName(graph.linked))
                                : (Services.Network.btEnabled ? Services.I18n.t("net.scanning") : Services.I18n.t("net.disabled"))
                        hubSub: graph.linked
                            ? (graph.linked.batteryAvailable
                                ? Math.round(graph.linked.battery * 100) + "%" : Services.I18n.t("settings.net.connected"))
                            : ""
                        // Nothing in the ring is not the same as nothing at all:
                        // with the one device you own connected, it IS the hub,
                        // and the card was still saying "No paired devices yet".
                        emptyHint: !(root.adapter && root.adapter.enabled) ? Services.I18n.t("bt.off")
                            : graph.scanMode ? Services.I18n.t("bt.nothingRange")
                            : graph.linked ? ""
                            : Services.I18n.t("bt.noPaired")

                        // Same scan chip as Wi-Fi, in the same slot: press it and the
                        // ring fills with everything the radio can see, six at a time.
                        // Strangers get no wire — nothing is paired with them yet.
                        waitLine: root.waitLine
                        scanEnabled: true
                        scanGlyph: "\ue8b6"
                        scanLabel: Services.I18n.t("bt.scan")
                        scanSub: graph.scanMode
                            ? (root.adapter && root.adapter.discovering
                                ? Services.I18n.t("net.scanningDots") : Services.I18n.t("bt.nearbyCount", { n: graph.strangers.length }))
                            : Services.I18n.t("bt.nearby")
                        // The exact complement of `known`: the two lists used to
                        // disagree about `trusted`, so a device that had been
                        // marked trusted and then failed to pair was in neither
                        // of them -- it simply vanished off the card.
                        readonly property var strangers: root.adapter
                            ? root.adapter.devices.values
                                .filter(d => !(d.paired || d.bonded || d.trusted || d.connected))
                                .slice().sort((a, b) => String(a.name).localeCompare(String(b.name)))
                            : []
                        // The ring pages, so it is handed everything the sweep
                        // found rather than the first six.
                        scanNodes: graph.strangers.slice(0, 24).map(d => ({
                            id: d.address,
                            glyph: "\ue1a8",
                            label: Services.BtLink.displayName(d),
                            // What it is in the middle of: without it a pair
                            // that takes eight seconds looked like a dead button.
                            sub: Services.BtLink.busyText(d),
                            active: false
                        }))
                        onScanActivated: root.startScan()
                        onScanNodeActivated: function(id) {
                            Services.BtLink.request(graph.strangers.find(x => x.address === id))
                        }
                        onScanClosed: root.stopScan()

                        // The hub is already the connected one, so it does not get a
                        // slot as well.
                        nodes: graph.known.filter(d => !d.connected).map(d => ({
                            id: d.address,
                            glyph: "\ue1a8",
                            label: Services.BtLink.displayName(d),
                            sub: Services.BtLink.busyText(d) || (d.paired || d.bonded ? Services.I18n.t("bt.paired") : ""),
                            active: false
                        }))

                        onNodeActivated: function(id) {
                            Services.BtLink.request(graph.known.find(x => x.address === id))
                        }
                        onHubActivated: if (graph.linked) graph.linked.disconnect()
                    }

                    Item { height: 4 }
                }
            }
        }
    }
}
