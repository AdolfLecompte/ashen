import Quickshell
import QtQuick
import QtQuick.Layouts
import "root:/services" as Services
import "root:/modules/widgets" as Widgets
import "root:/modules/settings/components"

// Playback and capture levels, plus the device pickers behind them.
Section {
    id: tab

    Card {
        title: Services.I18n.t("settings.sound.audio")
        Widgets.SliderRow {
            glyph: Services.Audio.muted ? "" : ""
            label: Services.I18n.t("common.volume")
            value: Services.Audio.volume
            valueText: Services.Audio.muted ? Services.I18n.t("common.muted") : shownPct + "%"
            dimmed: Services.Audio.muted
            muted: Services.Audio.muted
            onGlyphClicked: Services.Audio.toggleMute()
            glyphInteractive: true
            // Unmutes on drag: nudging a muted slider and hearing nothing
            // reads as broken. The service caps at 100% and does the unmuting.
            onMoved: pct => Services.Audio.setVolume(pct)
        }

        // Output device selector (speakers / headphones / HDMI)
        Widgets.DevicePicker {
            Layout.fillWidth: true
            glyph: "\ue050"
            devices: Services.Audio.sinks
            current: Services.Audio.defaultSink
            onPicked: name => Services.Audio.setSink(name)
        }

        Widgets.SliderRow {
            glyph: Services.Audio.micMuted ? "" : ""
            label: Services.I18n.t("settings.sound.mic")
            value: Services.Audio.micVolume
            valueText: Services.Audio.micMuted ? Services.I18n.t("common.muted") : shownPct + "%"
            dimmed: Services.Audio.micMuted
            muted: Services.Audio.micMuted
            // Click the mic glyph to mute/unmute
            onGlyphClicked: Services.Audio.toggleMicMute()
            glyphInteractive: true
            onMoved: pct => {
                if (Services.Audio.micMuted) Services.Audio.toggleMicMute()
                Services.Audio.setMicVolume(pct)
            }
        }

        // Input device selector (microphones)
        Widgets.DevicePicker {
            Layout.fillWidth: true
            glyph: "\ue029"
            devices: Services.Audio.sources
            current: Services.Audio.defaultSource
            onPicked: name => Services.Audio.setSource(name)
        }

    }

    Card {
        title: Services.I18n.t("settings.sound.recording")

        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            RowGlyph { glyph: "\ue029" }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text {
                    textFormat: Text.PlainText
                    text: Services.I18n.t("settings.sound.capture")
                    color: Services.Colors.snow
                    font.pixelSize: Services.Sizes.fsInput
                    font.bold: true
                    font.family: "JetBrainsMono NF"
                }
            }
            Item { Layout.fillWidth: true }
            Toggle {
                checked: Services.Prefs.recordAudio
                onToggled: Services.Prefs.recordAudio = !Services.Prefs.recordAudio
            }
        }
        DirField {
            glyph: "\ue2c7"
            title: Services.I18n.t("settings.sound.saveTo")
            value: Services.Prefs.recordDir !== ""
                ? Services.Prefs.recordDir : Services.Paths.recordings
            placeholder: Services.Paths.recordings
            onCommitted: path => Services.Prefs.recordDir = path
        }
    }

    Item { Layout.preferredHeight: 8 }
}
