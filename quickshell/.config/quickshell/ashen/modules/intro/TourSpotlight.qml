import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Shapes
import "root:/services" as Services
import "root:/modules/widgets" as Widgets

// The dimming behind the tour: the screen goes a little darker everywhere
// except where the step is pointing. It never takes a click -- the panel it
// lights is real, and still works.
PanelWindow {
    id: win
    anchors { top: true; left: true; right: true; bottom: true }
    screen: Services.Screens.active
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    // Its own namespace: the shell's default ("quickshell") has a blur rule,
    // and a blurred dim turns every window behind it to mush.
    WlrLayershell.namespace: "ashen:dim"
    // An empty input region: every click goes through to what is underneath.
    mask: Region { width: 0; height: 0 }

    readonly property rect want: Services.Tour.target
    readonly property bool lit: Services.Tour.active && win.want.width > 0
    visible: lit || fade.running || dim > 0.01

    // The lit box FOLLOWS the target, so moving between steps is the hole
    // gliding, not two holes swapping. It is only updated while there is a
    // target: the last box stays put while the dim fades out.
    property real hx: 0
    property real hy: 0
    property real hw: 0
    property real hh: 0
    onWantChanged: if (win.want.width > 0) {
        // The first box of a run appears in place; later ones glide to theirs.
        win.gliding = win.dim > 0.05
        win.hx = win.want.x - pad; win.hy = win.want.y - pad
        win.hw = win.want.width + pad * 2; win.hh = win.want.height + pad * 2
        win.gliding = true
    }
    readonly property real pad: 6
    property bool gliding: true

    Behavior on hx { enabled: win.gliding; Widgets.Anim { speed: Services.Sizes.msPanel } }
    Behavior on hy { enabled: win.gliding; Widgets.Anim { speed: Services.Sizes.msPanel } }
    Behavior on hw { enabled: win.gliding; Widgets.Anim { speed: Services.Sizes.msPanel } }
    Behavior on hh { enabled: win.gliding; Widgets.Anim { speed: Services.Sizes.msPanel } }

    property real dim: win.lit ? 1 : 0
    Behavior on dim { Widgets.Anim { id: fade; speed: Services.Sizes.msPanel } }

    // One path, two rectangles, odd-even fill: what lies between them is the
    // dim, the inner one is the hole.
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        opacity: win.dim

        ShapePath {
            fillColor: Qt.rgba(Services.Colors.scrimBase.r, Services.Colors.scrimBase.g,
                               Services.Colors.scrimBase.b, 0.45)
            strokeColor: "transparent"
            fillRule: ShapePath.OddEvenFill
            PathRectangle { x: 0; y: 0; width: win.width; height: win.height }
            PathRectangle {
                x: win.hx; y: win.hy; width: win.hw; height: win.hh
                radius: Math.min(Services.Sizes.panelR + win.pad, win.hw / 2, win.hh / 2)
            }
        }
        // A thin line round the lit box, so it reads as chosen and not as a gap.
        ShapePath {
            fillColor: "transparent"
            strokeColor: Qt.rgba(Services.Colors.ghost.r, Services.Colors.ghost.g, Services.Colors.ghost.b, 0.7)
            strokeWidth: 2
            PathRectangle {
                x: win.hx; y: win.hy; width: win.hw; height: win.hh
                radius: Math.min(Services.Sizes.panelR + win.pad, win.hw / 2, win.hh / 2)
            }
        }
    }
}
