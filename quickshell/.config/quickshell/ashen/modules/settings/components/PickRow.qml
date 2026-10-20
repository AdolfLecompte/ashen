import QtQuick
import "root:/services" as Services
import "root:/modules/widgets" as Widgets

// One entry of a list you pick from (saved cities, keyboard layouts, search
// hits): a glyph or a short code, a name and an optional line under it. Lit
// when it is the one in use. Hover brightens, never fills or grows.
Item {
    id: row
    property string glyph: ""
    // Shown in place of the glyph: a layout's "us", "latam".
    property string code: ""
    property string label: ""
    property string detail: ""
    property bool active: false
    property bool removable: false
    // Already taken: shown, but not offered.
    property bool taken: false
    property string takenNote: ""
    // A line that says something rather than offering a choice.
    property bool quiet: false
    signal picked()
    signal removed()

    width: parent ? parent.width : 0
    implicitHeight: row.detail !== "" ? 44 : 36
    readonly property bool hot: rowArea.containsMouse && !row.quiet && !row.taken

    Text {
        textFormat: Text.PlainText
        id: lead
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: row.code === "" ? 1 : 0
        width: row.code === "" ? implicitWidth : 52
        text: row.code !== "" ? row.code : row.glyph
        color: row.active ? Services.Colors.ghost
             : row.hot ? Services.Colors.snow
             : row.code !== "" && !row.taken ? Services.Colors.mist : Services.Colors.ash
        font.pixelSize: row.code === "" ? 16 : Services.Sizes.fsBody
        font.bold: row.code !== ""
        font.family: row.code === "" ? "Material Symbols Rounded" : "JetBrainsMono NF"
        Behavior on color { Widgets.ColorAnim { speed: Services.Sizes.msMicro } }
    }
    Column {
        anchors.left: lead.right
        anchors.leftMargin: 10
        anchors.right: tail.left
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1
        Text {
            textFormat: Text.PlainText
            width: parent.width
            text: row.label
            color: row.taken ? Services.Colors.ash
                 : row.active || row.hot ? Services.Colors.snow : Services.Colors.mist
            font.pixelSize: Services.Sizes.fsBody
            font.bold: row.active
            font.family: "JetBrainsMono NF"
            elide: Text.ElideRight
            Behavior on color { Widgets.ColorAnim { speed: Services.Sizes.msMicro } }
        }
        Text {
            textFormat: Text.PlainText
            width: parent.width
            visible: row.detail !== ""
            text: row.detail
            color: Services.Colors.ash
            font.pixelSize: Services.Sizes.fsCaption
            font.family: "JetBrainsMono NF"
            elide: Text.ElideRight
        }
    }
    MouseArea {
        id: rowArea
        anchors.fill: parent
        hoverEnabled: true
        enabled: !row.quiet && !row.taken
        cursorShape: row.active ? Qt.ArrowCursor : Qt.PointingHandCursor
        onClicked: if (!row.active) row.picked()
    }
    // The one in use says so; a removable one trades it for a cross on hover.
    Text {
        textFormat: Text.PlainText
        id: tail
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: row.taken ? 0 : 1
        visible: row.removable || row.active || row.taken
        text: row.taken ? row.takenNote
            : row.removable && (row.hot || dropArea.containsMouse) ? "\ue5cd"   // close
            : row.active ? "\ue5ca" : ""                                     // check
        color: dropArea.containsMouse ? Services.Colors.snow
             : row.active && !row.hot ? Services.Colors.ghost : Services.Colors.ash
        font.pixelSize: row.taken ? Services.Sizes.fsCaption : 16
        font.family: row.taken ? "JetBrainsMono NF" : "Material Symbols Rounded"
        scale: Services.Sizes.hoverScale(dropArea.containsMouse, dropArea.pressed)
        Behavior on scale { Widgets.Anim { speed: Services.Sizes.pillHoverMs } }
        Behavior on color { Widgets.ColorAnim { speed: Services.Sizes.msMicro } }
        MouseArea {
            id: dropArea
            anchors.fill: parent
            anchors.margins: -8
            hoverEnabled: true
            enabled: row.removable
            cursorShape: Qt.PointingHandCursor
            onClicked: row.removed()
        }
    }
}
