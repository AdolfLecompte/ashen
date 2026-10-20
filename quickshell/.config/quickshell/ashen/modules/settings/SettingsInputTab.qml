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

    // Match on code or name, so both "de" and "german" find German
    readonly property var filteredLayouts: {
        let q = finder.text.trim().toLowerCase()
        let all = Services.Keyboard.available
        if (q === "") return []
        return all.filter(l => l.code.indexOf(q) !== -1
            || l.name.toLowerCase().indexOf(q) !== -1)
    }
    function nameOf(code) {
        const l = Services.Keyboard.available.find(x => x.code === code)
        return l ? l.name : code
    }
    function add(code) {
        Services.Keyboard.addLayout(code)
        finder.clear()
    }


    Card {
        glyph: "\ue312"
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

        // The layouts in use: a list, in the order XKB cycles them. The row
        // switches, the cross drops (never the last one: nothing would type).
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: kbCol.implicitHeight + 12
            radius: Services.Sizes.cardR
            color: Services.Colors.fillInset

            Column {
                id: kbCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 6
                spacing: 2

                Repeater {
                    model: Services.Keyboard.layouts
                    delegate: PickRow {
                        required property var modelData
                        required property int index
                        code: modelData
                        label: tab.nameOf(modelData)
                        active: Services.Keyboard.activeIndex === index
                        removable: Services.Keyboard.layouts.length > 1
                        onPicked: Services.Keyboard.setLayout(index)
                        onRemoved: Services.Keyboard.removeLayout(modelData)
                    }
                }
            }
        }

        // 99 layouts, so it filters instead of listing. Enter adds the first
        // one not already in use.
        FindBox {
            id: finder
            visible: Services.Keyboard.canAdd
            placeholder: Services.I18n.t("settings.input.searchLayout")
            open: finder.text.trim() !== ""
            onAccepted: {
                const l = tab.filteredLayouts.find(x => !Services.Keyboard.layouts.includes(x.code))
                if (l) tab.add(l.code)
            }

            PickRow {
                visible: tab.filteredLayouts.length === 0
                glyph: "\uea76"                 // search_off
                label: tab.missLine
                quiet: true
            }
            // Capped: a short query still matches dozens.
            ListView {
                width: parent.width
                height: Math.min(contentHeight, 200)
                visible: tab.filteredLayouts.length > 0
                clip: true
                model: tab.filteredLayouts
                spacing: 2
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded; width: 4 }
                delegate: PickRow {
                    required property var modelData
                    width: ListView.view.width
                    code: modelData.code
                    label: modelData.name
                    taken: Services.Keyboard.layouts.includes(modelData.code)
                    takenNote: Services.I18n.t("settings.input.inUse")
                    onPicked: tab.add(modelData.code)
                }
            }
        }

        Text {
            textFormat: Text.PlainText
            visible: !Services.Keyboard.canAdd
            text: Services.I18n.t("settings.input.max")
            color: Services.Colors.ash
            font.pixelSize: Services.Sizes.fsMeta
            font.family: "JetBrainsMono NF"
        }


    }

    // What the touchpad does, read from conf/gestures.lua like the shortcuts
    // are from keybinds.lua: a gesture added there shows up here.
    Card {
        glyph: "\ue9ec"
        title: Services.I18n.t("settings.input.gestures")
        visible: Services.Keybinds.gestures.length > 0

        Repeater {
            model: Services.Keybinds.gestures
            delegate: RowLayout {
                required property var modelData
                Layout.fillWidth: true
                spacing: 14
                KeyChip {
                    Layout.preferredWidth: 240
                    wid: ""
                    plain: modelData.keys
                }
                Text {
                    textFormat: Text.PlainText
                    Layout.fillWidth: true
                    text: modelData.action
                    color: Services.Colors.mist
                    font.pixelSize: Services.Sizes.fsInput
                    font.family: "JetBrainsMono NF"
                    elide: Text.ElideRight
                }
            }
        }
    }

    Card {
        glyph: "\ueae7"
        title: Services.I18n.t("settings.input.shortcuts")

        Text {
            textFormat: Text.PlainText
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
                            textFormat: Text.PlainText
                            Layout.fillWidth: true
                            text: modelData.action
                            color: Services.Colors.mist
                            font.pixelSize: Services.Sizes.fsInput
                            font.family: "JetBrainsMono NF"
                            elide: Text.ElideRight
                        }
                        // Only where it is no longer what the file shipped.
                        Text {
                            textFormat: Text.PlainText
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
            textFormat: Text.PlainText
            visible: Services.Keybinds.binds.length === 0
            text: Services.I18n.t("settings.input.noShortcuts")
            color: Services.Colors.ash
            font.pixelSize: Services.Sizes.fsBody
            font.family: "JetBrainsMono NF"
        }
    }

    Item { Layout.preferredHeight: 8 }
}
