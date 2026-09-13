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
    mask: Widgets.ShellMask { winW: root.width; winH: root.height }
    // The line for an empty list, picked when it empties and not per frame.
    property string emptyLine: Services.Voice.pick("usb.empty")

    // stays mapped through the close animation, so the exit plays in reverse
    readonly property bool shown: Services.AppState.usbVisible

    // The last stick pulled out takes the panel with it. This card hangs off a
    // pill that only exists while something is plugged in, so once the pill
    // goes the panel is a card pointing at nothing.
    Connections {
        target: Services.USB
        function onDevicesChanged() {
            if (Services.USB.devices.length === 0) Services.AppState.usbVisible = false
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

    // Falls out of the USB pill like a drop, same as the rest of the bar.
    Widgets.PanelHost {
        id: card
        shown: Services.AppState.usbVisible
        pillCX: Services.AppState.usbPillCenterX
        pillCY: Services.AppState.usbPillCenterY
        pillW: Services.AppState.usbPillW
        pillH: Services.AppState.usbPillH
        pillActive: false
        // Standalone bar pill, not a system chip: its plate is the pill surface.
        pillColor: Services.Colors.surfacePill
        pillGlyph: Services.AppState.pillGlyph("usb")
        // The pill's icon lands on the panel's header icon: same glyph, moved.
        openW: 360
        openH: Math.min((card.bodyItem ? card.bodyItem.contentH : 0) + 28, root.height - 80)
        cardRadius: 14

        pillKey: "usb"
        restSide: "right"

        body: Component {
            Item {
                // The host sizes the card off this.
                readonly property real contentH: panelCol.implicitHeight
                readonly property Item glyphTarget: hdrGlyph

                Column {
                    id: panelCol
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 14
                    spacing: 10

                    RowLayout {
                        width: parent.width
                        Text {
                            textFormat: Text.PlainText
                            id: hdrGlyph
                            opacity: card.morphingGlyph ? 0 : 1
                            text: "\ue1e0"
                            color: Services.Colors.ghost
                            font.pixelSize: 18
                            font.family: "Material Symbols Rounded"
                        }
                        Text {
                            textFormat: Text.PlainText
                            text: Services.I18n.t("usb.title")
                            color: Services.Colors.snow
                            font.pixelSize: 14
                            font.bold: true
                            font.family: "JetBrainsMono NF"
                            Layout.fillWidth: true
                            leftPadding: 8
                        }
                    }

                    Text {
                        textFormat: Text.PlainText
                        visible: Services.USB.devices.length === 0
                        text: root.emptyLine
                        color: Services.Colors.ash
                        font.pixelSize: 11
                        font.family: "JetBrainsMono NF"
                        topPadding: 20
                        bottomPadding: 20
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Repeater {
                        model: Services.USB.devices
                        delegate: Rectangle {
                            required property var modelData
                            width: panelCol.width
                            height: 66
                            radius: 10
                            color: Services.Colors.fillInset

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 10

                                Rectangle {
                                    width: 36; height: 36
                                    radius: 9
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
                                        text: modelData.label
                                        color: Services.Colors.snow
                                        font.pixelSize: 13
                                        font.bold: true
                                        font.family: "JetBrainsMono NF"
                                        elide: Text.ElideRight
                                        width: parent.width
                                    }
                                    Text {
                                        textFormat: Text.PlainText
                                        text: modelData.size + (modelData.mountpoint ? " · " + modelData.mountpoint : " · Not mounted")
                                        color: Services.Colors.mist
                                        font.pixelSize: 10
                                        font.family: "JetBrainsMono NF"
                                        elide: Text.ElideRight
                                        width: parent.width
                                    }
                                }

                                Rectangle {
                                    width: mountLabel.implicitWidth + 16
                                    height: 28
                                    radius: 8
                                    color: modelData.mountpoint ? Services.Colors.fillLine : Services.Colors.ghost
                                    Text {
                                        textFormat: Text.PlainText
                                        id: mountLabel
                                        anchors.centerIn: parent
                                        text: modelData.mountpoint ? Services.I18n.t("usb.unmount") : Services.I18n.t("usb.mount")
                                        color: modelData.mountpoint ? Services.Colors.snow : Services.Colors.abyss
                                        font.pixelSize: 11
                                        font.family: "JetBrainsMono NF"
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (modelData.mountpoint) Services.USB.unmount(modelData.path)
                                            else Services.USB.mount(modelData.path)
                                        }
                                    }
                                }

                                Widgets.IconButton {
                                    glyph: "\ue8fb"
                                    onActivated: Services.USB.eject(modelData.parentName)
                                }
                            }
                        }
                    }

                    Item { height: 4 }
                }
            }
        }
    }
}
