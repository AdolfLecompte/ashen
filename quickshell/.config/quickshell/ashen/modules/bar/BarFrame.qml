import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Shapes

import "root:/modules/bar/components"
import "root:/services" as Services

// The framed style's border. Drawn as ONE ring with a rounded hole: four bands
// could only meet square. The room is claimed separately by thin invisible
// windows, because a window only reserves the edge it is anchored to.
Scope {
    id: root

    readonly property bool on: Services.Sizes.barFramed

    // The edges that have to be reserved. Not the bar's: it is standing there
    // already and reserves that edge in both of its states.
    readonly property var edges: ["top", "bottom", "left", "right"]
        .filter(e => e !== Services.Sizes.barPosition)

    Variants {
        // Same list the bar uses, for the same reason: a mirrored output is not
        // a screen you can put anything on.
        model: root.on ? Services.Screens.barScreens : []

        Scope {
            id: perScreen
            property var modelData

            // ── The room ────────────────────────────────────────────────
            // Variants, not a Repeater: a Repeater is an Item and inside a Scope
            // it builds nothing, silently.
            Variants {
                model: root.edges

                PanelWindow {
                    id: side
                    property var modelData
                    readonly property string edge: modelData
                    readonly property bool vertical: side.edge === "left" || side.edge === "right"
                    // The border, plus the line that keeps windows off it.
                    readonly property int reserve: Services.Sizes.frameW + Services.Sizes.framedGap

                    screen: perScreen.modelData
                    // Nothing is drawn here; this window is only its zone.
                    color: "transparent"
                    WlrLayershell.layer: WlrLayer.Bottom

                    anchors {
                        top: side.edge !== "bottom"
                        bottom: side.edge !== "top"
                        left: side.edge !== "right"
                        right: side.edge !== "left"
                    }
                    implicitWidth: side.vertical ? side.reserve : 0
                    implicitHeight: side.vertical ? 0 : side.reserve

                    exclusionMode: ExclusionMode.Normal
                    exclusiveZone: side.reserve

                    // Click-through, or the border is a dead strip.
                    mask: Region {}
                }
            }

            // ── The ring ────────────────────────────────────────────────
            PanelWindow {
                id: ring
                screen: perScreen.modelData
                color: "transparent"
                // Below the windows, above the wallpaper. Nothing covers it: the
                // room it draws in is already reserved above.
                WlrLayershell.layer: WlrLayer.Bottom
                // Covers the screen to draw its corners, so it claims none of it.
                exclusionMode: ExclusionMode.Ignore
                anchors { top: true; bottom: true; left: true; right: true }
                mask: Region {}

                // What the bar's own side gives up: all of the bar when it is
                // standing there, the plain border when it has hidden. Animated,
                // so the band closes at the same pace the bar slides out.
                readonly property real barSide:
                    (!Services.Sizes.autohide
                     || Services.AppState.barRevealedOn(perScreen.modelData ? perScreen.modelData.name : ""))
                    ? Services.Sizes.barH : Services.Sizes.frameW
                property real barSideNow: ring.barSide
                Behavior on barSideNow {
                    NumberAnimation { duration: Services.Sizes.msEmphasis; easing.type: Services.Sizes.easeOut }
                }

                // The bar's depth on its own side, the border's elsewhere.
                function inset(edge) {
                    return edge === Services.Sizes.barPosition ? ring.barSideNow
                                                               : Services.Sizes.frameW
                }

                // The wave lives HERE in this style, not on the bar: the ring
                // is what draws the bar's plate, and a wave in the bar's own
                // window is a layer above it, so it came out in front. Under
                // the Shape it is hidden for the bar's whole depth, so it is
                // given `cavaSpill` more to climb with and only the tips that
                // clear the frame's inner edge show.
                Item {
                    id: wave
                    z: -1
                    readonly property bool vertical: Services.Sizes.barVertical
                    readonly property int depth: Services.Sizes.barH + Services.Sizes.cavaSpill

                    width: wave.vertical ? wave.depth : ring.width
                    height: wave.vertical ? ring.height : wave.depth
                    x: (wave.vertical && Services.Sizes.barPosition === "right")
                       ? ring.width - wave.depth : 0
                    y: (!wave.vertical && Services.Sizes.barPosition === "bottom")
                       ? ring.height - wave.depth : 0

                    opacity: Services.Sizes.hidden ? 0 : 1
                    Behavior on opacity {
                        NumberAnimation { duration: 240; easing.type: Services.Sizes.easeInOut }
                    }

                    CavaBackground {}
                }

                Shape {
                    anchors.fill: parent
                    preferredRendererType: Shape.CurveRenderer

                    // Fades with the bar. A PanelWindow has no opacity of its
                    // own, so the fade lives on what it draws.
                    opacity: Services.Sizes.hidden ? 0 : 1
                    Behavior on opacity {
                        NumberAnimation { duration: 240; easing.type: Services.Sizes.easeInOut }
                    }

                    // Two rectangles, odd-even: the screen minus a rounded hole.
                    ShapePath {
                        fillColor: Services.Colors.surfaceBar
                        strokeWidth: 0
                        fillRule: ShapePath.OddEvenFill

                        PathRectangle {
                            width: ring.width
                            height: ring.height
                        }
                        // The hole. The bar's side gives up the bar's depth, so
                        // the two read as one piece.
                        PathRectangle {
                            x: ring.inset("left")
                            y: ring.inset("top")
                            width: Math.max(0, ring.width - ring.inset("left") - ring.inset("right"))
                            height: Math.max(0, ring.height - ring.inset("top") - ring.inset("bottom"))
                            radius: Services.Sizes.frameR
                        }
                    }
                }
            }
        }
    }

    // The compositor's outer gap, handed over and handed back. Never persisted:
    // general.lua is matugen's to rewrite, so this is re-applied at startup.
    onOnChanged: gaps.run()
    Component.onCompleted: gaps.run()

    Process {
        id: gaps
        function run() {
            gaps.command = [Services.Paths.script("ashen-gaps.sh"),
                            String(root.on ? 0 : Services.Sizes.shippedGap)]
            gaps.running = true
        }
    }
}
