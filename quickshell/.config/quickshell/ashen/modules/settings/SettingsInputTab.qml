import Quickshell
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "root:/services" as Services
import "root:/modules/settings/components"
import "root:/modules/widgets" as Widgets

// Keyboard layouts today; mouse and touchpad belong here when they land.
Section {
    id: tab

    property string missLine: Services.Voice.pick("search.noMatch")

    // Layout picker state
    property bool pickerOpen: false
    property string layoutQuery: ""
    // Match on code or name, so both "de" and "german" find German
    readonly property var filteredLayouts: {
        let q = tab.layoutQuery.trim().toLowerCase()
        let all = Services.Keyboard.available
        if (q === "") return all
        return all.filter(l => l.code.indexOf(q) !== -1
            || l.name.toLowerCase().indexOf(q) !== -1)
    }


    Card {
        title: Services.I18n.t("settings.tab.keyboard")
        RowLayout {
            Layout.fillWidth: true
            SectionLabel { text: Services.I18n.t("settings.input.layout"); Layout.fillWidth: true }
            SectionLabel {
                // XKB caps at 4 groups; past that they cannot be selected
                text: Services.Keyboard.layouts.length + " / " + Services.Keyboard.maxLayouts
                color: Services.Keyboard.canAdd ? Services.Colors.ash : Services.Colors.ghost
            }
        }

        Flow {
            Layout.fillWidth: true
            spacing: 10

            Repeater {
                model: Services.Keyboard.layouts
                delegate: Rectangle {
                    id: kbCard
                    required property var modelData
                    required property int index
                    readonly property bool active: Services.Keyboard.activeIndex === kbCard.index
                    width: 100; height: 64
                    radius: Services.Sizes.cardR
                    color: kbCard.active ? Services.Colors.ghost : Services.Colors.fillLine
                    gradient: Services.Prefs.useGradients && (kbCard.active) ? Services.Colors.accentGradient : null
                    Behavior on color { Widgets.ColorAnim { speed: Services.Sizes.msMicro } }
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        Text {
                            text: "\ue312"
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 20
                            color: kbCard.active ? Services.Colors.accentText : Services.Colors.mist
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Text {
                            text: kbCard.modelData.toUpperCase()
                            font.pixelSize: Services.Sizes.fsMeta
                            font.family: "JetBrainsMono NF"
                            color: kbCard.active ? Services.Colors.accentText : Services.Colors.mist
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: Services.Keyboard.setLayout(kbCard.index)
                    }
                    // Removing the last layout would leave a keyboard that
                    // types nothing, so the X only exists while there are 2+
                    Rectangle {
                        visible: Services.Keyboard.layouts.length > 1 && (kbCard.hovered || rmArea.containsMouse)
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 4
                        width: 18; height: 18
                        radius: Services.Sizes.innerR
                        color: Services.Colors.fillSunken
                        Text {
                            anchors.centerIn: parent
                            scale: Services.Sizes.hoverScale(rmArea.containsMouse, rmArea.pressed)
                            Behavior on scale { NumberAnimation { duration: Services.Sizes.pillHoverMs; easing.type: Services.Sizes.easeOut } }
                            text: "\ue5cd"
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 11
                            color: rmArea.containsMouse ? Services.Colors.snow : Services.Colors.ash
                            Behavior on color { Widgets.ColorAnim { speed: Services.Sizes.msMicro } }
                        }
                        MouseArea {
                            id: rmArea
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: Services.Keyboard.removeLayout(kbCard.modelData)
                        }
                    }
                    property bool hovered: false
                    HoverHandler { onHoveredChanged: kbCard.hovered = hovered }
                }
            }

            Rectangle {
                id: addCard
                width: 100; height: 64
                radius: Services.Sizes.cardR
                color: Services.Colors.fillInset
                border.color: Services.Colors.fillLine
                border.width: 1
                opacity: Services.Keyboard.canAdd ? 1.0 : 0.4
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 4
                    scale: Services.Keyboard.canAdd
                        ? Services.Sizes.hoverScale(addArea.containsMouse, addArea.pressed) : 1.0
                    Behavior on scale { NumberAnimation { duration: Services.Sizes.pillHoverMs; easing.type: Services.Sizes.easeOut } }
                    Text {
                        text: "\ue145"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 20
                        color: Services.Colors.ghost
                        Layout.alignment: Qt.AlignHCenter
                    }
                    Text {
                        text: Services.I18n.t("common.add")
                        font.pixelSize: Services.Sizes.fsMeta
                        font.family: "JetBrainsMono NF"
                        color: (addArea.containsMouse && Services.Keyboard.canAdd)
                            ? Services.Colors.snow : Services.Colors.mist
                        Behavior on color { Widgets.ColorAnim { speed: Services.Sizes.msMicro } }
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
                MouseArea {
                    id: addArea
                    anchors.fill: parent
                    cursorShape: Services.Keyboard.canAdd ? Qt.PointingHandCursor : Qt.ForbiddenCursor
                    hoverEnabled: true
                    enabled: Services.Keyboard.canAdd
                    onClicked: {
                        tab.pickerOpen = !tab.pickerOpen
                        if (tab.pickerOpen) {
                            tab.layoutQuery = ""
                            searchField.forceActiveFocus()
                        }
                    }
                }
            }
        }

        Text {
            visible: !Services.Keyboard.canAdd
            text: Services.I18n.t("settings.input.max")
            color: Services.Colors.ash
            font.pixelSize: Services.Sizes.fsMeta
            font.family: "JetBrainsMono NF"
        }

        // ── Layout picker: 99 layouts, so it filters instead of listing ──
        Rectangle {
            Layout.fillWidth: true
            clip: true
            radius: Services.Sizes.cardR
            color: Services.Colors.fillInset
            implicitHeight: pickerCol.implicitHeight + 20
            // Slide open/closed instead of snapping.
            Layout.preferredHeight: tab.pickerOpen ? implicitHeight : 0
            Behavior on Layout.preferredHeight { Widgets.Anim {} }
            opacity: tab.pickerOpen ? 1.0 : 0.0
            Behavior on opacity { Widgets.Anim { speed: Services.Sizes.msMicro } }

            ColumnLayout {
                id: pickerCol
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
                            text: "\ue8e2"
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 15
                            color: Services.Colors.ghost
                        }
                        TextField {
                            id: searchField
                            Layout.fillWidth: true
                            placeholderText: Services.I18n.t("settings.input.searchLayout")
                            text: tab.layoutQuery
                            onTextChanged: tab.layoutQuery = text
                            color: Services.Colors.snow
                            placeholderTextColor: Services.Colors.ash
                            font.pixelSize: Services.Sizes.fsBody
                            font.family: "JetBrainsMono NF"
                            background: null
                            padding: 0
                            Keys.onEscapePressed: tab.pickerOpen = false
                        }
                    }
                }

                Text {
                    visible: tab.filteredLayouts.length === 0
                    text: tab.missLine
                    color: Services.Colors.ash
                    font.pixelSize: Services.Sizes.fsBody
                    font.family: "JetBrainsMono NF"
                }

                // Capped height: the unfiltered list is 99 entries long
                ListView {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(contentHeight, 168)
                    visible: tab.filteredLayouts.length > 0
                    clip: true
                    model: tab.filteredLayouts
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded; width: 4 }

                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool already: Services.Keyboard.layouts.includes(modelData.code)
                        width: ListView.view.width
                        height: 30
                        radius: Services.Sizes.innerR
                        // A full-width row does not grow; hover lifts its name.
                        color: "transparent"
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 10
                            Text {
                                text: modelData.code
                                color: Services.Colors.ghost
                                font.pixelSize: Services.Sizes.fsBody
                                font.bold: true
                                font.family: "JetBrainsMono NF"
                                Layout.preferredWidth: 52
                            }
                            Text {
                                text: modelData.name
                                color: parent.parent.already ? Services.Colors.ash
                                     : rowArea.containsMouse ? Services.Colors.snow
                                     : Services.Colors.mist
                                Behavior on color { Widgets.ColorAnim { speed: Services.Sizes.msMicro } }
                                font.pixelSize: Services.Sizes.fsBody
                                font.family: "JetBrainsMono NF"
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            Text {
                                visible: parent.parent.already
                                text: Services.I18n.t("settings.input.inUse")
                                color: Services.Colors.ash
                                font.pixelSize: Services.Sizes.fsCaption
                                font.family: "JetBrainsMono NF"
                            }
                        }
                        MouseArea {
                            id: rowArea
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: !parent.already
                            cursorShape: parent.already ? Qt.ForbiddenCursor : Qt.PointingHandCursor
                            onClicked: {
                                Services.Keyboard.addLayout(modelData.code)
                                tab.pickerOpen = false
                            }
                        }
                    }
                }
            }
        }

        Text {
            text: Services.Keyboard.keymap
            color: Services.Colors.ash
            font.pixelSize: Services.Sizes.fsMeta
            font.family: "JetBrainsMono NF"
        }

    }

    Card {
        title: Services.I18n.t("settings.input.shortcuts")

        Text {
            text: Services.I18n.t("settings.input.rebind")
            color: Services.Colors.ash
            font.pixelSize: Services.Sizes.fsMeta
            font.family: "JetBrainsMono NF"
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        Repeater {
            model: Services.Keybinds.sections
            delegate: ColumnLayout {
                required property var modelData
                Layout.fillWidth: true
                Layout.topMargin: 10
                spacing: 8

                SectionLabel {
                    text: modelData.name
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Repeater {
                    model: modelData.items
                    delegate: RowLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 14

                        // Keys first: the list is scanned by "what do I
                        // press?", and pressing the chip is how you change it.
                        KeyChip {
                            Layout.preferredWidth: 240
                            wid: modelData.id
                            plain: modelData.keys
                        }
                        Text {
                            Layout.fillWidth: true
                            text: modelData.action
                            color: Services.Colors.mist
                            font.pixelSize: Services.Sizes.fsInput
                            font.family: "JetBrainsMono NF"
                            elide: Text.ElideRight
                        }
                        // Only where it is no longer what the file shipped.
                        Text {
                            visible: modelData.id !== ""
                                     && Services.Shortcuts.changed(modelData.id)
                            text: Services.I18n.t("settings.input.changed")
                            color: Services.Colors.ghost
                            font.pixelSize: Services.Sizes.fsMeta
                            font.family: "JetBrainsMono NF"
                        }
                    }
                }
            }
        }

        Text {
            visible: Services.Keybinds.binds.length === 0
            text: Services.I18n.t("settings.input.noShortcuts")
            color: Services.Colors.ash
            font.pixelSize: Services.Sizes.fsBody
            font.family: "JetBrainsMono NF"
        }
    }

    Item { Layout.preferredHeight: 8 }
}
