import QtQuick
import "root:/services" as Services

// The clipboard history, one click away.
GlyphPill {
    key: "clipboard"
    glyph: "\ue14f"
    active: Services.AppState.clipboardVisible
    onClicked: Services.AppState.togglePanel("clipboardVisible")
}
