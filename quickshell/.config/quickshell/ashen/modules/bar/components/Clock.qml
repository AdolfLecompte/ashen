import QtQuick
import QtQuick.Layouts

import "root:/services" as Services
import "root:/modules/widgets" as Widgets

Rectangle {
    id: root
    // The bar this pill stands on (Bar.qml hands it in).
    property var spec: Services.Sizes.first

    // How this pill draws itself, chosen in Settings > Bar > Layout.
    readonly property string content: Services.Pills.contentOf("clock")
    readonly property bool outlined: root.spec.outlined("clock")
    // These follow Services.Time -- the shell's single SystemClock. They used
    // to be assigned from a Timer of this pill's own, one of four.
    readonly property string currentTime: Services.Time.fmt(Services.Prefs.timeFormat)
    readonly property string currentDate: Services.Time.fmt("ddd, MMM d")
    // A side bar is one pill wide: the clock stacks hours over minutes there and
    // drops the date and the weather chip.
    readonly property bool vertical: Services.Sizes.barVertical
    // Qt only reads "hh" as 12-hour when AP is in the SAME format string, so
    // the hour is cut out of a full one rather than asked for alone.
    readonly property string vertHour: Services.Time.fmt(Services.Prefs.hourToken + "|AP").split("|")[0]
    readonly property string vertMinute: Services.Time.fmt("mm")
    readonly property string vertSuffix: Services.Prefs.clock24h ? "" : Services.Time.fmt("AP")
    readonly property string vertSecond: Services.Prefs.clockSeconds ? Services.Time.fmt("ss") : ""
    // The date comes back on a side bar. The horizontal pill says "Sat, Aug 29"
    // and the vertical one used to say nothing at all -- the month is what does
    // not fit in 44 px, not the day. Stacked like everything else in this
    // column: the name over its number, the way the glyph sits over its reading.
    // Two letters side by side, like AM/PM: MO, TU... in the shell's language.
    readonly property string vertDay: Services.Time.fmt("ddd").replace(".", "").slice(0, 2).toUpperCase()
    // The number and its unit stack too: "18°" over "C".
    readonly property string vertTemp: Services.Weather.offline ? "--"
        : Services.Weather.convert(Services.Weather.tempC) + (Services.Prefs.tempUnit === "K" ? "" : "\u00b0")
    readonly property string vertUnit: Services.Weather.offline ? "" : Services.Prefs.tempUnit
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
        const e = root.spec.edge
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
    color: root.outlined ? Services.Colors.surfaceGlass : (root.spec.pillPlate)
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
    // Back as the card lands on this rect, so the two meet instead of
    // leaving a hole.
    Timer { id: handBack; interval: Services.Sizes.panelHandBackMs; onTriggered: root.takenOverByPanel = false }

    opacity: (root.takenOverByPanel && Services.Pills.wearsFace) ? 0.0 : 1.0
    Behavior on opacity { Widgets.Anim { speed: Services.Sizes.msMicro } }


    Column {
        id: vertCol
        visible: root.vertical
        anchors.centerIn: parent
        spacing: 0

        // Three blocks -- day, time, weather -- each in one size, with air
        // between them so the weather glyph never reads as part of the time.
        // Compact is the time alone.
        VText { visible: root.content === "full"; text: root.vertDay; px: 13; tone: Services.Colors.mist }
        VText { visible: root.content === "full"; text: root.vertDayNum; px: 13; tone: Services.Colors.mist }
        Gap { visible: root.content === "full" }

        VText { text: root.vertHour; px: 13; tone: Services.Colors.snow }
        VText { text: root.vertMinute; px: 13; tone: Services.Colors.snow }
        VText { visible: root.vertSecond !== ""; text: root.vertSecond; px: 13; tone: Services.Colors.mist }
        VText { visible: root.vertSuffix !== ""; text: root.vertSuffix; px: 13; tone: Services.Colors.snow }

        Gap { visible: root.content === "full" }
        Text {
            textFormat: Text.PlainText
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.content === "full"
            text: Services.Weather.icon
            font.pixelSize: 16
            font.family: "Material Symbols Rounded"
            color: Services.Colors.neutral
        }
        Item { width: 1; height: 4; visible: root.content === "full" }
        VText { visible: root.content === "full"; text: root.vertTemp; px: 13; tone: Services.Colors.mist }
        VText { visible: root.content === "full" && root.vertUnit !== ""; text: root.vertUnit; px: 13; tone: Services.Colors.mist }
    }

    component VText: Text {
        property int px: 11
        property color tone: Services.Colors.mist
        textFormat: Text.PlainText
        anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
        color: tone
        font.pixelSize: px
        font.family: "JetBrainsMono NF"
        font.bold: true
    }
    component Gap: Item { width: 1; height: 8 }

    RowLayout {
        id: clockRow
        visible: !root.vertical
        anchors.centerIn: parent
        spacing: 16

        // Date, hour, weather: the hour holds the middle and the other two
        // fall either side of it, which is what the bar pivots on.
        Text {
            textFormat: Text.PlainText
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
                textFormat: Text.PlainText
                anchors.verticalCenter: parent.verticalCenter
                text: Services.Weather.icon
                font.pixelSize: 22
                font.family: "Material Symbols Rounded"
                color: Services.Colors.neutral
            }
            Text {
                textFormat: Text.PlainText
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
