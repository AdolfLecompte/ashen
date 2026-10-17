import Quickshell
import QtQuick

import "root:/modules/desktop"
import "root:/modules/widgets" as Widgets
import "root:/services" as Services

// Screen time on the wallpaper: today's total in the cap, and under it the
// apps that had you, the day's hours, or the week as bars.
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

    readonly property int boxW: 340

    component Head: WidgetHead {
        implicitWidth: root.boxW
        glyph: ""
        name: Services.I18n.t("widget.screenTime")
        note: Services.Usage.span(root.today.total)
    }

    // One app: its icon on a badge, name and time, and its share as a bar.
    component AppLine: Item {
        id: ln
        property var entry: null
        readonly property var app: ln.entry ? Services.Usage.appOf(ln.entry.key) : null
        property real most: 1
        implicitWidth: root.boxW
        implicitHeight: 34

        Rectangle {
            id: badge
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 34
            height: 34
            radius: Services.Sizes.innerR
            color: Services.Colors.fillLine

            Image {
                id: icon
                anchors.centerIn: parent
                width: 22
                height: 22
                source: {
                    const a = ln.app
                    if (!a || !a.icon) return ""
                    return a.icon.startsWith("/") ? ("file://" + a.icon)
                        : Quickshell.iconPath(a.icon, "application-x-executable")
                }
                sourceSize.width: 44
                sourceSize.height: 44
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                visible: status === Image.Ready
            }
            Text {
                textFormat: Text.PlainText
                anchors.centerIn: parent
                visible: icon.status !== Image.Ready
                text: ln.entry ? Services.Windows.iconForClass(ln.entry.key) : ""
                color: Services.Colors.ghost
                font.pixelSize: 18
                font.family: "Material Symbols Rounded"
            }
        }

        Text {
            textFormat: Text.PlainText
            anchors.left: badge.right
            anchors.leftMargin: 10
            anchors.right: time.left
            anchors.rightMargin: 8
            anchors.top: parent.top
            text: ln.entry ? Services.Usage.nameOf(ln.entry.key) : ""
            color: Services.Colors.snow
            font.pixelSize: Services.Sizes.fsBody
            font.bold: true
            font.family: "JetBrainsMono NF"
            elide: Text.ElideRight
        }
        Text {
            textFormat: Text.PlainText
            id: time
            anchors.right: parent.right
            anchors.top: parent.top
            text: ln.entry ? Services.Usage.span(ln.entry.secs) : ""
            color: Services.Colors.mist
            font.pixelSize: Services.Sizes.fsCaption
            font.bold: true
            font.family: "JetBrainsMono NF"
        }

        Rectangle {
            anchors.left: badge.right
            anchors.leftMargin: 10
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 10
            radius: 5
            color: Services.Colors.fillLine

            Rectangle {
                width: Math.max(parent.height, parent.width * (ln.entry ? ln.entry.secs : 0) / ln.most)
                height: parent.height
                radius: parent.radius
                color: Services.Colors.ghost
                gradient: Services.Prefs.useGradients ? Services.Colors.accentGradient : null
                Behavior on width { Widgets.Anim {} }
            }
        }
    }

    // Nothing counted yet: said plainly, as the notifications widget does.
    component Quiet: Item {
        implicitWidth: root.boxW
        implicitHeight: 46
        Text {
            textFormat: Text.PlainText
            anchors.centerIn: parent
            text: root.emptyLine
            color: Services.Colors.mist
            font.pixelSize: Services.Sizes.fsBody
            font.family: "JetBrainsMono NF"
        }
    }

    // ── Today: the applications that had you ─────────────────────────────
    component Today: Column {
        spacing: 10
        Head {}
        Repeater {
            model: root.empty ? [] : root.today.apps.slice(0, 3)
            AppLine {
                required property var modelData
                entry: modelData
                most: root.today.apps.length ? root.today.apps[0].secs : 1
            }
        }
        Quiet { visible: root.empty }
    }

    // ── Hours: the panel's stepped curve ─────────────────────────────────
    component Hours: Column {
        spacing: 10
        Head {}
        Item {
            width: root.boxW
            height: 104
            Widgets.Trend {
                id: curve
                width: parent.width
                height: 84
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
                    x: Math.max(0, Math.min(root.boxW - width, root.boxW * (modelData + 0.5) / 24 - width / 2))
                    anchors.bottom: parent.bottom
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
    component Week: Column {
        spacing: 10
        Head {}
        Row {
            id: cols
            width: root.boxW
            height: 104
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
                        width: 10
                        height: room
                        radius: 5
                        color: Services.Colors.fillLine
                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: modelData.total < 60 ? 0 : Math.max(parent.width, parent.room * modelData.total / root.weekMax)
                            radius: parent.radius
                            color: Services.Colors.ghost
                            opacity: parent.parent.isToday ? 1 : 0.55
                            gradient: Services.Prefs.useGradients ? Services.Colors.accentGradient : null
                            Behavior on height { Widgets.Anim {} }
                        }
                    }
                }
            }
        }
    }

    Component { id: todayShape; Today {} }
    Component { id: hoursShape; Hours {} }
    Component { id: weekShape; Week {} }

    Loader {
        sourceComponent: root.style === "week" ? weekShape
                       : root.style === "hours" ? hoursShape
                       : todayShape
    }
}
