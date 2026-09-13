import Quickshell
import QtQuick
import QtQuick.Layouts
import "root:/services" as Services
import "root:/modules/widgets" as Widgets
import "root:/modules/settings/components"

// What the shell is allowed to interrupt you with, and how long it may stay.
Section {
    id: tab
    Card {
        title: Services.I18n.t("settings.notify.dnd")

        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            RowGlyph { glyph: "" }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text {
                    text: Services.I18n.t("settings.notify.silence")
                    color: Services.Colors.snow
                    font.pixelSize: Services.Sizes.fsInput
                    font.bold: true
                    font.family: "JetBrainsMono NF"
                }
            }
            Item { Layout.fillWidth: true }
            Toggle {
                checked: Services.AppState.doNotDisturb
                onToggled: Services.AppState.doNotDisturb = !Services.AppState.doNotDisturb
            }
        }
    }

    Card {
        title: Services.I18n.t("settings.notify.toasts")

        SectionLabel { text: Services.I18n.t("settings.notify.duration") }
        Segmented {
            options: [
                { id: "3", label: "3s" },
                { id: "6", label: "6s" },
                { id: "10", label: "10s" },
                { id: "20", label: "20s" }
            ]
            current: String(Services.Prefs.toastSeconds)
            onPicked: id => Services.Prefs.toastSeconds = parseInt(id)
        }
        SectionLabel { text: Services.I18n.t("settings.notify.stack") }
        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            Segmented {
                options: [
                    { id: "3", label: "3" },
                    { id: "5", label: "5" },
                    { id: "8", label: "8" }
                ]
                current: String(Services.Prefs.maxToasts)
                onPicked: id => Services.Prefs.maxToasts = parseInt(id)
            }
        }
    }

    // Lives here, not in Sound: every preference behind it belongs to
    // Notifications (`notifySound`, `notifySoundFile`, `soundVolume`), and the
    // Sound tab is about what the machine plays, not about what interrupts you.
    Card {
        title: Services.I18n.t("settings.notify.sound")

        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            RowGlyph { glyph: "" }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text {
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
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text {
                        text: Services.I18n.t("settings.notify.critical")
                        color: Services.Colors.snow
                        font.pixelSize: Services.Sizes.fsInput
                        font.bold: true
                        font.family: "JetBrainsMono NF"
                    }
                }
                Item { Layout.fillWidth: true }
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

    Item { Layout.preferredHeight: 8 }
}
