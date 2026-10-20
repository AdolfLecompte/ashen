import QtQuick
import "root:/services" as Services

// The microphone: click mutes, the wheel sets its level, right-click opens Sound.
GlyphPill {
    key: "mic"
    glyph: Services.Audio.micMuted ? "\ue02b" : "\ue029"
    active: !Services.Audio.micMuted
    onClicked: Services.Audio.toggleMicMute()
    onRightClicked: Services.AppState.togglePanel("volumeVisible")
    onWheeled: delta => Services.Audio.setMicVolume(Services.Audio.micVolume + (delta > 0 ? 5 : -5))
}
