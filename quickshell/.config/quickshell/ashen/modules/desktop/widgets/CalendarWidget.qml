import QtQuick

import "root:/modules/desktop"
import "root:/modules/widgets" as Widgets
import "root:/services" as Services

// The month, or just the week you are in. The same grid the clock panel draws.
DesktopWidget {
    id: root
    wid: "calendar"

    readonly property var now: Services.Time.now
    readonly property int monthIndex: root.now.getFullYear() * 12 + root.now.getMonth()

    component Head: Text {
        textFormat: Text.PlainText
        text: Services.Time.fmt("MMMM yyyy").toUpperCase()
        color: Services.Colors.mist
        font.pixelSize: Services.Sizes.fsCaption
        font.bold: true
        font.letterSpacing: 1.4
        font.family: "JetBrainsMono NF"
    }

    // Sunday first, as the grid counts them.
    component DayNames: Row {
        property real cell: 30
        spacing: 3
        Repeater {
            model: 7
            delegate: Text {
                textFormat: Text.PlainText
                required property int index
                width: parent.cell
                horizontalAlignment: Text.AlignHCenter
                text: Services.Time.dayNarrow(index).toUpperCase()
                color: Services.Colors.ash
                font.pixelSize: Services.Sizes.fsCaption
                font.family: "JetBrainsMono NF"
            }
        }
    }

    Component {
        id: monthShape
        Column {
            spacing: 8
            Head {}
            DayNames { cell: 30 }
            Widgets.MonthGrid {
                width: 7 * 30 + 6 * 3
                cellW: 30
                cellSize: 30
                monthIndex: root.monthIndex
                interactive: false
            }
        }
    }

    // One row: the days either side of today, today in the accent. A whole
    // month is a lot of surface for "what is the date".
    Component {
        id: weekShape
        Column {
            spacing: 8
            Head {}

            Row {
                spacing: 4
                Repeater {
                    model: 7
                    delegate: Column {
                        id: day
                        required property int index
                        // Sunday of the current week, plus the column.
                        readonly property var date: {
                            const d = new Date(root.now)
                            d.setDate(d.getDate() - d.getDay() + day.index)
                            return d
                        }
                        readonly property bool isToday: day.date.getDate() === root.now.getDate()
                            && day.date.getMonth() === root.now.getMonth()
                        spacing: 4

                        Text {
                            textFormat: Text.PlainText
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Services.Time.fmtOf(day.date, "ddd").toUpperCase()
                            color: Services.Colors.ash
                            font.pixelSize: Services.Sizes.fsCaption
                            font.family: "JetBrainsMono NF"
                        }
                        Rectangle {
                            width: 34
                            height: 34
                            radius: Services.Sizes.innerR
                            color: day.isToday ? Services.Colors.ghost : "transparent"
                            gradient: (Services.Prefs.useGradients && day.isToday)
                                ? Services.Colors.accentGradientV : null

                            Text {
                                textFormat: Text.PlainText
                                anchors.centerIn: parent
                                text: day.date.getDate()
                                color: day.isToday ? Services.Colors.accentText : Services.Colors.snow
                                font.pixelSize: Services.Sizes.fsInput
                                font.bold: day.isToday
                                font.family: "JetBrainsMono NF"
                            }
                        }
                    }
                }
            }
        }
    }

    Loader {
        sourceComponent: root.style === "week" ? weekShape : monthShape
    }
}
