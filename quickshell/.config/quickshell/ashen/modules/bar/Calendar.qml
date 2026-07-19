import Quickshell
import QtQuick
import QtQuick.Layouts

import "root:/services" as Services

PanelWindow {
    id: root

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    // stays mapped through the close animation, so the exit plays in reverse
    readonly property bool shown: Services.AppState.calendarVisible
    visible: shown || closeDelay.running
    onShownChanged: if (!shown) closeDelay.restart()
    Timer { id: closeDelay; interval: 300 }

    // The big clock stacks hour over minute, so the parts are kept separate
    // instead of split() off a formatted string -- under 24h there is no " AP"
    // to split on and the old surgery produced "undefined".
    // Qt's "hh"/"h" only mean 12-hour when an AP/ap token sits in the SAME
    // format string; formatting the hour alone with "hh" silently yields 24h,
    // so the 12/24 split is computed by hand to match the bar pill.
    function hourText(d) {
        if (Services.Prefs.clock24h)
            return Qt.formatDateTime(d, "HH")
        let h = d.getHours() % 12
        if (h === 0) h = 12
        return (h < 10 ? "0" : "") + h
    }
    property string currentHour: hourText(new Date())
    property string currentMinute: Qt.formatDateTime(new Date(), "mm")
    property string currentSecs: Qt.formatDateTime(new Date(), "ss")
    property string currentAmPm: Services.Prefs.clock24h ? "" : Qt.formatDateTime(new Date(), "AP")
    property string currentDate: Qt.formatDateTime(new Date(), "MMMM d, yyyy")
    property string currentDayName: Qt.locale().dayName(new Date().getDay())

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            let now = new Date()
            root.currentHour = root.hourText(now)
            root.currentMinute = Qt.formatDateTime(now, "mm")
            root.currentSecs = Qt.formatDateTime(now, "ss")
            root.currentAmPm = Services.Prefs.clock24h ? "" : Qt.formatDateTime(now, "AP")
            root.currentDate = Qt.formatDateTime(now, "MMMM d, yyyy")
            root.currentDayName = Qt.locale().dayName(now.getDay())
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: Services.AppState.calendarVisible = false
    }

    readonly property int boxHeight: 320

    Row {
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 64
        spacing: 10
        opacity: Services.AppState.calendarVisible ? 1.0 : 0.0
        scale: Services.AppState.calendarVisible ? 1.0 : 0.92
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        transform: Translate {
            y: Services.AppState.calendarVisible ? 0 : -24
            Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        }

        // -- Center column: Time --
        Rectangle {
            width: 185
            height: root.boxHeight
            radius: 14
            color: Services.Colors.surfaceAlpha(0.95)
            border.color: Services.Colors.ghostAlpha(0.2)
            border.width: 0
            MouseArea { anchors.fill: parent; onClicked: {} }

            Column {
                anchors.centerIn: parent
                spacing: 18

                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: -6
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.currentHour
                        color: Services.Colors.ghost
                        font.pixelSize: 68
                        font.family: "JetBrainsMono NF"
                        font.bold: true
                        lineHeight: 0.9
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.currentMinute
                        color: Services.Colors.snow
                        font.pixelSize: 68
                        font.family: "JetBrainsMono NF"
                        font.bold: true
                        lineHeight: 0.9
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        // Either part can be switched off in Settings; with both
                        // gone the row collapses instead of leaving a stray gap.
                        text: [root.currentAmPm, Services.Prefs.clockSeconds ? root.currentSecs : ""]
                            .filter(s => s !== "").join("  ")
                        visible: text !== ""
                        color: Services.Colors.mist
                        font.pixelSize: 12
                        font.family: "JetBrainsMono NF"
                        font.bold: true
                        topPadding: 8
                    }
                }

                Rectangle { width: 40; height: 1; anchors.horizontalCenter: parent.horizontalCenter; color: Services.Colors.ghostAlpha(0.25) }

                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 4
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.currentDayName.toUpperCase()
                        color: Services.Colors.ash
                        font.pixelSize: 10
                        font.family: "JetBrainsMono NF"
                        font.bold: true
                        font.letterSpacing: 2
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.currentDate
                        color: Services.Colors.snow
                        font.pixelSize: 12
                        font.family: "JetBrainsMono NF"
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        width: 120
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }

        // -- Left column: Calendar --
        Rectangle {
            width: 360
            height: root.boxHeight
            radius: 14
            color: Services.Colors.surfaceAlpha(0.95)
            border.color: Services.Colors.ghostAlpha(0.2)
            border.width: 0
            MouseArea { anchors.fill: parent; onClicked: {} }

            Column {
                id: calCol
                anchors.centerIn: parent
                spacing: 10
                width: parent.width - 32

                RowLayout {
                    width: parent.width

                    Rectangle {
                        width: 26; height: 26; radius: 8; color: "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: "\u2039"
                            color: Services.Colors.ghost
                            font.pixelSize: 18
                            font.family: "JetBrainsMono NF"
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onEntered: parent.color = Services.Colors.ghostAlpha(0.15)
                            onExited: parent.color = "transparent"
                            onClicked: {
                                if (calRoot.currentMonth === 0) { calRoot.currentMonth = 11; calRoot.currentYear-- }
                                else calRoot.currentMonth--
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: Qt.locale().monthName(calRoot.currentMonth) + " " + calRoot.currentYear
                        color: Services.Colors.snow
                        font.pixelSize: 14
                        font.family: "JetBrainsMono NF"
                        font.bold: true
                    }

                    Rectangle {
                        width: 26; height: 26; radius: 8; color: "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: "\u203a"
                            color: Services.Colors.ghost
                            font.pixelSize: 18
                            font.family: "JetBrainsMono NF"
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onEntered: parent.color = Services.Colors.ghostAlpha(0.15)
                            onExited: parent.color = "transparent"
                            onClicked: {
                                if (calRoot.currentMonth === 11) { calRoot.currentMonth = 0; calRoot.currentYear++ }
                                else calRoot.currentMonth++
                            }
                        }
                    }

                    Rectangle {
                        width: 26; height: 26; radius: 8; color: "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: ""
                            color: Services.Colors.ghost
                            font.pixelSize: 15
                            font.family: "Material Symbols Rounded"
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onEntered: parent.color = Services.Colors.ghostAlpha(0.15)
                            onExited: parent.color = "transparent"
                            onClicked: {
                                calRoot.currentMonth = calRoot.todayMonth
                                calRoot.currentYear = calRoot.todayYear
                            }
                        }
                    }
                }

                Row {
                    width: parent.width
                    Repeater {
                        model: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
                        Text {
                            width: calCol.width / 7
                            horizontalAlignment: Text.AlignHCenter
                            text: modelData
                            color: Services.Colors.ash
                            font.pixelSize: 11
                            font.family: "JetBrainsMono NF"
                        }
                    }
                }

                Grid {
                    id: calRoot
                    width: parent.width
                    columns: 7
                    spacing: 3

                    // fixed cell size + a reserved height of 6 rows, so a 5-week
                    // month doesn't shrink the grid and shift the whole (centered)
                    // calendar column up/down when flipping months.
                    readonly property int cellSize: Math.min(calCol.width / 7 - 3, 32)
                    height: 6 * cellSize + 5 * spacing

                    property int currentMonth: new Date().getMonth()
                    property int currentYear: new Date().getFullYear()
                    property int today: new Date().getDate()
                    property int todayMonth: new Date().getMonth()
                    property int todayYear: new Date().getFullYear()
                    property int firstDay: new Date(currentYear, currentMonth, 1).getDay()
                    property int daysInMonth: new Date(currentYear, currentMonth + 1, 0).getDate()

                    Repeater {
                        model: calRoot.firstDay + calRoot.daysInMonth
                        delegate: Rectangle {
                            required property int index
                            property int day: index - calRoot.firstDay + 1
                            property bool isValid: index >= calRoot.firstDay
                            property bool isToday: isValid && day === calRoot.today && calRoot.currentMonth === calRoot.todayMonth && calRoot.currentYear === calRoot.todayYear

                            width: calCol.width / 7 - 3
                            height: calRoot.cellSize
                            radius: 6
                            color: isToday ? Services.Colors.ghost : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: parent.isValid ? parent.day : ""
                                color: parent.isToday ? Services.Colors.abyss : Services.Colors.snow
                                font.pixelSize: 12
                                font.family: "JetBrainsMono NF"
                                font.bold: parent.isToday
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onEntered: if (!parent.isToday) parent.color = Services.Colors.ghostAlpha(0.15)
                                onExited: if (!parent.isToday) parent.color = "transparent"
                            }
                        }
                    }
                }
            }
        }

        // -- Right column: Weather --
        Rectangle {
            width: 185
            height: root.boxHeight
            radius: 14
            color: Services.Colors.surfaceAlpha(0.95)
            border.color: Services.Colors.ghostAlpha(0.2)
            border.width: 0
            MouseArea { anchors.fill: parent; onClicked: {} }

            Column {
                anchors.centerIn: parent
                spacing: 14
                width: parent.width - 24

                // Current conditions: big glyph beside the temperature, condition
                // under it, city name centered below.
                Column {
                    width: parent.width
                    spacing: 6

                    RowLayout {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 10
                        Text {
                            text: Services.Weather.icon
                            color: Services.Colors.ghost
                            font.pixelSize: 54
                            font.family: "Material Symbols Rounded"
                        }
                        ColumnLayout {
                            spacing: 0
                            Text {
                                text: Services.Weather.temp
                                color: Services.Colors.snow
                                font.pixelSize: 32
                                font.bold: true
                                font.family: "JetBrainsMono NF"
                            }
                            Text {
                                text: Services.Weather.condition
                                color: Services.Colors.mist
                                font.pixelSize: 10
                                font.family: "JetBrainsMono NF"
                            }
                        }
                    }
                    // City name (blank until located); full width so it never clips
                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: Services.Weather.city
                        visible: text !== ""
                        color: Services.Colors.ash
                        font.pixelSize: 9
                        font.family: "JetBrainsMono NF"
                        elide: Text.ElideRight
                    }
                }

                Rectangle { width: parent.width; height: 1; color: Services.Colors.ghostAlpha(0.15) }

                // Following days as side-by-side columns (Today is already the header
                // above, so it's skipped here via slice(1)).
                RowLayout {
                    width: parent.width
                    spacing: 4
                    Repeater {
                        model: Services.Weather.forecast.slice(1)
                        delegate: ColumnLayout {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1     // equal share regardless of content
                            spacing: 3

                            Text {
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                                text: modelData.label
                                color: Services.Colors.mist
                                font.pixelSize: 10
                                font.bold: true
                                font.family: "JetBrainsMono NF"
                            }
                            Text {
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                                text: modelData.icon
                                color: Services.Colors.ghost
                                font.pixelSize: 20
                                font.family: "Material Symbols Rounded"
                                topPadding: 2
                                bottomPadding: 2
                            }
                            Text {
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                                text: Services.Weather.degrees(modelData.maxC)
                                color: Services.Colors.snow
                                font.pixelSize: 11
                                font.bold: true
                                font.family: "JetBrainsMono NF"
                            }
                            Text {
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                                text: Services.Weather.degrees(modelData.minC)
                                color: Services.Colors.ash
                                font.pixelSize: 11
                                font.family: "JetBrainsMono NF"
                            }
                        }
                    }
                }
            }
        }
    }
}
