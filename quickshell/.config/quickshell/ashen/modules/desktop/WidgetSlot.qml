import QtQuick

import "root:/services" as Services

// One widget's place on the desktop: the widget itself, and the row of shapes
// that follows it while arranging. Both are children of the field, never of
// each other -- see StyleChips for why.
Item {
    id: slot

    required property string wid
    required property Component source
    property bool live: true

    anchors.fill: parent

    readonly property bool wanted: Services.Desktop.shown(slot.wid)

    Loader {
        id: holder
        // Stays built while it fades out: a wallpaper that turns its widgets
        // off should look like they are leaving, not like they were cut.
        active: slot.wanted || leaving.running
        sourceComponent: slot.source
        opacity: slot.wanted ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                id: leaving
                duration: Services.Sizes.msPanel
                easing.type: Services.Sizes.easeOut
            }
        }
        onLoaded: {
            item.fieldW = Qt.binding(() => slot.width)
            item.fieldH = Qt.binding(() => slot.height)
            item.live = Qt.binding(() => slot.live)
        }
    }

    StyleChips {
        wid: slot.wid
        target: holder.item
    }

    FrameGrips {
        wid: slot.wid
        target: holder.item
    }
}
