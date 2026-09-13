import QtQuick
import QtQuick.Layouts
import "root:/services" as Services
import "root:/modules/widgets" as Widgets

// One Wi-Fi network row, shared by the bar panel and the settings tab. The
// caller sets the width, passes `net` ({ ssid, signal, secure }) and `known`
// (a saved network → shows the forget button), and handles `activate()` (tap
// the row) and `forget()` however it wants (connect vs. open a dialog, etc).
Rectangle {
    id: row
    required property var net
    property bool known: false
    signal activate()
    signal forget()

    height: 54
    radius: 8
    // The plate is there at rest and never changes under the pointer: hover is
    // that the name lifts to snow. A full-width row does not grow -- it would
    // climb over its neighbours.
    color: Services.Colors.fillInset
    Behavior on color { Widgets.ColorAnim { speed: Services.Sizes.msMicro } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 10

        Text {
            text: row.net.signal >= 75 ? "" : row.net.signal >= 50 ? "" : row.net.signal >= 25 ? "" : ""
            color: Services.Colors.mist
            font.pixelSize: 20
            font.family: "Material Symbols Rounded"
        }
        Column {
            Layout.fillWidth: true
            spacing: 2
            Text {
                text: row.net.ssid
                color: rowMouse.containsMouse ? Services.Colors.snow : Services.Colors.mist
                Behavior on color { Widgets.ColorAnim { speed: Services.Sizes.msMicro } }
                font.pixelSize: 13
                font.family: "JetBrainsMono NF"
                elide: Text.ElideRight
                width: parent.width
            }
            Text {
                text: row.net.signal + "% signal"
                color: Services.Colors.ash
                font.pixelSize: 10
                font.family: "JetBrainsMono NF"
            }
        }
        Text {
            visible: row.net.secure
            text: ""
            color: Services.Colors.ash
            font.pixelSize: 14
            font.family: "Material Symbols Rounded"
        }
        // Forget: only saved (known) networks can be forgotten.
        Widgets.IconButton {
            Layout.preferredWidth: 28
            Layout.preferredHeight: 28
            visible: row.known
            glyph: "\ue5cd"
            onActivated: row.forget()
        }
    }

    MouseArea {
        id: rowMouse
        anchors.fill: parent
        // leave the right edge clickable for the forget button on saved rows
        anchors.rightMargin: row.known ? 40 : 0
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: row.activate()
    }
}
