import QtQuick
import "root:/services" as Services

// Stopwatch, countdown and pomodoro: the tools that used to be tabs inside the
// clock panel. Content only, hosted by TimerPanel.
Item {
    id: root

    property var stageFn: null
    function beat(i) { return root.stageFn ? root.stageFn(i) : 1 }

    implicitWidth: 520
    implicitHeight: 420
    width: implicitWidth
    height: implicitHeight

    // Aim the countdown without starting it. A second is the floor: the wheels
    // can be spun to 00:00:00, and a timer of no length is not a thing to hand
    // to a service that would just refuse it and leave the wheels lying.
    function aimAt(ms) { Services.Countdown.setPreset(Math.max(1000, ms)) }

    // The quickest lap taken so far, so the strip can point at it.
    readonly property real bestSplit: {
        let b = -1
        for (const l of Services.Stopwatch.laps)
            if (b < 0 || l.split < b) b = l.split
        return b
    }
    readonly property real worstSplit: {
        let w = 0
        for (const l of Services.Stopwatch.laps) w = Math.max(w, l.split)
        return w
    }
    readonly property real avgSplit: {
        const n = Services.Stopwatch.laps.length
        return n ? Services.Stopwatch.laps[n - 1].total / n : 0
    }

    // "ends at 14:32", for whatever is counting down; empty when nothing is.
    function endsAt(ms) {
        return Qt.formatTime(new Date(Date.now() + ms), Services.Prefs.clock24h ? "HH:mm" : "h:mm AP")
    }

    // One column of a hh:mm:ss picker. A ListView with its highlight range
    // nailed to the middle row IS a wheel -- no Controls dependency and no
    // hand-rolled flicking. Nothing here reads `preset` as a binding: the wheel
    // both follows it and writes it, so the follow has to be an assignment that
    // can be switched off while it is the one doing the writing.
    component Wheel: Item {
        id: wheel
        property int count: 60
        property int unitMs: 1000
        readonly property int rowH: 38
        // What this column's digits are worth in the current preset.
        readonly property int value: Math.floor(Services.Countdown.preset / unitMs) % count
        property bool syncing: false
        // Nothing this wheel does counts as an instruction until a hand has
        // moved it. A ListView settles its own currentIndex once it has a
        // geometry, well after Component.onCompleted -- three wheels each
        // reporting that settle as a choice is what turned a fresh 5-minute
        // preset into 01:01:01.
        property bool touched: false

        width: 66
        height: rowH * 3

        // Setting currentIndex is enough: StrictlyEnforceRange already drags the
        // view onto it. Calling positionViewAtIndex as well made the two fight
        // and land a row off -- three wheels each one step out is where a fresh
        // 5-minute preset came up as 01:01:01.
        function sync() {
            if (view.moving || view.dragging) return
            wheel.syncing = true
            view.currentIndex = wheel.value
            wheel.syncing = false
        }
        Component.onCompleted: wheel.sync()
        Connections {
            target: Services.Countdown
            function onPresetChanged() { wheel.sync() }
        }

        ListView {
            id: view
            anchors.fill: parent
            clip: true
            model: wheel.count
            orientation: ListView.Vertical
            snapMode: ListView.SnapToItem
            // The selected row is the middle one, always.
            highlightRangeMode: ListView.StrictlyEnforceRange
            preferredHighlightBegin: wheel.rowH
            preferredHighlightEnd: wheel.rowH * 2
            boundsBehavior: Flickable.StopAtBounds

            onMovementStarted: wheel.touched = true
            onCurrentIndexChanged: {
                if (wheel.syncing || !wheel.touched) return
                const cur = Services.Countdown.preset
                const mine = Math.floor(cur / wheel.unitMs) % wheel.count
                if (view.currentIndex === mine) return
                root.aimAt(cur + (view.currentIndex - mine) * wheel.unitMs)
            }

            delegate: Item {
                required property int index
                width: wheel.width
                height: wheel.rowH
                readonly property bool sel: index === view.currentIndex
                Text {
                    textFormat: Text.PlainText
                    anchors.centerIn: parent
                    text: (parent.index < 10 ? "0" : "") + parent.index
                    color: parent.sel ? Services.Colors.snow : Services.Colors.ash
                    opacity: parent.sel ? 1 : 0.55
                    font.pixelSize: parent.sel ? 34 : 24
                    font.bold: parent.sel
                    font.family: "JetBrainsMono NF"
                    Behavior on font.pixelSize { Anim { speed: Services.Sizes.msMicro } }
                    Behavior on opacity { Anim { speed: Services.Sizes.msMicro } }
                }
            }
        }
    }

    component WheelColon: Text {
        textFormat: Text.PlainText
        width: 14
        height: 114
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: ":"
        color: Services.Colors.mist
        font.pixelSize: 30
        font.bold: true
        font.family: "JetBrainsMono NF"
    }


    SlideSwap {
        id: toolSlide
        axis: "horizontal"
        index: Services.AppState.timerMode
        onCommit: root.shownTool = Services.AppState.timerMode
    }
    property int shownTool: Services.AppState.timerMode

    component Tool: Item {
        property int index: 0
        anchors.fill: parent
        opacity: root.shownTool === index ? root.beat(1) * toolSlide.fade : 0
        visible: opacity > 0.01
        transform: Translate { x: toolSlide.offX }
    }

    // ── Three tools ─────────────────────────────────────────────────────
    // Same strip as the sound panel: one track, one plate that slides.
    Item {
        id: tabs
        width: parent.width
        height: 30
        opacity: root.beat(0)

        readonly property real slotW: (width - 8) / 3

        Rectangle {
            width: tabs.slotW
            height: parent.height
            radius: Services.Sizes.innerR
            x: Services.AppState.timerMode * (tabs.slotW + 4)
            color: Services.Colors.ghost
            gradient: Services.Prefs.useGradients ? Services.Colors.accentGradient : null
            Behavior on x { SmoothedAnimation { duration: Services.Sizes.msPronounced } }
        }

        Row {
            anchors.fill: parent
            spacing: 4
            Repeater {
                model: [
                    { id: 0, label: Services.I18n.t("clock.tab.stopwatch"), glyph: "\ue01b" },
                    { id: 1, label: Services.I18n.t("clock.mode.countdown"), glyph: "\ue425" },
                    { id: 2, label: Services.I18n.t("clock.tab.pomodoro"),  glyph: "\ue541" }
                ]
                delegate: Item {
                    id: tab
                    required property var modelData
                    readonly property bool active: Services.AppState.timerMode === modelData.id
                    width: tabs.slotW
                    height: tabs.height
                    readonly property color fg: tab.active ? Services.Colors.accentText
                        : (tabHover.containsMouse ? Services.Colors.snow : Services.Colors.mist)

                    Row {
                        anchors.centerIn: parent
                        spacing: 5
                        Text {
                            textFormat: Text.PlainText
                            anchors.verticalCenter: parent.verticalCenter
                            text: tab.modelData.glyph
                            color: tab.fg
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 14
                            Behavior on color { ColorAnim { speed: Services.Sizes.msMicro } }
                        }
                        Text {
                            textFormat: Text.PlainText
                            anchors.verticalCenter: parent.verticalCenter
                            text: tab.modelData.label
                            color: tab.fg
                            font.pixelSize: Services.Sizes.fsMeta
                            font.bold: true
                            font.family: "JetBrainsMono NF"
                            Behavior on color { ColorAnim { speed: Services.Sizes.msMicro } }
                        }
                    }
                    MouseArea {
                        id: tabHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Services.AppState.timerMode = tab.modelData.id
                    }
                }
            }
        }
    }

    Item {
        id: tools
        anchors.top: tabs.bottom
        anchors.topMargin: 8
        anchors.bottom: parent.bottom
        width: parent.width

        // ── Stopwatch: the number, the laps, and how they compare ───────
        // No bar under the digits: a stopwatch has no end to be a fraction of.
        Tool {
            index: 0

            Column {
                id: swTop
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 12
                Item { width: 360; height: 150
                    Digits { anchors.centerIn: parent; text: Services.Stopwatch.display }
                }
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 8
                    CtlChip {
                        glyph: Services.Stopwatch.running ? "" : ""
                        tip: Services.I18n.t("kb.playPause")
                        active: Services.Stopwatch.running
                        onTriggered: Services.Stopwatch.toggle()
                    }
                    CtlChip {
                        glyph: ""
                        tip: Services.I18n.t("tip.lap")
                        available: Services.Stopwatch.running
                        onTriggered: Services.Stopwatch.lap()
                    }
                    CtlChip {
                        glyph: ""
                        tip: Services.I18n.t("tip.reset")
                        available: !Services.Stopwatch.idle
                        onTriggered: Services.Stopwatch.reset()
                    }
                }
            }

            Rectangle {
                radius: Services.Sizes.cardLgR      // the plate Usage stands on
                color: Services.Colors.plate
                id: lapPlate
                anchors.bottom: parent.bottom
                width: parent.width
                height: 150
                readonly property bool has: Services.Stopwatch.laps.length > 0

                // No laps yet: the flag alone says what goes here.
                Text {
                    textFormat: Text.PlainText
                    anchors.centerIn: parent
                    visible: !lapPlate.has
                    text: ""
                    color: Services.Colors.mist
                    opacity: 0.4
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 34
                }

                // Newest first, each against the fastest: what you want to know
                // about a lap is whether it was a good one.
                ListView {
                    id: lapList
                    x: 14; y: 12
                    width: 290
                    height: parent.height - 24
                    visible: lapPlate.has
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: Services.Stopwatch.laps.slice().reverse()
                    delegate: Item {
                        required property var modelData
                        readonly property bool best: Services.Stopwatch.laps.length > 1
                                                     && modelData.split === root.bestSplit
                        width: lapList.width
                        height: 26
                        Text {
                            textFormat: Text.PlainText
                            anchors.verticalCenter: parent.verticalCenter
                            text: "#" + modelData.index
                            color: Services.Colors.ash
                            font.pixelSize: Services.Sizes.fsMeta
                            font.family: "JetBrainsMono NF"
                        }
                        Text {
                            textFormat: Text.PlainText
                            anchors.verticalCenter: parent.verticalCenter
                            x: 44
                            text: Services.Stopwatch.format(modelData.split)
                            color: parent.best ? Services.Colors.ghost : Services.Colors.snow
                            font.pixelSize: Services.Sizes.fsBody
                            font.bold: true
                            font.family: "JetBrainsMono NF"
                        }
                        // The gap to the fastest; the fastest itself wears the flag.
                        Text {
                            textFormat: Text.PlainText
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: parent.right
                            text: parent.best ? ""
                                : (Services.Stopwatch.laps.length > 1
                                   ? "+" + Services.Stopwatch.format(modelData.split - root.bestSplit) : "")
                            color: parent.best ? Services.Colors.ghost : Services.Colors.mist
                            font.pixelSize: parent.best ? 14 : Services.Sizes.fsMeta
                            font.family: parent.best ? "Material Symbols Rounded" : "JetBrainsMono NF"
                        }
                    }
                }

                // The laps side by side: fastest in the accent, the rest quiet.
                Item {
                    id: lapBars
                    x: 320; y: 14
                    width: parent.width - x - 14
                    height: parent.height - 28
                    visible: lapPlate.has
                    Row {
                        anchors.fill: parent
                        spacing: 4
                        layoutDirection: Qt.LeftToRight
                        Repeater {
                            model: Services.Stopwatch.laps.slice(-12)
                            delegate: Item {
                                required property var modelData
                                width: Math.max(6, (lapBars.width - 11 * 4) / 12)
                                height: lapBars.height
                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    width: parent.width
                                    height: Math.max(width, parent.height * modelData.split / Math.max(1, root.worstSplit))
                                    radius: Math.min(width / 2, 4)
                                    color: (Services.Stopwatch.laps.length > 1 && modelData.split === root.bestSplit)
                                           ? Services.Colors.ghost : Services.Colors.mist
                                    opacity: color === Services.Colors.ghost ? 1 : 0.45
                                    Behavior on height { Anim { speed: Services.Sizes.msMicro } }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── Countdown: wheels to set it, a bar once it runs ─────────────
        Tool {
            index: 1

            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 20

                // Two faces, one slot: the wheels are for setting, and once it
                // is counting the space belongs to what is left.
                Item {
                    width: 360
                    height: 150

                    Row {
                        id: wheels
                        anchors.centerIn: parent
                        spacing: 2
                        scale: 1.3
                        opacity: Services.Countdown.active ? 0 : 1
                        visible: opacity > 0.01
                        Behavior on opacity { Anim {} }

                        Wheel { id: wHours; count: 24; unitMs: 3600000 }
                        WheelColon { }
                        Wheel { id: wMins;  count: 60; unitMs: 60000 }
                        WheelColon { }
                        Wheel { id: wSecs;  count: 60; unitMs: 1000 }
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: 8
                        opacity: Services.Countdown.active ? 1 : 0
                        visible: opacity > 0.01
                        Behavior on opacity { Anim {} }
                        Digits {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Services.Countdown.display
                            color: Services.Countdown.running ? Services.Colors.snow : Services.Colors.mist
                            Behavior on color { ColorAnim {} }
                        }
                        RunBar {
                            anchors.horizontalCenter: parent.horizontalCenter
                            progress: 1 - Services.Countdown.progress
                            playing: Services.Countdown.running
                            ends: Services.Countdown.running ? root.endsAt(Services.Countdown.remaining) : ""
                        }
                    }
                }
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 8
                    CtlChip {
                        glyph: Services.Countdown.running ? "" : ""
                        tip: Services.I18n.t("kb.playPause")
                        active: Services.Countdown.running
                        available: Services.Countdown.remaining > 0
                        onTriggered: Services.Countdown.toggle()
                    }
                    CtlChip {
                        glyph: ""
                        tip: Services.I18n.t("tip.reset")
                        available: Services.Countdown.active
                        onTriggered: Services.Countdown.reset()
                    }
                }
            }

            // Saved lengths: press to aim, right-click to forget, + to keep the
            // one on the wheels.
            Rectangle {
                radius: Services.Sizes.cardLgR      // the plate Usage stands on
                color: Services.Colors.plate
                anchors.bottom: parent.bottom
                width: parent.width
                height: 150

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 24
                    spacing: 8
                    Repeater {
                        model: Services.Countdown.presets
                        delegate: Rectangle {
                            id: pc
                            required property var modelData
                            readonly property bool picked: Services.Countdown.preset === modelData * 60000
                            width: 54; height: 30; radius: Services.Sizes.innerR
                            color: picked ? Services.Colors.ghost : Services.Colors.fillInset
                            gradient: Services.Prefs.useGradients && picked ? Services.Colors.accentGradient : null
                            scale: Services.Sizes.hoverScale(pcHover.containsMouse, pcHover.pressed)
                            Behavior on scale { Anim { speed: Services.Sizes.msMicro } }
                            Behavior on color { ColorAnim { speed: Services.Sizes.msMicro } }
                            Text {
                                textFormat: Text.PlainText
                                anchors.centerIn: parent
                                text: modelData >= 60 && modelData % 60 === 0 ? (modelData / 60) + "h" : modelData + "m"
                                color: parent.picked ? Services.Colors.accentText : Services.Colors.snow
                                font.pixelSize: Services.Sizes.fsBody
                                font.bold: true
                                font.family: "JetBrainsMono NF"
                            }
                            MouseArea {
                                id: pcHover
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                cursorShape: Qt.PointingHandCursor
                                onClicked: mouse => {
                                    if (mouse.button === Qt.RightButton) Services.Countdown.dropPreset(pc.modelData)
                                    else root.aimAt(pc.modelData * 60000)
                                }
                            }
                        }
                    }
                    CtlChip {
                        glyph: ""
                        size: 30
                        tip: Services.I18n.t("timer.savePreset")
                        available: !Services.Countdown.active && Services.Countdown.presets.length < 6
                                   && Services.Countdown.presets.indexOf(Math.round(Services.Countdown.preset / 60000)) === -1
                                   && Services.Countdown.preset >= 60000
                        onTriggered: Services.Countdown.savePreset()
                    }
                }

                // Nudge what is on the clock, running or not.
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 88
                    spacing: 8
                    Repeater {
                        model: [-300000, -60000, 60000, 300000]
                        delegate: Rectangle {
                            id: nb
                            required property int modelData
                            width: 54; height: 30; radius: Services.Sizes.innerR
                            color: Services.Colors.fillInset
                            scale: Services.Sizes.hoverScale(nbHover.containsMouse, nbHover.pressed)
                            Behavior on scale { Anim { speed: Services.Sizes.msMicro } }
                            Text {
                                textFormat: Text.PlainText
                                anchors.centerIn: parent
                                text: (nb.modelData < 0 ? "−" : "+") + Math.abs(nb.modelData / 60000) + "m"
                                color: nbHover.containsMouse ? Services.Colors.snow : Services.Colors.mist
                                font.pixelSize: Services.Sizes.fsBody
                                font.bold: true
                                font.family: "JetBrainsMono NF"
                                Behavior on color { ColorAnim { speed: Services.Sizes.msMicro } }
                            }
                            MouseArea {
                                id: nbHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Services.Countdown.bump(nb.modelData)
                            }
                        }
                    }
                }
            }
        }

        // ── Pomodoro: the phases, the round, and what got done today ────
        Tool {
            index: 2

            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 20

                Item {
                    width: 360
                    height: 150

                    // One travelling plate under the three phases, like the tool strip.
                    Item {
                        id: phases
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 300
                        height: 26
                        readonly property var ids: ["focus", "short", "long"]
                        readonly property real slotW: (width - 8) / 3
                        Rectangle {
                            width: phases.slotW
                            height: parent.height
                            radius: Services.Sizes.innerR
                            x: phases.ids.indexOf(Services.Pomodoro.phase) * (phases.slotW + 4)
                            color: Services.Colors.ghost
                            gradient: Services.Prefs.useGradients ? Services.Colors.accentGradient : null
                            Behavior on x { SmoothedAnimation { duration: Services.Sizes.msPronounced } }
                        }
                        Row {
                            anchors.fill: parent
                            spacing: 4
                            Repeater {
                                model: phases.ids
                                delegate: Item {
                                    id: ph
                                    required property string modelData
                                    readonly property bool on: Services.Pomodoro.phase === modelData
                                    width: phases.slotW
                                    height: phases.height
                                    Text {
                                        textFormat: Text.PlainText
                                        anchors.centerIn: parent
                                        text: Services.I18n.t("pomodoro." + ph.modelData)
                                        color: ph.on ? Services.Colors.accentText
                                             : (phHover.containsMouse ? Services.Colors.snow : Services.Colors.mist)
                                        font.pixelSize: Services.Sizes.fsMeta
                                        font.bold: true
                                        font.family: "JetBrainsMono NF"
                                        Behavior on color { ColorAnim { speed: Services.Sizes.msMicro } }
                                    }
                                    MouseArea {
                                        id: phHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        // Jumping phase would throw away a run in progress.
                                        cursorShape: Services.Countdown.running ? Qt.ArrowCursor : Qt.PointingHandCursor
                                        onClicked: if (!Services.Countdown.running) Services.Pomodoro.goTo(ph.modelData)
                                    }
                                }
                            }
                        }
                    }

                    Column {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 36
                        spacing: 4
                        readonly property bool live: Services.Pomodoro.engaged || Services.Countdown.active
                        Digits {
                            anchors.horizontalCenter: parent.horizontalCenter
                            font.pixelSize: 64
                            text: parent.live ? Services.Countdown.display
                                : Services.Countdown.format(Services.Pomodoro.minutes[Services.Pomodoro.phase] * 60000)
                            color: Services.Countdown.running ? Services.Colors.snow : Services.Colors.mist
                            Behavior on color { ColorAnim {} }
                        }
                        RunBar {
                            anchors.horizontalCenter: parent.horizontalCenter
                            progress: parent.live ? 1 - Services.Countdown.progress : 0
                            playing: Services.Countdown.running
                            ends: Services.Countdown.running ? root.endsAt(Services.Countdown.remaining) : ""
                        }
                    }
                }
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 8
                    CtlChip {
                        glyph: Services.Countdown.running ? "" : ""
                        tip: Services.I18n.t("kb.playPause")
                        active: Services.Countdown.running
                        onTriggered: Services.Pomodoro.toggle()
                    }
                    CtlChip {
                        glyph: ""
                        tip: Services.I18n.t("pomodoro.skip")
                        available: Services.Pomodoro.engaged
                        onTriggered: Services.Pomodoro.next(false)
                    }
                    CtlChip {
                        glyph: ""
                        tip: Services.I18n.t("tip.reset")
                        available: Services.Pomodoro.engaged
                        onTriggered: Services.Pomodoro.reset()
                    }
                }
            }

            Rectangle {
                radius: Services.Sizes.cardLgR      // the plate Usage stands on
                color: Services.Colors.plate
                anchors.bottom: parent.bottom
                width: parent.width
                height: 150

                // The round of four, the current one filling as it runs; and
                // today's total on the right.
                Row {
                    id: round
                    x: 16; y: 16
                    spacing: 6
                    Repeater {
                        model: 4
                        delegate: Rectangle {
                            required property int index
                            width: 56; height: 8; radius: 4
                            color: Services.Colors.fillLine
                            readonly property real fill: index < Services.Pomodoro.done ? 1
                                : (index === Services.Pomodoro.done && Services.Pomodoro.phase === "focus" && Services.Pomodoro.engaged
                                   ? 1 - Services.Countdown.progress : 0)
                            Rectangle {
                                width: Math.max(parent.fill > 0 ? parent.height : 0, parent.width * parent.fill)
                                height: parent.height
                                radius: parent.radius
                                color: Services.Colors.ghost
                                gradient: Services.Prefs.useGradients ? Services.Colors.accentGradient : null
                            }
                        }
                    }
                }
                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: round.verticalCenter
                    spacing: 10
                    Row {
                        spacing: 3
                        Text {
                            textFormat: Text.PlainText
                            anchors.verticalCenter: parent.verticalCenter
                            text: ""
                            color: Services.Colors.ghost
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 15
                        }
                        Text {
                            textFormat: Text.PlainText
                            anchors.verticalCenter: parent.verticalCenter
                            text: Services.Pomodoro.today.blocks
                            color: Services.Colors.snow
                            font.pixelSize: Services.Sizes.fsBody
                            font.bold: true
                            font.family: "JetBrainsMono NF"
                        }
                    }
                    Text {
                        textFormat: Text.PlainText
                        anchors.verticalCenter: parent.verticalCenter
                        visible: Services.Pomodoro.today.secs >= 60
                        text: Services.Usage.span(Services.Pomodoro.today.secs)
                        color: Services.Colors.mist
                        font.pixelSize: Services.Sizes.fsBody
                        font.bold: true
                        font.family: "JetBrainsMono NF"
                    }
                }

                // The length of each phase, stepped; auto-start on the right.
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 56
                    spacing: 22
                    Repeater {
                        model: ["focus", "short", "long"]
                        delegate: Column {
                            id: sc
                            required property string modelData
                            spacing: 6
                            Text {
                                textFormat: Text.PlainText
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: Services.I18n.t("pomodoro." + sc.modelData).toUpperCase()
                                color: Services.Colors.ash
                                font.pixelSize: Services.Sizes.fsCaption
                                font.bold: true
                                font.letterSpacing: 1.2
                                font.family: "JetBrainsMono NF"
                            }
                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 8
                                CtlChip { size: 22; glyphSize: 14; glyph: ""; anchors.verticalCenter: parent.verticalCenter
                                       onTriggered: Services.Pomodoro.bumpMinutes(sc.modelData, -1) }
                                Text {
                                    textFormat: Text.PlainText
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 30
                                    horizontalAlignment: Text.AlignHCenter
                                    text: Services.Pomodoro.minutes[sc.modelData]
                                    color: Services.Colors.snow
                                    font.pixelSize: 16
                                    font.bold: true
                                    font.family: "JetBrainsMono NF"
                                }
                                CtlChip { size: 22; glyphSize: 14; glyph: ""; anchors.verticalCenter: parent.verticalCenter
                                       onTriggered: Services.Pomodoro.bumpMinutes(sc.modelData, 1) }
                            }
                        }
                    }
                    CtlChip {
                        anchors.verticalCenter: parent.verticalCenter
                        size: 30
                        glyph: ""
                        tip: Services.I18n.t("pomodoro.auto")
                        active: Services.Pomodoro.auto
                        onTriggered: Services.Pomodoro.setAuto(!Services.Pomodoro.auto)
                    }
                }
            }
        }
    }
}
