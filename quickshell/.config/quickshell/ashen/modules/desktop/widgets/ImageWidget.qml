import Quickshell
import Quickshell.Widgets
import QtQuick

import "root:/modules/desktop"
import "root:/modules/widgets" as Widgets
import "root:/services" as Services

// A picture on the desktop. The one widget you can have several of, so its id
// comes from outside ("image:1", "image:2"...) instead of being written here.
//
// The frame rules and the picture is cropped to it: three shapes are only
// starting sizes, and a corner handle takes it anywhere from there. Which part
// of the picture the frame shows is chosen in its own small mode -- dragging
// the body already means "move this", and one gesture cannot mean two things.
DesktopWidget {
    id: root

    // The picture is the widget; a rim of plate around it reads as a mount.
    padH: 0
    padV: 0
    // A frame pulled by hand lands where it was let go; rounding it up to the
    // grid here would take the last few pixels back every time.
    onGrid: false

    readonly property string src: root.entry.src
    readonly property bool empty: root.src === ""

    // The shape's own size, which a hand-pulled frame overrides. Steps of the
    // grid, so a picture that has not been touched still lines up with what is
    // next to it.
    readonly property real presetW: root.style === "small" ? 192
                                  : root.style === "large" ? 432 : 336
    readonly property real presetH: root.style === "small" ? 192
                                  : root.style === "large" ? 288 : 192
    readonly property real boxW: root.entry.w > 0 ? root.entry.w : root.presetW
    readonly property real boxH: root.entry.h > 0 ? root.entry.h : root.presetH

    readonly property bool cropping: root.managed && root.editing
                                     && Services.Desktop.cropping === root.wid

    // The picker lives in the service: Settings offers the same button for a
    // record it holds no instance of.
    function pick() { Services.Desktop.pickInto(root.wid) }

    // While framing, the LEFT button slides the picture inside its frame, so
    // moving the widget moves to the right one -- rather than not being
    // possible at all until you leave the mode.
    dragButtons: root.cropping ? Qt.RightButton : Qt.LeftButton
    // Its corners and its framing button are drawn outside the frame, by the
    // slot: a control sitting on the picture covers the thing being framed.
    resizable: true
    croppable: true

    ClippingRectangle {
        id: frame
        width: root.boxW
        height: root.boxH
        radius: Services.Sizes.panelR
        color: Services.Colors.fillInset

        // The item is sized to COVER the frame and then slid, rather than being
        // told to crop itself: a picture cropped in place is always cropped
        // down the middle, and choosing which half you keep is the whole point.
        // Zoom 1 is "just covers it", so the frame is never short of picture.
        Image {
            id: img
            source: root.empty ? "" : "file://" + root.src
            fillMode: Image.PreserveAspectFit
            asynchronous: true

            // The file's own proportions, TAKEN once when it loads rather than
            // read in a binding: an Image's implicit size answers with the size
            // it was given, so sizing it from that is a loop.
            property real aspect: 1
            onStatusChanged: if (img.status === Image.Ready && img.implicitHeight > 0)
                img.aspect = img.implicitWidth / img.implicitHeight

            // The smallest box of those proportions that still covers the
            // frame, then zoomed.
            readonly property real baseW: (frame.width / Math.max(1, frame.height)) > img.aspect
                ? frame.width : frame.height * img.aspect

            width: img.baseW * root.entry.zoom
            height: width / Math.max(0.01, img.aspect)
            // Half the overflow each way is as far as it can slide before the
            // frame would start showing what is outside the picture.
            x: (frame.width - width) / 2 + root.entry.ox * (width - frame.width) / 2
            y: (frame.height - height) / 2 + root.entry.oy * (height - frame.height) / 2

            // A wallpaper-sized photo decoded at wallpaper size, to be drawn
            // 200 px wide, is a lot of memory for nothing. Width only: naming
            // both would stretch the picture to the frame's own proportions.
            sourceSize.width: Math.round(Math.max(root.boxW, root.boxH) * 2)
        }

        // Nothing chosen yet, or the file is no longer there. A picture that
        // moved away should say so, not leave an empty plate.
        Column {
            anchors.centerIn: parent
            spacing: 6
            visible: root.empty || img.status === Image.Error
            opacity: root.editing ? 1 : 0.6

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "\ue3f4"
                font.family: "Material Symbols Rounded"
                font.pixelSize: 30
                color: Services.Colors.ghost
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: img.status === Image.Error ? Services.I18n.t("widget.pictureGone")
                    : root.editing ? Services.I18n.t("widget.pickPicture") : Services.I18n.t("widget.noPicture")
                color: Services.Colors.mist
                font.pixelSize: Services.Sizes.fsMeta
                font.family: "JetBrainsMono NF"
            }
        }

        // While framing, the edges of the picture are what you are aiming, so
        // the frame says where it ends.
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            // The frame's own number, not `parent.radius`: a ClippingRectangle
            // does not publish one, and reading it hands back undefined.
            radius: Services.Sizes.panelR
            border.width: root.cropping ? 2 : 0
            border.color: Services.Colors.ghost
            Behavior on border.width { NumberAnimation { duration: Services.Sizes.msMicro } }
        }
    }

    // An empty frame is not worth dragging, so while it is empty the click
    // picks a picture instead. Once it has one, the drag underneath rules and
    // the picture is changed from Settings.
    MouseArea {
        // Its own size, never `anchors.fill`: an overlay that fills the box is
        // measured by the box, and the box would then be measured by it.
        width: root.boxW
        height: root.boxH
        z: 2
        enabled: root.editing && root.empty && !root.cropping
        visible: enabled
        cursorShape: Qt.PointingHandCursor
        onClicked: root.pick()
    }

    // ── Framing: slide the picture inside its frame, wheel to zoom ──────
    MouseArea {
        width: root.boxW
        height: root.boxH
        z: 3
        enabled: root.cropping
        visible: enabled
        cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        acceptedButtons: Qt.LeftButton

        property real pressX: 0
        property real pressY: 0
        property real fromOx: 0
        property real fromOy: 0

        onPressed: mouse => {
            pressX = mouse.x; pressY = mouse.y
            fromOx = root.entry.ox; fromOy = root.entry.oy
        }
        // The picture moves with the hand: a pixel of overflow is worth two of
        // offset, since the offset spans from one edge to the other.
        onPositionChanged: mouse => {
            if (!pressed) return
            const roomX = Math.max(1, img.width - frame.width)
            const roomY = Math.max(1, img.height - frame.height)
            Services.Desktop.setCrop(root.wid,
                fromOx - (mouse.x - pressX) * 2 / roomX,
                fromOy - (mouse.y - pressY) * 2 / roomY,
                root.entry.zoom)
        }
        onWheel: wheel => {
            const step = wheel.angleDelta.y > 0 ? 0.1 : -0.1
            Services.Desktop.setCrop(root.wid, root.entry.ox, root.entry.oy,
                                     root.entry.zoom + step)
        }
    }

}
