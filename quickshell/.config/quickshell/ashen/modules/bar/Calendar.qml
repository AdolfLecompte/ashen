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
    visible: Services.AppState.calendarVisible

    property string currentTime: ""
    property string currentDate: ""
    property string currentDayName: ""

    Timer {
        interval: 1000
        running: root.visible
        repeat: true
        onTriggered: {
            let now = new Date()
            root.currentTime = Qt.formatDateTime(now, "hh:mm:ss AP")
            root.currentDate = Qt.formatDateTime(now, "MMMM d, yyyy")
            root.currentDayName = Qt.locale().dayName(now.getDay())
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: Services.AppState.calendarVisible = false
    }

    Column {
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 64
        spacing: 8
        opacity: Services.AppState.calendarVisible ? 1.0 : 0.0
        scale: Services.AppState.calendarVisible ? 1.0 : 0.92
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        // ── Caja superior ──────────────────────────
        Rectangle {
            width: 320
            height: 80
            radius: 14
            color: Qt.rgba(0x1d/255, 0x1d/255, 0x24/255, 0.95)
            border.color: Qt.rgba(0x24/255, 0x24/255, 0x2d/255, 0.5)
            border.width: 1

            MouseArea { anchors.fill: parent; onClicked: {} }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20

                Column {
                    spacing: 2
                    Layout.fillWidth: true
                    Text {
                        text: root.currentDayName
                        color: "#6272a4"
                        font.pixelSize: 12
                        font.family: "JetBrainsMono NF"
                        font.bold: true
                    }
                    Text {
                        text: root.currentDate
                        color: "#d4d4e0"
                        font.pixelSize: 15
                        font.family: "JetBrainsMono NF"
                        font.bold: true
                    }
                }

                Rectangle {
                    width: 1; height: 40
                    color: Qt.rgba(0x62/255, 0x72/255, 0xa4/255, 0.3)
                }

                Text {
                    text: root.currentTime
                    color: "#d4d4e0"
                    font.pixelSize: 14
                    font.family: "JetBrainsMono NF"
                    font.bold: true
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }

        // ── Caja inferior — Calendario ──────────────
        Rectangle {
            width: 320
            height: calCol.implicitHeight + 28
            radius: 14
            color: Qt.rgba(0x1d/255, 0x1d/255, 0x24/255, 0.95)
            border.color: Qt.rgba(0x24/255, 0x24/255, 0x2d/255, 0.5)
            border.width: 1

            MouseArea { anchors.fill: parent; onClicked: {} }

            Column {
                id: calCol
                anchors.centerIn: parent
                spacing: 10
                width: parent.width - 28

                // Header — mes a la izquierda, navegacion a la derecha
                RowLayout {
                    width: parent.width

                    Text {
                        Layout.fillWidth: true
                        text: Qt.locale().monthName(calRoot.currentMonth) + " " + calRoot.currentYear
                        color: "#d4d4e0"
                        font.pixelSize: 14
                        font.family: "JetBrainsMono NF"
                        font.bold: true
                    }

                    // Flecha izquierda
                    Rectangle {
                        width: 28; height: 28; radius: 8; color: "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: "‹"
                            color: "#6272a4"
                            font.pixelSize: 20
                            font.family: "JetBrainsMono NF"
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onEntered: parent.color = Qt.rgba(0x62/255, 0x72/255, 0xa4/255, 0.15)
                            onExited: parent.color = "transparent"
                            onClicked: {
                                if (calRoot.currentMonth === 0) { calRoot.currentMonth = 11; calRoot.currentYear-- }
                                else calRoot.currentMonth--
                            }
                        }
                    }

                    // Casita — volver a hoy
                    Rectangle {
                        width: 28; height: 28; radius: 8; color: "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: ""
                            color: "#6272a4"
                            font.pixelSize: 16
                            font.family: "Material Symbols Rounded"
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onEntered: parent.color = Qt.rgba(0x62/255, 0x72/255, 0xa4/255, 0.15)
                            onExited: parent.color = "transparent"
                            onClicked: {
                                calRoot.currentMonth = calRoot.todayMonth
                                calRoot.currentYear = calRoot.todayYear
                            }
                        }
                    }

                    // Flecha derecha
                    Rectangle {
                        width: 28; height: 28; radius: 8; color: "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: "›"
                            color: "#6272a4"
                            font.pixelSize: 20
                            font.family: "JetBrainsMono NF"
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onEntered: parent.color = Qt.rgba(0x62/255, 0x72/255, 0xa4/255, 0.15)
                            onExited: parent.color = "transparent"
                            onClicked: {
                                if (calRoot.currentMonth === 11) { calRoot.currentMonth = 0; calRoot.currentYear++ }
                                else calRoot.currentMonth++
                            }
                        }
                    }
                }

                // Dias de semana
                Row {
                    width: parent.width
                    Repeater {
                        model: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
                        Text {
                            width: calCol.width / 7
                            horizontalAlignment: Text.AlignHCenter
                            text: modelData
                            color: "#404052"
                            font.pixelSize: 11
                            font.family: "JetBrainsMono NF"
                        }
                    }
                }

                // Grid dias
                Grid {
                    id: calRoot
                    width: parent.width
                    columns: 7
                    spacing: 2

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

                            width: calCol.width / 7 - 2
                            height: width
                            radius: width / 2
                            color: isToday ? "#6272a4" : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: parent.isValid ? parent.day : ""
                                color: parent.isToday ? "#0f0f12" : "#d4d4e0"
                                font.pixelSize: 12
                                font.family: "JetBrainsMono NF"
                                font.bold: parent.isToday
                            }
                        }
                    }
                }
            }
        }
    }
}
