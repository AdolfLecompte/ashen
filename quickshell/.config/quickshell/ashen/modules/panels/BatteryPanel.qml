import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "root:/services" as Services
import "root:/modules/widgets" as Widgets
import "root:/modules/settings/components" as Parts

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



    // A caption, a number and a footnote. Three of them stand in a row under
    // the curve; the shape is the panel's, so it lives here and not in widgets.
    // A glyph and a number. The captions were words in capitals over every
    // value -- HEALTH, CYCLES, GOING IN -- and a heart, a loop and a bolt say
    // the same at a glance.
    component Fact: RowLayout {
        property string glyph: ""
        property string value: ""
        spacing: 6
        Text {
            textFormat: Text.PlainText
            text: parent.glyph
            color: Services.Colors.ash
            font.pixelSize: 16
            font.family: "Material Symbols Rounded"
            Layout.alignment: Qt.AlignVCenter
        }
        Text {
            textFormat: Text.PlainText
            text: parent.value
            color: Services.Colors.snow
            font.pixelSize: Services.Sizes.fsSectionTitle
            font.bold: true
            font.family: "JetBrainsMono NF"
            Layout.alignment: Qt.AlignVCenter
        }
    }

    // Level change per hour from the live rate, in percent of a full pack.
    readonly property real ratePerHour: Services.Battery.hasRate && Services.Battery.energyFull > 0
        ? Services.Battery.watts / Services.Battery.energyFull * 100 : 0

    property var availableProfiles: []
    property string activeProfile: ""

    function refreshBattery() { Services.Battery.refreshTime() }
    function refreshProfiles() { profProc.running = true }
    onShownChanged: {
        if (shown) {
            refreshBattery(); refreshProfiles()
        }
        else closeDelay.restart()
    }

    function setProfile(name) {
        if (!win.availableProfiles.includes(name)) return
        Quickshell.execDetached(["sh", "-c", "powerprofilesctl set " + name])
        win.activeProfile = name
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
        // Measured to what it holds. A card taller than its column does not
        // leave the room at the bottom: the layout hands it out between every
        // row, which is the dead space that showed up once the headings went.
        openH: (card.bodyItem ? card.bodyItem.contentH : 0) + 40

        body: Component {
            Item {
                // Where the chip's glyph and reading land.
                readonly property Item glyphTarget: battGlyph
                readonly property Item labelTarget: battLabel
                readonly property real contentH: boardCol.implicitHeight

                ColumnLayout {
                    id: boardCol
                    x: 20
                    y: 20
                    width: parent.width - 40
                    spacing: 12

                    // ── The reading, and what the pack is ───────────────
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: heroCol.implicitHeight + 28
                            radius: Services.Sizes.cardLgR
                            color: Services.Colors.plate

                            ColumnLayout {
                                id: heroCol
                                x: 14
                                y: 14
                                width: parent.width - 28
                                spacing: 8

                                RowLayout {
                                    spacing: 10
                                Text {
                                    textFormat: Text.PlainText
                                    id: battGlyph
                                    Layout.alignment: Qt.AlignVCenter
                                    text: Services.AppState.pillGlyph("battery")
                                    visible: !card.morphingGlyph
                                    color: Services.Battery.charging ? Services.Colors.ghost
                                                                     : Services.Colors.snow
                                    font.pixelSize: 34
                                    font.family: "Material Symbols Rounded"
                                    Behavior on color { Widgets.ColorAnim {} }
                                }
                                Text {
                                    textFormat: Text.PlainText
                                    id: battLabel
                                    Layout.alignment: Qt.AlignVCenter
                                    text: Services.Battery.level + "%"
                                    visible: !card.morphingLabel
                                    color: Services.Colors.snow
                                    font.pixelSize: 44
                                    font.bold: true
                                    font.family: "JetBrainsMono NF"
                                }
                                }
                                Text {
                                    textFormat: Text.PlainText
                                    Layout.alignment: Qt.AlignVCenter
                                    visible: text !== ""
                                    text: Services.Battery.timeShort === "" ? ""
                                        : Services.Battery.charging
                                            ? Services.I18n.t("battery.fullIn", { t: Services.Battery.timeShort })
                                            : Services.I18n.t("battery.left", { t: Services.Battery.timeShort })
                                    color: Services.Battery.charging ? Services.Colors.ghost
                                                                     : Services.Colors.mist
                                    font.pixelSize: 15
                                    font.bold: true
                                    font.family: "JetBrainsMono NF"
                                }
                                Widgets.TickMeter {
                                    Layout.fillWidth: true
                                    height: 16
                                    mode: "level"
                                    value: Services.Battery.level / 100
                                    color_: Services.Battery.level <= 20 && !Services.Battery.charging
                                        ? Services.Colors.error_ : Services.Colors.ghost
                                }
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 140
                            Layout.fillHeight: true
                            radius: Services.Sizes.cardLgR
                            color: Services.Colors.plate

                            Column {
                                anchors.left: parent.left
                                anchors.leftMargin: 16
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 10
                                Fact {
                                    // How fast the level moves, per hour.
                                    glyph: Services.Battery.charging ? "\ue5d8" : "\ue5db"
                                    value: win.ratePerHour > 0 ? win.ratePerHour.toFixed(0) + " %/h" : "--"
                                }
                                Fact {
                                    glyph: "\ue87d"      // favorite: what the pack still holds
                                    value: Services.Battery.health > 0
                                        ? Services.Battery.health + "%" : "--"
                                }
                                Fact {
                                    glyph: "\ue863"      // autorenew: charge cycles
                                    value: Services.Battery.cycles > 0
                                        ? String(Services.Battery.cycles) : "--"
                                }
                            }
                        }
                    }

                    // ── Power: profiles and game mode ────────────────────
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: powCol.implicitHeight + 24
                        radius: Services.Sizes.cardLgR
                        color: Services.Colors.plate

                        ColumnLayout {
                            id: powCol
                            x: 12
                            y: 12
                            width: parent.width - 24
                            spacing: 10

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
                                    radius: Services.Sizes.cardR
                                    color: Services.Colors.ghost
                                    gradient: Services.Prefs.useGradients ? Services.Colors.accentGradient : null
                                    Behavior on x { SmoothedAnimation { duration: Services.Sizes.msPronounced } }
                                }

                                RowLayout {
                                anchors.fill: parent
                                spacing: 10

                                Repeater {
                                    model: [
                                    // Three faces and no words. Naming the power
                                    // profile on the chip was tried on 2026-08-11 and
                                    // rejected with the rest of the extra readings the
                                    // bar and its panels used to carry: the shell does
                                    // not caption its own icons. The names live in
                                    // Settings, which is where you go to be told.
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
                                        radius: Services.Sizes.cardR
                                        // Only the sliding indicator carries the active fill;
                                        // idle slots are bare -- hover only brightens them,
                                        // it never paints a plate.
                                        color: "transparent"
                                        opacity: available ? 1.0 : 0.35
                                        Behavior on color { Widgets.ColorAnim { speed: Services.Sizes.msMicro } }

                                            Column {
                                                anchors.centerIn: parent
                                                spacing: 3
                                                readonly property color tone: active ? Services.Colors.accentText
                                                    : profHover.containsMouse ? Services.Colors.snow
                                                    : Services.Colors.mist

                                                Text {
                                                    textFormat: Text.PlainText
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                    text: modelData.icon
                                                    font.family: "Material Symbols Rounded"
                                                    font.pixelSize: 24
                                                    color: parent.tone
                                                    Behavior on color { Widgets.ColorAnim { speed: Services.Sizes.msMicro } }
                                                }
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

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.leftMargin: 6
                                spacing: 10
                                Text {
                                    textFormat: Text.PlainText
                                    text: "\uf135"
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 20
                                    color: Services.Game.on ? Services.Colors.ghost : Services.Colors.mist
                                }
                                Text {
                                    textFormat: Text.PlainText
                                    Layout.fillWidth: true
                                    text: Services.I18n.t("settings.system.game")
                                    color: Services.Colors.snow
                                    font.pixelSize: Services.Sizes.fsInput
                                    font.family: "JetBrainsMono NF"
                                }
                                Parts.Toggle {
                                    checked: Services.Game.on
                                    onToggled: Services.Game.toggle()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
