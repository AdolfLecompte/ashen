import QtQuick
import QtQuick.Layouts
import "root:/services" as Services

// Volume, mic and brightness are the same widget with a different backend, so
// the row lives here once -- and it is the same row in Settings and in the
// panels, which used to be two hand-written copies drifting apart.
// Two shapes, one behaviour:
//   stacked (default) — glyph · label · value, track underneath. Settings.
//   inline            — glyph · track · value on one line. Panels, where the
//                       title above already says what the level is.
ColumnLayout {
    id: sliderRow

    property string glyph: ""
    property string label: ""
    property int value: 0                 // authoritative, from the service
    // What is on screen right now: follows the drag, not the service poll
    readonly property int shownPct: Math.round((sliderRow.inline ? inlineBar.shown : bar.shown) * 100)
    property string valueText: shownPct + "%"
    property bool dimmed: false
    property bool muted: false
    // Brightness has nothing to mute, so its glyph must not pretend to be
    // a button (no hover, no hand cursor).
    property bool glyphInteractive: false

    property bool inline: false
    property int glyphSize: inline ? 15 : 18
    // One thickness everywhere. Settings drew its sliders at 10 and the panels at
    // 16, and the thin ones read as a hairline you had to aim for.
    property int trackHeight: 16
    property int valueSize: inline ? Services.Sizes.fsMeta : Services.Sizes.fsBody

    signal moved(int pct)
    signal glyphClicked()

    Layout.fillWidth: true
    spacing: inline ? 0 : 6

    // The glyph. No plate that appears under the pointer: hover is that it
    // grows and its glyph lifts to snow, the same as everywhere else.
    component Glyph: Text {
        text: sliderRow.glyph
        font.family: "Material Symbols Rounded"
        font.pixelSize: sliderRow.glyphSize
        color: sliderRow.muted ? Services.Colors.mist
             : (glyphArea.containsMouse && sliderRow.glyphInteractive
                ? Services.Colors.snow : Services.Colors.ghost)
        Behavior on color { ColorAnim { speed: Services.Sizes.msMicro } }
        scale: sliderRow.glyphInteractive
            ? Services.Sizes.hoverScale(glyphArea.containsMouse, glyphArea.pressed) : 1.0
        Behavior on scale {
            NumberAnimation { duration: Services.Sizes.pillHoverMs; easing.type: Services.Sizes.easeOut }
        }
        MouseArea {
            id: glyphArea
            anchors.fill: parent
            anchors.margins: -6
            enabled: sliderRow.glyphInteractive
            hoverEnabled: sliderRow.glyphInteractive
            cursorShape: Qt.PointingHandCursor
            onClicked: sliderRow.glyphClicked()
        }
    }

    component Value: Text {
        text: sliderRow.valueText
        color: Services.Colors.mist
        font.pixelSize: sliderRow.valueSize
        font.family: "JetBrainsMono NF"
    }

    // ── Stacked ───────────────────────────────────────────────────────────
    RowLayout {
        visible: !sliderRow.inline
        Layout.fillWidth: true
        spacing: 10
        Glyph { Layout.preferredWidth: 26; Layout.preferredHeight: 26
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter }
        Text {
            text: sliderRow.label
            color: Services.Colors.snow
            font.pixelSize: Services.Sizes.fsInput
            font.family: "JetBrainsMono NF"
            Layout.fillWidth: true
        }
        Value {}
    }

    // ── Inline ────────────────────────────────────────────────────────────
    RowLayout {
        visible: sliderRow.inline
        Layout.fillWidth: true
        spacing: 10
        Glyph { Layout.alignment: Qt.AlignVCenter }
        Item { Layout.fillWidth: true; Layout.preferredHeight: inlineBar.height
               SliderTrack {
                   id: inlineBar
                   width: parent.width
                   anchors.verticalCenter: parent.verticalCenter
                   trackHeight: sliderRow.trackHeight
                   hitMargin: 10
                   dimmed: sliderRow.dimmed
                   value: sliderRow.value / 100
                   onMoved: r => sliderRow.moved(Math.round(r * 100))
               } }
        Value { Layout.alignment: Qt.AlignVCenter }
    }

    SliderTrack {
        id: bar
        visible: !sliderRow.inline
        Layout.fillWidth: true
        trackHeight: sliderRow.trackHeight
        dimmed: sliderRow.dimmed
        value: sliderRow.value / 100
        onMoved: r => sliderRow.moved(Math.round(r * 100))
    }
}
