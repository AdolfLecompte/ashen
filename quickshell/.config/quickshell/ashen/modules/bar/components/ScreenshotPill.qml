import QtQuick
import Quickshell
import "root:/services" as Services

// An area screenshot, the same one SUPER+SHIFT+S takes; right-click records.
GlyphPill {
    key: "screenshot"
    glyph: "\uf7d2"
    active: Services.AppState.recording
    onClicked: Services.AppState.screenshotArea()
    onRightClicked: Services.AppState.toggleRecording()
}
