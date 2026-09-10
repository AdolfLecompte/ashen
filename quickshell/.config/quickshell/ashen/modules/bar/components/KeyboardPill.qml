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

        // The room it takes, and the chip standing in it.
        property real boxAmt: 0
        property real faceAmt: 0

        width: plate.width * slot.boxAmt
        height: Services.Sizes.innerH
        visible: slot.boxAmt > 0.01 || slot.faceAmt > 0.01

        onOnChanged: {
            if (slot.on) { outAnim.stop(); inAnim.restart() }
            else { inAnim.stop(); outAnim.restart() }
        }
        // Born with the lock already on: land there, do not play an entrance
        // for a state that was true before the bar existed.
        Component.onCompleted: if (slot.on) { slot.boxAmt = 1; slot.faceAmt = 1 }

        SequentialAnimation {
            id: inAnim
            NumberAnimation { target: slot; property: "boxAmt"; to: 1
                              duration: Services.Sizes.msStandard; easing.type: Services.Sizes.easeOut }
            NumberAnimation { target: slot; property: "faceAmt"; to: 1
                              duration: Services.Sizes.msMicro; easing.type: Services.Sizes.easeOut }
        }
        SequentialAnimation {
            id: outAnim
            NumberAnimation { target: slot; property: "faceAmt"; to: 0
                              duration: Services.Sizes.msMicro; easing.type: Services.Sizes.easeIn }
            NumberAnimation { target: slot; property: "boxAmt"; to: 0
                              duration: Services.Sizes.msStandard; easing.type: Services.Sizes.easeInOut }
        }

        SystemChip {
            id: plate
            bare: true
            interactive: false
            glyph: slot.glyph
            // Same rest as the layout beside it: the chip only EXISTS while
            // the lock is on, so its being there is the whole message.
            idleColor: Services.Colors.mist
            x: (slot.width - width) / 2
            anchors.verticalCenter: parent.verticalCenter
            opacity: slot.faceAmt
            scale: 0.82 + 0.18 * slot.faceAmt
        }
    }
}
