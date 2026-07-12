import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

import "root:/services" as Services

Scope {
    id: root

    IpcHandler {
        target: "wallpaper"
        function open() {
            Services.AppState.closeBigOverlays()
            Services.AppState.wallpaperVisible = true
            wallpaperScanner.running = true
        }
    }

    PanelWindow {
        id: win
        anchors { top: true; left: true; right: true; bottom: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        visible: Services.AppState.wallpaperVisible

        WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        property var wallpapers: []
        property int currentIndex: 0
        readonly property real skew: -0.16
        readonly property real cardH: Math.min(200, height * 0.2)
        readonly property real cardW: 340
        readonly property real bandHeight: cardH + 20

        onVisibleChanged: {
            if (visible) {
                wallpaperScanner.running = true
                focusItem.forceActiveFocus()
            }
        }

        Process {
            id: wallpaperScanner
            command: ["sh", "-c", "ls /home/adolf-arch/Pictures/wallpapers/ | grep -E '\\.(png|jpg|jpeg|webp)$' | sed 's|^|/home/adolf-arch/Pictures/wallpapers/|' | sort"]
            running: false
            stdout: StdioCollector {
                onStreamFinished: {
                    let files = text.trim().split("\n").filter(f => f.length > 0)
                    win.wallpapers = files
                    win.currentIndex = 0
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.0)
            MouseArea {
                anchors.fill: parent
                onClicked: Services.AppState.wallpaperVisible = false
            }
        }

        FocusScope {
            id: focusItem
            anchors.fill: parent
            focus: true

            Keys.onLeftPressed: {
                if (win.currentIndex > 0) win.currentIndex--
                else win.currentIndex = win.wallpapers.length - 1
                view.currentIndex = win.currentIndex
            }
            Keys.onRightPressed: {
                if (win.currentIndex < win.wallpapers.length - 1) win.currentIndex++
                else win.currentIndex = 0
                view.currentIndex = win.currentIndex
            }
            Keys.onReturnPressed: {
                if (win.wallpapers.length > 0) {
                    Quickshell.execDetached(["sh", "-c", "awww img \"" + win.wallpapers[win.currentIndex] + "\" --transition-type random --transition-duration 0.6 --transition-fps 60 && [ \"$(cat /home/adolf-arch/.cache/ashen_scheme_mode.txt 2>/dev/null)\" = \"dynamic\" ] && matugen image \"" + win.wallpapers[win.currentIndex] + "\" --mode dark --source-color-index 0 --type \"$(cat /home/adolf-arch/.cache/ashen_dynamic_type.txt 2>/dev/null || echo scheme-tonal-spot)\""])
                    Services.AppState.wallpaperVisible = false
                }
            }
            Keys.onEscapePressed: Services.AppState.wallpaperVisible = false
        }

        // FIX: pills Theme/Add ahora ancladas al nivel del titulo del archivo
        // (band.top), no arriba de toda la pantalla
        Row {
            anchors.bottom: band.top
            anchors.bottomMargin: 14
            anchors.left: parent.left
            anchors.leftMargin: 16
            spacing: 8
            z: 30

            Rectangle {
                height: 30
                width: themeRow.implicitWidth + 16
                radius: 8
                color: Services.Colors.surfaceAlpha(0.85)
                border.color: Services.Colors.ghostAlpha(0.2)
                border.width: 1
                Row {
                    id: themeRow
                    anchors.centerIn: parent
                    spacing: 5
                    Text {
                        text: ""
                        color: Services.Colors.ghost
                        font.pixelSize: 12
                        font.family: "Material Symbols Rounded"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: "Wallpaper"
                        color: Services.Colors.mist
                        font.pixelSize: 11
                        font.family: "JetBrainsMono NF"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            Rectangle {
                height: 30
                width: addRow.implicitWidth + 16
                radius: 8
                color: Services.Colors.surfaceAlpha(0.85)
                border.color: Services.Colors.ghostAlpha(0.2)
                border.width: 1
                Row {
                    id: addRow
                    anchors.centerIn: parent
                    spacing: 5
                    Text {
                        text: ""
                        color: Services.Colors.ghost
                        font.pixelSize: 12
                        font.family: "Material Symbols Rounded"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: "Add"
                        color: Services.Colors.mist
                        font.pixelSize: 11
                        font.family: "JetBrainsMono NF"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onEntered: parent.color = Services.Colors.ghostAlpha(0.3)
                    onExited: parent.color = Services.Colors.surfaceAlpha(0.85)
                    onClicked: Quickshell.execDetached(["sh", "-c", "nemo /home/adolf-arch/Pictures/wallpapers"])
                }
            }
        }

        Item {
            id: band
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 56
            height: win.bandHeight
            clip: true
            z: 10

            ListView {
                id: view
                anchors.fill: parent
                orientation: ListView.Horizontal
                clip: false
                spacing: 0
                model: win.wallpapers.length
                currentIndex: win.currentIndex

                highlightRangeMode: ListView.StrictlyEnforceRange
                preferredHighlightBegin: width / 2 - win.cardW / 2
                preferredHighlightEnd: width / 2 + win.cardW / 2
                highlightMoveDuration: 160

                header: Item { width: view.width / 2 - win.cardW / 2 }
                footer: Item { width: view.width / 2 - win.cardW / 2 }

                onCurrentIndexChanged: win.currentIndex = currentIndex

                delegate: Item {
                    required property int index
                    property bool isCurrent: index === win.currentIndex
                    property real dist: index - win.currentIndex

                    width: win.cardW
                    height: view.height

                    Item {
                        id: cardRoot
                        width: win.cardW - 20
                        height: parent.isCurrent ? win.cardH : win.cardH * 0.82
                        anchors.centerIn: parent

                        scale: parent.isCurrent ? 1.0 : 0.9
                        opacity: parent.isCurrent ? 1.0 : Math.max(0.3, 1.0 - Math.abs(parent.dist) * 0.22)

                        Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                        Behavior on opacity { NumberAnimation { duration: 120 } }

                        transform: Matrix4x4 {
                            matrix: Qt.matrix4x4(
                                1, win.skew, 0, 0,
                                0, 1,        0, 0,
                                0, 0,        1, 0,
                                0, 0,        0, 1
                            )
                        }

                        Image {
                            id: img
                            anchors.fill: parent
                            source: win.wallpapers.length > index ? "file://" + win.wallpapers[index] : ""
                            sourceSize.width: 360
                           sourceSize.height: 240
                           fillMode: Image.PreserveAspectCrop
                            smooth: true
                            asynchronous: false
                            cache: true
                            visible: false
                        }

                        Rectangle {
                            id: maskRect
                            anchors.fill: parent
                            radius: 14
                            visible: false
                        }

                        OpacityMask {
                            anchors.fill: parent
                            source: img
                            maskSource: maskRect
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: 14
                            color: "transparent"
                            border.color: parent.parent.isCurrent ? Services.Colors.ghost : Qt.rgba(1,1,1,0.08)
                            border.width: parent.parent.isCurrent ? 2 : 1
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (parent.parent.isCurrent) {
                                    Quickshell.execDetached(["sh", "-c", "awww img \"" + win.wallpapers[win.currentIndex] + "\" --transition-type random --transition-duration 0.6 --transition-fps 60 && [ \"$(cat /home/adolf-arch/.cache/ashen_scheme_mode.txt 2>/dev/null)\" = \"dynamic\" ] && matugen image \"" + win.wallpapers[win.currentIndex] + "\" --mode dark --source-color-index 0 --type \"$(cat /home/adolf-arch/.cache/ashen_dynamic_type.txt 2>/dev/null || echo scheme-tonal-spot)\""])
                                    Services.AppState.wallpaperVisible = false
                                } else {
                                    win.currentIndex = index
                                    view.currentIndex = index
                                }
                            }
                        }
                    }
                }
            }
        }

        Text {
            anchors.bottom: band.top
            anchors.bottomMargin: 10
            anchors.horizontalCenter: parent.horizontalCenter
            text: win.wallpapers.length > 0 ? win.wallpapers[win.currentIndex].split("/").pop() : ""
            color: Qt.rgba(1,1,1,0.55)
            font.pixelSize: 12
            font.family: "JetBrainsMono NF"
            z: 30
        }

        Row {
            anchors.top: band.bottom
            anchors.topMargin: 16
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8
            z: 30
            visible: win.wallpapers.length > 1

            Repeater {
                model: Math.min(win.wallpapers.length, 10)
                delegate: Rectangle {
                    required property int index
                    width: win.currentIndex === index ? 20 : 7
                    height: 7; radius: 4
                    color: win.currentIndex === index ? Services.Colors.ghost : Qt.rgba(1,1,1,0.2)
                    Behavior on width { NumberAnimation { duration: 200 } }
                    Behavior on color { ColorAnimation { duration: 200 } }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { win.currentIndex = index; view.currentIndex = index }
                    }
                }
            }
        }
    }
}
