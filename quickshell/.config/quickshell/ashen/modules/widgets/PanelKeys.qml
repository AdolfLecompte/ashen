import QtQuick

// The keys a panel answers while it is open: Escape closes it, the arrows and
// Space do what the panel says. Covers the panel without taking clicks; the
// window still has to ask for the keyboard (WlrLayershell.keyboardFocus).
FocusScope {
    id: root

    property bool shown: false
    signal closeRequested()
    signal stepLeft()
    signal stepRight()
    signal stepUp()
    signal stepDown()
    signal toggled()
    signal mutePressed()

    anchors.fill: parent
    focus: root.shown
    Keys.onEscapePressed: root.closeRequested()
    Keys.onLeftPressed: root.stepLeft()
    Keys.onRightPressed: root.stepRight()
    Keys.onUpPressed: root.stepUp()
    Keys.onDownPressed: root.stepDown()
    Keys.onSpacePressed: root.toggled()
    Keys.onPressed: e => { if (e.key === Qt.Key_M) { root.mutePressed(); e.accepted = true } }
}
