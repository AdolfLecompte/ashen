import QtQuick
import "root:/services" as Services

// A line that is too long for its slot: cut off with an ellipsis while you are
// not looking at it, and running past in one direction while the pointer is on
// the thing it belongs to. A second copy follows the first, so the line comes
// round again instead of walking to the end and reversing.
Item {
    id: root

    property string text: ""
    property color color: Services.Colors.snow
    property int pixelSize: 11
    property bool bold: true
    property string family: "JetBrainsMono NF"

    // The pointer is on the pill. Running is only ever a response to that.
    property bool active: false
    // Space between the tail of one copy and the head of the next, and how
    // fast the line travels. Constant speed, so a longer title takes longer
    // rather than going faster.
    property int gap: 28
    property int msPerPx: 26

    clip: true
    implicitHeight: label.implicitHeight
    implicitWidth: label.implicitWidth

    readonly property real overflow: Math.max(0, label.implicitWidth - width)
    readonly property bool runs: root.active && root.overflow > 1
    // One full turn: the first copy's width plus the gap. When it has gone that
    // far the second copy stands exactly where the first started, so resetting
    // to zero is invisible.
    readonly property real span: label.implicitWidth + root.gap

    Row {
        id: train
        spacing: root.gap
        x: 0

        Text {
            textFormat: Text.PlainText
            id: label
            text: root.text
            color: root.color
            font.pixelSize: root.pixelSize
            font.bold: root.bold
            font.family: root.family
            // Running, the whole line has to be there; standing still it is cut
            // so a long title does not simply run out of the pill.
            width: root.runs ? implicitWidth : root.width
            elide: root.runs ? Text.ElideNone : Text.ElideRight
            Behavior on color { ColorAnim {} }
        }

        // The copy that comes round behind it. Only alive while running, so a
        // pill at rest is one Text and nothing else.
        Text {
            textFormat: Text.PlainText
            visible: root.runs
            text: root.text
            color: root.color
            font.pixelSize: root.pixelSize
            font.bold: root.bold
            font.family: root.family
        }
    }

    // Linear and looping: any easing here would read as the line hesitating
    // every time it comes round.
    SequentialAnimation {
        id: run
        running: root.runs
        loops: Animation.Infinite
        // A beat at the start so the beginning can be read before it leaves.
        PauseAnimation { duration: 700 }
        NumberAnimation {
            target: train; property: "x"
            from: 0
            to: -root.span
            duration: Math.max(1, root.span * root.msPerPx)
            easing.type: Services.Sizes.easeTrace
        }
    }

    // Off the pill it goes home rather than freezing mid-word.
    onRunsChanged: if (!root.runs) homeAnim.restart()
    NumberAnimation {
        id: homeAnim
        target: train; property: "x"; to: 0
        duration: Services.Sizes.msStandard
        easing.type: Services.Sizes.easeOut
    }
}
