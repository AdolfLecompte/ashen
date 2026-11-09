import QtQuick
import "root:/services" as Services

// Stopwatch, countdown and pomodoro: the tools that used to be tabs inside the
// clock panel. Content only, hosted by TimerPanel.
Item {
    id: root

    property var stageFn: null
    function beat(i) { return root.stageFn ? root.stageFn(i) : 1 }

    implicitWidth: 400
    implicitHeight: 400
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

                // -- Stopwatch: the number, and nothing around it --
                // It had a ring for a while. A stopwatch has no end to be a
                // fraction of, so the ring was drawing a minute nobody asked
                // about while the digits -- the whole point -- had to shrink to
                // fit inside it.
                Tool {
                    index: 0
                    Column {
                        anchors.centerIn: parent
                        spacing: 20

                        Text {
                            textFormat: Text.PlainText
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Services.Stopwatch.display
                            color: Services.Colors.snow
                            font.pixelSize: 66
                            font.bold: true
                            font.family: "JetBrainsMono NF"
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

                        // Newest on the left, the fastest one wearing the accent:
                        // which lap was the good one is a comparison, and a
                        // column of bare numbers never makes it for you.
                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 6
                            Repeater {
                                model: Services.Stopwatch.laps.slice(-4).reverse()
                                delegate: Rectangle {
                                    required property var modelData
                                    // Nothing is "fastest" until there is
                                    // something to be faster than.
                                    readonly property bool best: Services.Stopwatch.laps.length > 1
                                        && modelData.split === root.bestSplit
                                    width: 60
                                    height: 34
                                    radius: Services.Sizes.innerR
                                    color: best ? Services.Colors.ghost : Services.Colors.fillInset
                                    gradient: Services.Prefs.useGradients && best
                                        ? Services.Colors.accentGradient : null
                                    Behavior on color { ColorAnim { speed: Services.Sizes.msMicro } }

                                    Column {
                                        anchors.centerIn: parent
                                        spacing: 0
                                        Text {
                                            textFormat: Text.PlainText
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: "#" + modelData.index
                                            color: parent.parent.best ? Services.Colors.accentBody : Services.Colors.ash
                                            font.pixelSize: 9
                                            font.family: "JetBrainsMono NF"
                                        }
                                        Text {
                                            textFormat: Text.PlainText
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: Services.Stopwatch.format(modelData.split)
                                            color: parent.parent.best ? Services.Colors.accentText : Services.Colors.snow
                                            font.pixelSize: 11
                                            font.bold: true
                                            font.family: "JetBrainsMono NF"
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // -- Countdown: pick the time on the wheels, or take a preset --
                Tool {
                    index: 1
                    Column {
                        anchors.centerIn: parent
                        spacing: 18

                        // Two faces, one slot: the wheels are for setting, and
                        // once it is counting the only thing worth the space is
                        // what is left.
                        Item {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: wheels.width * wheels.scale
                            height: 154

                            Row {
                                id: wheels
                                anchors.centerIn: parent
                                spacing: 2
                                scale: 1.35
                                opacity: Services.Countdown.active ? 0 : 1
                                visible: opacity > 0.01
                                Behavior on opacity { Anim {} }

                                Wheel { id: wHours;   count: 24; unitMs: 3600000 }
                                WheelColon { }
                                Wheel { id: wMins;    count: 60; unitMs: 60000 }
                                WheelColon { }
                                Wheel { id: wSecs;    count: 60; unitMs: 1000 }
                            }

                            Text {
                                textFormat: Text.PlainText
                                anchors.centerIn: parent
                                text: Services.Countdown.display
                                color: Services.Countdown.running ? Services.Colors.snow : Services.Colors.mist
                                font.pixelSize: 66
                                font.bold: true
                                font.family: "JetBrainsMono NF"
                                opacity: Services.Countdown.active ? 1 : 0
                                visible: opacity > 0.01
                                Behavior on opacity { Anim {} }
                                Behavior on color { ColorAnim {} }
                            }
                        }

                        // The lengths worth a button; the wheels cover everything
                        // between them.
                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 6
                            Repeater {
                                model: [1, 5, 10, 25]
                                delegate: Rectangle {
                                    required property var modelData
                                    readonly property bool picked: Services.Countdown.preset === modelData * 60000
                                    width: 42; height: 24; radius: 8
                                    color: picked ? Services.Colors.ghost : Services.Colors.fillInset
                                    gradient: Services.Prefs.useGradients && picked
                                        ? Services.Colors.accentGradient : null
                                    Behavior on color { ColorAnim { speed: Services.Sizes.msMicro } }
                                    Text {
                                        textFormat: Text.PlainText
                                        anchors.centerIn: parent
                                        text: modelData + "m"
                                        color: parent.picked ? Services.Colors.accentText : Services.Colors.snow
                                        font.pixelSize: 10
                                        font.bold: true
                                        font.family: "JetBrainsMono NF"
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        // A length aims the timer; starting is
                                        // the one button that starts things.
                                        onClicked: root.aimAt(modelData * 60000)
                                    }
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
                }
                // -- Pomodoro: the Countdown, run as focus / break phases --
                Tool {
                    index: 2
                    Column {
                        anchors.centerIn: parent
                        spacing: 18

                        Text {
                            textFormat: Text.PlainText
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Services.I18n.t("pomodoro." + Services.Pomodoro.phase)
                            color: Services.Colors.mist
                            font.pixelSize: 13
                            font.bold: true
                            font.family: "JetBrainsMono NF"
                        }
                        Text {
                            textFormat: Text.PlainText
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: (Services.Pomodoro.engaged || Services.Countdown.active) ? Services.Countdown.display
                                                            : Services.Countdown.format(25 * 60000)
                            color: Services.Countdown.running ? Services.Colors.snow : Services.Colors.mist
                            font.pixelSize: 66
                            font.bold: true
                            font.family: "JetBrainsMono NF"
                            Behavior on color { ColorAnim {} }
                        }
                        // Focus blocks done in this set of four
                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 8
                            Repeater {
                                model: 4
                                delegate: Rectangle {
                                    required property int index
                                    width: 8; height: 8; radius: 4
                                    color: index < Services.Pomodoro.done ? Services.Colors.ghost
                                                                          : Services.Colors.fillInset
                                    Behavior on color { ColorAnim { speed: Services.Sizes.msMicro } }
                                }
                            }
                        }
                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 8
                            CtlChip {
                                glyph: Services.Countdown.running ? "\ue034" : "\ue037"
                                tip: Services.I18n.t("kb.playPause")
                                active: Services.Countdown.running
                                onTriggered: Services.Pomodoro.toggle()
                            }
                            CtlChip {
                                glyph: "\ue044"
                                tip: Services.I18n.t("pomodoro.skip")
                                available: Services.Pomodoro.engaged
                                onTriggered: Services.Pomodoro.next()
                            }
                            CtlChip {
                                glyph: "\ue042"
                                tip: Services.I18n.t("tip.reset")
                                available: Services.Pomodoro.engaged
                                onTriggered: Services.Pomodoro.reset()
                            }
                        }
                    }
                }

    }
}
