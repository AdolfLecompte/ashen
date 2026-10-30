import QtQuick

import "root:/modules/desktop"
import "root:/modules/widgets" as Widgets
import "root:/services" as Services

// What the machine is doing. Content only, like every other widget out here:
// the plate belongs to the widget, and a card inside it is the double plate
// this rice threw out. What it borrows from the Process panel is the
// vocabulary, not its surface -- a glyph with a spaced NAME, the figure on the
// right, and every reading drawn as ticks: a past as a row of samples, a level
// as a row lit up to it. There is no other way to draw one, so there is no
// option for it.
DesktopWidget {
    id: root
    wid: "system"

    // Sampling is refcounted in the service: the Process panel opening and
    // closing must not switch the desktop's numbers off. The claim is keyed by
    // this very copy: the lock draws one per output and the desktop one per
    // screen, and with a shared "lock" key the first surface to go took the
    // sampling from the rest -- the lock's ticks froze. A full claim, so
    // SysMon keeps the histories the ticks draw.
    readonly property string claimant: "sys@" + String(root)
    Component.onCompleted: Services.SysMon.claim(root.claimant, root.live)
    Component.onDestruction: Services.SysMon.claim(root.claimant, false)
    onLiveChanged: Services.SysMon.claim(root.claimant, root.live)

    readonly property real ramFrac: Services.SysMon.ramTotalMB > 0
        ? Services.SysMon.ramUsedMB / Services.SysMon.ramTotalMB : 0
    readonly property string cpuTempText: Services.SysMon.cpuTemp > 0
        ? Math.round(Services.SysMon.cpuTemp) + "°" : ""
    readonly property string gpuTempText: Services.SysMon.gpuTemp > 0
        ? Math.round(Services.SysMon.gpuTemp) + "°" : ""

    // A level: an optional glyph, the figure, then ticks lit up to it.
    component Level: Item {
        id: lv
        property string glyph: ""
        property string reading: ""
        property real value: 0
        property color tone: Services.Colors.ghost

        implicitHeight: 30

        Row {
            id: lvText
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6
            Text {
                textFormat: Text.PlainText
                visible: lv.glyph !== ""
                anchors.verticalCenter: parent.verticalCenter
                text: lv.glyph
                color: Services.Colors.mist
                font.pixelSize: 15
                font.family: "Material Symbols Rounded"
            }
            Text {
                textFormat: Text.PlainText
                anchors.verticalCenter: parent.verticalCenter
                text: lv.reading
                color: Services.Colors.snow
                font.pixelSize: Services.Sizes.fsBody
                font.bold: true
                font.family: "JetBrainsMono NF"
                font.letterSpacing: 1.1
            }
        }
        Widgets.TickMeter {
            anchors.left: lvText.right
            anchors.leftMargin: 10
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: 18
            mode: "level"
            value: lv.value
            color_: lv.tone
        }
    }

    // A past: the last samples as ticks, with the temperature over their live
    // end -- the same idea as the day's temperature written over its hour.
    component Past: Item {
        id: ps
        property var samples: []
        property string reading: ""
        property color tone: Services.Colors.ghost

        Text {
            textFormat: Text.PlainText
            id: psReading
            anchors.right: parent.right
            anchors.top: parent.top
            visible: ps.reading !== ""
            text: ps.reading
            color: Services.Colors.snow
            font.pixelSize: Services.Sizes.fsBody
            font.bold: true
            font.family: "JetBrainsMono NF"
        }
        Widgets.TickMeter {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.top: psReading.visible ? psReading.bottom : parent.top
            anchors.topMargin: psReading.visible ? 4 : 0
            mode: "history"
            samples: ps.samples
            tickW: 5
            gap: 4
            color_: ps.tone
        }
    }

    // KB/s as the shortest honest figure.
    function rate(kb) { return kb >= 1024 ? (kb / 1024).toFixed(1) + "M" : Math.round(kb) + "K" }

    // Medium: the compact vocabulary with the CPU's last minute under its level.
    component Rows: Column {
        id: rows
        width: 300
        spacing: 8

        WidgetHead {
            width: rows.width
            glyph: ""
            name: Services.I18n.t("widget.system")
            note: root.cpuTempText
        }
        Level {
            width: rows.width
            glyph: ""
            reading: Math.round(Services.SysMon.cpuPercent) + "%"
            value: Services.SysMon.cpuPercent / 100
        }
        Past {
            width: rows.width
            height: 34
            samples: Services.SysMon.cpuHistory
        }
        Level {
            width: rows.width
            glyph: ""
            reading: (Services.SysMon.ramUsedMB / 1024).toFixed(1) + "G / "
                     + (Services.SysMon.ramTotalMB / 1024).toFixed(0) + "G"
            value: root.ramFrac
        }
        Level {
            width: rows.width
            glyph: ""
            reading: Services.SysMon.diskPercent + "%"
            value: Services.SysMon.diskPercent / 100
            tone: Services.Colors.neutral
        }
    }

    // Large: a board read across. Left, the CPU large with its minute; right,
    // everything else, the network with its own past.
    component Board: Row {
        spacing: 24

        Column {
            id: left
            width: 270
            spacing: 6
            WidgetHead {
                width: left.width
                glyph: ""
                name: Services.I18n.t("widget.cpu")
                note: root.cpuTempText
            }
            Text {
                textFormat: Text.PlainText
                text: Math.round(Services.SysMon.cpuPercent) + "%"
                color: Services.Colors.snow
                font.pixelSize: Services.Sizes.fsHero
                font.bold: true
                font.family: "JetBrainsMono NF"
            }
            Past {
                width: left.width
                height: 70
                samples: Services.SysMon.cpuHistory
            }
        }

        Column {
            id: right
            width: 250
            spacing: 10
            anchors.verticalCenter: parent.verticalCenter
            Level {
                width: right.width
                visible: Services.SysMon.gpuPercent > 0
                glyph: ""
                reading: Math.round(Services.SysMon.gpuPercent) + "%"
                value: Services.SysMon.gpuPercent / 100
                tone: Services.Colors.neutral
            }
            Level {
                width: right.width
                glyph: ""
                reading: (Services.SysMon.ramUsedMB / 1024).toFixed(1) + "G"
                value: root.ramFrac
            }
            Level {
                width: right.width
                glyph: ""
                reading: Services.SysMon.diskPercent + "%"
                value: Services.SysMon.diskPercent / 100
                tone: Services.Colors.neutral
            }
            Past {
                width: right.width
                height: 46
                samples: Services.SysMon.netHistory
                reading: "↓ " + root.rate(Services.SysMon.netRxKBs) + "  ↑ " + root.rate(Services.SysMon.netTxKBs)
                tone: Services.Colors.neutral
            }
        }
    }

    Component { id: largeShape; Board {} }
    Component { id: mediumShape; Rows {} }

    // Three levels on three lines: each one carries its glyph, or they would be
    // three identical rows of ticks with a number in front.
    Component {
        id: compactShape
        Column {
            id: small
            width: 230
            spacing: 8

            WidgetHead {
                width: small.width
                glyph: ""
                name: Services.I18n.t("widget.system")
                note: root.cpuTempText
            }
            Level {
                width: small.width
                glyph: ""
                reading: Math.round(Services.SysMon.cpuPercent) + "%"
                value: Services.SysMon.cpuPercent / 100
            }
            Level {
                width: small.width
                glyph: ""
                reading: (Services.SysMon.ramUsedMB / 1024).toFixed(1) + "G"
                value: root.ramFrac
            }
            Level {
                width: small.width
                glyph: ""
                reading: Services.SysMon.diskPercent + "%"
                value: Services.SysMon.diskPercent / 100
                tone: Services.Colors.neutral
            }
        }
    }

    Loader {
        sourceComponent: root.style === "compact" ? compactShape
                       : root.style === "medium" ? mediumShape
                       : largeShape
    }
}
