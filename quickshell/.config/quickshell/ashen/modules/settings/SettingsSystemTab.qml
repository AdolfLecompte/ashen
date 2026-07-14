import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "root:/services" as Services

Item {
    anchors.fill: parent

    Flickable {
        anchors.fill: parent
        anchors.margins: 28
        contentHeight: col.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded; width: 4 }

        ColumnLayout {
            id: col
            width: parent.width
            spacing: 14

            property string timeRemaining: "--"
            property var availableProfiles: []
            property string activeProfile: ""

            function setProfile(name) {
                if (!availableProfiles.includes(name)) return
                Quickshell.execDetached(["sh", "-c", "powerprofilesctl set " + name])
                activeProfile = name
            }

            Component.onCompleted: {
                battProc.running = true
                profProc.running = true
            }

            Process {
                id: battProc
                command: ["sh", "-c", "upower -i $(upower -e | grep BAT) 2>/dev/null | grep -E 'time to (empty|full)'"]
                running: false
                stdout: StdioCollector {
                    onStreamFinished: {
                        let line = text.trim()
                        col.timeRemaining = line.length > 0 ? line.split(":").slice(1).join(":").trim() : "--"
                    }
                }
            }
            Process {
                id: profProc
                command: ["sh", "-c", "powerprofilesctl list"]
                running: false
                stdout: StdioCollector {
                    onStreamFinished: {
                        let lines = text.split("\n")
                        let profiles = []
                        let active = ""
                        for (let line of lines) {
                            let m = line.match(/^\s*(\*?)\s*([\w-]+):$/)
                            if (m) { profiles.push(m[2]); if (m[1] === "*") active = m[2] }
                        }
                        col.availableProfiles = profiles
                        col.activeProfile = active
                    }
                }
            }

            Text {
                text: "System"
                color: Services.Colors.snow
                font.pixelSize: 20
                font.bold: true
                font.family: "JetBrainsMono NF"
            }

            RowLayout {
                spacing: 14
                Text {
                    text: Services.Battery.level + "%"
                    color: Services.Colors.snow
                    font.pixelSize: 24
                    font.bold: true
                    font.family: "JetBrainsMono NF"
                }
                ColumnLayout {
                    spacing: 2
                    Text {
                        text: Services.Battery.charging ? "Charging" : "On battery"
                        color: Services.Colors.mist
                        font.pixelSize: 11
                        font.family: "JetBrainsMono NF"
                    }
                    Text {
                        text: col.timeRemaining !== "--" ? col.timeRemaining : (Services.Battery.charging ? "Fully charged" : "Calculating...")
                        color: Services.Colors.ash
                        font.pixelSize: 10
                        font.family: "JetBrainsMono NF"
                    }
                }
            }

            Text {
                text: "Power Profile"
                color: Services.Colors.mist
                font.pixelSize: 11
                font.family: "JetBrainsMono NF"
            }

            RowLayout {
                spacing: 10
                Repeater {
                    model: [
                        { id: "power-saver", icon: "\uec1a", label: "Saver" },
                        { id: "balanced", icon: "\ueaf6", label: "Balanced" },
                        { id: "performance", icon: "\ueb9b", label: "Performance" },
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        property bool available: col.availableProfiles.includes(modelData.id)
                        width: 100; height: 64
                        radius: 12
                        color: col.activeProfile === modelData.id ? Services.Colors.ghost : Services.Colors.ghostAlpha(0.12)
                        opacity: available ? 1.0 : 0.35
                        Behavior on color { ColorAnimation { duration: 150 } }
                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 4
                            Text {
                                text: modelData.icon
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 20
                                color: col.activeProfile === modelData.id ? Services.Colors.abyss : Services.Colors.mist
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Text {
                                text: modelData.label
                                font.pixelSize: 10
                                font.family: "JetBrainsMono NF"
                                color: col.activeProfile === modelData.id ? Services.Colors.abyss : Services.Colors.mist
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: parent.available ? Qt.PointingHandCursor : Qt.ForbiddenCursor
                            enabled: parent.available
                            onClicked: col.setProfile(modelData.id)
                        }
                    }
                }
            }

            Item { Layout.preferredHeight: 8 }
        }
    }
}
