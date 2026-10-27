import QtQuick

import "root:/modules/widgets" as Widgets
import "root:/services" as Services

// While the desktop is being arranged: how things land, the widget tray, and
// the way out. Modes are icons; only the chosen one says its name.
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
    transform: Translate { y: root.shown ? 0 : -16; Behavior on y { Widgets.Anim {} } }

    Rectangle {
        id: plate
        width: row.width + 16
        height: 44
        radius: Services.Sizes.pillR
        color: Services.Colors.surfacePanel
        border.width: Services.Colors.panelEdgeW
        border.color: Services.Colors.panelEdgeColor

        // Behind the chosen mode, travelling between them. A child of the plate,
        // not of a Row: a Row would give the marker a slot of its own.
        Rectangle {
            x: row.x + modes.x + (modes.activeItem ? modes.activeItem.x : 0)
            y: row.y + modes.y
            width: modes.activeItem ? modes.activeItem.width : 0
            height: 30
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
            spacing: 8

            Row {
                id: modes
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                property Item activeItem: null

                Repeater {
                    model: [{ id: "free", glyph: "", label: Services.I18n.t("widget.free") },
                            { id: "grid", glyph: "", label: Services.I18n.t("widget.grid") },
                            { id: "magnet", glyph: "", label: Services.I18n.t("widget.magnet") }]

                    Item {
                        id: mode
                        required property var modelData
                        readonly property bool active: Services.Desktop.snap === mode.modelData.id
                        width: mode.active ? modeRow.implicitWidth + 24 : 34
                        height: 30
                        clip: true
                        Behavior on width { SmoothedAnimation { duration: Services.Sizes.msPronounced } }

                        onActiveChanged: if (active) modes.activeItem = mode
                        Component.onCompleted: if (active) modes.activeItem = mode

                        Row {
                            id: modeRow
                            anchors.centerIn: parent
                            spacing: 6
                            Text {
                                textFormat: Text.PlainText
                                anchors.verticalCenter: parent.verticalCenter
                                text: mode.modelData.glyph
                                color: mode.active ? Services.Colors.accentText
                                     : modeHover.containsMouse ? Services.Colors.snow
                                     : Services.Colors.mist
                                font.pixelSize: 17
                                font.family: "Material Symbols Rounded"
                                Behavior on color { Widgets.ColorAnim { speed: Services.Sizes.msMicro } }
                            }
                            Text {
                                textFormat: Text.PlainText
                                anchors.verticalCenter: parent.verticalCenter
                                visible: mode.active
                                text: mode.modelData.label
                                color: Services.Colors.accentText
                                font.pixelSize: Services.Sizes.fsBody
                                font.bold: true
                                font.family: "JetBrainsMono NF"
                            }
                        }
                        scale: Services.Sizes.hoverScale(modeHover.containsMouse, modeHover.pressed)
                        Behavior on scale { Widgets.Anim { speed: Services.Sizes.pillHoverMs } }

                        Widgets.Tip { target: mode; text: mode.modelData.label; show: modeHover.containsMouse && !mode.active }

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

            // The widget tray (it hangs below this bar -- see WidgetTray). The
            // plus turns into a cross while it is open.
            Item {
                id: tray
                anchors.verticalCenter: parent.verticalCenter
                width: 34
                height: 30
                readonly property bool open: Services.Desktop.trayOpen

                Rectangle {
                    anchors.fill: parent
                    radius: Services.Sizes.innerR
                    color: tray.open ? Services.Colors.ghost : Services.Colors.fillRest
                    gradient: Services.Prefs.useGradients && tray.open ? Services.Colors.accentGradient : null
                    Behavior on color { Widgets.ColorAnim { speed: Services.Sizes.msMicro } }
                }
                Text {
                    textFormat: Text.PlainText
                    anchors.centerIn: parent
                    text: ""
                    rotation: tray.open ? 45 : 0
                    Behavior on rotation { Widgets.Anim {} }
                    color: tray.open ? Services.Colors.accentText
                         : trayHover.containsMouse ? Services.Colors.snow
                         : Services.Colors.mist
                    font.pixelSize: 20
                    font.family: "Material Symbols Rounded"
                    Behavior on color { Widgets.ColorAnim { speed: Services.Sizes.msMicro } }
                }
                scale: Services.Sizes.hoverScale(trayHover.containsMouse, trayHover.pressed)
                Behavior on scale { Widgets.Anim { speed: Services.Sizes.pillHoverMs } }

                Widgets.Tip { target: tray; text: Services.I18n.t("widget.widgets"); show: trayHover.containsMouse }

                MouseArea {
                    id: trayHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Services.Desktop.trayOpen = !Services.Desktop.trayOpen
                }
            }

            // The way out, with the key that does the same.
            Item {
                id: done
                anchors.verticalCenter: parent.verticalCenter
                width: doneRow.implicitWidth + 20
                height: 30

                Rectangle {
                    anchors.fill: parent
                    radius: Services.Sizes.innerR
                    color: Services.Colors.ghost
                    gradient: Services.Prefs.useGradients ? Services.Colors.accentGradient : null
                }
                Row {
                    id: doneRow
                    anchors.centerIn: parent
                    spacing: 8
                    Text {
                        textFormat: Text.PlainText
                        anchors.verticalCenter: parent.verticalCenter
                        text: Services.I18n.t("common.done")
                        color: Services.Colors.accentText
                        font.pixelSize: Services.Sizes.fsBody
                        font.bold: true
                        font.family: "JetBrainsMono NF"
                    }
                    Text {
                        textFormat: Text.PlainText
                        anchors.verticalCenter: parent.verticalCenter
                        text: "esc"
                        color: Services.Colors.accentText
                        opacity: 0.6
                        font.pixelSize: Services.Sizes.fsMeta
                        font.family: "JetBrainsMono NF"
                    }
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
