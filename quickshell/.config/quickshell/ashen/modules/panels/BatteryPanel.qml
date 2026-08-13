import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "root:/services" as Services
import "root:/modules/widgets" as Widgets

PanelWindow {
    id: win
    anchors { top: true; left: true; right: true; bottom: true }
    screen: Services.Screens.active
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    // Everything but the bar's strip: a click on a pill has to reach it,
    // or changing panels costs two. See widgets/ShellMask.qml.
    mask: Widgets.ShellMask { winW: win.width; winH: win.height }
    // stays mapped through the close animation, so the exit plays in reverse
    readonly property bool shown: Services.AppState.batteryVisible
    visible: shown || closeDelay.running
    // Mapped until the drop is all the way home; see DropCard.closeMs.
    Timer { id: closeDelay; interval: card.closeMs }

    // The vessel is held empty until the card is really on screen, then the
    // water climbs to the charge; LiquidPane does the sweep off this flag.
    property bool battArmed: false
    // Holds the sweep until the card's contents are on screen, so the whole
    // 0->level trace is seen. It has to clear the drop's wait for the window
    // plus the pause before the contents fade in.
    Timer {
        id: openDelay
        interval: Services.Sizes.panelArmMs + 360
        onTriggered: win.battArmed = true
    }

    property string timeRemaining: "--"
    property var availableProfiles: []
    property string activeProfile: ""

    function refreshBattery() { battProc.running = true }
    function refreshProfiles() { profProc.running = true }
    onShownChanged: {
        if (shown) { refreshBattery(); refreshProfiles(); win.battArmed = false; openDelay.restart() }
        else { win.battArmed = false; closeDelay.restart() }
    }

    function setProfile(name) {
        if (!win.availableProfiles.includes(name)) return
        Quickshell.execDetached(["sh", "-c", "powerprofilesctl set " + name])
        win.activeProfile = name
    }

    Process {
        id: battProc
        command: ["sh", "-c", "upower -i $(upower -e | grep BAT) 2>/dev/null | grep -E 'time to (empty|full)'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let line = text.trim()
                if (line.length > 0) {
                    let parts = line.split(":")
                    win.timeRemaining = parts.length > 1 ? parts.slice(1).join(":").trim() : "--"
                } else {
                    win.timeRemaining = "--"
                }
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
                    if (m) {
                        profiles.push(m[2])
                        if (m[1] === "*") active = m[2]
                    }
                }
                win.availableProfiles = profiles
                win.activeProfile = active
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        // Off while the panel is closing: the window stays mapped for the
        // animation, and a live dismiss layer ate the next click.
        enabled: Services.AppState.batteryVisible
        onClicked: Services.AppState.batteryVisible = false
    }

    // Grows out of its chip when the chip is on the bar; unfolds where it
    // lives when the chip is hidden.
    Widgets.PanelHost {
        id: card
        shown: Services.AppState.batteryVisible
        pillKey: "battery"
        pillCX: Services.AppState.batteryPillCenterX
        pillCY: Services.AppState.batteryPillCenterY
        pillW: Services.AppState.batteryPillW
        pillH: Services.AppState.batteryPillH
        pillActive: Services.Battery.charging
        pillGlyph: Services.AppState.pillGlyph("battery")
        pillLabel: Services.AppState.pillLabel("battery")
        openW: 440
        openH: 340
        cardRadius: 18

        body: Component {
            Item {
                // Where the chip's glyph and reading land.
                readonly property Item glyphTarget: gauge.glyphItem
                readonly property Item labelTarget: gauge.labelItem

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 12

                    // The charge as water in a vessel, the same one sound got:
                    // it climbs from empty when the card lands, and the state
                    // and the reading standing in it are re-inked where the
                    // water has passed them.
                    Widgets.LiquidPane {
                        id: gauge
                        Layout.fillWidth: true
                        Layout.preferredHeight: 150
                        value: Math.max(0, Math.min(1, Services.Battery.level / 100))
                        // Accent at every level, never red: error_ is for things
                        // that actually went wrong, and a low battery is the panel
                        // doing its job. The old gauge made the same choice.
                        fillColor: Services.Colors.ghost
                        // Charging is the one state here that is still happening
                        // rather than simply being: the surface keeps moving and
                        // the vessel breathes, the way the dial's halo did.
                        lively: Services.Battery.charging
                        glow: Services.Battery.charging
                        armed: win.battArmed
                        sweepMs: 1500

                        readonly property Item glyphItem: battGlyph
                        readonly property Item labelItem: battLabel

                        // Charging state and time to full/empty, in the water.
                        Row {
                            x: 18
                            y: 16
                            width: parent.width - 36
                            spacing: 8

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: Services.Battery.charging
                                text: "\uea0b"
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 16
                                color: Services.Colors.snow
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: Services.Battery.charging ? "Charging" : "On battery"
                                color: Services.Colors.snow
                                font.pixelSize: 13
                                font.bold: true
                                font.family: "JetBrainsMono NF"
                            }
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: 18
                            y: 18
                            text: win.timeRemaining !== "--"
                                ? (Services.Battery.charging ? ("Full in " + win.timeRemaining) : (win.timeRemaining + " left"))
                                : (Services.Battery.charging ? "Fully charged" : "Calculating...")
                            color: Services.Colors.mist
                            font.pixelSize: 11
                            font.bold: true
                            font.family: "JetBrainsMono NF"
                        }

                        // The reading sits low, where the water reaches it first.
                        Row {
                            x: 18
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 16
                            spacing: 10

                            Text {
                                id: battGlyph
                                anchors.verticalCenter: parent.verticalCenter
                                text: Services.AppState.pillGlyph("battery")
                                visible: !card.morphingGlyph
                                color: Services.Colors.snow
                                font.pixelSize: 30
                                font.family: "Material Symbols Rounded"
                            }
                            Text {
                                id: battLabel
                                anchors.verticalCenter: parent.verticalCenter
                                text: Math.round(gauge.frac * 100) + "%"
                                visible: !card.morphingLabel
                                color: Services.Colors.snow
                                font.pixelSize: 40
                                font.bold: true
                                font.family: "JetBrainsMono NF"
                            }
                        }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: Services.Colors.ghostAlpha(0.15) }

                    Text {
                        text: "POWER PROFILE"
                        color: Services.Colors.ash
                        font.pixelSize: 10
                        font.family: "JetBrainsMono NF"
                        font.letterSpacing: 1
                    }

                    Item {
                        id: profSelect
                        Layout.fillWidth: true
                        Layout.preferredHeight: 64
                        property Item activeProf: null

                        // Sliding highlight behind the active profile (workspace-style)
                        Rectangle {
                            visible: profSelect.activeProf !== null
                            x: profSelect.activeProf ? profSelect.activeProf.x : 0
                            width: profSelect.activeProf ? profSelect.activeProf.width : 0
                            height: 64
                            radius: 12
                            color: Services.Colors.ghost
                            gradient: Services.Prefs.useGradients ? Services.Colors.accentGradient : null
                            Behavior on x { SmoothedAnimation { duration: Services.Sizes.msPronounced } }
                        }

                        RowLayout {
                        anchors.fill: parent
                        spacing: 10

                        Repeater {
                            model: [
                                { id: "power-saver", icon: "" },
                                { id: "balanced", icon: "" },
                                { id: "performance", icon: "" },
                            ]
                            delegate: Rectangle {
                                required property var modelData
                                property bool available: win.availableProfiles.includes(modelData.id)
                                readonly property bool active: win.activeProfile === modelData.id
                                onActiveChanged: if (active) profSelect.activeProf = this
                                Component.onCompleted: if (active) profSelect.activeProf = this
                                Layout.fillWidth: true
                                height: 64
                                radius: 12
                                // Only the sliding indicator carries the active fill;
                                // idle slots are bare (hover just brightens them).
                                color: active ? "transparent"
                                    : profHover.containsMouse ? Services.Colors.ghostAlpha(0.12) : "transparent"
                                opacity: available ? 1.0 : 0.35
                                Behavior on color { ColorAnimation { duration: Services.Sizes.msMicro } }

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.icon
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 28
                                    color: active ? Services.Colors.accentText : Services.Colors.mist
                                }

                                MouseArea {
                                    id: profHover
                                    anchors.fill: parent
                                    hoverEnabled: parent.available
                                    cursorShape: parent.available ? Qt.PointingHandCursor : Qt.ForbiddenCursor
                                    enabled: parent.available
                                    onClicked: win.setProfile(modelData.id)
                                }
                            }
                        }
                    }
                    }
                }
            }
        }
    }
}