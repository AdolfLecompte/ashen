import Quickshell
import Quickshell.Services.SystemTray
import QtQuick
import Qt5Compat.GraphicalEffects

import "root:/services" as Services
import "root:/modules/widgets" as Widgets

Rectangle {
    id: root

    // How this pill draws itself, chosen in Settings > Bar > Layout.
    readonly property string content: Services.Pills.contentOf("tray")
    readonly property bool outlined: Services.Pills.isOutlined("tray")
    readonly property bool vertical: Services.Sizes.barVertical
    height: root.vertical ? trayRow.height + 16 : Services.Sizes.pillH
    radius: Services.Sizes.pillR
    border.color: Services.Colors.fillOutline
    border.width: root.outlined ? Services.Sizes.outlineW : 0
    color: root.outlined ? Services.Colors.surfaceGlass : (Services.Colors.pillPlate)
    width: root.vertical ? Services.Sizes.pillH : trayRow.width + 16
    // An empty tray still measures its 16 px of padding, and a slot kept for
    // that is a hole in the row. `wanted` and not `visible`: read back, an
    // item's `visible` reports its parent's state too.
    readonly property bool wanted: SystemTray.items.values.filter(i => !isSystemItem(i.id)).length > 0
    visible: root.wanted

    function isSystemItem(id) {
        let excluded = ["blueman", "nm-applet", "networkmanager", "bluetooth", "pulseaudio", "pipewire"]
        return excluded.some(e => id.toLowerCase().includes(e))
    }

    BarStrip {
        id: trayRow
        anchors.centerIn: parent
        spacing: 6

        Repeater {
            model: SystemTray.items
            delegate: Item {
                required property SystemTrayItem modelData
                width: visible ? 26 : 0
                height: 26
                visible: !root.isSystemItem(modelData.id)

                // A tray icon is somebody else's artwork: keep its own colours.
                // Flattening it to one colour destroyed multi-tone icons (Discord
                // came out with outline and fill the same shade). Hover lifts it
                // instead: grows and brightens.
                Image {
                    id: trayIcon
                    anchors.centerIn: parent
                    source: modelData.icon
                    width: 24; height: 24
                    // render at 2x and downscale: tray icons ship small pixmaps
                    // and look mushy when Qt upscales them
                    sourceSize: Qt.size(48, 48)
                    smooth: true
                    mipmap: true

                    opacity: trayHover.containsMouse ? 1.0 : 0.88
                    Behavior on opacity { NumberAnimation { duration: Services.Sizes.pillHoverMs } }
                    scale: Services.Sizes.hoverScale(trayHover.containsMouse, trayHover.pressed)
                    Behavior on scale { NumberAnimation { duration: Services.Sizes.pillHoverMs; easing.type: Services.Sizes.easeOut } }

                    layer.enabled: trayHover.containsMouse
                    layer.effect: BrightnessContrast { brightness: 0.22 }
                }
                MouseArea {
                    id: trayHover
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: (mouse) => {
                        // In the LAYOUT, not in the window: on a monitor at
                        // x=1920 this comes back 1920 too far and the menu was
                        // pinned to that screen's right edge. Same correction
                        // as PillCenter.
                        let g = parent.mapToGlobal(parent.width / 2, 0)
                        let sc = QsWindow.window ? QsWindow.window.screen : null
                        g = { x: g.x - (sc ? sc.x : 0), y: g.y - (sc ? sc.y : 0) }
                        // onlyMenu items have no primary action, so a left click
                        // has to open the menu too or they do nothing at all
                        let wantsMenu = mouse.button === Qt.RightButton || modelData.onlyMenu
                        if (wantsMenu && modelData.hasMenu)
                            Services.AppState.openTrayMenu(modelData, g.x, g.y + parent.height / 2)
                        else if (mouse.button === Qt.LeftButton)
                            modelData.activate()
                    }
                }
            }
        }
    }
}
