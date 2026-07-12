pragma Singleton
import Quickshell
import QtQuick
Singleton {
    id: root
    readonly property color abyss:   "#080809"
    readonly property color void_:   "#0f0f11"
    readonly property color crypt:   "#16161a"
    readonly property color surface:  "#1c1c21"
    readonly property color raised:   "#242428"
    readonly property color elevated: "#2e2e34"
    readonly property color snow:     "#e8e8ec"
    readonly property color mist:     "#9090a0"
    readonly property color ash:      "#4a4a54"
    readonly property color ghost:    "#6e6e7a"
    readonly property color shade:    "#4e4e5a"
    readonly property color error_:   "#c87a7a"
    readonly property color neutral:  "#8a8a96"
    function ghostAlpha(a) { return Qt.rgba(ghost.r, ghost.g, ghost.b, a) }
    function surfaceAlpha(a) { return Qt.rgba(surface.r, surface.g, surface.b, a) }
    function snowAlpha(a) { return Qt.rgba(snow.r, snow.g, snow.b, a) }
}
