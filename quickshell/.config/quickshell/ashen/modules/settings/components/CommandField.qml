import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import "root:/services" as Services

// A command you type: click, type, Enter. Empty is a real answer -- it means
// "whatever this machine already prefers" -- so this never refuses to save one.
// It does check that the program exists and says so if it does not, because a
// keybind that silently opens nothing is the bug this whole row is here to fix.
RowLayout {
    id: root

    property string glyph: ""
    property string title: ""
    property string value: ""
    // What happens when the field is left empty, in the user's words.
    property string fallback: ""

    signal committed(string command)

    Layout.fillWidth: true
    spacing: 12

    property bool editing: false
    property bool missing: false

    function beginEdit() {
        root.missing = false
        field.text = root.value
        root.editing = true
        field.forceActiveFocus()
        field.selectAll()
    }
    function cancel() {
        root.editing = false
        root.missing = false
    }
    function commit() {
        const c = field.text.trim()
        root.editing = false
        root.committed(c)
        if (c === "") { root.missing = false; return }
        // Only the program itself: the rest of the line is its arguments.
        checkProc.candidate = c.split(" ")[0]
        checkProc.running = true
    }

    Process {
        id: checkProc
        property string candidate: ""
        running: false
        command: ["sh", "-c", "command -v \"$1\" >/dev/null && echo yes || echo no",
                  "sh", candidate]
        stdout: StdioCollector {
            onStreamFinished: root.missing = text.trim() !== "yes"
        }
    }

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

        Item {
            Layout.fillWidth: true
            implicitHeight: root.editing ? 28 : shown.implicitHeight
            Behavior on implicitHeight { NumberAnimation { duration: Services.Sizes.msMicro; easing.type: Services.Sizes.easeOut } }

            Text {
                id: shown
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                visible: !root.editing
                text: root.value !== "" ? root.value : root.fallback
                color: root.missing ? Services.Colors.error_
                     : root.value !== "" ? Services.Colors.ash : Services.Colors.mist
                font.pixelSize: Services.Sizes.fsMeta
                font.italic: root.value === ""
                font.family: "JetBrainsMono NF"
                elide: Text.ElideMiddle
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: 28
                visible: root.editing
                radius: Services.Sizes.innerR
                color: Services.Colors.fillLine
                border.width: 1
                border.color: field.activeFocus ? Services.Colors.ghost : Services.Colors.fillRest
                Behavior on border.color { ColorAnimation { duration: Services.Sizes.msMicro } }

                TextField {
                    id: field
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    verticalAlignment: TextInput.AlignVCenter
                    placeholderText: root.fallback
                    color: Services.Colors.snow
                    placeholderTextColor: Services.Colors.ash
                    font.pixelSize: 11
                    font.family: "JetBrainsMono NF"
                    background: null
                    padding: 0
                    onAccepted: root.commit()
                    Keys.onEscapePressed: root.cancel()
                }
            }
        }
    }

    // The program named is not installed. Said here rather than refused above:
    // it may be a command that only exists on the machine this profile is
    // headed for.
    Text {
        visible: root.missing && !root.editing
        text: "not installed"
        color: Services.Colors.error_
        font.pixelSize: Services.Sizes.fsMeta
        font.family: "JetBrainsMono NF"
    }

    ActionBtn {
        label: root.editing ? "Save" : "Change"
        onGo: root.editing ? root.commit() : root.beginEdit()
    }
}
