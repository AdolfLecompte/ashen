import QtQuick
import "root:/services" as Services

// What is running, as a card in the notification stack: the stopwatch and the
// countdown or pomodoro, each with its play/reset. It is not a notification --
// it has no history and does not time out; it is there while something runs,
// steps aside while the timer panel is open, and can be sent away. When a run
// ends it leaves and the "done" notification toast takes its place.
Item {
    id: root

    readonly property bool wanted: Services.AppState.timerBoxOut
    readonly property bool swOn: !Services.Stopwatch.idle
    readonly property bool tmOn: Services.Countdown.active
    readonly property bool poOn: Services.Pomodoro.engaged

    // 0 -> 1 as it arrives; the card's height rides on it so the stack below
    // makes room instead of jumping.
    property real amt: root.wanted ? 1 : 0
    Behavior on amt { Anim { speed: Services.Sizes.msPanel } }

    readonly property int rowH: 64
    readonly property int fullH: (root.swOn ? rowH : 0) + (root.tmOn ? rowH : 0) + 8

    width: Services.Prefs.toastWidth
    height: root.fullH * root.amt
    opacity: root.amt
    visible: root.amt > 0.01

    // One line of the card
    component Line: Item {
        id: ln
        property string glyph: ""
        property string name: ""
        property string value: ""
        property bool live: false
        property bool playing: false
        property bool canReset: false
        property int mode: 0
        property bool withClose: false
        signal toggled()
        signal cleared()

        width: parent.width
        height: root.rowH

        Text {
            textFormat: Text.PlainText
            id: gl
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            text: ln.glyph
            color: Services.Colors.ghost
            font.pixelSize: 26
            font.family: "Material Symbols Rounded"
        }
        Column {
            anchors.left: gl.right
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0
            Text {
                textFormat: Text.PlainText
                text: ln.name
                color: Services.Colors.mist
                font.pixelSize: Services.Sizes.fsCaption
                font.bold: true
                font.letterSpacing: 1.4
                font.family: "JetBrainsMono NF"
            }
            Text {
                textFormat: Text.PlainText
                text: ln.value
                color: ln.live ? Services.Colors.snow : Services.Colors.mist
                font.pixelSize: 28
                font.bold: true
                font.family: "JetBrainsMono NF"
                Behavior on color { ColorAnim { speed: Services.Sizes.msMicro } }
            }
        }
        // The reading opens its tool in the panel
        MouseArea {
            anchors.left: parent.left
            anchors.right: ctl.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            cursorShape: Qt.PointingHandCursor
            onClicked: Services.AppState.openTimerAt(ln.mode)
        }
        Row {
            id: ctl
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6
            CtlChip {
                size: 28
                glyphSize: 16
                glyph: ln.playing ? "" : ""
                tip: Services.I18n.t("kb.playPause")
                active: ln.playing
                onTriggered: ln.toggled()
            }
            CtlChip {
                size: 28
                glyphSize: 16
                glyph: ""
                tip: Services.I18n.t("tip.reset")
                available: ln.canReset
                onTriggered: ln.cleared()
            }
            CtlChip {
                visible: ln.withClose
                size: 28
                glyphSize: 16
                glyph: ""
                tip: Services.I18n.t("tip.dismiss")
                onTriggered: Services.AppState.timerDropHidden = true
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 16
        color: Services.Colors.surfacePanel
        border.width: Services.Colors.panelEdgeW
        border.color: Services.Colors.panelEdgeColor
        clip: true

        Column {
            width: parent.width
            y: 4

            Line {
                visible: root.swOn
                height: visible ? root.rowH : 0
                glyph: ""
                name: Services.I18n.t("clock.tab.stopwatch").toUpperCase()
                value: Services.Stopwatch.displayShort
                live: Services.Stopwatch.running
                playing: Services.Stopwatch.running
                canReset: !Services.Stopwatch.idle
                mode: 0
                withClose: !root.tmOn
                onToggled: Services.Stopwatch.toggle()
                onCleared: Services.Stopwatch.reset()
            }
            Line {
                visible: root.tmOn
                height: visible ? root.rowH : 0
                glyph: root.poOn ? "" : ""
                name: (root.poOn ? Services.I18n.t("pomodoro." + Services.Pomodoro.phase)
                                 : Services.I18n.t("clock.mode.countdown")).toUpperCase()
                value: Services.Countdown.display
                live: Services.Countdown.running
                playing: Services.Countdown.running
                canReset: Services.Countdown.active
                mode: root.poOn ? 2 : 1
                withClose: true
                onToggled: root.poOn ? Services.Pomodoro.toggle() : Services.Countdown.toggle()
                onCleared: root.poOn ? Services.Pomodoro.reset() : Services.Countdown.reset()
            }
        }
    }
}
