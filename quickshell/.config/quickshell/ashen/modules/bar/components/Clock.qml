import QtQuick
import QtQuick.Layouts

import "root:/services" as Services
import "root:/modules/widgets" as Widgets

Rectangle {
    id: root

    // How this pill draws itself, chosen in Settings > Bar > Layout.
    readonly property string content: Services.Pills.contentOf("clock")
    readonly property bool outlined: Services.Pills.isOutlined("clock")
    // These follow Services.Time -- the shell's single SystemClock. They used
    // to be assigned from a Timer of this pill's own, one of four.
    readonly property string currentTime: Services.Time.fmt(Services.Prefs.timeFormat)
    readonly property string currentDate: Services.Time.fmt("ddd, MMM d")
    // A side bar is one pill wide: the clock stacks hours over minutes there and
    // drops the date and the weather chip.
    readonly property bool vertical: Services.Sizes.barVertical
    readonly property string vertHour: Services.Time.fmt(Services.Prefs.hourToken)
    readonly property string vertMinute: Services.Time.fmt("mm")
    readonly property string vertSuffix: Services.Prefs.clock24h ? "" : Services.Time.fmt("AP")
    readonly property string vertSecond: Services.Prefs.clockSeconds ? Services.Time.fmt("ss") : ""
    // The date comes back on a side bar. The horizontal pill says "Sat, Aug 29"
    // and the vertical one used to say nothing at all -- the month is what does
    // not fit in 44 px, not the day. Stacked like everything else in this
    // column: the name over its number, the way the glyph sits over its reading.
    readonly property string vertDay: Services.Time.fmt("ddd").toUpperCase()
    readonly property string vertDayNum: Services.Time.fmt("d")

    height: root.vertical ? vertCol.implicitHeight + 16 : Services.Sizes.pillH
    width: root.vertical ? Services.Sizes.pillH : clockRow.implicitWidth + 40
    radius: Services.Sizes.pillR
    border.color: Services.Colors.fillOutline
    border.width: root.outlined ? Services.Sizes.outlineW : 0
    // While the timer box is hanging off it, the two corners facing it go
    // square. That join is the whole point: a rounded pill sitting on a squared
    // box leaves a notch either side of the seam, and the pair reads as two
    // surfaces that happen to touch. Squared, they are ONE taller capsule.
    readonly property string boxEdge: {
        if (!Services.AppState.timerBoxOut) return ""
        const e = Services.Sizes.barPosition
        if (e === "bottom") return "top"
        if (e === "left") return "right"
        if (e === "right") return "left"
        return "bottom"
    }
    topLeftRadius:     (root.boxEdge === "top" || root.boxEdge === "left")     ? 0 : root.radius
    topRightRadius:    (root.boxEdge === "top" || root.boxEdge === "right")    ? 0 : root.radius
    bottomLeftRadius:  (root.boxEdge === "bottom" || root.boxEdge === "left")  ? 0 : root.radius
    bottomRightRadius: (root.boxEdge === "bottom" || root.boxEdge === "right") ? 0 : root.radius
    // The weather text still changes width under it (a degree gained, an icon
    // swapped), so the settle stays. What used to widen it -- a live stopwatch --
    // hangs under the bar now, in TimerDrops.
    Behavior on width { enabled: !Services.Sizes.hidden; Widgets.Anim { speed: Services.Sizes.msPronounced; curve: Services.Sizes.easeBox } }
    color: root.outlined ? Services.Colors.surfaceGlass : (Services.Colors.pillPlate)
    // The bar pivots the centre group on this point, so the HOUR sits dead
    // centre on screen and the date and weather fall either side of it.
    // Plain arithmetic, never mapToItem: a mapping is read once and never
    // re-taken, so a rebuild left it stuck on scene coordinates.
    readonly property real pivot: root.vertical
        ? height / 2
        : (clockRow.visible && timeText.width > 0
            ? clockRow.x + timeText.x + timeText.width / 2
            : width / 2)

    MouseArea {
        id: pillHover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Services.AppState.togglePanel("calendarVisible")
    }

    // No hover grow here: the clock is the widest thing on the bar and it sits
    // dead centre, so swelling it under a passing pointer nudged the whole
    // strip. The press is kept — that half is feedback for something you did.
    scale: pillHover.pressed ? Services.Sizes.pillPressScale : 1.0
    Behavior on scale { Widgets.Anim { speed: Services.Sizes.pillHoverMs } }

    // Reports where it sits so the calendar can drop out of it
    PillCenter { key: "clock" }

    // …and its size, so the panel knows the rect it has to grow out of
    Binding { target: Services.AppState; property: "clockPillW"; value: root.width }
    Binding { target: Services.AppState; property: "clockPillH"; value: root.height }

    // The panel is a morphed copy of this pill, so while it is open the pill
    // steps aside: the card standing on its rect *is* the pill now. Fading
    // opacity rather than flipping `visible` — invisible still holds its slot
    // in the bar, hidden would let the row close the gap and shift.
    property bool takenOverByPanel: false
    Connections {
        target: Services.AppState
        // clockMorphing, not calendarVisible: the pill must stay on screen
        // until the panel's surface is up and the morph starts drawing
        function onClockMorphingChanged() {
            if (Services.AppState.clockMorphing) {
                handBack.stop()
                root.takenOverByPanel = true
            } else {
                handBack.restart()
            }
        }
    }
    // The card only becomes a pill again at ~480 ms and lands on this rect at
    // ~720; fade in just under that, so the two meet instead of leaving a hole.
    Timer { id: handBack; interval: 330; onTriggered: root.takenOverByPanel = false }

    opacity: (root.takenOverByPanel && Services.Pills.wearsFace) ? 0.0 : 1.0
    Behavior on opacity { Widgets.Anim { speed: Services.Sizes.msMicro } }


    Column {
        id: vertCol
        visible: root.vertical
        anchors.centerIn: parent
        spacing: 0

        // Date above, weather below, the hour between them: the three the
        // horizontal pill shows in a row, stacked in the same order. No rules
        // between them -- 15 px against 9 px already says which one is the
        // headline, and two hairlines in a 44 px column read as a fence.
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.vertDay
            color: Services.Colors.mist
            font.pixelSize: 9
            font.family: "JetBrainsMono NF"
            font.bold: true
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.vertDayNum
            color: Services.Colors.mist
            font.pixelSize: 11
            font.family: "JetBrainsMono NF"
            font.bold: true
        }
        Item { width: 1; height: 3 }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.vertHour
            color: Services.Colors.snow
            font.pixelSize: 15
            font.family: "JetBrainsMono NF"
            font.bold: true
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.vertMinute
            color: Services.Colors.snow
            font.pixelSize: 15
            font.family: "JetBrainsMono NF"
            font.bold: true
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.vertSecond !== ""
            text: root.vertSecond
            color: Services.Colors.mist
            font.pixelSize: 10
            font.family: "JetBrainsMono NF"
            font.bold: true
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.vertSuffix !== ""
            text: root.vertSuffix
            color: Services.Colors.mist
            font.pixelSize: 9
            font.family: "JetBrainsMono NF"
            font.bold: true
        }

        // Weather closes the pill the way the date opens it: the sky over its
        // number, not beside it.
        Item { width: 1; height: 3 }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Services.Weather.icon
            font.pixelSize: 14
            font.family: "Material Symbols Rounded"
            color: Services.Colors.neutral
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Services.Weather.temp
            color: Services.Colors.mist
            font.pixelSize: 9
            font.family: "JetBrainsMono NF"
            font.bold: true
        }
    }

    RowLayout {
        id: clockRow
        visible: !root.vertical
        anchors.centerIn: parent
        spacing: 16

        // Date, hour, weather: the hour holds the middle and the other two
        // fall either side of it, which is what the bar pivots on.
        Text {
            // Compact is the hour and nothing else: the date and the weather are
            // exactly what a clock asked to be small is giving up.
            visible: root.content === "full"
            Layout.alignment: Qt.AlignVCenter
            text: root.currentDate
            color: Services.Colors.mist
            font.pixelSize: 15
            font.family: "JetBrainsMono NF"
            font.bold: true
        }

        // Seconds at 9 px against the hour's 15: on a pill the one number that
        // never stops moving is the one that must not ask for width.
        Widgets.ClockText {
            id: timeText
            Layout.alignment: Qt.AlignVCenter
            time: root.currentTime
            px: 15
            secRatio: 0.6
        }

        Row {
            visible: root.content === "full"
            spacing: 4
            Layout.alignment: Qt.AlignVCenter
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Services.Weather.icon
                font.pixelSize: 22
                font.family: "Material Symbols Rounded"
                color: Services.Colors.neutral
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Services.Weather.temp
                font.pixelSize: 13
                font.family: "JetBrainsMono NF"
                font.bold: true
                color: Services.Colors.mist
            }
        }
    }
}
