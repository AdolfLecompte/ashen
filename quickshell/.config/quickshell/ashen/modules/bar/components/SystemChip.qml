import QtQuick

import "root:/services" as Services

// One chip inside the system pill: wifi, bluetooth, volume, battery,
// keyboard. The caller says what it shows and what a click does; the fill, the
// hover, the expand and the pill-centre report are shared. Give it altGlyph and
// altLabel and it carries two readings behind one hairline -- sound and
// brightness ride together in a single wide chip.
Rectangle {
    id: chip

    // AppState key the panel that belongs to this chip hangs off. Empty for a
    // chip nothing opens.
    property string pillKey: ""
    property string glyph: ""
    property string label: ""
    // Second reading, off by default. Its own face and text, same plate.
    property string altGlyph: ""
    property string altLabel: ""
    readonly property bool dual: chip.altGlyph !== "" || chip.altLabel !== ""
    // On: filled with the accent, text goes dark.
    property bool active: false
    // Its panel is open — on a vertical bar that holds the chip expanded.
    property bool open: false
    property bool interactive: true
    // Overrides the label/glyph colour when the chip is neither on nor hovered
    // (the battery goes red below 20 %).
    property color idleColor: Services.Colors.ash
    // Optional width band for the label, off by default. Only the chips whose
    // text is a name — the network and the bluetooth device — need it; a
    // percentage is always the same handful of characters and clamping it just
    // padded the chip out for nothing.
    property real minLabelW: 0
    property real maxLabelW: 0

    signal activated()

    // While its panel is up the chip IS the panel, so it steps aside: the whole
    // chip, not just its contents, the way the clock and the media pill do.
    // Opacity, not `visible`: invisible keeps its slot, hidden would let the
    // strip close the gap and shove the other chips sideways.
    property bool takenOver: false
    onOpenChanged: {
        if (open) { handBack.stop(); handOver.restart() }
        else { handOver.stop(); handBack.restart() }
    }
    // The panel waits for its window to actually be on screen before it starts
    // to fall, so the chip has to wait the same beat before standing down. Left
    // to go the instant it was clicked, the bar went blank and only THEN did the
    // drop begin — a gap where nothing was moving anywhere.
    Timer {
        id: handOver
        interval: Services.Sizes.panelArmMs
        onTriggered: chip.takenOver = true
    }
    // Coming back it goes the other way: contents out, pieces home, then the
    // box. The chip is free a little before the drop is all the way in, so the
    // two meet rather than the chip waiting for an empty pill to be handed back.
    Timer {
        id: handBack
        interval: Services.Sizes.panelCloseMs - 40
        onTriggered: chip.takenOver = false
    }
    opacity: (takenOver && Services.Pills.wearsFace) ? 0.0 : 1.0
    Behavior on opacity { NumberAnimation { duration: Services.Sizes.msMicro } }

    // The panel wears this for the first frames of its fall.
    onGlyphChanged: chip.publishFace()
    onLabelChanged: chip.publishFace()
    Component.onCompleted: chip.publishFace()
    function publishFace() {
        if (pillKey !== "")
            Services.AppState.setPillFace(pillKey, glyph, label)
    }

    // Defaults to the bar's own orientation; a caller off the bar (the
    // utility pill, glued to whichever edge it landed on) overrides it.
    property bool vertical: Services.Sizes.barVertical
    readonly property bool hovered: hover.containsMouse
    readonly property bool expanded: vertical && (hovered || open)
    // Lit, the text is whichever of black and white can be read on the accent --
    // matugen hands the shell whatever the wallpaper had, so "the accent is
    // light" is not something to assume. The hover tint never takes dark text:
    // it is a wash, not a fill, and dark letters on it came out as a smudge.
    readonly property color contentColor: active
        ? Services.Colors.accentText
        : (hovered ? Services.Colors.snow : idleColor)

    radius: Services.Sizes.innerR
    width: vertical ? Services.Sizes.innerH : inner.width + 16
    // On a side bar a chip is a FACE and nothing else -- the reading rides out
    // of the plate on hover (see `tail`) instead of making the column taller.
    // A dual chip is two faces, so it is the one that is twice as tall.
    height: vertical
        ? (chip.dual ? inner.height + 12 : Services.Sizes.innerH)
        : Services.Sizes.innerH
    Behavior on height { NumberAnimation { duration: Services.Sizes.msStandard; easing.type: Services.Sizes.easeOut } }

    // The plate does not react. Hover is the chip growing and its contents
    // lifting to snow -- nothing lights up underneath them.
    color: active ? Services.Colors.ghost : Services.Colors.fillRest
    gradient: Services.Prefs.useGradients && active ? Services.Colors.accentGradient : null
    Behavior on color { ColorAnimation { duration: Services.Sizes.msEmphasis } }

    // The bar's one hover language, from Sizes.
    scale: Services.Sizes.hoverScale(hovered, hover.pressed)
    Behavior on scale { NumberAnimation { duration: Services.Sizes.pillHoverMs; easing.type: Services.Sizes.easeOut } }

    // A chip nothing opens is inert: no cursor, no hover growth, no lift to
    // snow, and clicks go straight through it. Answering the pointer is the
    // shell saying "this does something", and the keyboard layout does not.
    MouseArea {
        id: hover
        anchors.fill: parent
        enabled: chip.interactive
        hoverEnabled: chip.interactive
        cursorShape: Qt.PointingHandCursor
        onClicked: chip.activated()
    }

    // Only a chip with a panel behind it needs to publish where it is.
    Loader {
        active: chip.pillKey !== ""
        sourceComponent: PillCenter { key: chip.pillKey; pill: chip }
    }

    BarStrip {
        id: inner
        anchors.centerIn: parent
        spacing: chip.vertical ? 0 : 5

        Face { text: chip.glyph; col: chip.contentColor }
        Reading {
            text: chip.label
            col: chip.contentColor
            vert: chip.vertical
            shown: chip.label !== "" && !chip.vertical
            band: chip.maxLabelW > 0
            loW: chip.minLabelW
            hiW: chip.maxLabelW
        }

        // No rule between the two readings -- only air, a touch wider than the
        // gap a glyph keeps from its own number, so they read as two and still
        // as one chip.
        Item {
            visible: chip.dual
            width: chip.vertical ? 1 : 4
            height: chip.vertical ? 4 : 1
        }

        Face { text: chip.altGlyph; col: chip.contentColor; visible: chip.dual }
        Reading {
            text: chip.altLabel
            col: chip.contentColor
            vert: chip.vertical
            shown: chip.dual && chip.altLabel !== "" && !chip.vertical
        }
    }

    // The reading, out past the bar. The bar's window is wider than the strip
    // (Sizes.barSpill) with its input mask still on the strip, so this is only
    // ever pixels: nothing here hears the pointer, which is also why it can sit
    // outside its ancestors without the usual click trouble. It starts at the
    // plate's own edge, so what unrolls reads as the plate and not as a label
    // that happens to be nearby.
    readonly property int plateEdge: 8
    readonly property bool outward: Services.Sizes.barPosition !== "right"

    Rectangle {
        id: tail
        visible: chip.vertical && (chip.label !== "" || chip.altLabel !== "")
        height: chip.height
        y: 0
        x: chip.outward ? chip.width + chip.plateEdge : -(width + chip.plateEdge)
        // Unrolls: the capsule grows and the words are revealed by it, rather
        // than words fading in over a box that was already there.
        width: chip.expanded ? tailCol.implicitWidth + 20 : 0
        clip: true
        radius: Services.Sizes.innerR
        color: Services.Colors.surfacePill
        opacity: chip.expanded ? 1 : 0
        Behavior on width { NumberAnimation { duration: Services.Sizes.msStandard; easing.type: Services.Sizes.easeOut } }
        Behavior on opacity { NumberAnimation { duration: Services.Sizes.msMicro } }

        Column {
            id: tailCol
            anchors.centerIn: parent
            spacing: 4
            Text {
                visible: chip.label !== ""
                text: chip.label
                color: Services.Colors.snow
                font.pixelSize: 12
                font.bold: true
                font.family: "JetBrainsMono NF"
            }
            Text {
                visible: chip.dual && chip.altLabel !== ""
                text: chip.altLabel
                color: Services.Colors.snow
                font.pixelSize: 12
                font.bold: true
                font.family: "JetBrainsMono NF"
            }
        }
    }

    // A face pops rather than cutting when it is swapped: the volume icon
    // changes between headphones and speaker often enough to notice. Inline
    // components cannot see the ids around them, so colour and size come in.
    component Face: Text {
        id: face
        property color col: "white"
        color: face.col
        font.pixelSize: 18
        font.family: "Material Symbols Rounded"
        Behavior on color { ColorAnimation { duration: 200 } }

        transform: Scale {
            id: popScale
            origin.x: face.width / 2
            origin.y: face.height / 2
        }
        onTextChanged: pop.restart()
        ParallelAnimation {
            id: pop
            NumberAnimation { target: face; property: "opacity"; from: 0.0; to: 1.0; duration: 180; easing.type: Easing.OutCubic }
            NumberAnimation { target: popScale; property: "xScale"; from: 0.7; to: 1.0; duration: 200; easing.type: Easing.OutCubic }
            NumberAnimation { target: popScale; property: "yScale"; from: 0.7; to: 1.0; duration: 200; easing.type: Easing.OutCubic }
        }
    }

    // The words next to a face. Only the first reading takes the width band.
    component Reading: Text {
        id: read
        property color col: "white"
        property bool vert: false
        property bool shown: true
        property bool band: false
        property real loW: 0
        property real hiW: 0
        color: read.col
        // Floor and ceiling on the width: the chip is where the panel hangs from,
        // so a long SSID used to drag the open panel across the screen and "Off"
        // used to snap it narrow. Past the ceiling the name trails off.
        width: read.band ? Math.max(read.loW, Math.min(implicitWidth, read.hiW))
                         : implicitWidth
        elide: read.band ? Text.ElideRight : Text.ElideNone
        // Sideways there is no room for the words. Zero text, not an empty label:
        // an empty one still counted as a lane in BarStrip's Grid and reserved the
        // spacing after the glyph, leaving the icon off-centre in its own chip.
        visible: read.shown
        font.pixelSize: read.vert ? 9 : 12
        font.family: "JetBrainsMono NF"
        font.bold: true
        Behavior on color { ColorAnimation { duration: 200 } }
    }
}
