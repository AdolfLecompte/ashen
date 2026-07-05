import Quickshell
import Quickshell.Services.SystemTray
import QtQuick

import "root:/services" as Services

Rectangle {
    id: root
    height: 44
    radius: 10
    color: Services.Colors.surfaceAlpha(0.82)
    border.color: Services.Colors.ghostAlpha(0.2)
    border.width: 1
    width: trayRow.width + 16
    visible: SystemTray.items.values.filter(i => !isSystemItem(i.id)).length > 0

    function isSystemItem(id) {
        let excluded = ["blueman", "nm-applet", "networkmanager", "bluetooth", "pulseaudio", "pipewire"]
        return excluded.some(e => id.toLowerCase().includes(e))
    }

    Row {
        id: trayRow
        anchors.centerIn: parent
        spacing: 6

        Repeater {
            model: SystemTray.items
            delegate: Item {
                required property SystemTrayItem modelData
                width: visible ? 22 : 0
                height: 22
                visible: !root.isSystemItem(modelData.id)

                Image {
                    anchors.centerIn: parent
                    source: modelData.icon
                    width: 18; height: 18
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.LeftButton) modelData.activate()
                        else modelData.provideContext(Qt.point(x, y))
                    }
                }
            }
        }
    }
}
