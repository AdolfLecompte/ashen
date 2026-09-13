import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "root:/services" as Services
import "root:/modules/widgets" as Widgets

PanelWindow {
    id: win
    property string emptyLine: Services.Voice.pick("battery.noHistory")
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

    // The line is held flat until the card has stopped travelling and opened
    // out, then it draws itself in with the rest of the contents. Armed any
    // earlier the whole 0->level trace played behind a box that had not
    // revealed its contents yet.
    property bool battArmed: false
    Timer {
        id: openDelay
        interval: Services.Sizes.panelArmMs + 350
        onTriggered: win.battArmed = true
    }

    // The curve, resampled to one slot per 40 minutes of the last day. Held
    // empty until armed so the line grows in rather than being there already.
    readonly property var plotted: win.battArmed ? Services.Battery.plot(36) : []


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
            font.pixelSize: 17
            font.bold: true
            font.family: "JetBrainsMono NF"
            Layout.alignment: Qt.AlignVCenter
        }
    }

    property var availableProfiles: []
    property string activeProfile: ""

    function refreshBattery() { Services.Battery.refreshTime() }
    function refreshProfiles() { profProc.running = true }
    onShownChanged: {
        if (shown) {
            refreshBattery(); refreshProfiles()
            // Picked on the open, never in the binding: a line that re-sorts
            // itself while the panel is up reads as a list still thinking.
            win.emptyLine = Services.Voice.pick("battery.noHistory")
            win.battArmed = false; openDelay.restart()
        }
        else { win.battArmed = false; closeDelay.restart() }
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
        openH: 372
        cardRadius: 18

        body: Component {
            Item {
                // Where the chip's glyph and reading land.
                readonly property Item glyphTarget: battGlyph
                readonly property Item labelTarget: battLabel

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 12

                    // ── The reading ──────────────────────────────────────
                    // The number is the headline and the accent is the LINE
                    // below it, not a slab behind it: full, the old vessel was
                    // 400x150 of flat accent and the water it was meant to show
                    // had nowhere left to rise.
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

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

                        Item { Layout.fillWidth: true }

                        // How long, and which way: a bare "2h 06" did not say whether
                        // that was until full or until empty, and that is the one
                        // reading on this card you actually plan around.
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
                    }

                    // ── The last day ─────────────────────────────────────
                    // The same stepped line the weather and the CPU use: this
                    // is a past, and a past is drawn as a past. Sunk into its
                    // own plate so the line has a floor to stand on.
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 80
                        radius: Services.Sizes.cardR
                        color: Services.Colors.fillInset


                        Widgets.Trend {
                            id: curve
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            anchors.bottomMargin: 12
                            height: 56
                            stepped: true
                            maxValue: 100
                            values: win.plotted
                            color_: Services.Colors.ghost
                            // The day draws itself in, oldest hour first. Linear
                            // on purpose: an ease front-loads the trace and the
                            // duration stops being felt (same lesson as the
                            // gauge's sweep).
                            reveal: win.battArmed && win.plotted.length > 1 ? 1 : 0
                            Behavior on reveal {
                                NumberAnimation { duration: 1100; easing.type: Easing.Linear }
                            }
                        }

                        // Nothing to draw is worth saying so: an empty plate
                        // reads as a bug, and this one is empty on a machine
                        // whose upower history is not readable.
                        Widgets.SaidLine {
                            anchors.centerIn: curve
                            visible: win.battArmed && win.plotted.length === 0
                            line: win.emptyLine
                            // A hole prints whole; only waits type.
                            msPerChar: 0
                            armed: win.shown
                            color: Services.Colors.ash
                            font.pixelSize: 11
                        }
                    }

                    // ── What the pack IS ─────────────────────────────────
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Fact {
                            Layout.fillWidth: true
                            glyph: "\ue87d"      // favorite: what the pack still holds
                            value: Services.Battery.health > 0
                                ? Services.Battery.health + "%" : "--"
                        }
                        Fact {
                            Layout.fillWidth: true
                            glyph: "\ue863"      // autorenew: charge cycles
                            value: Services.Battery.cycles > 0
                                ? String(Services.Battery.cycles) : "--"
                        }
                        Fact {
                            Layout.fillWidth: true
                            glyph: "\uea0b"      // bolt: watts, in or out
                            value: Services.Battery.hasRate
                                ? Services.Battery.watts.toFixed(1) + " W" : "--"
                        }
                    }

                    Widgets.Divider {}

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
                                radius: 12
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

                    // ── Game mode ────────────────────────────────────────
                    // Its own row, not a fourth chip beside the profiles: it is
                    // not a power profile, and standing in that row would say it
                    // was one of three you pick between.

                    Rectangle {
                        id: gameChip
                        Layout.fillWidth: true
                        Layout.preferredHeight: 52
                        radius: 12
                        // On, it wears the accent the way the chosen profile
                        // above does. Off it rests on a plate, unlike the
                        // profiles: those are three faces in a row and read as
                        // a choice on their own, while one glyph floating in an
                        // empty band does not read as a button at all. Hover
                        // only brightens and grows it -- it never adds a fill.
                        color: Services.Game.on ? Services.Colors.ghost : Services.Colors.fillRest
                        gradient: Services.Prefs.useGradients && Services.Game.on
                                  ? Services.Colors.accentGradient : null
                        Behavior on color { Widgets.ColorAnim { speed: Services.Sizes.msMicro } }
                        scale: gameHover.containsMouse ? 1.02 : 1.0
                        Behavior on scale { Widgets.Anim { speed: Services.Sizes.msMicro } }

                        Text {
                            textFormat: Text.PlainText
                            anchors.centerIn: parent
                            text: "\uf135"
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 24
                            color: Services.Game.on ? Services.Colors.accentText
                                 : gameHover.containsMouse ? Services.Colors.snow
                                 : Services.Colors.mist
                            Behavior on color { Widgets.ColorAnim { speed: Services.Sizes.msMicro } }
                        }

                        MouseArea {
                            id: gameHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Services.Game.toggle()
                        }
                    }
                }
            }
        }
    }
}
