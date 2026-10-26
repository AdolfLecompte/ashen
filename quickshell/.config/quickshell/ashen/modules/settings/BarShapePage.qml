import Quickshell
import QtQuick
import QtQuick.Layouts
import "root:/services" as Services
import "root:/modules/widgets" as Widgets
import "root:/modules/settings/components"

// Where the bar lives and what shape it wears.
Section {
    id: tab

    Card {
        glyph: "\ue9f7"
        title: Services.I18n.t("settings.tab.bar")

        SectionLabel { text: Services.I18n.t("settings.bar.position") }

        Segmented {
            stacked: true
            options: [
                { id: "top", icon: "\ue5d8", label: Services.I18n.t("settings.bar.top") },
                { id: "bottom", icon: "\ue5db", label: Services.I18n.t("settings.bar.bottom") },
                { id: "left", icon: "\ue5c4", label: Services.I18n.t("settings.bar.left") },
                { id: "right", icon: "\ue5c8", label: Services.I18n.t("settings.bar.right") },
            ]
            current: Services.Prefs.barPosition
            onPicked: id => Services.Prefs.barPosition = id
        }

        SectionLabel { text: Services.I18n.t("settings.bar.style"); Layout.topMargin: 4 }

        Segmented {
            options: [
                // Least to most: bare capsules, a plate per group, one plate
                // for the bar, that plate hung from the edge, then the whole edge.
                { id: "pills", icon: "\ue11f", label: Services.I18n.t("settings.bar.pills") },
                { id: "island", icon: "\ue8f3", label: Services.I18n.t("settings.bar.island") },
                { id: "solid", icon: "\ue9f7", label: Services.I18n.t("settings.bar.solid") },
                { id: "hang", icon: "\ue232", label: Services.I18n.t("settings.bar.hang") },
                { id: "docked", icon: "\uf7e6", label: Services.I18n.t("settings.bar.docked") },
            ]
            current: Services.Prefs.barStyle
            onPicked: id => Services.Prefs.barStyle = id
        }

        // Not for docked: it is the whole edge by definition.
        Widgets.SliderRow {
            visible: !Services.Sizes.barDocked
            Layout.topMargin: 4
            glyph: "\uf69b"
            label: Services.I18n.t("settings.bar.length")
            value: Services.Prefs.barLength
            valueText: shownPct + "%"
            onMoved: pct => Services.Prefs.barLength = Math.max(50, pct)
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 4
            spacing: 12
            RowGlyph { glyph: "\ue8f5" }        // visibility_off
            Text {
                textFormat: Text.PlainText
                Layout.fillWidth: true
                text: Services.I18n.t("settings.bar.autohide")
                color: Services.Colors.snow
                font.pixelSize: Services.Sizes.fsInput
                font.family: "JetBrainsMono NF"
            }
            Toggle {
                checked: Services.Prefs.barAutohide
                onToggled: Services.Prefs.barAutohide = !Services.Prefs.barAutohide
            }
        }
    }
}
