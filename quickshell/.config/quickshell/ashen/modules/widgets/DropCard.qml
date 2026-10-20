import QtQuick

import "root:/services" as Services

// A panel that comes out of its bar pill: the chip goes dark, the box
// stretches out of it in one movement and stays on it -- the side facing the
// bar never leaves the chip -- in the colour of the bar it came out of, and the
// contents fade in where they belong. Closing fades them out and goes home.
// Same movement in MorphCard, which is the clock's and the media panel's.
Item {
    id: root
    anchors.fill: parent

    property bool shown: false
    property real pillCX: 0
    property real pillCY: 0
    property real pillW: 44
    property real pillH: 32
    property real openW: 400
    property real openH: 300
    property real cardRadius: 20
    // What the chip was showing. Given a destination, the glyph and the name
    // FLY there instead of cross-fading -- that hand-off is the whole trick.
    property string pillGlyph: ""
    property string pillLabel: ""
    // Where they land. Text items, so their size and colour are read off them.
    property Item glyphTarget: null
    property Item labelTarget: null
    // Whether the chip it came from was lit.
    property bool pillActive: false
    // The plate the card is born on and returns to: the chip's own colour, so
    // the hand-over at either end is not a change of colour.
    property color pillColor: pillActive ? Services.Colors.ghost
                                         : Services.Colors.fillRest
    // Where the plate ENDS. Normally the panel surface; a panel that is not a
    // card -- the power menu is four tiles and nothing around them -- asks for
    // "transparent" and the plate leaves once it has arrived.
    property color landColor: Services.Colors.surfacePanel
    readonly property bool plateless: landColor.a < 0.01
    // A plateless panel has NO plate at any point -- not at rest, not on the
    // way in. The power menu is four tiles and nothing around them, and a box
    // that is only there while it travels is still a box you watch arrive.
    // What moves is the pieces flying out of the pill and the tiles staging in.
    // Grown out of the bar it settles on the colour of what it came out of, so
    // it reads as the bar stretching; one that names its own spot keeps the
    // panel surface.
    readonly property bool joined: !root.ownEdge && isNaN(root.openXOverride) && isNaN(root.openYOverride)
    readonly property color settleColor: root.joined
        ? Services.AppState.joinColorAt(root.pillCX, root.pillCY) : Services.Colors.surfacePanel
    // One colour the whole way: a card born in the chip's accent and draining
    // into the bar's read as the pill lighting up for no reason.
    // Born in its chip's colour when that is not the bar's, and fading into
    // the panel as it stretches: a workspace chip lit as the active one got a
    // dark square dropped over it.
    property color startColor: "transparent"
    readonly property color fromColor: root.startColor.a > 0.01 ? root.startColor : root.settleColor
    readonly property color cardColor: card.mix(root.fromColor, root.settleColor, card.relay)
    readonly property real plateFade: card.plateless ? 0 : 1
    // A carried piece keeps its own colour the whole way: the one it has where
    // it lands.
    function pieceColor(settled) { return settled }
    // A piece only travels if it is the same piece at both ends.
    readonly property bool glyphFlies: glyphTarget !== null && pillGlyph !== ""
        && glyphTarget.text === pillGlyph
    readonly property bool labelFlies: labelTarget !== null && pillLabel !== ""
        && labelTarget.text === pillLabel

    // In flight: the copy is drawn and the real one is hidden. One flag drives
    // both, so the two are never on screen at once.
    // Nothing flies any more: the contents fade where they belong. Kept as
    // flags so a body can still ask, and always answers no.
    readonly property bool morphing: false
    readonly property bool morphingGlyph: morphing && glyphFlies
    readonly property bool morphingLabel: morphing && labelFlies

    // Scales every duration and pause together, so the order of the beats
    // survives whatever the speed. 1.0 is the shell's pace.
    property real speed: 1.0
    function ms(v) { return Math.max(1, Math.round(v / root.speed)) }

    // How long the retraction takes. The panel window has to stay mapped for
    // all of it -- unmapping earlier leaves the box halfway home and reads as
    // vanishing.
    readonly property int closeMs: root.ms(Services.Sizes.panelCloseMs)

    // Content fades in only once the drop has landed, and the caller can hang
    // its own timings off this.
    readonly property alias contentAmt: card.contentAmt
    // For a panel that carries shared pieces of its own (the clock, media):
    // 0 = they sit where the pill has them, 1 = where the panel does.
    readonly property alias morph: card.morph
    readonly property alias card: card
    // Everything declared inside goes in the card, clipped to it.
    default property alias content: body.data
    // Normally the card grows out of the bar, and which side stays pinned is
    // decided by the bar's edge. A panel whose pill is NOT on the bar says so
    // here instead.
    property string sourceEdge: ""            // "", "top" or "bottom"
    property real openXOverride: NaN
    property real openYOverride: NaN

    readonly property bool ownEdge: sourceEdge !== ""
    // The edge the pill's bar stands on.
    readonly property string pinSide: ownEdge ? sourceEdge
        : Services.Sizes.edgeAt(root.pillCX, root.pillCY, root.width, root.height)

    // The side facing the bar stays on the bar's outer edge where the chip
    // stands; along the bar the card is centred on the chip and kept on screen.
    readonly property real pinAt: Services.AppState.outerEdgeAt(pinSide, root.pillCX, root.pillCY, card.srcW, card.srcH)
    // Where it rests, for the window's input mask: the part of it over the
    // bar has to take clicks too.
    readonly property rect restRect: root.shown ? Qt.rect(root.openX, root.openY, root.fullW, root.fullH)
                                                : Qt.rect(0, 0, 0, 0)
    readonly property real fullW: root.openW
    readonly property real fullH: root.openH
    readonly property real openX: !isNaN(openXOverride) ? openXOverride
        : pinSide === "left" ? root.pinAt
        : pinSide === "right" ? root.pinAt - root.fullW
        : Services.Sizes.panelX(width, root.fullW, root.pillCX, root.pinSide)
    readonly property real openY: !isNaN(openYOverride) ? openYOverride
        : pinSide === "top" ? root.pinAt
        : pinSide === "bottom" ? root.pinAt - root.fullH
        : Services.Sizes.panelY(height, root.fullH, root.pillCY, root.pinSide)

    // A layer surface is not on screen in the frame it is asked for, so the
    // stretch waits for it or its first frames play unseen.
    Timer { id: arm; interval: Services.Sizes.panelArmMs; onTriggered: openAnim.restart() }
    onShownChanged: {
        if (shown) { closeAnim.stop(); arm.restart() }
        else { arm.stop(); openAnim.stop(); closeAnim.restart() }
    }
    Component.onCompleted: if (shown) arm.restart()

    Rectangle {
        id: card
        // Not drawn while it waits for the surface: it sat as a still square
        // on the chip for the length of the wait before it started to grow.
        visible: (root.shown && !arm.running) || card.fall > 0
        // The panel's own outline, separate from the bar's (Prefs.panelOutline).
        border.width: root.plateless || root.joined ? 0 : Services.Colors.panelEdgeW
        border.color: Services.Colors.panelEdgeColor

        // How far it has travelled, stretched away from the bar and spread
        // along it, and how much of the content is in.
        property real fall: 0
        property real stretch: 0
        property real spread: 0
        property real contentAmt: 0
        property real morph: 0
        // 0 = the chip's colour, 1 = the panel's.
        property real relay: 0

        function lerp(a, b, t) { return a + (b - a) * t }
        function mix(c1, c2, t) {
            return Qt.rgba(c1.r + (c2.r - c1.r) * t,
                           c1.g + (c2.g - c1.g) * t,
                           c1.b + (c2.b - c1.b) * t,
                           c1.a + (c2.a - c1.a) * t)
        }
        // Centre of a target in card coordinates. mapToItem has no change
        // signal, so the card's geometry and the target's own are touched to
        // make the binding re-run when either moves.
        function tgtX(item) {
            if (!item) return width / 2
            card.width; card.height; card.x
            item.x; item.y; item.width; item.height
            const p = item.mapToItem(card, item.width / 2, item.height / 2)
            return p.x
        }
        function tgtY(item) {
            if (!item) return height / 2
            card.width; card.height; card.y
            item.x; item.y; item.width; item.height
            const p = item.mapToItem(card, item.width / 2, item.height / 2)
            return p.y
        }

        // The chip goes dark, the box stretches out of it on one curve (fall,
        // stretch and spread together keep the bar side pinned), and the
        // contents fade in where they belong once it has most of its room.
        ParallelAnimation {
            id: openAnim
            PropertyAction { target: card; property: "morph"; value: 1 }
            NumberAnimation {
                target: card; property: "relay"; to: 1
                duration: root.ms(Services.Sizes.panelFlowInMs / 2); easing.type: Services.Sizes.easeOut
            }
            NumberAnimation {
                target: card; properties: "fall,stretch,spread"; to: 1
                duration: root.ms(Services.Sizes.panelFlowInMs)
                easing.type: Easing.BezierSpline; easing.bezierCurve: Services.Sizes.panelFlowCurve
            }
            SequentialAnimation {
                PauseAnimation { duration: root.ms(Services.Sizes.panelFlowInMs / 2) }
                NumberAnimation {
                    target: card; property: "contentAmt"; to: 1
                    duration: root.ms(Services.Sizes.panelFlowInMs / 2); easing.type: Easing.OutCubic
                }
            }
        }

        // The contents fade out, then the box goes home on the same curve and
        // lands soft on the chip.
        ParallelAnimation {
            id: closeAnim
            NumberAnimation {
                target: card; property: "contentAmt"; to: 0
                duration: root.ms(Services.Sizes.panelFadeMs); easing.type: Services.Sizes.easeIn
            }
            SequentialAnimation {
                PauseAnimation { duration: root.ms(Services.Sizes.panelShrinkDelayMs) }
                NumberAnimation {
                    target: card; properties: "fall,stretch,spread"; to: 0
                    duration: root.ms(Services.Sizes.panelFlowOutMs)
                    easing.type: Easing.BezierSpline; easing.bezierCurve: Services.Sizes.panelFlowCurve
                }
                PropertyAction { target: card; property: "morph"; value: 0 }
            }
            // Back into the chip's colour as it lands on the chip.
            SequentialAnimation {
                PauseAnimation { duration: root.ms(Services.Sizes.panelShrinkDelayMs + Services.Sizes.panelFlowOutMs / 2) }
                NumberAnimation {
                    target: card; property: "relay"; to: 0
                    duration: root.ms(Services.Sizes.panelFlowOutMs / 2); easing.type: Services.Sizes.easeIn
                }
            }
        }

        // Floored: a pill that is collapsed to nothing (the USB one hides when
        // no stick is in) would otherwise start the drop as a sliver.
        readonly property real srcW: Math.max(24, root.pillW)
        readonly property real srcH: Math.max(24, root.pillH)
        width: srcW + (root.fullW - srcW) * spread
        height: srcH + (root.fullH - srcH) * stretch
        x: root.pillCX + (root.openX + root.fullW / 2 - root.pillCX) * fall - width / 2
        y: root.pillCY + (root.openY + root.fullH / 2 - root.pillCY) * fall - height / 2

        radius: Services.Sizes.pillR + (root.cardRadius - Services.Sizes.pillR)
                * Math.min(1, Math.max(spread, stretch))

        // The alpha rides on the COLOUR, never on the item: `opacity` here would
        // take the tiles standing on the plate down with it.
        color: Qt.rgba(root.cardColor.r, root.cardColor.g, root.cardColor.b,
                       root.cardColor.a * root.plateFade)
        clip: true

        // Clicks inside must not reach the dismiss layer behind the panel.
        MouseArea { anchors.fill: parent; onClicked: {} }

        // ── The shared pieces ───────────────────────────────────────
        // Drawn at their final size and scaled down: stepping font.pixelSize
        // reflows in integer jumps. Positioned by centre, so scale never drags.
        Text {
            textFormat: Text.PlainText
            id: flyGlyph
            visible: root.morphingGlyph
            text: root.pillGlyph
            font.family: "Material Symbols Rounded"
            font.pixelSize: root.glyphTarget ? root.glyphTarget.font.pixelSize : 18
            color: root.pieceColor(root.glyphTarget ? root.glyphTarget.color
                                                    : Services.Colors.ghost)

            readonly property real s: card.lerp(18 / font.pixelSize, 1, card.morph)
            // Start: where it sits inside the CHIP, expressed against the card
            // itself -- the card is born on the chip's rect, so the two are the
            // same place. Read off the pill's screen position instead, the
            // piece would stay in the bar while the card travelled away from
            // it and then fall on its own afterwards.
            // Next to a name it is tucked against the left edge; on its own
            // (the USB pill) it is centred, and starting it off to one side
            // made it come home crooked.
            readonly property real fromCX: root.pillLabel !== ""
                ? (card.width - root.pillW) / 2 + 8
                  + flyGlyph.width * (18 / flyGlyph.font.pixelSize) / 2
                : card.width / 2
            readonly property real fromCY: card.height / 2
            x: card.lerp(fromCX, card.tgtX(root.glyphTarget), card.morph) - width / 2
            y: card.lerp(fromCY, card.tgtY(root.glyphTarget), card.morph) - height / 2
            transform: Scale {
                origin.x: flyGlyph.width / 2
                origin.y: flyGlyph.height / 2
                xScale: flyGlyph.s
                yScale: flyGlyph.s
            }
        }

        Text {
            textFormat: Text.PlainText
            id: flyLabel
            visible: root.morphingLabel
            text: root.pillLabel
            // Its landing spot's font: a label can be a glyph or a kanji.
            font.family: root.labelTarget ? root.labelTarget.font.family : "JetBrainsMono NF"
            font.bold: true
            font.pixelSize: root.labelTarget ? root.labelTarget.font.pixelSize : 12
            color: root.pieceColor(root.labelTarget ? root.labelTarget.color
                                                    : Services.Colors.snow)

            readonly property real s: card.lerp(12 / font.pixelSize, 1, card.morph)
            // Against the card, for the same reason as the glyph above.
            readonly property real fromCX: (card.width + root.pillW) / 2 - 8
                - flyLabel.width * (12 / flyLabel.font.pixelSize) / 2
            readonly property real fromCY: card.height / 2
            x: card.lerp(fromCX, card.tgtX(root.labelTarget), card.morph) - width / 2
            y: card.lerp(fromCY, card.tgtY(root.labelTarget), card.morph) - height / 2
            transform: Scale {
                origin.x: flyLabel.width / 2
                origin.y: flyLabel.height / 2
                xScale: flyLabel.s
                yScale: flyLabel.s
            }
        }

        // The content is laid out at the card's open size from the first frame,
        // so nothing reflows while it grows. It stands on the side the card is
        // pinned to, like the card does: centred, it slid inside the box as the
        // box grew and shrank, and showed through cut in half on the way home.
        Item {
            id: body
            width: root.openW
            height: root.openH
            x: root.pinSide === "left" ? 0
             : root.pinSide === "right" ? parent.width - width
             : (parent.width - width) / 2
            y: root.pinSide === "top" ? 0
             : root.pinSide === "bottom" ? parent.height - height
             : (parent.height - height) / 2
            opacity: card.contentAmt
            visible: opacity > 0.01
        }
    }
}
