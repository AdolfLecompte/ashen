import Quickshell
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "root:/services" as Services
import "root:/modules/widgets" as Widgets
import "root:/modules/settings/components"

// What the clock chip reads, and the weather beside it.
Section {
    id: tab

    // Picked when the search stops matching, never inside the binding: a line
    // re-rolling on every keystroke reads as a list still searching.
    property string missLine: Services.Voice.pick("search.noMatch")
    Card {
        glyph: "\ue192"
        title: Services.I18n.t("settings.tab.clock")
        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            RowGlyph { glyph: "\uefd6" }        // access_time
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text { textFormat: Text.PlainText; text: Services.I18n.t("settings.clock.format"); color: Services.Colors.snow; font.pixelSize: Services.Sizes.fsInput; font.family: "JetBrainsMono NF" }
            }
            Segmented {
                options: [
                    { id: "24", label: "24H" },
                    { id: "12", label: "12H" },
                ]
                current: Services.Prefs.clock24h ? "24" : "12"
                onPicked: id => Services.Prefs.clock24h = (id === "24")
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            RowGlyph { glyph: "\ue425" }        // timer
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text { textFormat: Text.PlainText; text: Services.I18n.t("settings.clock.seconds"); color: Services.Colors.snow; font.pixelSize: Services.Sizes.fsInput; font.family: "JetBrainsMono NF" }
            }
            Item { Layout.fillWidth: true }
            Toggle {
                checked: Services.Prefs.clockSeconds
                onToggled: Services.Prefs.clockSeconds = !Services.Prefs.clockSeconds
            }
        }
    }

    Card {
        glyph: "\uf172"                         // partly_cloudy_day
        title: Services.I18n.t("settings.clock.weather")
        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            RowGlyph { glyph: "\uf076" }        // thermostat
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text { textFormat: Text.PlainText; text: Services.I18n.t("settings.clock.temperature"); color: Services.Colors.snow; font.pixelSize: Services.Sizes.fsInput; font.family: "JetBrainsMono NF" }
            }
            Segmented {
                options: [
                    { id: "C", label: "°C" },
                    { id: "F", label: "°F" },
                    { id: "K", label: "K" },
                ]
                current: Services.Prefs.tempUnit
                onPicked: id => Services.Prefs.tempUnit = id
            }
        }

        SectionLabel { text: Services.I18n.t("settings.clock.location"); Layout.topMargin: 4 }

        // Saved cities: a list, since it grows. The row picks, the cross drops.
        // With none saved the forecast follows the IP, and the list says so.
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: cityCol.implicitHeight + 12
            radius: Services.Sizes.cardR
            color: Services.Colors.fillInset

            Column {
                id: cityCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 6
                spacing: 2

                PickRow {
                    visible: Services.Weather.savedLocs.length === 0
                    glyph: "\ue55c"             // my_location
                    label: Services.I18n.t("settings.clock.autoIp")
                    active: true
                }
                Repeater {
                    model: Services.Weather.savedLocs
                    delegate: PickRow {
                        required property var modelData
                        required property int index
                        glyph: "\uf1db"         // place
                        label: modelData.city
                        active: Services.Weather.activeLocIndex === index
                        removable: true
                        onPicked: Services.Weather.selectLoc(index)
                        onRemoved: Services.Weather.removeLoc(index)
                    }
                }
            }
        }

        // The search, in the Settings search box's dress; what it finds
        // unfolds inside the same box. Enter takes the first one.
        FindBox {
            id: finder
            placeholder: Services.I18n.t("settings.clock.searchCity")
            open: finder.text.trim().length >= 2
                  && (Services.Weather.searchResults.length > 0 || Services.Weather.cityError)
            busy: Services.Weather.searching && finder.text.trim().length >= 2
            onTextChanged: cityDebounce.restart()
            onCleared: Services.Weather.search("")
            onAccepted: {
                const r = Services.Weather.searchResults
                if (finder.open && r.length > 0) tab.choose(r[0])
            }

            PickRow {
                visible: Services.Weather.cityError && !Services.Weather.searching
                glyph: "\uea76"                 // search_off
                label: tab.missLine
                quiet: true
            }
            Repeater {
                model: Services.Weather.searchResults
                delegate: PickRow {
                    required property var modelData
                    glyph: "\uf1db"             // place
                    label: modelData.label
                    detail: modelData.detail
                    onPicked: tab.choose(modelData)
                }
            }
        }

        // Debounce keystrokes so the geocoder isn't hit on every letter.
        Timer {
            id: cityDebounce
            interval: 350
            onTriggered: Services.Weather.search(finder.text)
        }
    }

    function choose(r) {
        Services.Weather.chooseResult(r.lat, r.lon, r.label)
        finder.clear()
    }
}
