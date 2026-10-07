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
                    textFormat: Text.PlainText
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
        SectionLabel { text: Services.I18n.t("settings.notify.width") }
        Segmented {
            options: [
                { id: "300", label: "300" },
                { id: "360", label: "360" },
                { id: "440", label: "440" }
            ]
            current: String(Services.Prefs.toastWidth)
            onPicked: id => Services.Prefs.toastWidth = parseInt(id)
        }
    }

    Card {
        title: Services.I18n.t("settings.notify.osd")

        SectionLabel { text: Services.I18n.t("settings.notify.duration") }
        Segmented {
            options: [
                { id: "1000", label: "1s" },
                { id: "1400", label: "1.4s" },
                { id: "3000", label: "3s" }
            ]
            current: String(Services.Prefs.osdMs)
            onPicked: id => Services.Prefs.osdMs = parseInt(id)
        }
    }

    Item { Layout.preferredHeight: 8 }
}
