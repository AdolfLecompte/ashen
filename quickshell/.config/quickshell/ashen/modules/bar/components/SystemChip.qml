import QtQuick

import "root:/modules/widgets" as Widgets
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
    // Standing alone as a pill of its own rather than inside a plate: the pill
    // draws the fill and answers the pointer, so the chip draws neither. Two
    // plates stacked read as a chip sitting on a tray, which is what the system
    // pill used to be and is exactly what was taken apart.
    property bool bare: false
    // Overrides the LABEL colour when the chip is neither on nor hovered
    // (the battery goes red below 20 %).
    property color idleColor: Services.Colors.ash
    // What the reading rests at when the pill CANNOT fill -- a solid or island
    // bar, or outline. `ash` is chosen for a capsule floating on a wallpaper,
    // where the pill's own plate gives it its contrast; dropped onto the bar's
    // own plate it sinks into it, which is why the battery (which rests at
    // mist) looked lit while wifi and bluetooth beside it looked switched off.
    // A caller with something louder to say overrides it, as the battery does
    // below 20 %.
    property color idleSolid: Services.Colors.mist
    // The glyph's own resting colour, and the one thing on these pills that
    // carries the wallpaper: `neutral` comes from the scheme, the way the
    // clock tints its weather icon. A caller overrides it when the glyph has
    // to say something louder than the wallpaper -- the battery going red.
    property color glyphTint: Services.Colors.neutral
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
    Behavior on opacity { Widgets.Anim { speed: Services.Sizes.msMicro } }

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
    readonly property bool pressed: hover.pressed
    readonly property bool expanded: vertical && (hovered || open)
    // Lit, the text is whichever of black and white can be read on the accent --
    // matugen hands the shell whatever the wallpaper had, so "the accent is
    // light" is not something to assume. The hover tint never takes dark text:
    // it is a wash, not a fill, and dark letters on it came out as a smudge.
    // On a plate of its own, the accent is under the letters and they go dark to
    // be read on it. Standing alone as a pill, the plate only fills while the
    // panel is OPEN -- every other pill on the bar says "open" that way and
    // nothing else -- so "on" is carried by the letters taking the accent
    // colour instead, which is the same language hover speaks.
    // Nothing fills underneath, so the reading itself takes the accent. Not
    // accentText: that colour exists to be read ON the accent, and there is no
    // accent behind these letters to read them on.
    readonly property color contentColor: !Services.Pills.fills
        // OPEN only, never `active`: a radio that is switched on is the normal
        // state of a radio, and painting it accent left the wifi, the bluetooth
        // and the sound reading in the accent colour all day -- four capsules
        // shouting next to a battery that rests. What the radio is DOING is the
        // glyph's job. Same rule the bare branch below already follows.
        ? (open ? Services.Colors.ghost
                : hovered ? Services.Colors.snow : idleSolid)
        : chip.bare
        // Standing alone as a pill, only an OPEN panel fills the plate, so only
        // then do the letters go dark to be read on the accent. "On" is not
        // worth tinting them: it was tried in accent blue and read as a warning.
        //
        // On rests at MIST, not snow: with the letters already at their
        // brightest there was nothing left for hover to do, and hover lifting
        // the reading is the one language every other pill on this bar speaks.
        ? (open ? Services.Colors.accentText
                : hovered ? Services.Colors.snow
                : active ? Services.Colors.mist : idleColor)
        : (active ? Services.Colors.accentText
                  : (hovered ? Services.Colors.snow : idleColor))

    // The glyph walks the same ladder, but rests on the wallpaper's tone
    // instead of the text colour.
    readonly property color glyphColor: !Services.Pills.fills
        ? (open ? Services.Colors.ghost
                : hovered ? Services.Colors.snow : chip.glyphTint)
        : chip.bare
        ? (open ? Services.Colors.accentText
                : hovered ? Services.Colors.snow : chip.glyphTint)
        : (active ? Services.Colors.accentText
                  : (hovered ? Services.Colors.snow : chip.glyphTint))

    radius: Services.Sizes.innerR
    width: vertical ? Services.Sizes.innerH : inner.width + 16
    // On a side bar a chip is a FACE and nothing else -- the reading rides out
    // of the plate on hover (see `tail`) instead of making the column taller.
    // A dual chip is two faces, so it is the one that is twice as tall.
    height: vertical
        ? (chip.dual ? inner.height + 12 : Services.Sizes.innerH)
        : Services.Sizes.innerH
    Behavior on height { enabled: !Services.Sizes.hidden; Widgets.Anim {} }

    // The plate does not react. Hover is the chip growing and its contents
    // lifting to snow -- nothing lights up underneath them.
    // On a solid bar, or in outline, the chip does NOT fill: see Pills.fills.
    // A filled block inside a filled plate is a block inside a block, and a
    // filled block inside a drawn outline is what undoes the outline.
    color: (chip.bare || !Services.Pills.fills) ? "transparent"
         : active ? Services.Colors.ghost : Services.Colors.fillRest
    gradient: (!chip.bare && Services.Pills.fills && Services.Prefs.useGradients && Services.Pills.fills && active)
              ? Services.Colors.accentGradient : null
    Behavior on color { Widgets.ColorAnim { speed: Services.Sizes.msEmphasis } }

    // The bar's one hover language, from Sizes.
    scale: chip.bare ? 1 : Services.Sizes.hoverScale(hovered, hover.pressed)
    Behavior on scale { Widgets.Anim { speed: Services.Sizes.pillHoverMs } }

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

        Face { text: chip.glyph; col: chip.glyphColor }
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

        Face { text: chip.altGlyph; col: chip.glyphColor; visible: chip.dual }
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
        Behavior on width { enabled: !Services.Sizes.hidden; Widgets.Anim {} }
        Behavior on opacity { Widgets.Anim { speed: Services.Sizes.msMicro } }

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
