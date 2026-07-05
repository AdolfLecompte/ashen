import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

Row {
    id: root
    spacing: 6

    readonly property int pillRadius: 10
    readonly property int innerRadius: 8
    readonly property int pillHeight: 44
    readonly property int innerHeight: 32
    readonly property int pillPadding: 8
    readonly property color pillBg: Qt.rgba(0x1d/255, 0x1d/255, 0x24/255, 0.82)
    readonly property color pillBorder: Qt.rgba(0x24/255, 0x24/255, 0x2d/255, 0.5)

    property var activeSpecial: {
        let specials = Hyprland.workspaces.values.filter(w => w.id < 0)
        if (specials.length === 0) return null
        return specials[0]
    }
    property bool inSpecial: activeSpecial !== null
    property string specialName: inSpecial ? activeSpecial.name.replace("special:", "") : ""

    function specialIcon(name) {
        if (name === "music")   return ""
        if (name === "discord") return ""
        if (name === "notes")   return ""
        if (name === "term")    return ""
        if (name === "fav")     return ""
        return ""
    }

    // Launcher
    Rectangle {
        width: root.pillHeight; height: root.pillHeight
        radius: root.pillRadius
        color: root.pillBg
        border.color: root.pillBorder
        border.width: 1
        Text {
            anchors.centerIn: parent
            text: ""
            color: "#6272a4"
            font.pixelSize: 22
            font.family: "Material Symbols Rounded"
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
        }
    }

    // Workspaces normales
    Rectangle {
        height: root.pillHeight
        radius: root.pillRadius
        color: root.pillBg
        border.color: root.pillBorder
        border.width: 1
        width: wsRow.width + root.pillPadding * 2
        opacity: root.inSpecial ? 0.4 : 1.0
        Behavior on opacity { NumberAnimation { duration: 200 } }

        Rectangle {
            id: slideIndicator
            width: root.innerHeight; height: root.innerHeight
            radius: root.innerRadius
            color: "#6272a4"
            y: (root.pillHeight - root.innerHeight) / 2
            x: {
                let focused = Hyprland.focusedWorkspace
                if (!focused) return root.pillPadding
                let base = Math.floor((focused.id - 1) / 5) * 5
                let idx = focused.id - base - 1
                return root.pillPadding + idx * (root.innerHeight + 4)
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
                    width: root.innerHeight; height: root.innerHeight

                    Rectangle {
                        anchors.fill: parent
                        radius: root.innerRadius
                        color: "#6272a4"
                        opacity: parent.hasWindows && !parent.isActive ? 0.15 : 0
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: wsId
                        color: parent.isActive ? "#0f0f12" : "#7878a0"
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
                        onClicked: { var id = wsId; Quickshell.execDetached(["sh", "-c", "hyprctl dispatch workspace " + id]) }
                    }
                }
            }
        }
    }

    // Special workspace pill
    Rectangle {
        height: root.pillHeight
        radius: root.pillRadius
        color: "#6272a4"
        width: root.inSpecial ? (root.innerHeight + root.pillPadding * 2) : 0
        opacity: root.inSpecial ? 1.0 : 0.0
        clip: true
        Behavior on width { SmoothedAnimation { duration: 250 } }
        Behavior on opacity { NumberAnimation { duration: 200 } }

        Text {
            anchors.centerIn: parent
            text: root.specialIcon(root.specialName)
            color: "#0f0f12"
            font.pixelSize: 20
            font.family: "Material Symbols Rounded"
            opacity: root.inSpecial ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Quickshell.execDetached(["sh", "-c", "hyprctl dispatch togglespecialworkspace " + root.specialName])
        }
    }
}
