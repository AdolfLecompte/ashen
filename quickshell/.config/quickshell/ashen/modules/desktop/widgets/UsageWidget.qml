import Quickshell
import QtQuick

import "root:/modules/desktop"
import "root:/modules/widgets" as Widgets
import "root:/services" as Services

// Screen time on the wallpaper, in the panel's own language: the day's total
// against the week's average, and then one of three things under it -- the
// applications that had you, the day's hours, or the week as bars.
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
    // The last seven days that had anything counted, today included.
    readonly property real average: {
        const had = root.week.filter(d => d.total >= 60)
        return had.length ? had.reduce((a, d) => a + d.total, 0) / had.length : 0
    }
    readonly property real delta: root.today.total - root.average
    readonly property bool empty: root.today.total < 60 && root.today.apps.length === 0
    property string emptyLine: Services.Voice.pick("usage.empty")

    // Every shape is 440 x 152: with the plate's padding that lands on the 48
    // grid at 480 x 192, 20 px on every side.
    component Head: Item {
        width: 440
        height: 40
        Text {
            textFormat: Text.PlainText
            id: headGlyph
            anchors.verticalCenter: parent.verticalCenter
            text: ""
            color: Services.Colors.ghost
            font.pixelSize: 26
            font.family: "Material Symbols Rounded"
        }
        Text {
            textFormat: Text.PlainText
            anchors.left: headGlyph.right
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: Services.Usage.span(root.today.total)
            color: Services.Colors.snow
            font.pixelSize: 30
            font.bold: true
            font.family: "JetBrainsMono NF"
        }
        // Against the average: the arrow says which way, the number how far.
        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4
            visible: root.average >= 60 && Math.abs(root.delta) >= 60
            Text {
                textFormat: Text.PlainText
                anchors.verticalCenter: parent.verticalCenter
                text: root.delta > 0 ? "" : ""
                color: root.delta > 0 ? Services.Colors.ghost : Services.Colors.mist
                font.pixelSize: 18
                font.family: "Material Symbols Rounded"
            }
            Text {
                textFormat: Text.PlainText
                anchors.verticalCenter: parent.verticalCenter
                text: Services.Usage.span(Math.abs(root.delta))
                color: Services.Colors.mist
                font.pixelSize: Services.Sizes.fsInput
                font.bold: true
                font.family: "JetBrainsMono NF"
            }
        }
    }

    // ── Today: the applications that had you ─────────────────────────────
    Component {
        id: todayShape
        Item {
            width: 440
            height: 152
            Head { id: head }
            Column {
                y: head.height + 12
                width: parent.width
                spacing: 6
                visible: !root.empty
                readonly property real most: root.today.apps.length ? root.today.apps[0].secs : 1
                Repeater {
                    model: root.today.apps.slice(0, 3)
                    delegate: Item {
                        required property var modelData
                        width: parent.width
                        height: 28
                        Text {
                            textFormat: Text.PlainText
                            anchors.left: parent.left
                            anchors.right: appTime.left
                            anchors.rightMargin: 10
                            text: Services.Usage.nameOf(modelData.key)
                            color: Services.Colors.snow
                            font.pixelSize: Services.Sizes.fsInput
                            font.family: "JetBrainsMono NF"
                            elide: Text.ElideRight
                        }
                        Text {
                            textFormat: Text.PlainText
                            id: appTime
                            anchors.right: parent.right
                            text: Services.Usage.span(modelData.secs)
                            color: Services.Colors.mist
                            font.pixelSize: Services.Sizes.fsBody
                            font.family: "JetBrainsMono NF"
                        }
                        // The storage bar: a track and its share.
                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 5
                            radius: 2.5
                            color: Services.Colors.fillLine
                            Rectangle {
                                width: Math.max(parent.height, parent.width * modelData.secs / parent.parent.parent.most)
                                height: parent.height
                                radius: parent.radius
                                color: Services.Colors.ghost
                                gradient: Services.Prefs.useGradients ? Services.Colors.accentGradient : null
                            }
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

    // ── Hours: the shape of the day ──────────────────────────────────────
    // The panel's stepped curve: each hour holds its own level.
    Component {
        id: hoursShape
        Item {
            width: 440
            height: 152
            Head { id: hhead }
            Widgets.Trend {
                id: curve
                y: hhead.height + 10
                width: parent.width
                height: 80
                stepped: true
                cornerR: 6
                values: {
                    const h = root.today.hours || []
                    return (h.length === 24 ? h : new Array(24).fill(0)).map(s => s / 60)
                }
                maxValue: 60
            }
            Repeater {
                model: [0, 6, 12, 18]
                delegate: Text {
                    textFormat: Text.PlainText
                    required property int modelData
                    x: Math.max(0, Math.min(440 - width, 440 * (modelData + 0.5) / 24 - width / 2))
                    anchors.top: curve.bottom
                    anchors.topMargin: 4
                    text: Services.Prefs.clock24h
                        ? (modelData < 10 ? "0" : "") + modelData + ":00"
                        : (modelData % 12 === 0 ? 12 : modelData % 12) + (modelData < 12 ? " am" : " pm")
                    color: Services.Colors.ash
                    font.pixelSize: Services.Sizes.fsMeta
                    font.family: "JetBrainsMono NF"
                }
            }
        }
    }

    // ── Week: a plain bar chart ──────────────────────────────────────────
    Component {
        id: weekShape
        Item {
            width: 440
            height: 152
            Head { id: whead }
            Row {
                id: cols
                y: whead.height + 10
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
                        Text {
                            textFormat: Text.PlainText
                            id: dayName
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            text: Services.I18n.locale.dayName(modelData.date.getDay(), Locale.ShortFormat)
                            color: parent.isToday ? Services.Colors.snow : Services.Colors.mist
                            font.pixelSize: Services.Sizes.fsMeta
                            font.bold: parent.isToday
                            font.family: "JetBrainsMono NF"
                        }
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: dayName.top
                            anchors.bottomMargin: 6
                            readonly property real room: parent.height - dayName.height - 6
                            width: Math.min(28, parent.width - 14)
                            height: modelData.total < 60 ? 0 : Math.max(4, room * modelData.total / root.weekMax)
                            radius: 5
                            color: parent.isToday ? Services.Colors.ghost
                                 : Services.Colors.tint(Services.Colors.fillLine, Services.Colors.ghost, 0.45)
                        }
                    }
                }
            }
        }
    }

    Loader {
        sourceComponent: root.style === "week" ? weekShape
                       : root.style === "hours" ? hoursShape
                       : todayShape
    }
}
