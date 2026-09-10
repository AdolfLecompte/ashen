import Quickshell
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "root:/services" as Services
import "root:/modules/widgets" as Widgets
import "root:/modules/settings/components"

// Where the bar lives and what shape it wears.
Section {
    id: tab

    Card {
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
                { id: "pills", icon: "", label: Services.I18n.t("settings.bar.pills") },
                { id: "solid", icon: "", label: Services.I18n.t("settings.bar.solid") },
                { id: "framed", icon: "", label: Services.I18n.t("settings.bar.framed") },
                { id: "island", icon: "\ue8f3", label: Services.I18n.t("settings.bar.island") },
            ]
            current: Services.Prefs.barStyle
            onPicked: id => Services.Prefs.barStyle = id
        }

        // One switch for every capsule on the bar. It lived on each of the
        // fifteen cards in Layout, which meant fifteen ways to end up with a
        // bar that is half glass and half plate.
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 4
            spacing: 12
            RowGlyph { glyph: "\ue3c6" }        // border_outer
            Text {
                Layout.fillWidth: true
                text: Services.I18n.t("settings.layout.outline")
                color: Services.Colors.snow
                font.pixelSize: Services.Sizes.fsInput
                font.family: "JetBrainsMono NF"
            }
            Toggle {
                checked: Services.Prefs.barOutline
                onToggled: Services.Prefs.barOutline = !Services.Prefs.barOutline
            }
        }

        // Not for the framed style: there the bar IS the screen's border, and a
        // border that stops short of the corners is not one.
        Widgets.SliderRow {
            visible: !Services.Sizes.barFramed
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
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text { text: Services.I18n.t("settings.bar.autohide"); color: Services.Colors.snow; font.pixelSize: Services.Sizes.fsInput; font.family: "JetBrainsMono NF" }
            }
            Item { Layout.fillWidth: true }
            Toggle {
                checked: Services.Prefs.barAutohide
                onToggled: Services.Prefs.barAutohide = !Services.Prefs.barAutohide
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 4
            spacing: 12
            RowGlyph { glyph: "\ue53b" }        // apps
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text { text: Services.I18n.t("settings.bar.wsicons"); color: Services.Colors.snow; font.pixelSize: Services.Sizes.fsInput; font.family: "JetBrainsMono NF" }
            }
        }

        // Three answers, not a switch: a chip shows the app's icon, its number,
        // or nothing at all -- a dot, with the one you are on drawn as a bar.
        Segmented {
            options: [
                { id: "icons",   icon: "\ue53b", label: Services.I18n.t("settings.bar.wsIcons") },
                { id: "numbers", icon: "\ue3ec", label: Services.I18n.t("settings.bar.wsNumbers") },
                { id: "dots",    icon: "\ue061", label: Services.I18n.t("settings.bar.wsDots") }
            ]
            current: Services.Prefs.workspaceStyle
            onPicked: id => Services.Prefs.workspaceStyle = id
        }
    }
}
