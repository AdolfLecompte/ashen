import QtQuick

import "root:/modules/widgets" as Widgets
import "root:/services" as Services

// The shapes a widget can take, offered under it while the desktop is being
// arranged: one row for how much it shows, and a second for how it draws --
// for the widgets that have a second axis at all.
//
// It follows its widget rather than living inside it: Qt does not deliver mouse
// events to anything drawn outside its ancestors' bounds, and a row hanging off
// the bottom of a widget is exactly that.
Item {
    id: root

    required property string wid
    // The widget this row belongs to. Null while its loader is still empty.
    property Item target: null

    readonly property var styles: Services.Desktop.stylesOf(root.wid)
    readonly property var skins: Services.Desktop.skinsOf(root.wid)
    // One shape is not a choice.
    readonly property bool offered: Services.Desktop.editMode && root.target !== null
                                    && (root.styles.length > 1 || root.skins.length > 1)

    // Above every widget: two of them sitting close would otherwise bury one
    // another's row of shapes.
    z: 5
    visible: opacity > 0
    opacity: root.offered ? 1 : 0
    Behavior on opacity { Widgets.Anim { speed: Services.Sizes.msMicro } }

    implicitWidth: rows.width
    implicitHeight: rows.height
    width: implicitWidth
    height: implicitHeight

    x: root.target ? root.target.x + (root.target.width - width) / 2 : 0
    y: root.target ? root.target.y + root.target.height + 8 : 0

    // A row of chips in its own container pill, with the accent travelling to
    // the chosen one -- the same language as the wallpaper categories.
    component Bank: Rectangle {
        id: bank
        property var model_: []
        property string current: ""
        signal picked(string id)

        width: strip.width + 8
        height: strip.height + 8
        radius: Services.Sizes.pillR
        color: Services.Colors.surfacePill
        visible: bank.model_.length > 1

        Rectangle {
            // A child of the plate and of no Row: a Row lays out everything it
            // holds, and a marker in there takes a slot of its own.
            x: 4 + (strip.activeItem ? strip.activeItem.x : 0)
            y: 4
            width: strip.activeItem ? strip.activeItem.width : 0
            height: strip.height
            radius: Services.Sizes.innerR
            color: Services.Colors.ghost
            gradient: Services.Prefs.useGradients ? Services.Colors.accentGradient : null
            visible: strip.activeItem !== null
            Behavior on x { SmoothedAnimation { duration: Services.Sizes.msPronounced } }
            Behavior on width { SmoothedAnimation { duration: Services.Sizes.msPronounced } }
        }

        Row {
            id: strip
            x: 4
            y: 4
            spacing: 2
            property Item activeItem: null

            Repeater {
                model: bank.model_

                Item {
                    id: chip
                    required property var modelData
                    readonly property bool active: bank.current === chip.modelData.id

                    width: label.implicitWidth + 20
                    height: 26

                    // Letting go matters as much as taking hold: with nothing
                    // active the marker has to leave, or it keeps pointing at
                    // the shape you just stopped wearing.
                    onActiveChanged: {
                        if (chip.active) strip.activeItem = chip
                        else if (strip.activeItem === chip) strip.activeItem = null
                    }
                    Component.onCompleted: if (active) strip.activeItem = chip

                    Text {
                        id: label
                        anchors.centerIn: parent
                        text: chip.modelData.label
                        // Hover brightens the word; the plate never changes.
                        color: chip.active ? Services.Colors.accentText
                             : hover.containsMouse ? Services.Colors.snow
                             : Services.Colors.mist
                        font.pixelSize: Services.Sizes.fsMeta
                        font.bold: true
                        font.family: "JetBrainsMono NF"
                        Behavior on color { Widgets.ColorAnim { speed: Services.Sizes.msMicro } }
                    }

                    scale: Services.Sizes.hoverScale(hover.containsMouse, hover.pressed)
                    Behavior on scale { Widgets.Anim { speed: Services.Sizes.pillHoverMs } }

                    MouseArea {
                        id: hover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: bank.picked(chip.modelData.id)
                    }
                }
            }
        }
    }

    Column {
        id: rows
        spacing: 6

        Bank {
            anchors.horizontalCenter: parent.horizontalCenter
            model_: root.styles
            // What it is wearing, not what was last picked: a frame pulled to
            // its own size wears none of these.
            current: Services.Desktop.activeStyle(root.wid)
            onPicked: id => {
                // A size picked while framing would resize the picture under
                // the hand still sliding it.
                if (Services.Desktop.cropping === root.wid) Services.Desktop.toggleCrop(root.wid)
                Services.Desktop.setStyle(root.wid, id)
            }
        }
        Bank {
            anchors.horizontalCenter: parent.horizontalCenter
            model_: root.skins
            current: Services.Desktop.entry(root.wid).skin
            onPicked: id => Services.Desktop.setSkin(root.wid, id)
        }
    }
}
