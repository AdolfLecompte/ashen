import Quickshell
import QtQuick
import "root:/services" as Services
import "root:/modules/widgets" as Widgets

Rectangle {
    id: root

    // How this pill draws itself, chosen in Settings > Bar > Layout.
    readonly property string content: Services.Pills.contentOf("recording")
    readonly property bool outlined: Services.Pills.isOutlined("recording")
    // The bar's one hover language, from Sizes: grow under the pointer,
    // give a little under the click.
    scale: Services.Sizes.hoverScale(hover.containsMouse, hover.pressed)
    Behavior on scale { Widgets.Anim { speed: Services.Sizes.pillHoverMs } }

    readonly property bool active: Services.AppState.recording

    // Taken off the bar, the pill still stands in the left section, hidden, so
    // that a recording starting can bring it in without the section being
    // rebuilt. Two beats, not one: the slot opens at once and the neighbours
    // slide with the bar's own `move` transition while the pill grows out of
    // its leading edge on the same curve -- so its edge never overtakes them.
    // Stopping runs it backwards: the pill folds first, then the gap closes.
    //
    // Growing the WIDTH instead was tried and looked wrong: every frame of it
    // re-laid the row, the move transition restarted each time, and the
    // neighbours trailed behind and sat on top of the timer.
    readonly property bool parked: Services.Prefs.barSectionOf("recording") === ""
    readonly property bool shown: !root.parked || root.active
    property real presence: root.shown ? 1 : 0
    Behavior on presence { Widgets.Anim { speed: Services.Sizes.msPronounced } }
    readonly property bool wanted: root.shown || root.presence > 0.001
    // Still folding away after a recording stopped: it keeps the shape it had,
    // or it snapped to a bare square on the first frame and only then folded.
    readonly property bool leaving: root.parked && !root.shown && root.presence > 0.001
    readonly property bool wide: root.active || root.leaving
    opacity: root.presence
    // A transform of its own, not `scale`: that one belongs to hover and has a
    // Behavior that would chase this.
    transform: Scale {
        origin.x: 0
        origin.y: 0
        xScale: root.vertical ? 1 : root.presence
        yScale: root.vertical ? root.presence : 1
    }

    // Idle it is a square icon-only pill like the ones on the right; while
    // recording it grows to fit the elapsed time and fills with the accent,
    // the same inversion every other active pill uses (see SystemPill).
    readonly property bool vertical: Services.Sizes.barVertical

    // On a side bar there is no room for the elapsed time, so it stays a square
    // icon pill and only the glyph reports that a recording is running.
    width: (root.wide && !vertical && root.content !== "icon") ? row.width + 20
                                                            : Services.Sizes.pillH
    height: Services.Sizes.pillH
    radius: Services.Sizes.pillR
    border.color: active ? Services.Colors.ghost : Services.Colors.fillOutline
    border.width: root.outlined ? Services.Sizes.outlineW : 0
    clip: true
    color: root.outlined ? Services.Colors.surfaceGlass
         : ((active && Services.Pills.fills) ? Services.Colors.ghost : Services.Colors.pillPlate)
    gradient: (Services.Prefs.useGradients && Services.Pills.fills && active)
              ? Services.Colors.accentGradient : null
    // Opening out to fit the clock is the pill telling you it started, so it
    // gets the same settle as the panels rather than a flat 150 ms slide.
    // Parked, `presence` already carries the entrance; opening out from a
    // square at the same time would be two motions for one event.
    Behavior on width { enabled: !Services.Sizes.hidden && !root.parked; Widgets.Anim { speed: Services.Sizes.msPronounced; curve: Services.Sizes.easeBox } }
    Behavior on color { Widgets.ColorAnim {} }

    // Counted in AppState from the start file, so a shell restart mid-recording
    // picks the same clock back up.
    readonly property string elapsed: Services.AppState.recordingElapsed

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6
        Text {
            textFormat: Text.PlainText
            id: dot
            text: "\uf679"
            // Dark only on the solid accent fill; over the hover tint it lifts.
            color: root.active ? (Services.Pills.fills ? Services.Colors.accentText : Services.Colors.ghost)
                 : hover.containsMouse ? Services.Colors.snow : Services.Colors.mist
            font.pixelSize: (root.active && !root.vertical) ? 16 : 22
            font.family: "Material Symbols Rounded"
            anchors.verticalCenter: parent.verticalCenter
            Behavior on color { Widgets.ColorAnim {} }
            Behavior on font.pixelSize { Widgets.Anim {} }

            // A recording is the one thing on the bar that is still happening
            // while you look away, so the dot breathes for as long as it runs.
            // Scale, not colour: red is not this shell's alarm — the scheme is
            // (see the colour rules), and a pulsing tint would fight the fill.
            transform: Scale {
                id: beat
                origin.x: dot.width / 2
                origin.y: dot.height / 2
            }
            SequentialAnimation {
                running: root.active
                loops: Animation.Infinite
                alwaysRunToEnd: true
                onStopped: { beat.xScale = 1; beat.yScale = 1; dot.opacity = 1 }
                ParallelAnimation {
                    NumberAnimation { target: beat; property: "xScale"; to: 1.18; duration: 620; easing.type: Services.Sizes.easeLoop }
                    NumberAnimation { target: beat; property: "yScale"; to: 1.18; duration: 620; easing.type: Services.Sizes.easeLoop }
                    NumberAnimation { target: dot; property: "opacity"; to: 0.72; duration: 620; easing.type: Services.Sizes.easeLoop }
                }
                ParallelAnimation {
                    NumberAnimation { target: beat; property: "xScale"; to: 1.0; duration: 620; easing.type: Services.Sizes.easeLoop }
                    NumberAnimation { target: beat; property: "yScale"; to: 1.0; duration: 620; easing.type: Services.Sizes.easeLoop }
                    NumberAnimation { target: dot; property: "opacity"; to: 1.0; duration: 620; easing.type: Services.Sizes.easeLoop }
                }
            }
        }
        Text {
            textFormat: Text.PlainText
            // No room for a timer on a side bar. `visible` alone collapses it
            // in the Row; binding width to implicitWidth is a loop, because a
            // Text recomputes implicitWidth from the width it was given.
            visible: root.wide && !root.vertical && root.content !== "icon"
            text: root.elapsed
            // Dark letters are for reading ON the accent. Where the pill cannot
            // fill -- a solid or island bar, or outline -- there is no accent
            // under them and the timer went invisible while recording, which is
            // the one moment the pill has something to say.
            color: Services.Pills.fills ? Services.Colors.accentText
                                        : Services.Colors.ghost
            font.pixelSize: 12
            font.bold: true
            font.family: "JetBrainsMono NF"
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: Services.AppState.toggleRecording()
    }
}
