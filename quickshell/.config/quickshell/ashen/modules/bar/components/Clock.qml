import QtQuick
import QtQuick.Layouts

import "root:/services" as Services

Rectangle {
    id: root
    property string currentTime: ""
    property string currentDate: ""
    property string timeIcon: ""

    height: 44
    width: clockRow.implicitWidth + 40
    radius: 10
    color: Qt.rgba(0x1d/255, 0x1d/255, 0x24/255, 0.82)
    border.color: Qt.rgba(0x24/255, 0x24/255, 0x2d/255, 0.5)
    border.width: 1

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Services.AppState.calendarVisible = !Services.AppState.calendarVisible
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            let now = new Date()
            let h = now.getHours()
            root.currentTime = Qt.formatDateTime(now, "hh:mm:ss AP")
            root.currentDate = Qt.formatDateTime(now, "ddd, MMM d")
            if (h >= 0 && h < 5)        root.timeIcon = ""
            else if (h >= 5 && h < 8)   root.timeIcon = ""
            else if (h >= 8 && h < 17)  root.timeIcon = ""
            else if (h >= 17 && h < 20) root.timeIcon = ""
            else                         root.timeIcon = ""
        }
    }

    RowLayout {
        id: clockRow
        anchors.centerIn: parent
        spacing: 16

        Column {
            spacing: 1
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.currentTime
                color: "#d4d4e0"
                font.pixelSize: 15
                font.family: "JetBrainsMono NF"
                font.bold: true
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.currentDate
                color: "#7878a0"
                font.pixelSize: 10
                font.family: "JetBrainsMono NF"
            }
        }

        Text {
            text: root.timeIcon
            font.pixelSize: 24
            font.family: "Material Symbols Rounded"
            color: {
                let h = new Date().getHours()
                if (h >= 0 && h < 5)        return "#aab4d4"
                else if (h >= 5 && h < 8)   return "#c4a882"
                else if (h >= 8 && h < 17)  return "#c4c882"
                else if (h >= 17 && h < 20) return "#c4a882"
                else                         return "#8899cc"
            }
        }
    }
}
