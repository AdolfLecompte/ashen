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

    // What a notification sounds like. With the rest of what the machine
    // plays, not with the toasts: you come looking for a sound under Sound.
    Card {
        title: Services.I18n.t("settings.tab.notifications")

        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            RowGlyph { glyph: "" }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text {
                    textFormat: Text.PlainText
                    text: Services.I18n.t("settings.notify.play")
                    color: Services.Colors.snow
                    font.pixelSize: Services.Sizes.fsInput
                    font.bold: true
                    font.family: "JetBrainsMono NF"
                }
            }
            Item { Layout.fillWidth: true }
            Toggle {
                checked: Services.Prefs.notifySound
                onToggled: Services.Prefs.notifySound = !Services.Prefs.notifySound
            }
        }

        Collapse {
            open: Services.Prefs.notifySound
            gap: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                RowGlyph { glyph: "\uf654" }
                Text {
                    textFormat: Text.PlainText
                    Layout.fillWidth: true
                    text: Services.I18n.t("settings.notify.critical")
                    color: Services.Colors.snow
                    font.pixelSize: Services.Sizes.fsInput
                    font.bold: true
                    font.family: "JetBrainsMono NF"
                }
                Toggle {
                    checked: Services.Prefs.notifySoundCriticalOnly
                    onToggled: Services.Prefs.notifySoundCriticalOnly = !Services.Prefs.notifySoundCriticalOnly
                }
            }

            // The slider speaks in whole percent, the preference in 0..1.
            Widgets.SliderRow {
                glyph: ""
                label: Services.I18n.t("common.volume")
                value: Math.round(Services.Prefs.soundVolume * 100)
                onMoved: pct => Services.Prefs.soundVolume = pct / 100
            }

            SectionLabel { text: Services.I18n.t("settings.notify.sound") }

            // A list, not a grid of chips: anything dropped in the shell's sound
            // folder turns up here, so the set grows on its own. Picking one
            // plays it -- choosing a sound you cannot hear is choosing blind.
            // The shell's own are marked: they travel with the rice.
            Widgets.DevicePicker {
                Layout.fillWidth: true
                overlay: true
                rowH: 34
                glyph: "\ue050"
                devices: Services.Notifications.soundChoices.map(c => ({
                    name: c.path, desc: (c.mine ? "\u2726 " : "") + c.name }))
                current: Services.Notifications.soundFile
                onPicked: name => {
                    Services.Prefs.notifySoundFile = name
                    Services.Notifications.play(name)
                }
            }
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
