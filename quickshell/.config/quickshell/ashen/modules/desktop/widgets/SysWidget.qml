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

    // Wide, not tall: a board reads across, and the past is the thing that
    // wants the room. The left column is what the machine is doing right now;
    // the right is everything else it has to say.
    Component {
        id: largeShape
        Row {
            id: board
            spacing: 18

            Column {
                id: main
                width: 320
                spacing: 8
                anchors.verticalCenter: parent.verticalCenter

                WidgetHead {
                    width: main.width
                    glyph: ""
                    name: Services.I18n.t("widget.cpu")
                    note: ""
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
                    width: main.width
                    height: 96
                    samples: Services.SysMon.cpuHistory
                    reading: root.cpuTempText
                }
            }

            Column {
                id: side
                width: 210
                spacing: 10
                anchors.verticalCenter: parent.verticalCenter

                // Only when there is one awake to talk about: the laptop's
                // discrete card sleeps, and a row of empty ticks says nothing.
                WidgetHead {
                    width: side.width
                    visible: Services.SysMon.gpuPercent > 0
                    glyph: ""
                    name: Services.I18n.t("widget.gpu")
                    note: Math.round(Services.SysMon.gpuPercent) + "%"
                }
                Past {
                    width: side.width
                    height: 46
                    visible: Services.SysMon.gpuPercent > 0
                    samples: Services.SysMon.gpuHistory
                    reading: root.gpuTempText
                    tone: Services.Colors.neutral
                }

                WidgetHead {
                    width: side.width
                    glyph: ""
                    name: Services.I18n.t("widget.memory")
                    note: (Services.SysMon.ramUsedMB / 1024).toFixed(1) + "G"
                }
                Level {
                    width: side.width
                    reading: (Services.SysMon.ramUsedMB / 1024).toFixed(1) + "G / "
                             + (Services.SysMon.ramTotalMB / 1024).toFixed(0) + "G"
                    value: root.ramFrac
                }

                WidgetHead {
                    width: side.width
                    glyph: ""
                    name: Services.I18n.t("widget.storage")
                    note: Services.SysMon.diskPercent + "%"
                }
                Level {
                    width: side.width
                    reading: Math.round(Services.SysMon.diskUsedGB) + " / "
                             + Math.round(Services.SysMon.diskTotalGB) + " GB"
                    value: Services.SysMon.diskPercent / 100
                    tone: Services.Colors.neutral
                }
            }
        }
    }

    Component {
        id: mediumShape
        Column {
            id: mid
            width: 300
            spacing: 10

            WidgetHead {
                width: mid.width
                glyph: ""
                name: Services.I18n.t("widget.cpu")
                note: Math.round(Services.SysMon.cpuPercent) + "%"
            }
            Past {
                width: mid.width
                height: 62
                samples: Services.SysMon.cpuHistory
                reading: root.cpuTempText
            }

            WidgetHead {
                width: mid.width
                glyph: ""
                name: Services.I18n.t("widget.memory")
                note: (Services.SysMon.ramUsedMB / 1024).toFixed(1) + "G"
            }
            Level {
                width: mid.width
                reading: (Services.SysMon.ramUsedMB / 1024).toFixed(1) + "G"
                value: root.ramFrac
            }

            WidgetHead {
                width: mid.width
                glyph: ""
                name: Services.I18n.t("widget.storage")
                note: Services.SysMon.diskPercent + "%"
            }
            Level {
                width: mid.width
                reading: Math.round(Services.SysMon.diskUsedGB) + " GB"
                value: Services.SysMon.diskPercent / 100
                tone: Services.Colors.neutral
            }
        }
    }

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
