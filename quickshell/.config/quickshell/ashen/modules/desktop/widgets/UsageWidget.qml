import Quickshell
import QtQuick

import "root:/modules/desktop"
import "root:/modules/widgets" as Widgets
import "root:/services" as Services

// Screen time on the wallpaper: today's total with the apps that had it, or the
// week as seven columns. The same numbers as the panel, from Services.Usage.
DesktopWidget {
    id: root
    wid: "usage"

    // Minutes change no faster than this, and only while it is on screen.
    property int beat: 0
    Timer { interval: 60000; running: root.live; repeat: true; onTriggered: root.beat++ }
    onLiveChanged: if (root.live) root.beat++
    readonly property var today: { root.beat; Services.Usage.revision; return Services.Usage.today() }
    readonly property var week: { root.beat; Services.Usage.revision; return Services.Usage.week() }
    readonly property real weekMax: Math.max(3600, ...root.week.map(d => d.total))
    readonly property bool empty: root.today.total < 60 && root.today.apps.length === 0
    property string emptyLine: Services.Voice.pick("usage.empty")

    // The same box for both shapes, sized for the 48 grid: 440 x 152 plus the
    // plate's padding lands on 480 x 192, 20 px on every side.
    component Head: Row {
        spacing: 10
        height: 44
        Text {
            textFormat: Text.PlainText
            anchors.verticalCenter: parent.verticalCenter
            text: ""
            color: Services.Colors.ghost
            font.pixelSize: 26
            font.family: "Material Symbols Rounded"
        }
        Text {
            textFormat: Text.PlainText
            anchors.verticalCenter: parent.verticalCenter
            text: Services.Usage.span(root.today.total)
            color: Services.Colors.snow
            font.pixelSize: Services.Sizes.fsReadout
            font.bold: true
            font.family: "JetBrainsMono NF"
        }
    }

    Component {
        id: todayShape
        Item {
            width: 440
            height: 152
            Head { id: head }
            Column {
                y: head.height + 16
                width: parent.width
                spacing: 10
                visible: !root.empty
                Repeater {
                    model: root.today.apps.slice(0, 3)
                    delegate: Item {
                        required property var modelData
                        width: parent.width
                        height: 24
                        Text {
                            textFormat: Text.PlainText
                            id: appName
                            anchors.verticalCenter: parent.verticalCenter
                            width: 140
                            text: Services.Usage.nameOf(modelData.key)
                            color: Services.Colors.snow
                            font.pixelSize: Services.Sizes.fsInput
                            font.family: "JetBrainsMono NF"
                            elide: Text.ElideRight
                        }
                        Widgets.TickMeter {
                            anchors.left: appName.right
                            anchors.leftMargin: 10
                            anchors.right: appTime.left
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            height: 14
                            mode: "level"
                            tickW: 3
                            gap: 2
                            value: root.today.apps.length > 0 ? modelData.secs / root.today.apps[0].secs : 0
                            color_: Services.Colors.ghost
                        }
                        Text {
                            textFormat: Text.PlainText
                            id: appTime
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            width: 64
                            horizontalAlignment: Text.AlignRight
                            text: Services.Usage.span(modelData.secs)
                            color: Services.Colors.mist
                            font.pixelSize: Services.Sizes.fsInput
                            font.bold: true
                            font.family: "JetBrainsMono NF"
                        }
                    }
                }
            }
            Text {
                textFormat: Text.PlainText
                y: head.height + 16
                width: parent.width
                visible: root.empty
                text: root.emptyLine
                color: Services.Colors.mist
                font.pixelSize: Services.Sizes.fsInput
                font.family: "JetBrainsMono NF"
            }
        }
    }

    Component {
        id: weekShape
        Item {
            width: 440
            height: 152
            Head { id: whead }
            Row {
                id: cols
                y: whead.height + 12
                width: parent.width
                height: parent.height - y
                Repeater {
                    model: root.week
                    delegate: Item {
                        required property var modelData
                        required property int index
                        readonly property bool isToday: index === root.week.length - 1
                        width: cols.width / 7
                        height: cols.height
                        // Ticks stood on end, lit from the bottom.
                        Widgets.TickMeter {
                            width: parent.height - 20
                            height: 14
                            rotation: -90
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.top
                            anchors.topMargin: (parent.height - 20 - 14) / 2
                            mode: "level"
                            tickW: 4
                            gap: 3
                            value: modelData.total / root.weekMax
                            color_: parent.isToday ? Services.Colors.ghost : Services.Colors.mist
                        }
                        Text {
                            textFormat: Text.PlainText
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            text: Services.I18n.locale.dayName(modelData.date.getDay(), Locale.NarrowFormat).toUpperCase()
                            color: parent.isToday ? Services.Colors.snow : Services.Colors.ash
                            font.pixelSize: Services.Sizes.fsMeta
                            font.bold: parent.isToday
                            font.family: "JetBrainsMono NF"
                        }
                    }
                }
            }
        }
    }

    Loader {
        sourceComponent: root.style === "week" ? weekShape : todayShape
    }
}
