import QtQuick

import "root:/services" as Services

// A month of days, seven across. Lived inside the clock card until the desktop
// wanted one too; the card keeps its own arrows and slide, this only draws.
Grid {
    id: root

    // ONE property moves the calendar. Month and year would be two changes for
    // one press, and anything watching would run twice.
    property int monthIndex: Services.Time.now.getFullYear() * 12 + Services.Time.now.getMonth()
    // The month the days are drawn from. Assigned by the caller when its slide
    // commits, so the days change off screen; never bound, or they would change
    // under the press.
    property int shownIndex: root.monthIndex
    property real cellW: 34
    property real cellSize: 34
    // Six rows always: a five-week month must not shorten the column.
    property bool reserveRows: true
    property bool interactive: true

    columns: 7
    spacing: 3
    height: root.reserveRows ? 6 * cellSize + 5 * spacing : implicitHeight

    readonly property int curMonth: shownIndex % 12
    readonly property int curYear: Math.floor(shownIndex / 12)
    readonly property int today: Services.Time.now.getDate()
    readonly property int todayMonth: Services.Time.now.getMonth()
    readonly property int todayYear: Services.Time.now.getFullYear()
    readonly property int firstDay: new Date(curYear, curMonth, 1).getDay()
    readonly property int daysInMonth: new Date(curYear, curMonth + 1, 0).getDate()

    Repeater {
        model: root.firstDay + root.daysInMonth
        delegate: Rectangle {
            required property int index
            readonly property int day: index - root.firstDay + 1
            readonly property bool isValid: index >= root.firstDay
            readonly property bool isToday: isValid && day === root.today
                && root.curMonth === root.todayMonth && root.curYear === root.todayYear

            width: root.cellW
            height: root.cellSize
            radius: 8
            // Today takes the accent; every other day is bare and answers the
            // pointer by brightening its number.
            color: isToday ? Services.Colors.ghost : "transparent"
            // Vertical: the cell is a square block, not a wide pill, so the
            // light reads down it -- lit top, dark foot.
            gradient: Services.Prefs.useGradients && isToday ? Services.Colors.accentGradientV : null
            Behavior on color { ColorAnim { speed: Services.Sizes.msMicro } }

            Text {
                anchors.centerIn: parent
                text: parent.isValid ? parent.day : ""
                color: parent.isToday ? Services.Colors.accentText
                     : (dayHover.containsMouse && parent.isValid) ? Services.Colors.snow
                     : Services.Colors.mist
                Behavior on color { ColorAnim { speed: Services.Sizes.msMicro } }
                font.pixelSize: 12
                font.family: "JetBrainsMono NF"
                font.bold: parent.isToday
            }

            MouseArea {
                id: dayHover
                anchors.fill: parent
                hoverEnabled: root.interactive && parent.isValid
                cursorShape: Qt.PointingHandCursor
            }
        }
    }
}
