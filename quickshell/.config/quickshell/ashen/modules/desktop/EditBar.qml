import QtQuick

import "root:/modules/widgets" as Widgets
import "root:/services" as Services

// While the desktop is being arranged: how things land, and the way out. It is
// also where you learn that Escape works.
Item {
    id: root

    readonly property bool shown: Services.Desktop.editMode

    implicitWidth: plate.width
    implicitHeight: plate.height
    width: implicitWidth
    height: implicitHeight

    z: 10
    visible: opacity > 0
    opacity: root.shown ? 1 : 0
    Behavior on opacity { Widgets.Anim {} }
    transform: Translate { y: root.shown ? 0 : -16 }

    Rectangle {
        id: plate
        width: row.width + 20
        height: 44
        radius: Services.Sizes.pillR
        color: Services.Colors.surfacePanel
        border.width: Services.Colors.panelEdgeW
        border.color: Services.Colors.fillOutline

        // Behind the chosen mode, travelling between them. A child of the plate
        // and of no Row at all: a Row lays out everything it holds, so a marker
        // inside one takes a slot of its own and shoves the first mode aside.
        Rectangle {
            x: row.x + modes.x + (modes.activeItem ? modes.activeItem.x : 0)
            y: row.y + modes.y
            width: modes.activeItem ? modes.activeItem.width : 0
            height: 28
            radius: Services.Sizes.innerR
            color: Services.Colors.ghost
            gradient: Services.Prefs.useGradients ? Services.Colors.accentGradient : null
            visible: modes.activeItem !== null
            Behavior on x { SmoothedAnimation { duration: Services.Sizes.msPronounced } }
            Behavior on width { SmoothedAnimation { duration: Services.Sizes.msPronounced } }
        }

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 14

            Row {
                id: modes
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                property Item activeItem: null

                Repeater {
                    model: [{ id: "free", label: Services.I18n.t("widget.free") },
                            { id: "grid", label: Services.I18n.t("widget.grid") },
                            { id: "magnet", label: Services.I18n.t("widget.magnet") }]

                    Item {
                        id: mode
                        required property var modelData
                        readonly property bool active: Services.Desktop.snap === mode.modelData.id
                        width: modeText.implicitWidth + 24
                        height: 28

                        onActiveChanged: if (active) modes.activeItem = mode
                        Component.onCompleted: if (active) modes.activeItem = mode

                        Text {
                            textFormat: Text.PlainText
                            id: modeText
                            anchors.centerIn: parent
                            text: mode.modelData.label
                            color: mode.active ? Services.Colors.accentText
                                 : modeHover.containsMouse ? Services.Colors.snow
                                 : Services.Colors.mist
                            font.pixelSize: Services.Sizes.fsBody
                            font.bold: true
                            font.family: "JetBrainsMono NF"
                            Behavior on color { Widgets.ColorAnim { speed: Services.Sizes.msMicro } }
                        }
                        scale: Services.Sizes.hoverScale(modeHover.containsMouse, modeHover.pressed)
                        Behavior on scale { Widgets.Anim { speed: Services.Sizes.pillHoverMs } }

                        MouseArea {
                            id: modeHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Services.Desktop.setSnap(mode.modelData.id)
                        }
                    }
                }
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 1
                height: 20
                color: Services.Colors.fillLine
            }

            // The tray of widgets: what is out, and what could be. It hangs
            // below this bar rather than inside it -- see WidgetTray.
            Item {
                id: tray
                anchors.verticalCenter: parent.verticalCenter
                width: trayRow.implicitWidth + 24
                height: 28

                readonly property bool open: Services.Desktop.trayOpen

                Rectangle {
                    anchors.fill: parent
                    radius: Services.Sizes.innerR
                    color: tray.open ? Services.Colors.ghost : Services.Colors.fillRest
                    gradient: Services.Prefs.useGradients && tray.open
                        ? Services.Colors.accentGradient : null
                    Behavior on color { Widgets.ColorAnim { speed: Services.Sizes.msMicro } }
                }
                Row {
                    id: trayRow
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        textFormat: Text.PlainText
                        text: "\ue1bd"
                        color: tray.open ? Services.Colors.accentText
                             : trayHover.containsMouse ? Services.Colors.snow
                             : Services.Colors.ash
                        font.pixelSize: 14
                        font.family: "Material Symbols Rounded"
                        anchors.verticalCenter: parent.verticalCenter
                        Behavior on color { Widgets.ColorAnim { speed: Services.Sizes.msMicro } }
                    }
                    Text {
                        textFormat: Text.PlainText
                        text: Services.I18n.t("widget.widgets")
                        color: tray.open ? Services.Colors.accentText
                             : trayHover.containsMouse ? Services.Colors.snow
                             : Services.Colors.mist
                        font.pixelSize: Services.Sizes.fsBody
                        font.bold: true
                        font.family: "JetBrainsMono NF"
                        anchors.verticalCenter: parent.verticalCenter
                        Behavior on color { Widgets.ColorAnim { speed: Services.Sizes.msMicro } }
                    }
                }
                scale: Services.Sizes.hoverScale(trayHover.containsMouse, trayHover.pressed)
                Behavior on scale { Widgets.Anim { speed: Services.Sizes.pillHoverMs } }

                MouseArea {
                    id: trayHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Services.Desktop.trayOpen = !Services.Desktop.trayOpen
                }
            }

            Text {
                textFormat: Text.PlainText
                anchors.verticalCenter: parent.verticalCenter
                text: Services.I18n.t("widget.escapeDone")
                color: Services.Colors.ash
                font.pixelSize: Services.Sizes.fsMeta
                font.family: "JetBrainsMono NF"
            }

            Item {
                id: done
                anchors.verticalCenter: parent.verticalCenter
                width: doneText.implicitWidth + 26
                height: 28

                Rectangle {
                    anchors.fill: parent
                    radius: Services.Sizes.innerR
                    color: Services.Colors.fillRest
                }
                Text {
                    textFormat: Text.PlainText
                    id: doneText
                    anchors.centerIn: parent
                    text: Services.I18n.t("common.done")
                    color: doneHover.containsMouse ? Services.Colors.snow : Services.Colors.mist
                    font.pixelSize: Services.Sizes.fsBody
                    font.bold: true
                    font.family: "JetBrainsMono NF"
                    Behavior on color { Widgets.ColorAnim { speed: Services.Sizes.msMicro } }
                }
                scale: Services.Sizes.hoverScale(doneHover.containsMouse, doneHover.pressed)
                Behavior on scale { Widgets.Anim { speed: Services.Sizes.pillHoverMs } }

                MouseArea {
                    id: doneHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Services.Desktop.editMode = false
                }
            }
        }
    }
}
