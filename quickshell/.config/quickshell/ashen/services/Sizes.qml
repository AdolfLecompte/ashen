pragma Singleton
import Quickshell
import QtQuick

// Shared bar metrics and geometry. Tweak the numbers here to scale the whole
// bar at once; ask the helpers below where a panel should sit rather than
// hardcoding an edge, so every panel follows the bar when it moves.
Singleton {
    id: root

    // Bar thickness: height on a horizontal bar, width on a vertical one
    // The same in every style: the bar IS the frame's top side, so it needs no
    // room for it.
    readonly property int barH: 56

    // The widest a column of settings rows may get. A row is a label with its
    // control on the end; past this the two stop reading as a pair however the
    // row is built. The panel itself stays wide -- the column is centred in it.
    readonly property int readMeasure: 900

    // Dock: the icon box, and the plate's padding around the row.
    readonly property int dockIcon: Math.max(28, Math.min(72, Prefs.dockIconSize))
    readonly property int dockPad: 8

    // Pill (top level bar item) size and corner radius
    readonly property int pillH: 44
    readonly property int pillR: 10
    // Air between capsules in a group -- ONE number, the same between any two
    // neighbours. Tall pills used to buy extra air on each side, which meant a
    // column of capsules had three different gaps in it depending on who stood
    // next to whom. A 44 px button already reads as a different thing from a
    // 190 px column without the gap having to say so.
    // On a plate (solid, island, framed) nothing but bare icons stands on the
    // bar, and capsule air between them read as a bar with holes in it.
    readonly property int barGap: root.barSolid ? 2 : (root.barVertical ? 10 : 6)

    // A side bar is 56 px of INPUT but its window is wider, so a chip can paint
    // its reading out past the strip instead of growing taller. The mask stays
    // on the strip, so the extra width is only ever pixels: nothing there hears
    // the pointer and nothing under it stops hearing it.
    readonly property int barSpill: 220

    // The utility pill that peeks out of the edges the bar is not on. Slimmer
    // than a bar pill, so it reads as a ledge. Here because panels grow from it.

    // ── Hover language ──────────────────────────────────────────────────
    // One place for how everything you can click on the bar reacts: grow
    // under the pointer, give a little under the click. Every pill and chip
    // calls the same function, so none of them can drift on its own.
    readonly property real pillHoverScale: 1.06
    readonly property real pillPressScale: 0.94
    readonly property int pillHoverMs: 150
    function hoverScale(hovered, pressed) {
        if (pressed) return pillPressScale
        return hovered ? pillHoverScale : 1.0
    }

    // The same gesture on something wide. 6% of a 32 px chip is two pixels; 6%
    // of a card half the panel across is thirty, and it shoves itself out of
    // whatever is holding it. The growth is capped in PIXELS instead, so a chip
    // keeps exactly the hover it always had and a big surface only breathes.
    readonly property real hoverGrowPx: 4
    function hoverScaleFor(w, hovered, pressed) {
        if (pressed) return pillPressScale
        if (!hovered) return 1.0
        if (w <= 0) return pillHoverScale
        return Math.min(pillHoverScale, 1 + hoverGrowPx / w)
    }

    // The tint a thing takes on under the pointer is NOT here: it is a colour,
    // and it lives with the other fills in Colors (fillRest / fillStrong /
    // fillSunken). Sizes owns how things move, Colors owns how they look.

    // Inner chip (item nested inside a pill) size and corner radius
    readonly property int innerH: 32
    readonly property int innerR: 8

    // Smallest gap between two clickable things: closer and they read as one
    // control, and a hovered button grows into its neighbour. Never less.
    readonly property int btnGap: 6

    // ── Type scale ───────────────────────────────────────────────────────
    // Nine steps and nothing between them. A panel uses at most four; if it
    // needs five, it is two panels.
    readonly property int fsCaption: 9        // the line under a title, units
    readonly property int fsMeta: 10          // column headers, labels
    readonly property int fsBody: 11          // list rows — the default
    readonly property int fsInput: 13         // anything typed into
    readonly property int fsCardTitle: 14     // bold: a card's name
    readonly property int fsSectionTitle: 17  // bold: SectionHead
    readonly property int fsPanelTitle: 20    // bold: the panel's own name
    readonly property int fsReadout: 24       // bold: the number that IS the card
    readonly property int fsHero: 42          // empty-state glyph, lock clock

    // ── Shape ────────────────────────────────────────────────────────────
    // Everything is a rounded rectangle or a circle; these are the corners it
    // may have. See innerR and pillR above for the two small ones.
    readonly property int cardR: 14           // a card inside a panel
    readonly property int cardLgR: 18         // a hero card
    readonly property int panelR: 22          // the panel itself

    // ── Motion ───────────────────────────────────────────────────────────
    // Every duration in the shell comes from here. Choreographies -- a drop,
    // an arrival, a staged swap -- keep their own numbers: those are a score,
    // not a style.
    readonly property int msInstant: 90       // acknowledging a click
    readonly property int msMicro: 140        // colour, opacity, hover
    readonly property int msStandard: 200     // a property moving on your input
    readonly property int msPronounced: 260   // an accent travelling, a tab turning
    readonly property int msEmphasis: 320     // resizing, or covering a distance
    readonly property int msPanel: 420        // a panel's own box

    // Does anything move? False and every Anim/ColorAnim takes zero time: the
    // values still arrive, they just stop travelling. Game mode turns this off
    // and nothing else should -- it is not a preference, it is a mode. Distinct
    // from `hidden`, which is about the bar being off screen while it changes
    // edge, not about motion in general.
    readonly property bool motion: !Game.on

    // The curves, named by what they are for.
    readonly property int easeOut: Easing.OutCubic      // arriving, settling
    readonly property int easeIn: Easing.InCubic        // leaving
    readonly property int easeInOut: Easing.InOutCubic  // there and back
    readonly property int easeBox: Easing.OutQuint      // a panel's box, no bounce
    readonly property int easeLoop: Easing.InOutSine    // heartbeats, glows
    readonly property int easeTrace: Easing.Linear      // progress strokes: a
                                                        // front-loaded curve
                                                        // hides the duration
    // Overshoot lives only in a landing, and only across the short axis.
    readonly property real overshoot: 0.7

    // ── Panel opening language ──────────────────────────────────────────
    // A layer surface is not on screen in the frame it is asked for, so panels
    // wait this long before growing -- and their pill hands over on the same
    // beat, or the bar goes blank first.
    readonly property int panelArmMs: 200
    // How long a panel takes to climb back into its pill. The window has to
    // stay mapped for all of it and the pill only comes back at the end, so
    // the panel, its dismiss layer and the chip all read it from here.
    // Four beats, so it is longer than a single collapse was: extras out,
    // pieces home, card back to a pill, pill back to its slot, colour last.
    readonly property int panelCloseMs: 470

    // Gap between the bar and a panel hanging off it, and between a panel and
    // the far screen edges
    readonly property int panelGap: 8
    // Room a panel keeps from a screen edge; inside the frame, never on it.
    readonly property int edgeGap: 12 + (root.barFramed ? root.frameW : 0)

    // ── Bar style ────────────────────────────────────────────────────────
    // `solid` and `framed` share the plate; only `framed` lines the other three
    // edges. Read from `appliedStyle`, so the change rides the fade.
    readonly property bool barSolid: root.appliedStyle === "solid" || root.barFramed
                                     || root.barIsland
    readonly property bool barFramed: root.appliedStyle === "framed"
    // One plate per SECTION instead of one across the edge: the bar stops being
    // a band and becomes two or three floating blocks. It still reserves the
    // same strip, so nothing else on screen moves.
    readonly property bool barIsland: root.appliedStyle === "island"
    // The bar's share of its edge, 50-100 %. Framed keeps the whole side: the
    // border is the bar there, and half a border is not a border.
    readonly property int barLength: root.barFramed
        ? 100 : Math.max(50, Math.min(100, Prefs.barLength))
    // Framed draws no plate of its own: the frame is it.
    readonly property bool barPlate: root.appliedStyle === "solid"
    // Border thickness, and the outer gap it stands in for while it is up.
    // `shippedGap` is what hypr/conf/general.lua sets.
    // How thick the outline style draws its edge. Not 1: at one pixel over a
    // wallpaper the border reads as an artefact of the blur rather than as a
    // line somebody chose.
    readonly property int outlineW: 2
    readonly property int frameW: 10
    readonly property int shippedGap: 8
    // Line of wallpaper between a window and the border.
    readonly property int framedGap: 8
    // Corner of the hole the frame leaves.
    readonly property int frameR: 16

    // The plate sits exactly where the capsules sit, so switching style moves
    // nothing: `plateAlong` is the gap at the ends, `plateCross` the long sides.
    // One slot of the visualiser's wave, in PIXELS. A count would make the same
    // 96 bars thinner on a shorter edge, so the wave changed with the bar's side.
    readonly property int cavaSlot: 20
    // How far the wave may reach past the frame's inner edge in the framed
    // style, where the ring covers the whole bar: without it nothing shows.
    readonly property int cavaSpill: 24

    readonly property int plateAlong: 12
    readonly property int plateCross: (root.barH - root.pillH) / 2
    readonly property int barR: root.pillR

    // ── Bar placement ────────────────────────────────────────────────────
    // `barPosition` is what the user picked; `applied` is the edge everything
    // lays out against, and it only changes while the bar is hidden -- moving
    // the bar is animated: it fades out, swaps edge, and fades back in.
    readonly property string wanted: Prefs.barPosition
    property string applied: Prefs.barPosition
    // Also the gate on every animated pill SIZE: while this is up the bar is
    // invisible, so the pills swap their two axes in one frame instead of
    // sliding from the old edge's number to the new one -- which is what left
    // a 298 px media pill inside a 56 px column.
    property bool hidden: false

    // Both are still BINDINGS until something assigns them, so the first change
    // of the session skipped the fade. Assigning here cuts them loose.
    Connections {
        target: Prefs
        function onLoadedChanged() {
            if (!Prefs.loaded) return
            root.applied = Prefs.barPosition
            root.appliedStyle = Prefs.barStyle
        }
    }

    // The style rides the same swap as the edge.
    readonly property string wantedStyle: Prefs.barStyle
    property string appliedStyle: Prefs.barStyle

    onWantedStyleChanged: if (wantedStyle !== appliedStyle) {
        hidden = true
        swapTimer.restart()
    }

    onWantedChanged: if (wanted !== applied) {
        hidden = true
        swapTimer.restart()
    }

    Timer {
        id: swapTimer
        // Just long enough for the fade-out to finish.
        interval: 240
        onTriggered: {
            root.applied = root.wanted
            root.appliedStyle = root.wantedStyle
            revealTimer.restart()
        }
    }
    Timer {
        id: revealTimer
        // Hyprland animates the layer when its geometry changes; coming back
        // during that jump reads as a pop-in.
        interval: 320
        onTriggered: root.hidden = false
    }

    readonly property string barPosition: applied
    // Where the utility pill a keybind should use lives: the bottom one, unless
    // the bar is sitting there.
    // Which edge a panel with no capsule on the bar arrives from. Named for what
    // it does now rather than for the utility pill it used to belong to.
    // From the bottom, or from the top when the bar is down there: the left edge
    // it used to take made a centred panel arrive sideways, which read as
    // something out of place rather than as the same panel moved.
    readonly property string overlayEdge: applied === "bottom" ? "top" : "bottom"
    readonly property bool barVertical: applied === "left" || applied === "right"

    // ── Auto-hide ────────────────────────────────────────────────────────
    // The bar hides at its edge and comes back under the pointer. It stops
    // reserving room, so windows get the whole screen.
    readonly property bool autohide: Prefs.barAutohide
    // Input strip left alive at the very edge while the bar is away.
    readonly property int peekPx: 6
    // How long a revealed bar waits after the pointer leaves.
    readonly property int peekHideMs: 400
    // …and the least it stays out once it is out, so a hover lost for a frame
    // while the windows reflow cannot bounce it.
    readonly property int peekStayMs: 600

    // How deep the bar is on screen: framed, that includes the same line of
    // wallpaper the border keeps, since the outer gap is zero while it is up.
    // This is what it reserves whenever it is standing there.
    readonly property int barDepth: root.barH + (root.barFramed ? root.framedGap : 0)
    // …and what its edge keeps while it is away: nothing, except in framed,
    // where the border is still drawn and windows must stay off it.
    readonly property int barZoneAway: root.barFramed ? root.frameW + root.framedGap : 0

    // Distance from the bar's edge to the first pixel a panel may use
    readonly property int panelTop: barDepth + panelGap

    // Margins for a panel pinned to a screen corner: the side the bar is on has
    // to clear it, the other three only keep the usual breathing room.
    readonly property int marginTop: applied === "top" ? panelTop : edgeGap
    readonly property int marginBottom: applied === "bottom" ? panelTop : edgeGap
    readonly property int marginLeft: applied === "left" ? panelTop : edgeGap
    readonly property int marginRight: applied === "right" ? panelTop : edgeGap
    // Corner-pinned panels hang from the bottom edge only when the bar is there
    readonly property bool pinBottom: applied === "bottom"

    // Width of the notification rail. Lives here because the toasts have to
    // know where the rail lands to take the other corner.
    readonly property int notifRailW: 400

    // Where the bar's own window starts on `s`. mapToGlobal on a layer surface
    // hands back window-local coordinates, so anything reporting a position out
    // of the bar has to add this to get to screen coordinates. Zero on the top
    // and left edges, which is why it went unnoticed for so long. Takes the
    // screen rather than reading Screens.active: with a bar per monitor, the one
    // asking is not always the focused one.
    // A right-hand bar's window is the strip plus its spill (barSpill), so its
    // left edge sits that much further in than the strip does.
    function barOriginX(s) { return (s && barPosition === "right") ? s.width - barH - barSpill : 0 }
    function barOriginY(s) { return (s && barPosition === "bottom") ? s.height - barH : 0 }

    // Where a panel that drops out of a bar pill belongs, in window coords.
    // On a horizontal bar it tracks the pill across the screen and is pinned to
    // the bar's edge; on a vertical bar the two axes swap roles.
    function panelX(winW, cardW, pillX) {
        if (!barVertical)
            return Math.max(edgeGap, Math.min(winW - cardW - edgeGap, pillX - cardW / 2))
        return applied === "left" ? panelTop : winW - cardW - panelTop
    }

    function panelY(winH, cardH, pillY) {
        if (barVertical)
            return Math.max(edgeGap, Math.min(winH - cardH - edgeGap, pillY - cardH / 2))
        return applied === "top" ? panelTop : winH - cardH - panelTop
    }

    // Transform origin for the grow-out-of-its-pill open animation: the corner
    // or point of the card that faces the bar.
    function originX(cardX, cardW, pillX) {
        if (!barVertical) return Math.max(0, Math.min(cardW, pillX - cardX))
        return applied === "left" ? 0 : cardW
    }

    function originY(cardY, cardH, pillY) {
        if (barVertical) return Math.max(0, Math.min(cardH, pillY - cardY))
        return applied === "top" ? 0 : cardH
    }
}
