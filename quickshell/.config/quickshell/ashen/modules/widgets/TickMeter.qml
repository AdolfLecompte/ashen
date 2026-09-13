import QtQuick

import "root:/services" as Services

// A row of thin rounded ticks: the shell's way of drawing a reading.
//
// Two ways to read it, one shape:
//   level    — every tick the full height, lit up to the value. For things with
//              a ceiling that crawl: memory, a drive, a battery, a volume.
//   history  — each tick is one recent sample, its height the value, newest on
//              the right. For things that move: CPU, GPU, traffic. The card
//              shows the last minute instead of one number and a guess.
//
// It replaced the liquid that used to fill these cards. That one repainted a
// wave on every frame the panel was open, and read as decoration; ticks are
// plain rectangles the scene graph draws once and only touches when a sample
// lands. Same language as the workspace dots and the visualiser.
Item {
    id: meter

    property string mode: "level"
    // level: 0..1
    property real value: 0
    // history: oldest first, each 0..1
    property var samples: []

    property int tickW: 4
    property int gap: 3
    // How short a tick in history may get, so an idle reading still draws a row
    // rather than nothing at all.
    property int minTick: 3
    property color color_: Services.Colors.ghost
    property color offColor: Services.Colors.fillLine

    // As many ticks as fit, never a fraction of one.
    readonly property int count: Math.max(1, Math.floor((meter.width + meter.gap) / (meter.tickW + meter.gap)))
    // What is left over is split either side, so the row sits centred.
    readonly property real lead: (meter.width - (meter.count * meter.tickW + (meter.count - 1) * meter.gap)) / 2

    function sampleAt(i) {
        const s = meter.samples || []
        const k = s.length - meter.count + i
        return k >= 0 && k < s.length ? Math.max(0, Math.min(1, s[k])) : 0
    }

    Repeater {
        model: meter.count

        Rectangle {
            required property int index
            readonly property real v: meter.mode === "history" ? meter.sampleAt(index) : 0
            readonly property bool lit: meter.mode === "history"
                ? v > 0.001
                : (index + 0.5) / meter.count <= Math.max(0, Math.min(1, meter.value))

            x: meter.lead + index * (meter.tickW + meter.gap)
            width: meter.tickW
            height: meter.mode === "history"
                ? Math.max(meter.minTick, v * meter.height)
                : meter.height
            y: meter.height - height
            radius: meter.tickW / 2
            color: lit ? meter.color_ : meter.offColor

            Behavior on height { Anim { speed: Services.Sizes.msStandard } }
            Behavior on color { ColorAnim { speed: Services.Sizes.msMicro } }
        }
    }
}
