import Quickshell
import QtQuick
import QtQuick.Layouts
import "root:/services" as Services
import "root:/modules/widgets" as Widgets
import "root:/modules/settings/components"

// The music card: the sound it draws and the words it shows.
Section {
    id: tab
    // ── Media ───────────────────────────────────────────────────────────
    // The sound and the words: both belong to the card that plays them, not to
    // the bar the card hangs off.
    Card {
        title: Services.I18n.t("settings.tab.media")

        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            RowGlyph { glyph: "\ue1b8" }        // graphic_eq
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text { textFormat: Text.PlainText; text: Services.I18n.t("settings.media.visualizer"); color: Services.Colors.snow; font.pixelSize: Services.Sizes.fsInput; font.family: "JetBrainsMono NF" }
            }
            Item { Layout.fillWidth: true }
            Toggle {
                checked: Services.Prefs.visualizer
                onToggled: Services.Prefs.visualizer = !Services.Prefs.visualizer
            }
        }

        // The sung line on the media card. The chip on the card closes it too;
        // this is where you find it again after forgetting you did.
        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            RowGlyph { glyph: "\uec0b" }       // lyrics
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text { textFormat: Text.PlainText; text: Services.I18n.t("settings.media.lyrics"); color: Services.Colors.snow; font.pixelSize: Services.Sizes.fsInput; font.family: "JetBrainsMono NF" }            }
            Item { Layout.fillWidth: true }
            Toggle {
                checked: Services.Prefs.mediaLyrics
                onToggled: Services.Prefs.mediaLyrics = !Services.Prefs.mediaLyrics
            }
        }

    }
}
