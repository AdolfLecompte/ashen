import Quickshell
import QtQuick

import "root:/services" as Services

// The keyboard layout, with caps and num lock growing inside it. Was a chip on
// the system plate until that plate was taken apart.
Rectangle {
    id: root

    readonly property bool vertical: Services.Sizes.barVertical
    // How this pill draws itself, chosen per pill in Settings > Bar > Layout.
    readonly property string content: Services.Pills.contentOf("keyboard")
    readonly property bool outlined: Services.Pills.isOutlined("keyboard")

    // Icon-only is a SQUARE, like every other pill that offers it. Without this
    // branch the plate kept the width of a row whose label had just been
    // emptied -- a glyph adrift in a pill sized for words that are not there.
    width: root.vertical ? Services.Sizes.pillH
         : root.content === "icon" ? Services.Sizes.pillH
         : kbRow.width + 16
    height: root.vertical ? kbRow.height + 16 : Services.Sizes.pillH
    radius: Services.Sizes.pillR
    // One plate, drawn here: the chips inside are bare. A readout, so it never
    // fills -- nothing opens from it.
    color: root.outlined ? Services.Colors.surfaceGlass
                                      : Services.Colors.pillPlate
    border.width: root.outlined ? Services.Sizes.outlineW : 0
    border.color: Services.Colors.fillOutline

    BarStrip {
        id: kbRow
        anchors.centerIn: parent
        spacing: 4

            // light and unlit: a lock that is off is not a state worth a slot, so
            // the chip is there or it is not -- and it grows into the strip rather
            // than popping the other chips sideways.
            LockChip { on: Services.Keyboard.capsLock; glyph: "\uf7de" }
            LockChip { on: Services.Keyboard.numLock;  glyph: "\ue400" }

            SystemChip {
                id: chip
                bare: true
                interactive: false
                glyph: "\uE312"
                label: root.content === "icon" ? "" : (Services.Keyboard.label)
                // A readout that is never "off", so it rests where the battery
                // rests -- not at `ash`, which is the dimmed state a radio that
                // is switched off wears, and not at `snow`, which is hover's.
                idleColor: Services.Colors.mist
            }
    }

    component LockChip: Item {
        id: slot
        property bool on: false
        property string glyph: ""

        // 0..1: how much of the chip is there. Box and glyph grow TOGETHER
        // along the bar's own axis, so the neighbours never slide aside for
        // a gap that is still empty.
        property real amt: 0
        // The strip's spacing is folded into the slot, so it opens from
        // nothing instead of jumping by one gap when it becomes visible.
        readonly property real gap: kbRow.spacing
        readonly property real along: Math.max(0,
            ((root.vertical ? plate.height : plate.width) + gap) * slot.amt - gap)

        width: root.vertical ? plate.width : slot.along
        height: root.vertical ? slot.along : Services.Sizes.innerH
        visible: slot.along > 0.5

        onOnChanged: slot.amt = slot.on ? 1 : 0
        // Born with the lock already on: land there, do not play an entrance
        // for a state that was true before the bar existed.
        Component.onCompleted: { slot.amt = slot.on ? 1 : 0; slot.armed = true }
        property bool armed: false
        Behavior on amt {
            enabled: slot.armed
            NumberAnimation { duration: Services.Sizes.msStandard; easing.type: Services.Sizes.easeOut }
        }

        SystemChip {
            id: plate
            bare: true
            interactive: false
            glyph: slot.glyph
            // Same rest as the layout beside it: the chip only EXISTS while
            // the lock is on, so its being there is the whole message.
            idleColor: Services.Colors.mist
            anchors.centerIn: parent
            opacity: slot.amt
            scale: 0.5 + 0.5 * slot.amt
        }
    }
}
