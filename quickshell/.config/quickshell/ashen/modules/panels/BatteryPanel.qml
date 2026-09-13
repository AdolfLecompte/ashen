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

    // How much of the last day there actually is. A pack that has only been
    // watched for two hours must not draw those two hours as a full day.
    readonly property string spanText: {
        const s = Services.Battery.series
        if (s.length < 2) return ""
        const hours = (Date.now() / 1000 - s[0].t) / 3600
        // Only worth saying when the window is genuinely short: an hour missing
        // off a day is not news.
        if (hours >= Services.Battery.seriesHours - 2) return ""
        return hours < 1 ? Math.round(hours * 60) + " min of it"
                         : Math.round(hours) + " h of it"
    }

    // A caption, a number and a footnote. Three of them stand in a row under
    // the curve; the shape is the panel's, so it lives here and not in widgets.
    component Fact: ColumnLayout {
        property string caption: ""
        property string value: ""
        property string note: ""
        spacing: 1
        Text {
            text: parent.caption
            color: Services.Colors.ash
            font.pixelSize: 9
            font.bold: true
            font.letterSpacing: 1
            font.family: "JetBrainsMono NF"
        }
        Text {
            text: parent.value
            color: Services.Colors.snow
            font.pixelSize: 17
            font.bold: true
            font.family: "JetBrainsMono NF"
        }
        Text {
            visible: text !== ""
            text: parent.note
            color: Services.Colors.mist
            font.pixelSize: 9
            font.family: "JetBrainsMono NF"
            elide: Text.ElideRight
            Layout.fillWidth: true
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
        // 396 was the card before game mode: its heading and chip add a
        // 12 gap, a 13 line, another 12 and 52 of chip.
        openH: 396 + 89
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

                        ColumnLayout {
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 2
                            Text {
                                Layout.alignment: Qt.AlignRight
                                text: Services.Battery.charging ? Services.I18n.t("battery.charging") : Services.I18n.t("battery.onBattery")
                                color: Services.Battery.charging ? Services.Colors.ghost
                                                                 : Services.Colors.mist
                                font.pixelSize: 10
                                font.bold: true
                                font.letterSpacing: 1
                                font.family: "JetBrainsMono NF"
                            }
                            Text {
                                Layout.alignment: Qt.AlignRight
                                // Only when it has something the line above does
                                // not already say: "CHARGING / Fully charged" is
                                // the same fact twice, and "Calculating..." is
                                // the panel talking about itself.
                                visible: text !== ""
                                text: Services.Battery.timeRemaining === "--" ? ""
                                    : Services.Battery.charging
                                        ? Services.I18n.t("battery.fullIn", { t: Services.Battery.timeRemaining })
                                        : Services.I18n.t("battery.left", { t: Services.Battery.timeRemaining })
                                color: Services.Colors.snow
                                font.pixelSize: 13
                                font.family: "JetBrainsMono NF"
                            }
                        }
                    }

                    // ── The last day ─────────────────────────────────────
                    // The same stepped line the weather and the CPU use: this
                    // is a past, and a past is drawn as a past. Sunk into its
                    // own plate so the line has a floor to stand on.
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 104
                        radius: Services.Sizes.cardR
                        color: Services.Colors.fillInset

                        Text {
                            x: 12; y: 10
                            text: Services.I18n.t("battery.last24")
                            color: Services.Colors.ash
                            font.pixelSize: 9
                            font.bold: true
                            font.letterSpacing: 1
                            font.family: "JetBrainsMono NF"
                        }
                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            y: 10
                            visible: win.spanText !== ""
                            text: win.spanText
                            color: Services.Colors.mist
                            font.pixelSize: 9
                            font.bold: true
                            font.family: "JetBrainsMono NF"
                        }

                        Widgets.Trend {
                            id: curve
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            anchors.bottomMargin: 12
                            height: 60
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
                            caption: Services.I18n.t("battery.health")
                            value: Services.Battery.health > 0
                                ? Services.Battery.health + "%" : "--"
                            // The two numbers the percentage is made of. The
                            // other facts only said their own caption again in
                            // words ("full charges", "Wh in it"); those are gone.
                            note: Services.Battery.energyDesign > 0
                                ? (Services.Battery.energyFull.toFixed(1) + " / "
                                   + Services.Battery.energyDesign.toFixed(1) + " Wh") : ""
                        }
                        Fact {
                            Layout.fillWidth: true
                            caption: Services.I18n.t("battery.cycles")
                            value: Services.Battery.cycles > 0
                                ? String(Services.Battery.cycles) : "--"
                        }
                        Fact {
                            Layout.fillWidth: true
                            // Full and plugged in, nothing is moving -- which
                            // is a reading, not a blank.
                            caption: !Services.Battery.charging ? Services.I18n.t("battery.drawing")
                                   : Services.Battery.watts > 0 ? Services.I18n.t("battery.goingIn") : Services.I18n.t("battery.toppedUp")
                            value: Services.Battery.hasRate
                                ? Services.Battery.watts.toFixed(1) + " W" : "--"
                        }
                    }

                    Widgets.Divider {}

                    Text {
                        text: Services.I18n.t("battery.profile")
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
                    // Its own heading, and not a fourth chip in the row above:
                    // it is not a power profile, it touches the compositor and
                    // not the governor, and sitting in that row would say it
                    // was one of three you pick between.
                    Text {
                        text: Services.I18n.t("battery.game")
                        color: Services.Colors.ash
                        font.pixelSize: 10
                        font.family: "JetBrainsMono NF"
                        font.letterSpacing: 1
                    }

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
