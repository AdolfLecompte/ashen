import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "root:/services" as Services
import "root:/modules/widgets" as Widgets

// A search field in the Settings search box's dress, whose finds unfold inside
// the same box, under a hairline. The caller puts the finds in as children and
// says when there are any to show (open).
Rectangle {
    id: box
    property alias text: input.text
    property string placeholder: ""
    // A lookup is out: the clear cross turns into a spinner.
    property bool busy: false
    property bool open: false
    default property alias finds: list.data
    signal accepted()
    signal cleared()

    function focusField() { input.forceActiveFocus() }
    function clear() { input.text = ""; box.cleared() }

    Layout.fillWidth: true
    implicitHeight: 38 + box.shownH
    property real shownH: box.open ? list.implicitHeight + 8 : 0
    Behavior on shownH { Widgets.Anim { speed: Services.Sizes.msPanel } }
    radius: Services.Sizes.innerR
    color: Services.Colors.fillInset
    border.width: 1
    border.color: input.activeFocus ? Services.Colors.ghost : Services.Colors.fillLine
    Behavior on border.color { Widgets.ColorAnim { speed: Services.Sizes.msMicro } }
    clip: true

    Item {
        id: field
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 38

        Text {
            textFormat: Text.PlainText
            id: glyph
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 1
            text: "\ue8b6"              // search
            color: input.activeFocus ? Services.Colors.ghost : Services.Colors.mist
            font.pixelSize: 16
            font.family: "Material Symbols Rounded"
            Behavior on color { Widgets.ColorAnim { speed: Services.Sizes.msMicro } }
        }
        TextField {
            id: input
            anchors.left: glyph.right
            anchors.leftMargin: 10
            anchors.right: fieldEnd.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            placeholderText: box.placeholder
            color: Services.Colors.snow
            placeholderTextColor: Services.Colors.ash
            font.pixelSize: Services.Sizes.fsBody
            font.family: "JetBrainsMono NF"
            background: null
            padding: 0
            Keys.onPressed: e => { if (Services.Readline.handle(e, input)) e.accepted = true }
            Keys.onEscapePressed: box.clear()
            onAccepted: box.accepted()
        }
        Text {
            textFormat: Text.PlainText
            id: fieldEnd
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            visible: input.text.length > 0
            text: box.busy ? "\ue9d0" : "\ue5cd"     // progress_activity / close
            color: clearArea.containsMouse ? Services.Colors.snow : Services.Colors.ash
            font.pixelSize: 16
            font.family: "Material Symbols Rounded"
            scale: box.busy ? 1 : Services.Sizes.hoverScale(clearArea.containsMouse, clearArea.pressed)
            Behavior on scale { Widgets.Anim { speed: Services.Sizes.pillHoverMs } }
            RotationAnimator on rotation {
                running: box.busy && fieldEnd.visible
                from: 0; to: 360
                duration: 900
                loops: Animation.Infinite
                onRunningChanged: if (!running) fieldEnd.rotation = 0
            }
            MouseArea {
                id: clearArea
                anchors.fill: parent
                anchors.margins: -6
                hoverEnabled: true
                enabled: !box.busy
                cursorShape: Qt.PointingHandCursor
                onClicked: box.clear()
            }
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: field.bottom
        anchors.leftMargin: 6
        anchors.rightMargin: 6
        height: 1
        color: Services.Colors.fillLine
        opacity: list.opacity
    }
    Column {
        id: list
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: field.bottom
        anchors.topMargin: 3
        anchors.leftMargin: 6
        anchors.rightMargin: 6
        spacing: 2
        opacity: box.open ? 1 : 0
        Behavior on opacity { Widgets.Anim { speed: Services.Sizes.msMicro } }
    }
}
