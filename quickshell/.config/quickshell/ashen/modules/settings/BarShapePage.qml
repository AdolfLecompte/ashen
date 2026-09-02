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
        title: "Bar"

        SectionLabel { text: "Position" }

        Segmented {
            stacked: true
            options: [
                { id: "top", icon: "\ue5d8", label: "Top" },
                { id: "bottom", icon: "\ue5db", label: "Bottom" },
                { id: "left", icon: "\ue5c4", label: "Left" },
                { id: "right", icon: "\ue5c8", label: "Right" },
            ]
            current: Services.Prefs.barPosition
            onPicked: id => Services.Prefs.barPosition = id
        }

        SectionLabel { text: "Style"; Layout.topMargin: 4 }

        Segmented {
            options: [
                { id: "pills", icon: "", label: "Pills" },
                { id: "solid", icon: "", label: "Solid" },
                { id: "framed", icon: "", label: "Framed" },
            ]
            current: Services.Prefs.barStyle
            onPicked: id => Services.Prefs.barStyle = id
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 4
            spacing: 12
            RowGlyph { glyph: "\ue8f5" }        // visibility_off
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text { text: "Auto-hide"; color: Services.Colors.snow; font.pixelSize: Services.Sizes.fsInput; font.family: "JetBrainsMono NF" }
            }
            Item { Layout.fillWidth: true }
            Toggle {
                checked: Services.Prefs.barAutohide
                onToggled: Services.Prefs.barAutohide = !Services.Prefs.barAutohide
            }
        }
    }
}
