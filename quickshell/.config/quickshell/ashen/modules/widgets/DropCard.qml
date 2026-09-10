import QtQuick

import "root:/services" as Services

// A panel that comes out of its bar pill, in four beats that do NOT run at
// once -- that is the whole point of them:
//   1. the chip lets go of its colour: the lit fill drains away and what it
//      says lights up instead, still sitting in the bar;
//   2. STILL A PILL, it leaves the bar and travels to where the panel lives;
//   3. only once it has arrived does it become the card: the box opens along
//      two axes, the one it travelled on leading, and what it carries slides
//      out into the panel's arrangement while it does;
//   4. everything that was never in the chip fades in last.
// Closing runs the beats backwards: the card becomes a pill again, the pill
// goes home, and only then does it light back up.
// Same beats in MorphCard, which is the clock's and the media panel's.
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
    readonly property real tone: card.relay
    // Where the plate ENDS. Normally the panel surface; a panel that is not a
    // card -- the power menu is four tiles and nothing around them -- asks for
    // "transparent" and the plate leaves once it has arrived.
    property color landColor: Services.Colors.surfacePanel
    readonly property bool plateless: landColor.a < 0.01
    // A plateless panel has NO plate at any point -- not at rest, not on the
    // way in. The power menu is four tiles and nothing around them, and a box
    // that is only there while it travels is still a box you watch arrive.
    // What moves is the pieces flying out of the pill and the tiles staging in.
    readonly property color cardColor:
        card.mix(pillColor, Services.Colors.surfacePanel, tone)
    readonly property real plateFade: card.plateless ? 0 : 1
    // A flying piece still needs a tone to be read against, and it is not the
    // plate that is not there: it is the surface the panel sits on.
    readonly property color inkAgainst: root.plateless
        ? Services.Colors.surfacePanel : root.cardColor
    // What a carried piece looks like while it is on its way: OFF, the way a
    // disabled chip reads. It is lit only once it is in its place -- see the
    // `ink` driver.
    property color pieceDim: Services.Colors.mist
    // Chip ink -> off -> lit. Written once here because both pieces cross the
    // same three colours and only their landing colour differs.
    function pieceColor(settled) {
        return card.mix(card.mix(Services.Colors.onColor(root.pillColor),
                                 root.pieceDim, card.relay),
                        settled, card.ink)
    }
    // A piece only travels if it is the same piece at both ends.
    readonly property bool glyphFlies: glyphTarget !== null && pillGlyph !== ""
        && glyphTarget.text === pillGlyph
    readonly property bool labelFlies: labelTarget !== null && pillLabel !== ""
        && labelTarget.text === pillLabel

    // In flight: the copy is drawn and the real one is hidden. One flag drives
    // both, so the two are never on screen at once.
    readonly property bool morphing: card.morph < 0.995 && (shown || card.fall > 0.01)
    readonly property bool morphingGlyph: morphing && glyphFlies
    readonly property bool morphingLabel: morphing && labelFlies

    // Scales every duration and pause together, so the order of the beats
    // survives whatever the speed. 1.0 is the shell's pace.
    property real speed: 1.0
    function ms(v) { return Math.max(1, Math.round(v / root.speed)) }

    // How long the whole retraction takes, last beat included: contents out,
    // pieces home, the box back to a pill, the pill back to the bar, then the
    // colour. The panel window has to stay mapped for all of it -- unmapping
    // earlier leaves the pill halfway to its slot and reads as vanishing.
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
    // Normally the drop hangs off the bar, and where it lands is decided by the
    // bar's edge. A panel whose pill is NOT on the bar -- Process, off its peek
    // button on the bottom of the screen -- says so here instead, and the neck
    // ties it to that edge rather than to the bar.
    property string sourceEdge: ""            // "", "top" or "bottom"
    property real openXOverride: NaN
    property real openYOverride: NaN

    readonly property bool ownEdge: sourceEdge !== ""
    // Which line the drop is hanging from.
    readonly property real srcEdge: ownEdge
        ? (sourceEdge === "bottom" ? root.height : 0)
        : (Services.Sizes.barPosition === "bottom" ? root.height - Services.Sizes.barH
                                                   : Services.Sizes.barH)
    readonly property bool srcBelow: ownEdge ? sourceEdge === "bottom"
                                             : Services.Sizes.barPosition === "bottom"
    // A panel that lands far from where it left -- the launcher crosses to the
    // middle of the screen -- can turn the bridge off. Stretched over half a
    // screen it stops reading as something being pulled apart and becomes a
    // rope tying the card to the edge.
    property bool neckEnabled: true

    // A neck only makes sense pulling up or down; sideways it would be a rope
    // across the screen. GooNeck only ever draws a vertical bridge, so an own
    // edge of "left" or "right" gets no neck rather than a wrong one.
    readonly property bool neckable: neckEnabled && (ownEdge
        ? (sourceEdge === "top" || sourceEdge === "bottom")
        : !Services.Sizes.barVertical)

    // Which axis leads the growth, the way MorphCard reckons it: a card leaving
    // a capsule glued to the SIDE of the screen has to sweep sideways, or it
    // reads as falling from somewhere it never was.
    readonly property bool sideways: ownEdge
        ? (sourceEdge === "left" || sourceEdge === "right")
        : Services.Sizes.barVertical
    readonly property int leadMs: root.ms(120)
    readonly property int trailMs: root.ms(160)

    readonly property real openX: isNaN(openXOverride)
        ? Services.Sizes.panelX(width, root.openW, root.pillCX) : openXOverride
    readonly property real openY: isNaN(openYOverride)
        ? Services.Sizes.panelY(height, root.openH, root.pillCY) : openYOverride

    // A layer surface is not on screen in the frame it is asked for, so the
    // fall waits for it or its first frames play unseen.
    Timer { id: arm; interval: Services.Sizes.panelArmMs; onTriggered: openAnim.restart() }
    onShownChanged: {
        if (shown) { closeAnim.stop(); arm.restart() }
        else { arm.stop(); openAnim.stop(); closeAnim.restart() }
    }
    Component.onCompleted: if (shown) arm.restart()

    // The goo bridge tying the drop to the bar until it pinches off. Only on a
    // horizontal bar: sideways it would be a neck across the screen.
    GooNeck {
        active: root.neckable
        pillCX: root.pillCX
        pillW: root.pillW
        fromBelow: root.srcBelow
        barEdge: root.srcEdge
        cardEdge: root.srcBelow ? card.y + card.height : card.y
        cardHalfW: card.width / 2
        pinch: Math.max(0, Math.min(1, card.fall / 0.55))
        // Not a fixed surface tone here: the card is born the chip's accent and
        // settles to the panel colour, and the neck has to cross with it.
        fillColor: root.cardColor
    }

    Rectangle {
        id: card
        // The panel's own outline, separate from the bar's (Prefs.panelOutline).
        border.width: Services.Colors.panelEdgeW
        border.color: Services.Colors.fillOutline

        // How far it has fallen, how far it has stretched away from the bar,
        // how far it has spread sideways, and how much of the content is in.
        property real fall: 0
        property real stretch: 0
        property real spread: 0
        property real contentAmt: 0
        property real morph: 0
        // How lit the carried pieces are. Last of all: they arrive off and
        // light up once they are where they belong.
        property real ink: 0
        // How far along the colour hand-over is; see `tone` on the root.
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

        // The beats, as pauses off a single clock. Named here so the order can
        // be read in one place instead of totted up from six animations.
        readonly property int tColour: root.ms(100)   // 1. the lit fill drains
        readonly property int tGo: root.ms(100)       // 2. leaves the bar…
        readonly property int tGoMs: root.ms(100)     //    …still pill-shaped
        readonly property int tOpen: root.ms(190)     // 3. becomes the card
        readonly property int tSlide: root.ms(210)    //    contents slide out
        readonly property int tFill: root.ms(350)     // 4. the rest fades in
        readonly property int tInk: root.ms(370)      //    and the pieces light

        ParallelAnimation {
            id: openAnim
            // 1. The chip hands its colour over before anything moves: the card
            // is a copy of the chip until this is done, so what you see is the
            // pill going quiet, not a second pill appearing.
            NumberAnimation {
                target: card; property: "relay"; to: 1
                duration: card.tColour; easing.type: Services.Sizes.easeInOut
            }
            // …and what it says goes OFF with it: the piece travels dim and is
            // lit only at the end, so the journey is one quiet thing moving.
            SequentialAnimation {
                PauseAnimation { duration: card.tInk }
                NumberAnimation {
                    target: card; property: "ink"; to: 1
                    duration: root.ms(130); easing.type: Services.Sizes.easeOut
                }
            }
            // 2. It leaves the bar at pill size. Nothing grows yet -- a box
            // that opens on the way down is the drop this used to be.
            SequentialAnimation {
                PauseAnimation { duration: card.tGo }
                NumberAnimation {
                    target: card; property: "fall"; to: 1
                    duration: card.tGoMs; easing.type: Services.Sizes.easeOut
                }
            }
            // 3. Arrived, it opens out: the axis it travelled on leads and the
            // other trails, so it unfolds rather than zooms.
            SequentialAnimation {
                PauseAnimation { duration: card.tOpen }
                NumberAnimation {
                    target: card; property: "stretch"; to: 1
                    duration: root.sideways ? root.trailMs : root.leadMs
                    easing.type: Services.Sizes.easeOut
                }
            }
            SequentialAnimation {
                PauseAnimation { duration: card.tOpen }
                NumberAnimation {
                    target: card; property: "spread"; to: 1
                    duration: root.sideways ? root.leadMs : root.trailMs
                    easing.type: Services.Sizes.easeOut
                }
            }
            // …and what the chip was carrying travels to its place in the panel
            // WHILE the box opens: the box and its contents are one movement.
            SequentialAnimation {
                PauseAnimation { duration: card.tSlide }
                NumberAnimation {
                    target: card; property: "morph"; to: 1
                    duration: root.ms(150); easing.type: Services.Sizes.easeOut
                }
            }
            // 4. Never before the carried piece has landed: with the two at
            // once the panel reads as assembling backwards.
            SequentialAnimation {
                PauseAnimation { duration: card.tFill }
                NumberAnimation { target: card; property: "contentAmt"; to: 1; duration: root.ms(120) }
            }
        }

        ParallelAnimation {
            id: closeAnim
            // Backwards, beat for beat: the extras go, the carried pieces
            // regroup into the chip's arrangement, the card becomes a pill
            // again, the pill goes home, and only there does it light up.
            NumberAnimation { target: card; property: "contentAmt"; to: 0; duration: root.ms(90) }
            // The pieces go off before they set off, the way they arrived.
            NumberAnimation { target: card; property: "ink"; to: 0; duration: root.ms(110) }
            SequentialAnimation {
                PauseAnimation { duration: root.ms(40) }
                NumberAnimation {
                    target: card; property: "morph"; to: 0
                    duration: root.ms(130); easing.type: Services.Sizes.easeInOut
                }
            }
            SequentialAnimation {
                PauseAnimation { duration: root.ms(120) }
                ParallelAnimation {
                    // The leading axis closes last, so it leaves along the line
                    // it arrived on.
                    NumberAnimation {
                        target: card; property: "stretch"; to: 0
                        duration: root.sideways ? root.ms(140) : root.ms(120)
                        easing.type: Services.Sizes.easeInOut
                    }
                    NumberAnimation {
                        target: card; property: "spread"; to: 0
                        duration: root.sideways ? root.ms(120) : root.ms(140)
                        easing.type: Services.Sizes.easeInOut
                    }
                }
            }
            SequentialAnimation {
                PauseAnimation { duration: root.ms(240) }
                NumberAnimation {
                    target: card; property: "fall"; to: 0
                    duration: root.ms(120); easing.type: Services.Sizes.easeInOut
                }
            }
            // Home first, lit after: taking the accent back mid-flight is a
            // flash on the way out.
            SequentialAnimation {
                PauseAnimation { duration: root.ms(350) }
                NumberAnimation {
                    target: card; property: "relay"; to: 0
                    duration: root.ms(100); easing.type: Services.Sizes.easeInOut
                }
            }
        }

        // Floored: a pill that is collapsed to nothing (the USB one hides when
        // no stick is in) would otherwise start the drop as a sliver.
        readonly property real srcW: Math.max(24, root.pillW)
        readonly property real srcH: Math.max(24, root.pillH)
        width: srcW + (root.openW - srcW) * spread
        height: srcH + (root.openH - srcH) * stretch
        x: root.pillCX + (root.openX + root.openW / 2 - root.pillCX) * fall - width / 2
        y: root.pillCY + (root.openY + root.openH / 2 - root.pillCY) * fall - height / 2

        radius: Services.Sizes.pillR + (root.cardRadius - Services.Sizes.pillR)
                * Math.min(1, Math.max(spread, stretch))

        // The alpha rides on the COLOUR, never on the item: `opacity` here would
        // take the tiles standing on the plate down with it.
        color: Qt.rgba(root.cardColor.r, root.cardColor.g, root.cardColor.b,
                       root.cardColor.a * root.plateFade)
        gradient: Services.Prefs.useGradients && root.pillActive && root.tone < 0.02
            ? Services.Colors.accentGradient : null
        clip: true

        // Clicks inside must not reach the dismiss layer behind the panel.
        MouseArea { anchors.fill: parent; onClicked: {} }

        // ── The shared pieces ───────────────────────────────────────
        // Drawn at their final size and scaled down: stepping font.pixelSize
        // reflows in integer jumps. Positioned by centre, so scale never drags.
        Text {
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
            id: flyLabel
            visible: root.morphingLabel
            text: root.pillLabel
            font.family: "JetBrainsMono NF"
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
        // so nothing reflows on the way down; it is only revealed at the end.
        Item {
            id: body
            width: root.openW
            height: root.openH
            anchors.horizontalCenter: parent.horizontalCenter
            y: (parent.height - height) / 2
            opacity: card.contentAmt
            visible: opacity > 0.01
        }
    }
}
