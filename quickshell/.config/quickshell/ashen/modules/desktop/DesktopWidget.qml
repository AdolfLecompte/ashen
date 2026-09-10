import QtQuick

import "root:/modules/widgets" as Widgets
import "root:/services" as Services

// A widget sitting on the wallpaper. Holds the plate, the dragging and the
// clamping; what it says is the content its caller puts inside.
Item {
    id: root

    required property string wid
    // The screen box the widget has to stay inside.
    property real fieldW: 0
    property real fieldH: 0
    // False when the desktop is behind a fullscreen window: anything that
    // paints on a clock -- a canvas, a poll -- has to stop, because nobody is
    // looking at it.
    property bool live: true
    default property alias content: body.data

    // The lock screen builds its columns out of these same widgets: there it
    // chooses the shape, lays them out itself, and there is nothing to drag
    // them onto. Unmanaged means no record is read or written -- no position,
    // no arranging, no outline.
    property bool managed: true
    property string styleOverride: ""
    property string skinOverride: ""

    readonly property bool editing: root.managed && Services.Desktop.editMode
    readonly property var entry: Services.Desktop.entry(root.wid)
    // The shape this widget is wearing, and -- where it has a second axis --
    // how it draws. Every widget picks its face off these and nothing else.
    readonly property string style: root.styleOverride !== "" ? root.styleOverride : root.entry.style
    readonly property string skin: root.skinOverride !== "" ? root.skinOverride : root.entry.skin

    // Where the record says it goes, kept on screen. Dragging writes straight
    // to x/y (that is what drag does), so the binding is restored by hand when
    // the hand lets go.
    readonly property real targetX: Math.max(0, Math.min(root.entry.x, Math.max(0, root.fieldW - width)))
    readonly property real targetY: Math.max(0, Math.min(root.entry.y, Math.max(0, root.fieldH - height)))
    x: root.targetX
    y: root.targetY

    // The LEAST the plate leaves around its content -- the rest is whatever
    // the grid adds below. A picture wants none: there the widget IS the
    // picture, and a rim of plate around it reads as a mount.
    property real padH: 24
    property real padV: 20

    // Every plate lands on the same 48 grid the guides and the magnet already
    // use, so two widgets side by side line up whatever they are showing.
    // Widths of 126 and 728 next to each other never can. Off for the picture:
    // there the plate IS the image and growing it would letterbox it.
    property bool onGrid: true
    function toGrid(v) {
        const step = Services.Desktop.gridStep
        return root.onGrid ? Math.ceil(v / step) * step : v
    }

    implicitWidth: root.toGrid(body.implicitWidth + root.padH)
    implicitHeight: root.toGrid(body.implicitHeight + root.padV)

    // Off while a widget owns the pointer for something else -- framing a
    // picture is done with the same button that would otherwise move it.
    property bool dragEnabled: true
    // Which button drags the box. A widget whose body already means something
    // else while arranging -- a picture being framed slides under the left
    // button -- hands the drag to another one rather than giving it up.
    property int dragButtons: Qt.LeftButton
    // Can this one be pulled to a size of its own? The corner grips are drawn
    // OUTSIDE the frame, by the slot, so they say so from here.
    property bool resizable: false
    // …and can what it shows be framed by hand? Same arrangement: the button
    // that turns it on sits outside the widget, with the grips.
    property bool croppable: false

    // Widgets with something to press say so: the wallpaper layer is deaf by
    // default (a click on the desktop has to reach the desktop), so it cuts a
    // hole for exactly these boxes and no others.
    property bool wantsInput: false

    // The magnet reads these when something is dropped, so they have to be
    // current -- including while a widget is being dragged past its neighbours.
    // Nothing off the lock screen belongs in the desktop's map: the magnet
    // would snap wallpaper widgets onto boxes that are not out there.
    function publish() {
        if (!root.managed) return
        Services.Desktop.setRect(root.wid, root.x, root.y, root.width, root.height)
        if (root.wantsInput)
            Services.Desktop.setInputRect(root.wid, root.x, root.y, root.width, root.height)
    }
    // A shape can lose its buttons (the lyric page has none): the hole has to
    // go with them, or it would keep eating clicks meant for the wallpaper.
    onWantsInputChanged: {
        if (root.wantsInput) root.publish()
        else Services.Desktop.dropInputRect(root.wid)
    }
    onXChanged: root.publish()
    onYChanged: root.publish()
    onWidthChanged: root.publish()
    onHeightChanged: root.publish()
    Component.onCompleted: root.publish()
    Component.onDestruction: if (root.managed) {
        Services.Desktop.dropRect(root.wid)
        Services.Desktop.dropInputRect(root.wid)
    }

    Rectangle {
        id: plate
        anchors.fill: parent
        radius: Services.Sizes.panelR
        color: Services.Prefs.widgetOutline ? Services.Colors.surfaceGlass
                                            : Services.Colors.surfacePill
        // Two reasons for a border, and arranging wins: while you are dragging
        // boxes around, the accent edge says which ones are grabbable. The rest
        // of the time it is the widget outline, or nothing.
        border.color: root.editing ? Services.Colors.ghost
                    : Services.Prefs.widgetOutline ? Services.Colors.fillOutline
                    : "transparent"
        border.width: root.editing ? 2
                    : Services.Prefs.widgetOutline ? Services.Sizes.outlineW : 0
        Behavior on border.width { Widgets.Anim { speed: Services.Sizes.msMicro } }
    }

    // Hover is the box growing, never a fill; only when there is something to
    // grab. Content brightening is each widget's own business.
    scale: root.editing ? Services.Sizes.hoverScaleFor(width, drag_.containsMouse, drag_.pressed) : 1
    Behavior on scale { Widgets.Anim { speed: Services.Sizes.pillHoverMs } }

    Item {
        id: body
        anchors.centerIn: parent
        // Above the drag area below, which is declared later and would
        // otherwise swallow every press meant for something INSIDE the widget
        // while arranging -- which is exactly when a picture's corners are
        // there to be pulled. Items that are not MouseAreas do not take events,
        // so dragging the widget by its plate still works.
        z: 1
        // Measured from the FIRST child -- what the widget draws -- and never
        // from childrenRect. Anything else in here (an overlay filling the box)
        // is sized BY the box, so measuring the box by it is a loop: shrink the
        // picture and the plate keeps the size the overlay is still holding.
        readonly property Item shape: body.children.length > 0 ? body.children[0] : null
        implicitWidth: body.shape ? body.shape.width : 0
        implicitHeight: body.shape ? body.shape.height : 0
        width: implicitWidth
        height: implicitHeight
    }

    MouseArea {
        id: drag_
        anchors.fill: parent
        acceptedButtons: root.dragButtons
        enabled: root.editing && root.dragEnabled
        hoverEnabled: root.editing && root.dragEnabled
        cursorShape: root.editing && root.dragEnabled
            ? (pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor)
            : Qt.ArrowCursor
        drag.target: root.editing && root.dragEnabled ? root : undefined
        drag.minimumX: 0
        drag.minimumY: 0
        drag.maximumX: Math.max(0, root.fieldW - root.width)
        drag.maximumY: Math.max(0, root.fieldH - root.height)
        onReleased: {
            // The service decides where it actually lands: free hand, or on
            // the grid.
            Services.Desktop.place(root.wid, root.x, root.y, root.fieldW, root.fieldH)
            // Dragging destroyed the binding above; without this the widget
            // stops following its record and a profile could not move it.
            root.x = Qt.binding(() => root.targetX)
            root.y = Qt.binding(() => root.targetY)
        }
    }
}
