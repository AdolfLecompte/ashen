pragma Singleton
import Quickshell
import QtQuick
Singleton {
    id: root
    // ── Fondos ──────────────────────────
    readonly property color abyss:   "#0e0e0e"
    readonly property color void_:   "#131313"
    readonly property color crypt:   "#1b1b1b"
    // ── Superficies ─────────────────────
    readonly property color surface:  "#1f1f1f"
    readonly property color raised:   "#2a2a2a"
    readonly property color elevated: "#353535"
    // ── Texto ───────────────────────────
    readonly property color snow:     "#e2e2e2"
    readonly property color mist:     "#c6c6c6"
    readonly property color ash:      "#919191"
    // ── Acento ──────────────────────────
    readonly property color ghost:    "#adc6ff"
    readonly property color shade:    "#bfc6dc"
    // ── Estados ─────────────────────────
    readonly property color error_:   "#ffb4ab"
    readonly property color neutral:  "#debcdf"
    // ── Helpers con alpha ───────────────
    function ghostAlpha(a) { return Qt.rgba(ghost.r, ghost.g, ghost.b, a) }
    function surfaceAlpha(a) { return Qt.rgba(surface.r, surface.g, surface.b, a) }
    function snowAlpha(a) { return Qt.rgba(snow.r, snow.g, snow.b, a) }
}
