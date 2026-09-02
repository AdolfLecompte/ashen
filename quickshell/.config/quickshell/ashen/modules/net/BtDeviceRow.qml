import QtQuick
import QtQuick.Layouts
import "root:/services" as Services
import "root:/modules/widgets" as Widgets

// One Bluetooth device row, shared by the bar panel and the settings tab so
// both render identically (device-type icon, status, connected mark, forget).
// The caller sets the width (Column: `width:`; ColumnLayout: `Layout.fillWidth`)
// and passes `device` (a BluetoothDevice). All actions are self-contained.
Rectangle {
    id: row
    required property var device
    // BlueZ remembers a device once it is paired, bonded or trusted. Game
    // controllers often show up trusted-only (paired:no bonded:no trusted:yes),
    // so keying off `paired` alone hid the forget button for them.
    readonly property bool remembered: device.paired || device.bonded || device.trusted

    height: 54
    radius: 8
    // Connected is a state and takes a fill; hover is not, and only lifts the
    // name to snow. A full-width row does not grow.
    color: device.connected ? Services.Colors.fillRest : Services.Colors.fillInset
    Behavior on color { ColorAnimation { duration: Services.Sizes.msMicro } }

    // BlueZ reports a freedesktop icon name ("audio-headset", "input-mouse"…);
    // map it to a Material Symbol. Order matters: "audio-headset" also matches
    // the "audio" test, so headset/headphone/earbud come first.
    function deviceGlyph(d) {
        let n = (d && d.icon ? d.icon : "").toLowerCase()
        if (n.indexOf("headset") !== -1) return ""
        if (n.indexOf("headphone") !== -1) return ""
        if (n.indexOf("earbud") !== -1) return ""
        if (n.indexOf("speaker") !== -1 || n.indexOf("audio") !== -1) return ""
        if (n.indexOf("mouse") !== -1) return ""
        if (n.indexOf("keyboard") !== -1) return ""
        if (n.indexOf("gaming") !== -1 || n.indexOf("joypad") !== -1) return ""
        if (n.indexOf("phone") !== -1) return ""
        if (n.indexOf("watch") !== -1) return ""
        if (n.indexOf("computer") !== -1) return ""
        if (n.indexOf("printer") !== -1) return ""
        if (n.indexOf("display") !== -1 || n.indexOf("tv") !== -1) return ""
        if (n.indexOf("car") !== -1) return ""
        return ""
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 10

        Text {
            text: row.deviceGlyph(row.device)
            color: row.device.connected ? Services.Colors.ghost : Services.Colors.mist
            font.pixelSize: 20
            font.family: "Material Symbols Rounded"
        }
        Column {
            Layout.fillWidth: true
            spacing: 2
            Text {
                text: Services.BtLink.displayName(row.device)
                color: (row.device.connected || rowMouse.containsMouse)
                    ? Services.Colors.snow : Services.Colors.mist
                Behavior on color { ColorAnimation { duration: Services.Sizes.msMicro } }
                font.pixelSize: 13
                font.family: "JetBrainsMono NF"
                font.bold: row.device.connected
                elide: Text.ElideRight
                width: parent.width
            }
            Text {
                // A link in flight says so: the row used to read "Paired" for
                // the whole of a connect that takes seconds.
                text: Services.BtLink.busyText(row.device) !== "" ? Services.BtLink.busyText(row.device)
                    : row.device.connected ? "Connected"
                    : (row.device.paired || row.device.bonded) ? "Paired"
                    : row.device.trusted ? "Saved"
                    : "Available"
                color: row.device.connected ? Services.Colors.ghost : Services.Colors.ash
                font.pixelSize: 10
                font.family: "JetBrainsMono NF"
            }
        }
        Text {
            visible: row.device.connected
            text: ""
            color: Services.Colors.ghost
            font.pixelSize: 18
            font.family: "Material Symbols Rounded"
        }
        // Forget (unpair): only paired devices can be forgotten.
        Widgets.IconButton {
            Layout.preferredWidth: 28
            Layout.preferredHeight: 28
            visible: row.remembered
            glyph: "\ue5cd"
            onActivated: row.device.forget()
        }
    }

    MouseArea {
        id: rowMouse
        anchors.fill: parent
        // leave the right edge clickable for the forget button on remembered rows
        anchors.rightMargin: row.remembered ? 40 : 0
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        enabled: !row.device.pairing
        onClicked: {
            if (row.device.connected) {
                row.device.disconnect()
            } else {
                // Pair-or-connect, discovery stopped first and the link chased
                // after bonding lands. See services/BtLink.qml.
                Services.BtLink.request(row.device)
            }
        }
    }
}
