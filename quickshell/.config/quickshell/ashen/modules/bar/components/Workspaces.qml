import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

import "root:/services" as Services

Row {
    id: root
    spacing: 6

    readonly property int pillH: 44
    readonly property int innerH: 32
    readonly property int innerR: 8
    readonly property int pillR: 10
    readonly property int pad: 8

    property var activeSpecial: {
        let specials = Hyprland.workspaces.values.filter(w => w.id < 0)
        if (specials.length === 0) return null
        return specials[0]
    }
    property bool inSpecial: activeSpecial !== null
    property string specialName: inSpecial ? activeSpecial.name.replace("special:", "") : ""

    function specialIcon(name) {
        if (name === "music")   return "󿿘"
        if (name === "discord") return ""
        if (name === "notes")   return ""
        if (name === "term")    return "󿾋"
        if (name === "fav")     return ""
        return ""
    }

    // Launcher
    Rectangle {
        width: root.pillH; height: root.pillH
        radius: root.pillR
        color: Services.Colors.surfaceAlpha(0.82)
        border.color: Services.Colors.ghostAlpha(0.2)
        border.width: 1
        Text {
            anchors.centerIn: parent
            text: ""
            color: Services.Colors.ghost
            font.pixelSize: 22
            font.family: "Material Symbols Rounded"
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Services.AppState.launcherVisible = !Services.AppState.launcherVisible
        }
    }

    // Workspaces normales
    Rectangle {
        height: root.pillH
        radius: root.pillR
        color: Services.Colors.surfaceAlpha(0.82)
        border.color: Services.Colors.ghostAlpha(0.2)
        border.width: 1
        width: wsRow.width + root.pad * 2
        opacity: root.inSpecial ? 0.4 : 1.0
        Behavior on opacity { NumberAnimation { duration: 200 } }

        Rectangle {
            id: slideIndicator
            width: root.innerH; height: root.innerH
            radius: root.innerR
            color: Services.Colors.ghost
            y: (root.pillH - root.innerH) / 2
            x: {
                let focused = Hyprland.focusedWorkspace
                if (!focused) return root.pad
                let base = Math.floor((focused.id - 1) / 5) * 5
                let idx = focused.id - base - 1
                return root.pad + idx * (root.innerH + 4)
            }
            Behavior on x { SmoothedAnimation { duration: 250 } }
        }

        Row {
            id: wsRow
            anchors.centerIn: parent
            spacing: 4

            Repeater {
                model: 5
                delegate: Item {
                    required property int index
                    property int wsId: {
                        let focused = Hyprland.focusedWorkspace
                        if (!focused) return index + 1
                        let base = Math.floor((focused.id - 1) / 5) * 5
                        return base + index + 1
                    }
                    property bool isActive: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === wsId
                    property bool hasWindows: Hyprland.workspaces.values.find(w => w.id === wsId) !== undefined
                    width: root.innerH; height: root.innerH

                    Rectangle {
                        anchors.fill: parent
                        radius: root.innerR
                        color: Services.Colors.ghost
                        opacity: parent.hasWindows && !parent.isActive ? 0.2 : 0
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: wsId
                        color: parent.isActive ? Services.Colors.abyss : Services.Colors.ash
                        font.pixelSize: 13
                        font.family: "JetBrainsMono NF"
                        font.bold: parent.isActive
                        z: 1
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        z: 10
                        onClicked: { var id = wsId; Quickshell.execDetached(["sh", "-c", "hyprctl dispatch 'hl.dsp.focus({ workspace = " + id + " })'"]) }
                    }
                }
            }
        }
    }

    // Special workspace pill
    Rectangle {
        height: root.pillH
        radius: root.pillR
        color: Services.Colors.ghost
        width: root.inSpecial ? (root.innerH + root.pad * 2) : 0
        opacity: root.inSpecial ? 1.0 : 0.0
        clip: true
        Behavior on width { SmoothedAnimation { duration: 250 } }
        Behavior on opacity { NumberAnimation { duration: 200 } }

        Text {
            anchors.centerIn: parent
            text: root.specialIcon(root.specialName)
            color: Services.Colors.abyss
            font.pixelSize: 20
            font.family: "Material Symbols Rounded"
            opacity: root.inSpecial ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Quickshell.execDetached(["sh", "-c", "hyprctl dispatch 'hl.dsp.workspace.toggle_special(\"" + root.specialName + "\")'"])
        }
    }
}
