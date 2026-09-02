import Quickshell
import Quickshell.Io
import QtQuick
import "root:/services" as Services
import "root:/modules/widgets" as Widgets

// Sound as one thing with two sides, not two stacked copies of the same three
// controls. The dial says what the level is; the categories under it say whose.
// Output and input share the layout, the slider and the device list, so moving
// between them moves nothing on screen except the reading.
PanelWindow {
    id: win
    property string quietLine: Services.Voice.pick("audio.noApps")
    anchors { top: true; left: true; right: true; bottom: true }
    screen: Services.Screens.active
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    // Everything but the bar's strip: a click on a pill has to reach it,
    // or changing panels costs two. See widgets/ShellMask.qml.
    mask: Widgets.ShellMask { winW: win.width; winH: win.height }
    // stays mapped through the close animation, so the exit plays in reverse
    readonly property bool shown: Services.AppState.volumeVisible
    visible: shown || closeDelay.running
    // Opening resyncs the body with the tab: a cross-fade cut short by closing
    // used to leave the panel showing the side you were not on.
    onShownChanged: {
        if (win.shown) win.shownCat = win.cat
        else closeDelay.restart()
    }
    // Mapped until the drop is all the way home; see DropCard.closeMs.
    Timer { id: closeDelay; interval: card.closeMs }

    // `cat` is the tab you picked; `shownCat` is what the body shows. It turns
    // over at the bottom of the cross-fade so the contents never swap under a
    // fully opaque body.
    property string cat: "output"
    property string shownCat: "output"
    onCatChanged: if (!win.shown) win.shownCat = win.cat

    readonly property bool isOut: win.cat !== "input"
    // The device in use on the side you are looking at.
    readonly property string deviceName: win.isOut
        ? (Services.Audio.activeSinkName || "Output")
        : (Services.Audio.activeSourceName || "Input")
    readonly property string deviceKind: Services.Audio.deviceKind(
        win.isOut ? Services.Audio.defaultSink : Services.Audio.defaultSource)
    readonly property int level: win.isOut ? Services.Audio.volume : Services.Audio.micVolume
    readonly property bool muted: win.isOut ? Services.Audio.muted : Services.Audio.micMuted
    // The output glyph is read off the bar chip, never rebuilt here: that set
    // has a headphones variant, and a second copy of the rule went out of step
    // with it the moment headphones were plugged in.
    readonly property string catGlyph: win.isOut
        ? Services.AppState.pillGlyph("volume")
        : (Services.Audio.micMuted ? "\ue02b" : "\ue31d")

    function setLevel(ratio) {
        ratio = Math.max(0, Math.min(1, ratio))
        const pct = Math.round(ratio * 100)
        if (win.isOut) {
            Services.Audio.setVolume(pct)
        } else {
            Services.Audio.setMicVolume(pct)
        }
    }
    function toggleMute() {
        if (win.isOut) Services.Audio.toggleMute()
        else Services.Audio.toggleMicMute()
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        // Off while the panel is closing: the window stays mapped for the
        // animation, and a live dismiss layer ate the next click.
        enabled: Services.AppState.volumeVisible
        onClicked: Services.AppState.volumeVisible = false
    }

    // Falls out of its chip like a drop, the same opening as the clock.
    Widgets.PanelHost {
        id: card
        shown: Services.AppState.volumeVisible
        pillCX: Services.AppState.volumePillCenterX
        pillCY: Services.AppState.volumePillCenterY
        pillActive: !Services.Audio.muted && Services.Audio.volume > 0
        pillGlyph: Services.AppState.pillGlyph("volume")
        pillLabel: Services.AppState.pillLabel("volume")
        // The chip's speaker glyph lands on the dial's, its reading in the
        // middle of the dial: the same two things, moved.
        pillW: Services.AppState.volumePillW
        pillH: Services.AppState.volumePillH
        openW: 460
        openH: (card.bodyItem ? card.bodyItem.contentH : 0) + 32
        cardRadius: 16

        pillKey: "volume"
        restSide: "right"

        body: Component {
            Item {
                readonly property real contentH: col.implicitHeight
                readonly property Item glyphTarget: dial.glyphItem
                readonly property Item labelTarget: dial.labelItem



                Widgets.SlideSwap {
                    id: swap
                    axis: "horizontal"
                    index: win.cat === "apps" ? 2 : (win.cat === "input" ? 1 : 0)
                    onCommit: win.shownCat = win.cat
                }

                Column {
                    id: col
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 16
                    spacing: 14
                    opacity: card.contentAmt

                    // ── The reading and the bar ────────────────────────────
                    // One vessel holding the whole reading: the device, the
                    // number and the slider all stand in the liquid, and the
                    // part of them it has reached is re-inked -- the bar
                    // changes colour exactly the way the lettering does.
                    Widgets.LiquidPane {
                        id: dial
                        width: parent.width
                        height: 148
                        dimmed: win.muted
                        fillColor: win.muted ? Services.Colors.mist : Services.Colors.ghost
                        value: levelBar.shown
                        easeMs: levelBar.dragging ? 0 : 220
                        onTapped: win.toggleMute()

                        readonly property Item glyphItem: volGlyph
                        readonly property Item labelItem: volLabel

                        // What is actually playing this, and how it is plugged
                        // in: "the Bluetooth ones" is what you think in, not the
                        // model of the chip.
                        Row {
                            x: 18
                            y: 16
                            width: parent.width - 36
                            spacing: 6

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: Services.Audio.kindGlyph(win.deviceKind)
                                color: Services.Colors.snow
                                font.pixelSize: 15
                                font.family: "Material Symbols Rounded"
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 90
                                text: win.deviceName
                                color: Services.Colors.snow
                                font.pixelSize: Services.Sizes.fsBody
                                font.bold: true
                                font.family: "JetBrainsMono NF"
                                elide: Text.ElideRight
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: win.muted ? "Muted"
                                     : Services.Audio.kindLabel(win.deviceKind)
                                color: Services.Colors.mist
                                font.pixelSize: Services.Sizes.fsMeta
                                font.family: "JetBrainsMono NF"
                            }
                        }

                        Row {
                            x: 18
                            y: 48
                            spacing: 8

                            Text {
                                id: volGlyph
                                anchors.verticalCenter: parent.verticalCenter
                                text: win.catGlyph
                                visible: !card.morphingGlyph
                                color: Services.Colors.snow
                                font.pixelSize: 26
                                font.family: "Material Symbols Rounded"
                            }
                            Text {
                                id: volLabel
                                anchors.verticalCenter: parent.verticalCenter
                                text: Math.round(levelBar.shown * 100) + "%"
                                visible: !card.morphingLabel
                                color: Services.Colors.snow
                                font.pixelSize: 34
                                font.bold: true
                                font.family: "JetBrainsMono NF"
                            }
                        }

                        // The slider stands in the vessel: its own track and
                        // fill, re-inked by the liquid it is standing in.
                        Widgets.SliderTrack {
                            id: levelBar
                            x: 18
                            width: parent.width - 36
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 16
                            trackHeight: 14
                            hitMargin: 10
                        dimmed: win.muted
                            fillColor: win.muted ? Services.Colors.mist : Services.Colors.ghost
                            value: (win.isOut ? Services.Audio.volume
                                              : Services.Audio.micVolume) / 100
                            onMoved: r => win.setLevel(r)
                        }
                    }

                    // ── Three sides ───────────────────────────────────────
                    // Output, input, and what each program is playing. One
                    // accent travels between them; the movement is what says
                    // which one you picked.
                    Item {
                        id: tabs
                        width: parent.width
                        height: 30

                        readonly property var ids: ["output", "input", "apps"]
                        readonly property real slotW: (width - 8) / 3

                        Rectangle {
                            width: tabs.slotW
                            height: parent.height
                            radius: 8
                            x: (tabs.ids.indexOf(win.cat)) * (tabs.slotW + 4)
                            color: Services.Colors.ghost
                            gradient: Services.Prefs.useGradients ? Services.Colors.accentGradient : null
                            Behavior on x { SmoothedAnimation { duration: Services.Sizes.msPronounced } }
                        }

                        Row {
                            anchors.fill: parent
                            spacing: 4

                            Repeater {
                                model: [
                                    { id: "output", label: "Output", glyph: "\ue050" },
                                    { id: "input",  label: "Input",  glyph: "\ue31d" },
                                    { id: "apps",   label: "Apps",   glyph: "\ue5c3" },
                                ]
                                delegate: Item {
                                    id: tab
                                    required property var modelData
                                    readonly property bool active: win.cat === modelData.id
                                    width: tabs.slotW
                                    height: tabs.height

                                    readonly property color fg: tab.active
                                        ? Services.Colors.accentText
                                        : (tabHover.containsMouse ? Services.Colors.snow
                                                                  : Services.Colors.mist)

                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 5
                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: tab.modelData.glyph
                                            color: tab.fg
                                            font.family: "Material Symbols Rounded"
                                            font.pixelSize: 14
                                            Behavior on color { ColorAnimation { duration: Services.Sizes.msMicro } }
                                        }
                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: tab.modelData.label
                                            color: tab.fg
                                            font.pixelSize: 10
                                            font.bold: true
                                            font.family: "JetBrainsMono NF"
                                            Behavior on color { ColorAnimation { duration: Services.Sizes.msMicro } }
                                        }
                                    }

                                    MouseArea {
                                        id: tabHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: win.cat = tab.modelData.id
                                    }
                                }
                            }
                        }
                    }

                    // ── The side you picked ───────────────────────────────
                    Item {
                        id: body
                        width: parent.width
                        height: shownItem ? shownItem.implicitHeight : 0
                        clip: true
                        opacity: swap.fade
                        transform: Translate { x: swap.offX; y: swap.offY }

                        readonly property bool onApps: win.shownCat === "apps"
                        readonly property bool out: win.shownCat === "output"
                        readonly property Item shownItem: body.onApps ? appCol : devPicker
                        Behavior on height {
                            NumberAnimation {
                                duration: Services.Sizes.msPronounced
                                easing.type: Services.Sizes.easeOut
                            }
                        }

                        Widgets.DevicePicker {
                            id: devPicker
                            width: parent.width
                            visible: !body.onApps
                            glyph: body.out ? "\ue050" : "\ue029"
                            devices: body.out ? Services.Audio.sinks : Services.Audio.sources
                            current: body.out ? Services.Audio.defaultSink
                                              : Services.Audio.defaultSource
                            onPicked: name => body.out ? Services.Audio.setSink(name)
                                                       : Services.Audio.setSource(name)
                        }

                        // One row per program that is making sound, each with
                        // its own bar. Nothing here when nothing is playing --
                        // an empty list is the honest answer.
                        Column {
                            id: appCol
                            width: parent.width
                            visible: body.onApps
                            spacing: 8

                            Text {
                                visible: Services.Audio.streams.length === 0
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                topPadding: 14
                                bottomPadding: 14
                                text: win.quietLine
                                color: Services.Colors.ash
                                font.pixelSize: Services.Sizes.fsBody
                                font.family: "JetBrainsMono NF"
                            }

                            Repeater {
                                model: Services.Audio.streams

                                delegate: Rectangle {
                                    id: streamRow
                                    required property var modelData
                                    readonly property bool sMuted: modelData.audio ? modelData.audio.muted : false
                                    readonly property int sVol: modelData.audio ? Math.round(modelData.audio.volume * 100) : 0
                                    width: parent.width
                                    height: 54
                                    radius: Services.Sizes.cardR
                                    color: Services.Colors.fillInset

                                    Column {
                                        anchors.fill: parent
                                        anchors.leftMargin: 12
                                        anchors.rightMargin: 12
                                        anchors.topMargin: 8
                                        spacing: 6

                                        Row {
                                            width: parent.width
                                            spacing: 6

                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: streamRow.sMuted ? "\ue04f" : "\ue050"
                                                color: streamRow.sMuted ? Services.Colors.mist
                                                                        : Services.Colors.ghost
                                                font.pixelSize: 14
                                                font.family: "Material Symbols Rounded"
                                                MouseArea {
                                                    anchors.fill: parent
                                                    anchors.margins: -6
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: Services.Audio.toggleStreamMute(modelData)
                                                }
                                            }
                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                width: parent.width - 60
                                                text: Services.Audio.streamLabel(modelData)
                                                color: Services.Colors.snow
                                                font.pixelSize: 11
                                                font.bold: true
                                                font.family: "JetBrainsMono NF"
                                                elide: Text.ElideRight
                                            }
                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: streamRow.sVol + "%"
                                                color: Services.Colors.mist
                                                font.pixelSize: 10
                                                font.family: "JetBrainsMono NF"
                                            }
                                        }

                                        Widgets.SliderTrack {
                                            width: parent.width
                                            hitMargin: 10
                                            dimmed: streamRow.sMuted
                                            fillColor: streamRow.sMuted ? Services.Colors.mist
                                                                        : Services.Colors.ghost
                                            value: streamRow.sVol / 100
                                            onMoved: r => Services.Audio.setStreamVolume(modelData, r * 100)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ── Brightness ────────────────────────────────────────
                    // It had a card of its own once, for one number the keys
                    // already change. Down here it is a line at the foot of the
                    // panel you open to change a level anyway.
                    Widgets.Divider { width: parent.width }

                    // The same row Settings uses, laid out inline: one glyph,
                    // one track, one number.
                    Widgets.SliderRow {
                        width: parent.width
                        inline: true
                        glyph: Services.Brightness.icon(Services.Brightness.level)
                        value: Services.Brightness.level
                        onMoved: pct => Services.Brightness.setLevel(pct)
                    }
                }
            }
        }
    }
}
