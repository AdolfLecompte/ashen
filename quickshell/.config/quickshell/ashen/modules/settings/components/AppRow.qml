import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import "root:/services" as Services

// One of the four app keys: which program it opens, and which keys open it.
// Both on one line because they are one question -- "what does SUPER+T do" --
// and answering it in two places was how SUPER+W ended up pointing at a browser
// that was not installed.
ColumnLayout {
    id: root

    property string kind: ""
    property string title: ""
    property string glyph: ""
    property string fallback: ""

    Layout.fillWidth: true
    spacing: 8

    readonly property string command: Services.Apps.commandOf(root.kind)
    // The .desktop entry whose Exec is what we are running, if it came from the
    // list rather than being typed.
    readonly property var app: {
        for (const a of Services.Apps.all) if (a.exec === root.command) return a
        return null
    }

    property bool picking: false     // the list of programs is open

    RowLayout {
        Layout.fillWidth: true
        spacing: 12

        RowGlyph { glyph: root.glyph }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Text {
                text: root.title
                color: Services.Colors.snow
                font.pixelSize: Services.Sizes.fsInput
                font.bold: true
                font.family: "JetBrainsMono NF"
            }
            Text {
                // The program's own name when we know it, the command when it
                // was typed, and what happens by itself when neither.
                text: root.app ? root.app.name
                    : root.command !== "" ? root.command : root.fallback
                color: root.command === "" ? Services.Colors.mist : Services.Colors.ash
                font.italic: root.command === ""
                font.pixelSize: Services.Sizes.fsMeta
                font.family: "JetBrainsMono NF"
                elide: Text.ElideMiddle
                Layout.fillWidth: true
            }
        }

        // The same chip the Shortcuts list uses: one way to change a
        // combination, wherever a combination is shown.
        KeyChip { wid: root.kind }

        ActionBtn {
            label: root.picking ? Services.I18n.t("common.close") : Services.I18n.t("common.change")
            onGo: root.picking = !root.picking
        }
    }

    Collapse {
        id: pick
        open: root.picking

        // What this machine actually has of that kind, read off the .desktop
        // files rather than a list written here that would go stale, and then
        // whatever you are typing.
        readonly property var offered: {
            const mine = Services.Apps.ofKind(root.kind)
            const pool = root.showAll || mine.length === 0 ? Services.Apps.all : mine
            const q = root.query.trim().toLowerCase()
            if (q === "") return pool
            // The command too, not only the name: you may know it as `foot`
            // while its .desktop calls it something else entirely.
            return pool.filter(a => a.name.toLowerCase().indexOf(q) !== -1
                                 || a.exec.toLowerCase().indexOf(q) !== -1)
        }

        // Typing here is how you find one in a list of two hundred, which is
        // what "All apps" turns this into.
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 30
            radius: Services.Sizes.innerR
            color: Services.Colors.fillLine
            border.width: 1
            border.color: search.activeFocus ? Services.Colors.ghost : Services.Colors.fillRest
            Behavior on border.color { ColorAnimation { duration: Services.Sizes.msMicro } }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: "\ue8b6"
                color: Services.Colors.ash
                font.pixelSize: 15
                font.family: "Material Symbols Rounded"
            }
            TextField {
                id: search
                anchors.fill: parent
                anchors.leftMargin: 34
                anchors.rightMargin: 10
                verticalAlignment: TextInput.AlignVCenter
                placeholderText: Services.I18n.t("settings.apps.search")
                color: Services.Colors.snow
                placeholderTextColor: Services.Colors.ash
                font.pixelSize: 11
                font.family: "JetBrainsMono NF"
                background: null
                padding: 0
                text: root.query
                onTextChanged: root.query = text
                Keys.onEscapePressed: root.query = ""
            }
        }

        Repeater {
            model: pick.offered

            Rectangle {
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: 40
                radius: Services.Sizes.innerR
                color: modelData.exec === root.command
                    ? Services.Colors.fillRest : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 10

                    IconImage {
                        implicitSize: 22
                        source: Quickshell.iconPath(modelData.icon, true)
                        visible: source !== ""
                    }
                    Text {
                        Layout.fillWidth: true
                        text: modelData.name
                        color: rowHover.containsMouse || modelData.exec === root.command
                            ? Services.Colors.snow : Services.Colors.mist
                        font.pixelSize: Services.Sizes.fsBody
                        font.family: "JetBrainsMono NF"
                        elide: Text.ElideRight
                    }
                    Text {
                        text: modelData.exec
                        color: Services.Colors.ash
                        font.pixelSize: Services.Sizes.fsMeta
                        font.family: "JetBrainsMono NF"
                        elide: Text.ElideLeft
                        Layout.maximumWidth: 240
                    }
                }

                MouseArea {
                    id: rowHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Services.Apps.setCommand(root.kind, modelData.exec)
                        root.picking = false
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            ActionBtn {
                label: root.showAll ? "Only " + root.title.toLowerCase() + "s" : "All apps"
                onGo: root.showAll = !root.showAll
            }
            ActionBtn {
                label: Services.I18n.t("common.automatic")
                onGo: {
                    Services.Apps.setCommand(root.kind, "")
                    root.picking = false
                }
            }
            Item { Layout.fillWidth: true }
        }

        // Typed by hand, for the cases a .desktop cannot express -- a terminal
        // with the flags that keep it to one instance, a browser in a profile.
        CommandField {
            title: Services.I18n.t("settings.apps.command")
            value: root.command
            fallback: root.fallback
            onCommitted: cmd => Services.Apps.setCommand(root.kind, cmd)
        }
    }

    // Kept out here: the Collapse rebuilds its contents, and a flag inside it
    // would forget itself every time the list opened.
    property bool showAll: false
    property string query: ""
    // A search from last time is not a search: reopening starts clean.
    onPickingChanged: if (!root.picking) root.query = ""
}
