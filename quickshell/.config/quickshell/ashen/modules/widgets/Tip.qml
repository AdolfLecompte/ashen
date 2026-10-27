import QtQuick

import "root:/services" as Services

// The name of an icon-only control, once the pointer rests on it. Drawn in the
// window's top item so no card clips it; above the control, below if no room.
Item {
    id: root

    property Item target: null
    property string text: ""
    property bool show: false

    property bool resting: false
    Timer { id: wait; interval: 700; onTriggered: root.resting = true }
    function arm() {
        if (root.show && root.text !== "") wait.restart()
        else { wait.stop(); root.resting = false }
    }
    onShowChanged: root.arm()
    Component.onCompleted: root.arm()

    parent: root.target && root.target.Window.contentItem ? root.target.Window.contentItem : root.target
    z: 1000
    visible: opacity > 0.01
    opacity: root.resting ? 1 : 0
    Behavior on opacity { Anim { speed: Services.Sizes.msMicro } }

    width: label.implicitWidth + 16
    height: label.implicitHeight + 8

    // Where the control is, taken when the tip comes up.
    readonly property point at: {
        root.resting
        return root.target && root.parent ? root.target.mapToItem(root.parent, 0, 0) : Qt.point(0, 0)
    }
    x: root.target && root.parent
        ? Math.max(4, Math.min(root.parent.width - width - 4, at.x + root.target.width / 2 - width / 2)) : 0
    y: root.target ? (at.y - height - 6 < 4 ? at.y + root.target.height + 6 : at.y - height - 6) : 0

    Rectangle {
        anchors.fill: parent
        radius: Services.Sizes.innerR
        color: Services.Colors.surfacePopup
    }
    Text {
        textFormat: Text.PlainText
        id: label
        anchors.centerIn: parent
        text: root.text
        color: Services.Colors.snow
        font.pixelSize: Services.Sizes.fsMeta
        font.family: "JetBrainsMono NF"
    }
}
