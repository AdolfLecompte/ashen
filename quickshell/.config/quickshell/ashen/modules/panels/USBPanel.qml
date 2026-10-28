import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "root:/services" as Services
import "root:/modules/widgets" as Widgets

PanelWindow {
    id: root
    anchors { top: true; left: true; right: true; bottom: true }
    screen: Services.Screens.active
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    // Everything but the bar's strip: a click on a pill has to reach it,
    // or changing panels costs two. See widgets/ShellMask.qml.
    mask: Widgets.ShellMask { winW: root.width; winH: root.height; keepRect: card.restRect }
    // The line for an empty list, picked when it empties and not per frame.
    property string emptyLine: Services.Voice.pick("usb.empty")

    // stays mapped through the close animation, so the exit plays in reverse
    readonly property bool shown: Services.AppState.usbVisible

    // The last stick pulled out takes the panel with it. This card hangs off a
    // pill that only exists while something is plugged in, so once the pill
    // goes the panel is a card pointing at nothing.
    Connections {
        target: Services.USB
        function onDrivesChanged() {
            if (Services.USB.drives.length === 0) Services.AppState.usbVisible = false
        }
    }
    visible: shown || closeDelay.running
    onShownChanged: if (!shown) closeDelay.restart()
    // Mapped until the drop is all the way home; see DropCard.closeMs.
    Timer { id: closeDelay; interval: card.closeMs }

    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    MouseArea {
        anchors.fill: parent
        z: -1
        // Off while the panel is closing: the window stays mapped for the
        // animation, and a live dismiss layer ate the next click.
        enabled: Services.AppState.usbVisible
        onClicked: Services.AppState.usbVisible = false
    }

    // Grows out of the USB pill like the rest of the bar.
    Widgets.PanelHost {
        id: card
        shown: Services.AppState.usbVisible
        pillCX: Services.AppState.usbPillCenterX
        pillCY: Services.AppState.usbPillCenterY
        pillW: Services.AppState.usbPillW
        pillH: Services.AppState.usbPillH
        pillGlyph: Services.AppState.pillGlyph("usb")
        // The pill's icon lands on the panel's header icon: same glyph, moved.
        openW: 380
        openH: Math.min((card.bodyItem ? card.bodyItem.contentH : 0) + 28, root.height - 80)

        pillKey: "usb"
        restSide: "right"

        body: Component {
            Item {
                id: bodyRoot
                // The host sizes the card off this.
                readonly property real contentH: panelCol.implicitHeight
                readonly property Item glyphTarget: hdrGlyph

                // A worded button: what it does, with a glyph for the eye. Hover
                // grows it and lifts its ink; the plate never lights.
                component WordBtn: Rectangle {
                    id: wb
                    property string glyph: ""
                    property string label: ""
                    property bool working: false
                    signal activated()
                    implicitWidth: wbRow.implicitWidth + 20
                    implicitHeight: 30
                    radius: Services.Sizes.innerR
                    color: Services.Colors.fillRest
                    scale: wb.working ? 1 : Services.Sizes.hoverScale(wbArea.containsMouse, wbArea.pressed)
                    Behavior on scale { Widgets.Anim { speed: Services.Sizes.pillHoverMs } }
                    Row {
                        id: wbRow
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            textFormat: Text.PlainText
                            anchors.verticalCenter: parent.verticalCenter
                            visible: wb.glyph !== ""
                            text: wb.glyph
                            color: wbArea.containsMouse ? Services.Colors.snow : Services.Colors.ghost
                            font.pixelSize: 16
                            font.family: "Material Symbols Rounded"
                        }
                        Text {
                            textFormat: Text.PlainText
                            anchors.verticalCenter: parent.verticalCenter
                            text: wb.working ? Services.I18n.t("usb.working") : wb.label
                            color: wbArea.containsMouse ? Services.Colors.snow : Services.Colors.mist
                            font.pixelSize: Services.Sizes.fsBody
                            font.bold: true
                            font.family: "JetBrainsMono NF"
                        }
                    }
                    MouseArea {
                        id: wbArea
                        anchors.fill: parent
                        enabled: !wb.working && Services.USB.busyPath === ""
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: wb.activated()
                    }
                }

                Column {
                    id: panelCol
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 14
                    spacing: 10

                    Row {
                        spacing: 8
                        Text {
                            textFormat: Text.PlainText
                            id: hdrGlyph
                            anchors.verticalCenter: parent.verticalCenter
                            opacity: card.morphingGlyph ? 0 : 1
                            text: "\ue1e0"
                            color: Services.Colors.ghost
                            font.pixelSize: 18
                            font.family: "Material Symbols Rounded"
                        }
                        Text {
                            textFormat: Text.PlainText
                            anchors.verticalCenter: parent.verticalCenter
                            text: Services.I18n.t("usb.title")
                            color: Services.Colors.snow
                            font.pixelSize: Services.Sizes.fsCardTitle
                            font.bold: true
                            font.family: "JetBrainsMono NF"
                        }
                    }

                    Text {
                        textFormat: Text.PlainText
                        visible: Services.USB.drives.length === 0
                        text: root.emptyLine
                        color: Services.Colors.ash
                        font.pixelSize: Services.Sizes.fsBody
                        font.family: "JetBrainsMono NF"
                        topPadding: 20
                        bottomPadding: 20
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    // One card per thing you pull out; its partitions inside.
                    Repeater {
                        model: Services.USB.drives
                        delegate: Rectangle {
                            id: driveCard
                            required property var modelData
                            width: panelCol.width
                            height: driveCol.implicitHeight + 24
                            radius: Services.Sizes.cardR
                            color: Services.Colors.plate

                            Column {
                                id: driveCol
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 12
                                spacing: 12

                                RowLayout {
                                    width: parent.width
                                    spacing: 10
                                    Rectangle {
                                        Layout.preferredWidth: 36
                                        Layout.preferredHeight: 36
                                        radius: Services.Sizes.innerR
                                        color: Services.Colors.fillLine
                                        Text {
                                            textFormat: Text.PlainText
                                            anchors.centerIn: parent
                                            text: "\ue1e0"
                                            color: Services.Colors.ghost
                                            font.pixelSize: 18
                                            font.family: "Material Symbols Rounded"
                                        }
                                    }
                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Text {
                                            textFormat: Text.PlainText
                                            width: parent.width
                                            text: driveCard.modelData.title
                                            color: Services.Colors.snow
                                            font.pixelSize: Services.Sizes.fsInput
                                            font.bold: true
                                            font.family: "JetBrainsMono NF"
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            textFormat: Text.PlainText
                                            width: parent.width
                                            text: [driveCard.modelData.model, Services.Disks.human(driveCard.modelData.size)]
                                                .filter(t => t !== "" && t !== driveCard.modelData.title).join(" · ")
                                            color: Services.Colors.mist
                                            font.pixelSize: Services.Sizes.fsMeta
                                            font.family: "JetBrainsMono NF"
                                            elide: Text.ElideRight
                                        }
                                    }
                                    WordBtn {
                                        glyph: "\ue8fb"
                                        label: Services.I18n.t("usb.eject")
                                        working: Services.USB.busyPath === driveCard.modelData.path
                                        onActivated: Services.USB.eject(driveCard.modelData)
                                    }
                                }

                                Repeater {
                                    model: driveCard.modelData.parts
                                    delegate: Column {
                                        id: partRow
                                        required property var modelData
                                        readonly property bool mounted: modelData.mountpoint !== ""
                                        readonly property bool working: Services.USB.busyPath === modelData.path
                                        readonly property real total: modelData.used + modelData.avail
                                        width: driveCol.width
                                        spacing: 6

                                        RowLayout {
                                            width: parent.width
                                            spacing: 8
                                            Column {
                                                Layout.fillWidth: true
                                                spacing: 1
                                                Text {
                                                    textFormat: Text.PlainText
                                                    width: parent.width
                                                    text: partRow.modelData.label !== "" ? partRow.modelData.label : partRow.modelData.name
                                                    color: Services.Colors.snow
                                                    font.pixelSize: Services.Sizes.fsBody
                                                    font.family: "JetBrainsMono NF"
                                                    elide: Text.ElideRight
                                                }
                                                Text {
                                                    textFormat: Text.PlainText
                                                    width: parent.width
                                                    text: partRow.modelData.fstype + " · " + Services.Disks.human(partRow.modelData.size)
                                                    color: Services.Colors.ash
                                                    font.pixelSize: Services.Sizes.fsMeta
                                                    font.family: "JetBrainsMono NF"
                                                    elide: Text.ElideRight
                                                }
                                            }
                                            // Opening an unmounted one mounts it first.
                                            Widgets.IconButton {
                                                glyph: "\ue2c8"
                                                size: 28
                                                available: Services.USB.busyPath === ""
                                                onActivated: Services.USB.open(partRow.modelData)
                                            }
                                            WordBtn {
                                                label: partRow.mounted ? Services.I18n.t("usb.unmount") : Services.I18n.t("usb.mount")
                                                working: partRow.working
                                                onActivated: partRow.mounted ? Services.USB.unmount(partRow.modelData)
                                                                             : Services.USB.mount(partRow.modelData, false)
                                            }
                                        }

                                        // How full it is, once there is a filesystem to ask.
                                        Item {
                                            width: parent.width
                                            height: 22
                                            visible: partRow.mounted && partRow.total > 0
                                            Rectangle {
                                                anchors.left: parent.left
                                                anchors.right: freeText.left
                                                anchors.rightMargin: 10
                                                anchors.verticalCenter: parent.verticalCenter
                                                height: 10
                                                radius: 5
                                                color: Services.Colors.fillLine
                                                Rectangle {
                                                    width: parent.width * (partRow.total > 0 ? partRow.modelData.used / partRow.total : 0)
                                                    height: parent.height
                                                    radius: parent.radius
                                                    color: Services.Colors.ghost
                                                    gradient: Services.Prefs.useGradients ? Services.Colors.accentGradient : null
                                                    Behavior on width { Widgets.Anim {} }
                                                }
                                            }
                                            Text {
                                                textFormat: Text.PlainText
                                                id: freeText
                                                anchors.right: parent.right
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: Services.I18n.t("usb.free", { n: Services.Disks.human(partRow.modelData.avail) })
                                                color: Services.Colors.mist
                                                font.pixelSize: Services.Sizes.fsMeta
                                                font.bold: true
                                                font.family: "JetBrainsMono NF"
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Item { width: 1; height: 2 }
                }
            }
        }
    }

    // Escape closes it.
    Widgets.PanelKeys {
        shown: Services.AppState.usbVisible
        onCloseRequested: Services.AppState.usbVisible = false
    }
}
