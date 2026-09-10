import QtQuick

import "root:/modules/desktop"
import "root:/modules/widgets" as Widgets
import "root:/services" as Services

// What the machine is doing. Content only, like every other widget out here:
// the plate belongs to the widget, and a card inside it is the double plate
// this rice threw out. What it borrows from the Process panel is the
// vocabulary, not its surface -- a glyph with a spaced NAME, the figure on the
// right, a past drawn as a curve and a level drawn as liquid.
DesktopWidget {
    id: root
    wid: "system"

    // Sampling is refcounted in the service: the Process panel opening and
    // closing must not switch the desktop's numbers off. The claim is keyed by
    // WHO, so the lock's copy claims under its own name -- sharing the key,
    // the one that went away would switch the other one's numbers off.
    readonly property string claimant: root.managed ? "desktop" : "lock"
    Component.onCompleted: Services.SysMon.claim(root.claimant, root.live)
    Component.onDestruction: Services.SysMon.claim(root.claimant, false)
    onLiveChanged: Services.SysMon.claim(root.claimant, root.live)

    // The service keeps no history, so the widget keeps its own: the last forty
    // samples, oldest first.
    property var cpuHistory: []
    property var gpuHistory: []
    property var ramHistory: []
    Connections {
        target: Services.SysMon
        enabled: root.live
        function onCpuPercentChanged() {
            const next = root.cpuHistory.slice(-39)
            next.push(Services.SysMon.cpuPercent)
            root.cpuHistory = next

            // Sampled on the same beat, so the two curves line up in time.
            const g = root.gpuHistory.slice(-39)
            g.push(Services.SysMon.gpuPercent)
            root.gpuHistory = g

            const r = root.ramHistory.slice(-39)
            r.push(root.ramFrac * 100)
            root.ramHistory = r
        }
    }

    // Forty samples drawn as forty steps is noise. Folded into ten plateaus it
    // is the same shape the day's temperature wears -- and a reading taken
    // every second and a half did not slide between them either.
    function plateaus(hist, n) {
        if (!hist || hist.length === 0) return []
        const out = []
        const per = hist.length / n
        for (let i = 0; i < n; i++) {
            const from = Math.floor(i * per)
            const to = Math.max(from + 1, Math.floor((i + 1) * per))
            let sum = 0
            for (let k = from; k < to && k < hist.length; k++) sum += hist[k]
            out.push(sum / (to - from))
        }
        return out
    }

    readonly property real ramFrac: Services.SysMon.ramTotalMB > 0
        ? Services.SysMon.ramUsedMB / Services.SysMon.ramTotalMB : 0

    // Glyph, name, figure. No box: the widget's own plate is the only one.

    // A level as a capsule of water. The vessel IS the reading -- it is not a
    // card with a reading inside it.
    component Vessel: Item {
        id: vs
        property string reading: ""
        property real value: 0
        property color tone: Services.Colors.ghost

        implicitHeight: 30

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: Services.Colors.fillLine
            clip: true

            Widgets.LiquidFill {
                id: liquid
                anchors.fill: parent
                shape: "rect"
                radius_: parent.height / 2
                level: Math.max(0, Math.min(1, vs.value))
                color_: vs.tone
                running: root.live
            }
        }

        Item {
            id: face
            anchors.fill: parent
            Text {
                anchors.centerIn: parent
                text: vs.reading
                color: Services.Colors.snow
                font.pixelSize: Services.Sizes.fsBody
                font.bold: true
                font.family: "JetBrainsMono NF"
                font.letterSpacing: 1.1
            }
        }

        // The words go under the water rather than floating over it.
        Widgets.Submerged {
            anchors.fill: parent
            source: face
            mask: liquid
            ink: Services.Colors.onColor(vs.tone)
        }
    }

    component Chart: Item {
        id: ch
        property var samples: []
        property string reading: ""
        property color tone: Services.Colors.ghost

        implicitHeight: 78

        Widgets.Trend {
            id: line
            anchors.fill: parent
            values: root.plateaus(ch.samples, 10)
            maxValue: 100
            stepped: true
            cornerR: 8
            color_: ch.tone
        }

        // On the curve, at its live end -- the same idea as the temperature
        // written over the hour it belongs to, and the same arithmetic Trend
        // uses to place a point, or the number floats off its own line.
        Text {
            id: figure
            x: parent.width - width
            y: Math.max(0, (1 - ch.hLast) * (parent.height - line.padding * 2)
                        + line.padding - height - 4)
            text: ch.reading
            color: Services.Colors.snow
            font.pixelSize: Services.Sizes.fsBody
            font.bold: true
            font.family: "JetBrainsMono NF"
        }
        readonly property real hLast: {
            const v = line.values
            return v.length > 0 ? Math.max(0, Math.min(1, v[v.length - 1] / 100)) : 0
        }
    }

    // Dry, flat, rectangular: a track with its fill and the two numbers at the
    // ends. Next to a stepped curve this reads as the same family; a ring did
    // not, which is why it is gone.
    component Bar: Item {
        id: br
        property string caption: ""
        property string reading: ""
        property real value: 0
        property color tone: Services.Colors.ghost

        implicitHeight: 30

        Text {
            id: cap
            anchors.left: parent.left
            anchors.top: parent.top
            text: br.caption
            color: Services.Colors.mist
            font.pixelSize: Services.Sizes.fsCaption
            font.letterSpacing: 1.2
            font.family: "JetBrainsMono NF"
        }
        Text {
            anchors.right: parent.right
            anchors.top: parent.top
            text: br.reading
            color: Services.Colors.snow
            font.pixelSize: Services.Sizes.fsCaption
            font.bold: true
            font.family: "JetBrainsMono NF"
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 8
            radius: 4
            color: Services.Colors.fillLine

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, br.value))
                height: parent.height
                radius: parent.radius
                color: br.tone
                gradient: Services.Prefs.useGradients ? Services.Colors.accentGradient : null
                Behavior on width {
                    Widgets.Anim {}
                }
            }
        }
    }

    // One reading, drawn the way the skin says. Water, or the flat language of
    // the curve above it -- and where the reading has a past worth drawing, the
    // dry skin draws that instead of a bar.
    component Level: Item {
        id: lv
        property string reading: ""
        property string caption: ""
        property real value: 0
        property var history: []
        property color tone: Services.Colors.ghost
        readonly property bool wet: root.skin !== "chart"
        // A disk that moves a gigabyte a week has no curve worth drawing, and
        // pretending otherwise is a flat line that says nothing.
        readonly property bool traced: !lv.wet && lv.history.length > 1

        implicitHeight: lv.traced ? 58 : 30

        Vessel {
            anchors.fill: parent
            visible: lv.wet
            reading: lv.reading
            value: lv.value
            tone: lv.tone
        }
        Bar {
            anchors.fill: parent
            visible: !lv.wet && !lv.traced
            caption: lv.caption
            reading: lv.reading
            value: lv.value
            tone: lv.tone
        }
        Chart {
            anchors.fill: parent
            visible: lv.traced
            samples: lv.history
            reading: lv.reading
            tone: lv.tone
        }
    }

    // Wide, not tall: a board reads across, and the curve is the thing that
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
                    glyph: "\ue322"
                    name: Services.I18n.t("widget.cpu")
                    note: ""
                }
                Text {
                    text: Math.round(Services.SysMon.cpuPercent) + "%"
                    color: Services.Colors.snow
                    font.pixelSize: Services.Sizes.fsHero
                    font.bold: true
                    font.family: "JetBrainsMono NF"
                }
                Chart {
                    width: main.width
                    implicitHeight: 96
                    samples: root.cpuHistory
                    reading: Services.SysMon.cpuTemp > 0
                        ? Math.round(Services.SysMon.cpuTemp) + "\u00b0" : ""
                }
            }

            Column {
                id: side
                width: 210
                spacing: 10
                anchors.verticalCenter: parent.verticalCenter

                // Only when there is one awake to talk about: the laptop's
                // discrete card sleeps, and a flat line at zero says nothing.
                WidgetHead {
                    width: side.width
                    visible: Services.SysMon.gpuPercent > 0
                    glyph: "\ue30a"
                    name: Services.I18n.t("widget.gpu")
                    note: Math.round(Services.SysMon.gpuPercent) + "%"
                }
                Chart {
                    width: side.width
                    implicitHeight: 46
                    visible: Services.SysMon.gpuPercent > 0
                    samples: root.gpuHistory
                    reading: Services.SysMon.gpuTemp > 0
                        ? Math.round(Services.SysMon.gpuTemp) + "\u00b0" : ""
                    tone: Services.Colors.neutral
                }

                WidgetHead {
                    width: side.width
                    visible: root.skin !== "chart"
                    glyph: "\ue30d"
                    name: Services.I18n.t("widget.memory")
                    note: (Services.SysMon.ramUsedMB / 1024).toFixed(1) + "G"
                }
                Level {
                    width: side.width
                    caption: Services.I18n.t("widget.memory")
                    reading: (Services.SysMon.ramUsedMB / 1024).toFixed(1) + "G / "
                             + (Services.SysMon.ramTotalMB / 1024).toFixed(0) + "G"
                    value: root.ramFrac
                    history: root.ramHistory
                }

                WidgetHead {
                    width: side.width
                    visible: root.skin !== "chart"
                    glyph: "\ue1db"
                    name: Services.I18n.t("widget.storage")
                    note: Services.SysMon.diskPercent + "%"
                }
                Level {
                    width: side.width
                    caption: Services.I18n.t("widget.storage")
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
                glyph: "\ue322"
                name: Services.I18n.t("widget.cpu")
                note: Math.round(Services.SysMon.cpuPercent) + "%"
            }
            Chart {
                width: mid.width
                implicitHeight: 62
                samples: root.cpuHistory
                reading: Services.SysMon.cpuTemp > 0
                    ? Math.round(Services.SysMon.cpuTemp) + "\u00b0" : ""
            }

            WidgetHead {
                width: mid.width
                visible: root.skin !== "chart"
                glyph: "\ue30d"
                name: Services.I18n.t("widget.memory")
                note: (Services.SysMon.ramUsedMB / 1024).toFixed(1) + "G"
            }
            Level {
                width: mid.width
                caption: Services.I18n.t("widget.memory")
                reading: (Services.SysMon.ramUsedMB / 1024).toFixed(1) + "G"
                value: root.ramFrac
                history: root.ramHistory
            }

            WidgetHead {
                width: mid.width
                visible: root.skin !== "chart"
                glyph: "\ue1db"
                name: Services.I18n.t("widget.storage")
                note: Services.SysMon.diskPercent + "%"
            }
            Level {
                width: mid.width
                caption: Services.I18n.t("widget.storage")
                reading: Math.round(Services.SysMon.diskUsedGB) + " GB"
                value: Services.SysMon.diskPercent / 100
                tone: Services.Colors.neutral
            }
        }
    }

    Component {
        id: compactShape
        Column {
            id: small
            width: 230
            spacing: 8

            WidgetHead {
                width: small.width
                glyph: "\ueaa2"
                name: Services.I18n.t("widget.system")
                note: Services.SysMon.cpuTemp > 0
                    ? Math.round(Services.SysMon.cpuTemp) + "\u00b0" : ""
            }
            Level {
                width: small.width
                caption: Services.I18n.t("widget.cpu")
                reading: Math.round(Services.SysMon.cpuPercent) + "%"
                value: Services.SysMon.cpuPercent / 100
            }
            Level {
                width: small.width
                caption: Services.I18n.t("widget.ram")
                reading: (Services.SysMon.ramUsedMB / 1024).toFixed(1) + "G"
                value: root.ramFrac
            }
            Level {
                width: small.width
                caption: Services.I18n.t("widget.disk")
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
