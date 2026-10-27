import Quickshell
import QtQuick
import "root:/services" as Services
import "root:/modules/widgets" as Widgets

// Microphone, camera and screen in use: one glyph each, lit. Parked by default,
// it claims a slot only while something is listening or watching, the way the
// recording pill does.
Rectangle {
    id: root
    // The bar this pill stands on (Bar.qml hands it in).
    property var spec: Services.Sizes.first

    readonly property bool outlined: root.spec.outlined("privacy")
    readonly property bool active: Services.Privacy.any
    readonly property bool vertical: Services.Sizes.barVertical

    readonly property bool parked: Services.Prefs.barSectionOf("privacy") === ""
    readonly property bool shown: !root.parked || root.active
    property real presence: root.shown ? 1 : 0
    Behavior on presence { Widgets.Anim { speed: Services.Sizes.msPronounced } }
    readonly property bool wanted: root.shown || root.presence > 0.001
    opacity: root.presence
    transform: Scale {
        origin.x: 0
        origin.y: 0
        xScale: root.vertical ? 1 : root.presence
        yScale: root.vertical ? root.presence : 1
    }

    readonly property var glyphs: {
        const out = []
        if (Services.Privacy.mic) out.push("")
        if (Services.Privacy.camera) out.push("")
        if (Services.Privacy.screen) out.push("")
        return out.length ? out : [""]
    }

    width: root.vertical ? Services.Sizes.pillH : Math.max(Services.Sizes.pillH, row.width + 20)
    height: root.vertical ? Math.max(Services.Sizes.pillH, row.height + 20) : Services.Sizes.pillH
    radius: Services.Sizes.pillR
    border.color: root.active ? Services.Colors.ghost : Services.Colors.fillOutline
    border.width: root.outlined ? Services.Sizes.outlineW : 0
    color: root.outlined ? Services.Colors.surfaceGlass
         : ((root.active && root.spec.fills) ? Services.Colors.ghost : root.spec.pillPlate)
    gradient: (Services.Prefs.useGradients && root.spec.fills && root.active)
              ? Services.Colors.accentGradient : null
    Behavior on color { Widgets.ColorAnim {} }
    Behavior on width { enabled: !Services.Sizes.hidden; Widgets.Anim { speed: Services.Sizes.msPronounced } }

    Grid {
        id: row
        anchors.centerIn: parent
        flow: root.vertical ? Grid.TopToBottom : Grid.LeftToRight
        columns: root.vertical ? 1 : root.glyphs.length
        spacing: 4
        Repeater {
            model: root.glyphs
            Text {
                textFormat: Text.PlainText
                required property string modelData
                text: modelData
                color: root.active ? (root.spec.fills ? Services.Colors.accentText : Services.Colors.ghost)
                     : Services.Colors.mist
                font.pixelSize: 18
                font.family: "Material Symbols Rounded"
            }
        }
    }
}
