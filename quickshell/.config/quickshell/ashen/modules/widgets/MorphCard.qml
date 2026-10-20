import QtQuick
import "root:/services" as Services

// ── Dynamic-island morph ────────────────────────────────────────────────────
// A panel that IS its pill, grown up: it stretches out of the pill's rect in
// one movement and stays on it -- the edge on the bar's side never leaves the
// pill -- wearing the colour of what it came out of, so it reads as the bar
// stretching rather than a card dropped over it.
Item {
    id: root

    // Open state, straight off the panel's AppState flag.
    property bool shown: false

    // The pill it grows out of, and the card it grows into.
    property real pillW: 1
    property real pillH: 1
    property real pillCX: 0
    property real pillCY: 0
    // Where the card is going. Once it has landed these can still change --
    // a tab swapped inside the card, a list that grew -- and the card travels
    // between the two sizes instead of jumping, the same way a panel does.
    // Armed only after the landing: while the card is on its way the size IS
    // the destination, and `spread` is already the thing interpolating it.
    property real openW: 100
    property real openH: 100
    // …and only in the morph style: a card that travels is a transformation,
    // which is the one thing the window style asked not to have.
    Behavior on openW {
        enabled: plate.spread >= 1 && !plate.plain
        Anim { speed: Services.Sizes.msPanel }
    }
    Behavior on openH {
        enabled: plate.spread >= 1 && !plate.plain
        Anim { speed: Services.Sizes.msPanel }
    }

    // What the window-style card is made of. Transparent for a card whose
    // content already carries its own plates and wants no container.
    property color plateColor: Services.Colors.surfacePanel
    // Grown out of a pill it wears the plate the pill stands on instead.
    readonly property color joinColor: Services.AppState.joinColorAt(root.pillCX, root.pillCY)

    // Where it lands. Left alone, it grows out of its pill. A morph that
    // happens somewhere else (the lock screen has no bar) names its own spot.
    property real openXOverride: NaN
    property real openYOverride: NaN
    // Is its pill on the bar? A parked pill reports nothing, and morphing out
    // of wherever it last was flew the card in from a spot on no bar: with no
    // pill it arrives as a window, in the middle of the screen.
    property bool hasPill: true

    // True once the surface has landed and the morph is armed. The panel
    // mirrors it into AppState -- which flag it is differs per panel, so it is
    // not set here.
    property bool morphing: false

    // In "window" style the card never becomes the pill: it just appears where
    // it would have dropped. A capsule that hides itself anyway leaves a hole
    // and half a morph -- the pill only stands aside when the card is really
    // wearing its face. This is the only thing a capsule should ask.
    readonly property bool plain: plate.plain
    readonly property bool wearingFace: root.morphing && !plate.plain

    // Children go inside the blob, clipped by it, positioned against the part
    // of it past the bar, and faded with it. The pieces this file owns are
    // assigned to `data` by hand further down: with the default property
    // aliased away, they would otherwise try to become children of the very
    // rectangle they build.
    default property alias content: inner.data

    // The drivers, published for the shared items to interpolate against.
    property alias fall: plate.fall          // travel from the bar to the resting spot
    property alias stretch: plate.stretch    // height
    property alias spread: plate.spread      // width
    // 0 = shared items sit in the pill's arrangement, 1 = the card's.
    property alias morph: plate.morph
    // Fade for everything that exists only in the card
    property alias contentAmt: plate.contentAmt

    // The body's pieces arrive one after another rather than all together --
    // the same reckoning PanelArrive does, so a panel reads the same whichever
    // style it is wearing. The blob is the box; this is only what is inside it,
    // which is why it can be had on top of the morph rather than instead of it.
    // In the plain (window) style there is no choreography to join: the content
    // simply fades, and staggering a fade reads as lag.
    function stage(i) {
        if (plate.plain) return plate.contentAmt
        const start = Math.min(0.5, i * 0.1)
        return Math.max(0, Math.min(1, (plate.contentAmt - start) / (1 - start)))
    }
    // A few pixels of rise, so a piece settles rather than appears.
    function riseOf(i) { return plate.plain ? 0 : (1 - root.stage(i)) * 10 }

    // Where the blob actually is, for anything that has to line up with it.
    readonly property alias plateH: plate.height

    function lerp(a, b, t) { return a + (b - a) * t }
    function mix(c1, c2, t) {
        return Qt.rgba(c1.r + (c2.r - c1.r) * t,
                       c1.g + (c2.g - c1.g) * t,
                       c1.b + (c2.b - c1.b) * t,
                       c1.a + (c2.a - c1.a) * t)
    }

    // A layer surface is not presented on the frame it is asked for, so a morph
    // started at click time spends its first ~200 ms off screen and only its
    // tail is ever seen. Hold the pill, let the surface land, then run.
    onShownChanged: {
        if (shown) {
            arm.restart()
        } else {
            arm.stop()
            root.morphing = false
            openAnim.stop()
            closeAnim.start()
            closeDelay.restart()
        }
    }
    // The window has to stay mapped through the close: the panel asks this.
    readonly property bool closing: closeDelay.running
    // Where it rests, for the window's input mask: the part over the bar has
    // to take clicks too.
    readonly property rect restRect: root.shown
        ? Qt.rect(plate.openX, plate.openY, plate.fullW, plate.fullH) : Qt.rect(0, 0, 0, 0)

    data: [

    Timer {
        id: arm
        interval: Services.Sizes.panelArmMs
        onTriggered: {
            root.morphing = true
            closeAnim.stop()
            // The style may have changed since it last closed.
            plate.restDrivers()
            openAnim.start()
        }
    },

    // The whole way home.
    Timer { id: closeDelay; interval: Services.Sizes.panelCloseMs },

    Rectangle {
        id: plate

        // Where the grown-up card wants to end up. Out of a pill, the side that
        // faces the bar stays on the bar's outer edge there; along the bar it
        // is centred on the pill and kept on screen.
        readonly property real pinAt: Services.AppState.outerEdgeAt(edge, root.pillCX, root.pillCY, root.pillW, root.pillH)
        readonly property real fullW: root.openW
        readonly property real fullH: root.openH
        readonly property real openX: !root.hasPill ? (root.width - root.openW) / 2
            : !isNaN(root.openXOverride) ? root.openXOverride
            : !plate.plain && edge === "left" ? plate.pinAt
            : !plate.plain && edge === "right" ? plate.pinAt - plate.fullW
            : Services.Sizes.panelX(root.width, plate.fullW, root.pillCX, edge)
        readonly property real openY: !root.hasPill ? (root.height - root.openH) / 2
            : !isNaN(root.openYOverride) ? root.openYOverride
            : !plate.plain && edge === "top" ? plate.pinAt
            : !plate.plain && edge === "bottom" ? plate.pinAt - plate.fullH
            : Services.Sizes.panelY(root.height, plate.fullH, root.pillCY, edge)

        // Only drawn once the morph is actually armed, so the pill never has to
        // share the screen with a copy of itself.
        visible: root.morphing || closeDelay.running

        // "Window" style: the drivers land on 1 at once and only the opacity
        // moves, so the card appears where it belongs without becoming the
        // pill first.
        readonly property bool plain: Services.Prefs.panelStyle === "plain" || !root.hasPill
        property real plainFade: 0

        // Where the drivers rest while closed. In "window" they stay landed -- the
        // card never becomes the pill -- but in "morph" they must be back at
        // zero. The style can change between openings, so this is applied on the
        // way in rather than assumed.
        function restDrivers() {
            const v = plate.plain ? 1 : 0
            plate.fall = v; plate.stretch = v; plate.spread = v; plate.morph = v
            plate.contentAmt = plate.plain ? 1 : 0
            plate.plainFade = 0
        }
        onPlainChanged: if (!root.shown) plate.restDrivers()

        property real fall: 0
        property real stretch: 0
        property real spread: 0
        property real morph: 0
        property real contentAmt: 0

        // Explicit animations rather than Behaviors with direction-dependent
        // durations: a `root.opening ? a : b` inside a Behavior is read with
        // the *old* value of the flag, so the close silently ran with the open
        // timings. Two named animations leave no room for that.
        //
        // Morph: the pill goes dark, the box stretches out of it on one curve
        // (fall, stretch and spread together keep the bar side pinned), and
        // what is inside fades in where it belongs once the box has most of
        // its room. Nothing travels: rearranging pieces on the way read as
        // broken. Window: only the fade moves; the drivers are already landed.
        ParallelAnimation {
            id: openAnim
            NumberAnimation {
                target: plate; property: "plainFade"; to: 1
                duration: plate.plain ? 260 : 0; easing.type: Services.Sizes.easeOut
            }
            PropertyAction { target: plate; property: "morph"; value: 1 }
            NumberAnimation {
                target: plate; properties: "fall,stretch,spread"; to: 1
                duration: plate.plain ? 0 : Services.Sizes.panelFlowInMs
                easing.type: Easing.BezierSpline; easing.bezierCurve: Services.Sizes.panelFlowCurve
            }
            SequentialAnimation {
                PauseAnimation { duration: plate.plain ? 0 : Services.Sizes.panelFlowInMs / 2 }
                NumberAnimation {
                    target: plate; property: "contentAmt"; to: 1
                    duration: plate.plain ? 0 : Services.Sizes.panelFlowInMs / 2; easing.type: Easing.OutCubic
                }
            }
        }
        // The contents fade out, then the box goes home and lands soft.
        ParallelAnimation {
            id: closeAnim
            NumberAnimation {
                target: plate; property: "plainFade"; to: 0
                duration: plate.plain ? 200 : 0; easing.type: Services.Sizes.easeIn
            }
            NumberAnimation {
                target: plate; property: "contentAmt"; to: plate.plain ? 1 : 0
                duration: plate.plain ? 0 : Services.Sizes.panelFadeMs; easing.type: Services.Sizes.easeIn
            }
            SequentialAnimation {
                PauseAnimation { duration: plate.plain ? 0 : Services.Sizes.panelShrinkDelayMs }
                NumberAnimation {
                    target: plate; properties: "fall,stretch,spread"; to: plate.plain ? 1 : 0
                    duration: plate.plain ? 0 : Services.Sizes.panelFlowOutMs
                    easing.type: Easing.BezierSpline; easing.bezierCurve: Services.Sizes.panelFlowCurve
                }
                PropertyAction { target: plate; property: "morph"; value: plate.plain ? 1 : 0 }
            }
        }

        // Window style unrolls away from the bar's edge, along its own axis.
        // The edge the pill's bar stands on.
        readonly property string edge: Services.Sizes.edgeAt(root.pillCX, root.pillCY, root.width, root.height)
        readonly property bool sideways: edge === "left" || edge === "right"
        readonly property real unroll: plate.plain ? 0.06 + 0.94 * plate.plainFade : 1
        width: (root.pillW + (plate.fullW - root.pillW) * spread) * (sideways ? unroll : 1)
        height: (root.pillH + (plate.fullH - root.pillH) * stretch) * (sideways ? 1 : unroll)
        x: !plate.plain ? root.pillCX + (openX + plate.fullW / 2 - root.pillCX) * fall - width / 2
           : edge === "right" ? openX + plate.fullW - width
           : sideways ? openX : openX + plate.fullW / 2 - width / 2
        y: !plate.plain ? root.pillCY + (openY + plate.fullH / 2 - root.pillCY) * fall - height / 2
           : edge === "bottom" ? openY + plate.fullH - height : openY

        // Pill corner while small, card corner once open
        opacity: plate.plain ? plate.plainFade : 1
        radius: Services.Sizes.pillR + (20 - Services.Sizes.pillR) * Math.min(1, spread)
        color: plate.plain ? root.plateColor : root.joinColor
        border.width: plate.plain ? Services.Colors.panelEdgeW : 0
        border.color: Services.Colors.panelEdgeColor
        clip: true

        MouseArea { anchors.fill: parent; onClicked: {} }

        // Everything the panel puts inside, faded in and out as one -- the
        // window style's contents are always in.
        Item {
            id: inner
            anchors.fill: parent
            opacity: plate.contentAmt
        }
    }
    ]
}
