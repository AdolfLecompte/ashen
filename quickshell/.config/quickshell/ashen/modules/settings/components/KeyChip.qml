import QtQuick
import QtQuick.Layouts

import "root:/services" as Services

// A key combination you can change: press the chip, then press the keys. The
// combination IS the button, because "what do I press" and "what should I press
// instead" are the same question asked twice.
//
// A shortcut with no id is one keybinds.lua does not offer for rebinding (the
// mouse drags, the lid switch, the workspace numbers): it still reads, it just
// does not take a press.
Rectangle {
    id: chip

    property string wid: ""
    readonly property bool editable: chip.wid !== ""
    readonly property string combo: chip.editable
        ? Services.Shortcuts.keyOf(chip.wid) : chip.plain
    // For the ones with no id: what to show, straight from the parser.
    property string plain: ""
    readonly property string clash: chip.editable
        ? Services.Shortcuts.clashOf(chip.wid, chip.combo) : ""

    property bool grabbing: false

    implicitWidth: Math.max(120, label.implicitWidth + 26)
    implicitHeight: 30
    radius: Services.Sizes.innerR
    color: chip.grabbing ? Services.Colors.ghost : Services.Colors.fillLine
    border.width: chip.clash !== "" && !chip.grabbing ? 1 : 0
    border.color: Services.Colors.error_
    Behavior on color { ColorAnimation { duration: Services.Sizes.msMicro } }

    scale: chip.editable
        ? Services.Sizes.hoverScale(hover.containsMouse, hover.pressed) : 1
    Behavior on scale { NumberAnimation { duration: Services.Sizes.pillHoverMs; easing.type: Services.Sizes.easeOut } }

    Text {
        id: label
        anchors.centerIn: parent
        text: chip.grabbing ? "press keys…" : chip.combo
        color: chip.grabbing ? Services.Colors.accentText
             : !chip.editable ? Services.Colors.mist
             : hover.containsMouse ? Services.Colors.snow
             : Services.Shortcuts.changed(chip.wid) ? Services.Colors.ghost
             : Services.Colors.mist
        font.pixelSize: Services.Sizes.fsMeta
        font.bold: true
        font.family: "JetBrainsMono NF"
        Behavior on color { ColorAnimation { duration: Services.Sizes.msMicro } }
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        enabled: chip.editable
        hoverEnabled: chip.editable
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            // Right-click puts the shipped combination back: an "undo" button
            // on every row would double the width of the list.
            if (mouse.button === Qt.RightButton) {
                Services.Shortcuts.reset(chip.wid)
                chip.grabbing = false
                return
            }
            chip.grabbing = !chip.grabbing
            if (chip.grabbing) grabber.forceActiveFocus()
        }
    }

    // What Hyprland calls the key that was pressed. A printable character is
    // itself; the rest are named, because "Key_F5" is not something a bind
    // parser has ever heard of.
    function keyName(event) {
        const named = {}
        named[Qt.Key_Space] = "space"
        named[Qt.Key_Return] = "return"
        named[Qt.Key_Enter] = "return"
        named[Qt.Key_Tab] = "Tab"
        named[Qt.Key_Backspace] = "backspace"
        named[Qt.Key_Delete] = "delete"
        named[Qt.Key_Home] = "home"
        named[Qt.Key_End] = "end"
        named[Qt.Key_PageUp] = "prior"
        named[Qt.Key_PageDown] = "next"
        named[Qt.Key_Left] = "left"
        named[Qt.Key_Right] = "right"
        named[Qt.Key_Up] = "up"
        named[Qt.Key_Down] = "down"
        named[Qt.Key_Escape] = "Escape"
        if (named[event.key] !== undefined) return named[event.key]
        if (event.key >= Qt.Key_F1 && event.key <= Qt.Key_F12)
            return "F" + (event.key - Qt.Key_F1 + 1)
        if (event.text && event.text.trim().length === 1)
            return event.text.trim().toUpperCase()
        return ""
    }

    // Nothing is written until a real key lands: a bare modifier is half a
    // combination, and Escape on its own means "never mind".
    Item {
        id: grabber
        focus: chip.grabbing
        Keys.onPressed: event => {
            event.accepted = true
            if (event.key === Qt.Key_Escape && event.modifiers === Qt.NoModifier) {
                chip.grabbing = false
                return
            }
            if (event.key === Qt.Key_Shift || event.key === Qt.Key_Control
                || event.key === Qt.Key_Alt || event.key === Qt.Key_Meta
                || event.key === Qt.Key_Super_L || event.key === Qt.Key_Super_R)
                return

            let parts = []
            if (event.modifiers & Qt.MetaModifier) parts.push("SUPER")
            if (event.modifiers & Qt.ControlModifier) parts.push("CTRL")
            if (event.modifiers & Qt.AltModifier) parts.push("ALT")
            if (event.modifiers & Qt.ShiftModifier) parts.push("SHIFT")
            // A key with no modifier would swallow that letter everywhere in
            // the session.
            if (parts.length === 0) return

            const name = chip.keyName(event)
            if (name === "") return

            parts.push(name)
            Services.Shortcuts.setKey(chip.wid, parts.join(" + "))
            chip.grabbing = false
        }
    }
}
