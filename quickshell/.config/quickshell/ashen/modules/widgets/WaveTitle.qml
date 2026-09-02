import QtQuick
import "root:/services" as Services

// A word that moves like water: each letter rides a sine that travels along the
// line, so the whole title rolls rather than bouncing in place. One phase, one
// wave, and the letters only read it -- which is why it never falls out of step
// the way a per-letter animation would.
//
// It is the same wave the media progress draws, spent on the one place in the
// shell that is allowed to be decorative.
Item {
    id: root

    property string text: ""
    property int pixelSize: 46
    property real letterSpacing: 8
    property color color: Services.Colors.snow
    // How far a letter travels from the line, in pixels.
    property real amplitude: 5
    // Seconds for the wave to cross the whole word.
    property int period: 2600
    // How many crests fit in the word.
    property real waves: 1.4
    property bool running: true
    // 0..1 -- the entrance. Letters arrive one after another, left to right,
    // and the wave only starts once they are all in.
    property real arrive: 1

    implicitWidth: row.implicitWidth
    implicitHeight: pixelSize * 1.6

    property real phase: 0
    NumberAnimation on phase {
        running: root.running
        from: 0; to: 2 * Math.PI
        duration: root.period
        loops: Animation.Infinite
    }

    readonly property int count: root.text.length

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 0

        Repeater {
            model: root.count

            Text {
                required property int index
                // Where this letter sits in the word, 0..1 -- the wave is read
                // off the position, never off the index alone, so a longer word
                // is the same wave stretched rather than a faster one.
                readonly property real at: root.count > 1 ? index / (root.count - 1) : 0
                // Its own turn to arrive: the last letter lands at `arrive` 1.
                readonly property real inAmt: {
                    const start = at * 0.55
                    return Math.max(0, Math.min(1, (root.arrive - start) / 0.45))
                }

                text: root.text.charAt(index)
                color: root.color
                font.pixelSize: root.pixelSize
                font.bold: true
                font.letterSpacing: root.letterSpacing
                font.family: "JetBrainsMono NF"
                opacity: inAmt
                transform: Translate {
                    // Riding the wave once it is here; dropped below the line
                    // while it is still on its way in.
                    y: root.amplitude * Math.sin(at * root.waves * 2 * Math.PI + root.phase)
                       * root.arrive
                       + (1 - inAmt) * 14
                }
            }
        }
    }
}
