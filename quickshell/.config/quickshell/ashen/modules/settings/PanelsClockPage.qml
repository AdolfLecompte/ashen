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
    // City add-picker (weather): open state for the search box
    property bool cityPickerOpen: false
    Card {
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

        SectionLabel { text: Services.I18n.t("settings.clock.weather"); Layout.topMargin: 4 }
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

        RowLayout {
            Layout.fillWidth: true
            SectionLabel { text: Services.I18n.t("settings.clock.location"); Layout.fillWidth: true }
            SectionLabel {
                text: Services.Weather.cityError
                    ? tab.missLine
                    : (Services.Weather.city !== "" ? Services.Weather.city : Services.I18n.t("settings.clock.autoIp"))
                color: Services.Weather.cityError ? Services.Colors.error_ : Services.Colors.ash
            }
        }

        // Saved cities as cards (mirrors the keyboard-layout picker below):
        // click to switch the active one, X to drop it, + to add another.
        Flow {
            Layout.fillWidth: true
            spacing: 10

            Repeater {
                model: Services.Weather.savedLocs
                delegate: Rectangle {
                    id: cityCard
                    required property var modelData
                    required property int index
                    readonly property bool active: Services.Weather.activeLocIndex === cityCard.index
                    property bool hovered: false
                    implicitWidth: Math.min(cityName.implicitWidth + 44, 220)
                    height: 40
                    radius: Services.Sizes.pillR
                    color: cityCard.active ? Services.Colors.ghost : Services.Colors.fillLine
                    gradient: Services.Prefs.useGradients && (cityCard.active) ? Services.Colors.accentGradient : null
                    Behavior on color { Widgets.ColorAnim { speed: Services.Sizes.msMicro } }
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 8
                        spacing: 6
                        Text {
                            textFormat: Text.PlainText
                            text: "\uf1db"                 // location_on
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 15
                            color: cityCard.active ? Services.Colors.accentText : Services.Colors.ghost
                        }
                        Text {
                            textFormat: Text.PlainText
                            id: cityName
                            text: cityCard.modelData.city
                            color: cityCard.active ? Services.Colors.accentText : Services.Colors.snow
                            font.pixelSize: Services.Sizes.fsBody
                            font.family: "JetBrainsMono NF"
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        anchors.rightMargin: 20      // leave the X hit-area free
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Services.Weather.selectLoc(cityCard.index)
                    }
                    Rectangle {
                        visible: cityCard.hovered || rmCityArea.containsMouse
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 4
                        width: 18; height: 18; radius: Services.Sizes.innerR
                        color: Services.Colors.fillSunken
                        Text {
                            textFormat: Text.PlainText
                            anchors.centerIn: parent
                            scale: Services.Sizes.hoverScale(rmCityArea.containsMouse, rmCityArea.pressed)
                            Behavior on scale { NumberAnimation { duration: Services.Sizes.pillHoverMs; easing.type: Services.Sizes.easeOut } }
                            text: "\ue5cd"           // close
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 11
                            color: rmCityArea.containsMouse ? Services.Colors.snow : Services.Colors.ash
                            Behavior on color { Widgets.ColorAnim { speed: Services.Sizes.msMicro } }
                        }
                        MouseArea {
                            id: rmCityArea
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: Services.Weather.removeLoc(cityCard.index)
                        }
                    }
                    HoverHandler { onHoveredChanged: cityCard.hovered = hovered }
                }
            }

            // Add-city card: toggles the search box.
            Rectangle {
                height: 40
                implicitWidth: 92
                radius: Services.Sizes.pillR
                color: Services.Colors.fillInset
                border.color: Services.Colors.fillLine
                border.width: 1
                RowLayout {
                    anchors.centerIn: parent
                    spacing: 4
                    scale: Services.Sizes.hoverScale(addCityArea.containsMouse, addCityArea.pressed)
                    Behavior on scale { NumberAnimation { duration: Services.Sizes.pillHoverMs; easing.type: Services.Sizes.easeOut } }
                    Text {
                        textFormat: Text.PlainText
                        text: "\ue145"                    // add
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 18
                        color: Services.Colors.ghost
                    }
                    Text {
                        textFormat: Text.PlainText
                        text: Services.I18n.t("common.add")
                        font.pixelSize: Services.Sizes.fsMeta
                        font.family: "JetBrainsMono NF"
                        color: addCityArea.containsMouse ? Services.Colors.snow : Services.Colors.mist
                        Behavior on color { Widgets.ColorAnim { speed: Services.Sizes.msMicro } }
                    }
                }
                MouseArea {
                    id: addCityArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: {
                        tab.cityPickerOpen = !tab.cityPickerOpen
                        if (tab.cityPickerOpen) cityInput.forceActiveFocus()
                        else { cityInput.text = ""; Services.Weather.search("") }
                    }
                }
            }
        }

        // City search box + candidate dropdown (only while adding).
        Rectangle {
            Layout.fillWidth: true
            clip: true
            radius: Services.Sizes.cardR
            color: Services.Colors.fillInset
            implicitHeight: cityPickerCol.implicitHeight + 20
            // Slide open/closed instead of snapping.
            Layout.preferredHeight: tab.cityPickerOpen ? implicitHeight : 0
            Behavior on Layout.preferredHeight { Widgets.Anim {} }
            opacity: tab.cityPickerOpen ? 1.0 : 0.0
            Behavior on opacity { Widgets.Anim { speed: Services.Sizes.msMicro } }

            ColumnLayout {
                id: cityPickerCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 10
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    height: 34
                    radius: Services.Sizes.innerR
                    color: Services.Colors.fillLine
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8
                        Text {
                            textFormat: Text.PlainText
                            text: "\ue8e2"               // search
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 15
                            color: Services.Colors.ghost
                        }
                        TextField {
                            id: cityInput
                            Layout.fillWidth: true
                            placeholderText: Services.I18n.t("settings.clock.searchCity")
                            color: Services.Colors.snow
                            placeholderTextColor: Services.Colors.ash
                            font.pixelSize: Services.Sizes.fsBody
                            font.family: "JetBrainsMono NF"
                            background: null
                            padding: 0
                            onTextChanged: cityDebounce.restart()
                            Keys.onEscapePressed: { tab.cityPickerOpen = false; text = "" }
                            onAccepted: {
                                let r = Services.Weather.searchResults
                                if (r.length > 0) {
                                    Services.Weather.chooseResult(r[0].lat, r[0].lon, r[0].label)
                                    text = ""
                                    tab.cityPickerOpen = false
                                }
                            }
                        }
                    }
                }

                // Candidate dropdown (name + region/country); one tap to add.
                Repeater {
                    model: Services.Weather.searchResults
                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: 38
                        radius: Services.Sizes.innerR
                        color: Services.Colors.fillInset

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10
                            Text {
                                textFormat: Text.PlainText
                                text: "\uf1db"            // location_on
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 14
                                color: Services.Colors.ghost
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                Text {
                                    textFormat: Text.PlainText
                                    text: modelData.label
                                    color: sugArea.containsMouse ? Services.Colors.snow : Services.Colors.mist
                                    Behavior on color { Widgets.ColorAnim { speed: Services.Sizes.msMicro } }
                                    font.pixelSize: Services.Sizes.fsBody
                                    font.family: "JetBrainsMono NF"
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                                Text {
                                    textFormat: Text.PlainText
                                    text: modelData.detail
                                    visible: text !== ""
                                    color: Services.Colors.ash
                                    font.pixelSize: Services.Sizes.fsCaption
                                    font.family: "JetBrainsMono NF"
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }
                        }
                        MouseArea {
                            id: sugArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Services.Weather.chooseResult(modelData.lat, modelData.lon, modelData.label)
                                cityInput.text = ""
                                tab.cityPickerOpen = false
                            }
                        }
                    }
                }
            }
        }

        // Debounce keystrokes so the geocoder isn't hit on every letter.
        Timer {
            id: cityDebounce
            interval: 350
            onTriggered: Services.Weather.search(cityInput.text)
        }

    }
}
