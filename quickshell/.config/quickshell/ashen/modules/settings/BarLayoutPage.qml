import Quickshell
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "root:/services" as Services
import "root:/modules/widgets" as Widgets
import "root:/modules/settings/components"

// Which capsules stand on it, and in what order. Names and icons come
// from services/Pills.qml, the one catalogue.
Section {
    id: tab


    // ── Bar layout editor ───────────────────────────────────────────────
    // Names and icons come from services/Pills.qml, the one catalogue.
    // Everything the catalogue says you may arrange on the bar.
    readonly property var allPills: Services.Pills.arrangeable
    // Whatever is in no section at all
    readonly property var availablePills:
        tab.allPills.filter(id => Services.Prefs.barSectionOf(id) === "")

    // Which pill is in the air, so its own zone can be lifted above the others
    property string draggingId: ""
    // …and how wide it is, so the gap a plate offers is the size of the pill
    // itself. A 3 px caret gave you an index; it never said what was about to
    // be there.
    property real draggingW: 0

    // A chip that can be picked up. The slot keeps its place in the row while
    // only the face travels, so the layout underneath never gets disturbed and
    // a drop that lands nowhere just snaps home.
    component PillChip: Item {
        id: slot
        property string pillId: ""
        // How far this chip steps aside to open the gap the drop preview is
        // standing in. A visual shift and not a place in the model: inserting a
        // real placeholder rebuilds the chip under the pointer and wedges the
        // drag that is holding it.
        property real shift: 0
        // Widest the chip may get before its name starts eliding. A third of
        // the drawer is narrow enough that "Notifications" plus an icon can
        // outgrow it, and a chip wider than the plate it sits in wraps to a
        // line of its own and still hangs off the edge. 0 means unbounded.
        property real maxWidth: 0
        width: face.width
        height: 28
        transform: Translate { x: slot.shift }
        Behavior on shift {
            NumberAnimation { duration: Services.Sizes.msStandard; easing.type: Services.Sizes.easeOut }
        }

        Rectangle {
            id: face
            // Built from the two texts' NATURAL widths, never from the Row's
            // laid-out one: the label's width is derived from this, so reading
            // the Row back here would be a binding loop.
            implicitWidth: gly.implicitWidth + chipInner.spacing + lab.implicitWidth + 18
            width: slot.maxWidth > 0 ? Math.min(implicitWidth, slot.maxWidth) : implicitWidth
            height: 28
            radius: Services.Sizes.innerR
            z: dragArea.drag.active ? 100 : 0
            color: dragArea.drag.active ? Services.Colors.ghost : Services.Colors.fillRest
            Behavior on color { ColorAnimation { duration: Services.Sizes.msMicro } }
            scale: dragArea.drag.active
                ? 1.0 : Services.Sizes.hoverScale(hoverArea.containsMouse, hoverArea.pressed)
            Behavior on scale { NumberAnimation { duration: Services.Sizes.pillHoverMs; easing.type: Services.Sizes.easeOut } }

            // What the DropArea reads on the other end. `Drag.mimeData` is
            // only ever filled for Drag.Automatic (a real cross-process drag);
            // an internal QML drag carries the item itself and nothing else,
            // so the id has to live on the item as a plain property.
            property string pillId: slot.pillId

            Drag.active: dragArea.drag.active
            Drag.dragType: Drag.Internal
            Drag.hotSpot.x: width / 2
            Drag.hotSpot.y: height / 2

            Behavior on x { enabled: !dragArea.drag.active; NumberAnimation { duration: Services.Sizes.msMicro; easing.type: Services.Sizes.easeOut } }
            Behavior on y { enabled: !dragArea.drag.active; NumberAnimation { duration: Services.Sizes.msMicro; easing.type: Services.Sizes.easeOut } }

            // Icon first, then the name: the same face the pill wears on the
            // utility pill, so a chip in this editor is recognisable as the
            // thing it will become rather than a word in a list.
            Row {
                id: chipInner
                anchors.centerIn: parent
                spacing: 6

                Text {
                    id: gly
                    anchors.verticalCenter: parent.verticalCenter
                    text: Services.Pills.glyph(slot.pillId)
                    color: dragArea.drag.active ? Services.Colors.accentText : Services.Colors.ghost
                    font.pixelSize: 14
                    font.family: "Material Symbols Rounded"
                }
                Text {
                    id: lab
                    anchors.verticalCenter: parent.verticalCenter
                    // The icon never elides -- it is what identifies the pill
                    // once the name is cut. Only the name gives way.
                    width: Math.min(implicitWidth,
                                    Math.max(0, face.width - 18 - gly.width - chipInner.spacing))
                    elide: Text.ElideRight
                    text: Services.Pills.label(slot.pillId)
                    color: dragArea.drag.active ? Services.Colors.accentText : Services.Colors.snow
                    font.pixelSize: Services.Sizes.fsBody
                    font.family: "JetBrainsMono NF"
                }
            }

            MouseArea {
                id: hoverArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: dragArea.drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
            }
            MouseArea {
                id: dragArea
                anchors.fill: parent
                drag.target: face
                drag.smoothed: false
                onPressed: {
                    tab.draggingId = slot.pillId
                    tab.draggingW = face.width
                }
                onReleased: {
                    // Clear the drag flag BEFORE dropping: a successful drop rewrites the
                    // layout, which destroys this delegate mid-handler, so anything after the
                    // drop throws and leaves the zone stuck in its raised state.
                    tab.draggingId = ""
                    face.Drag.drop()
                    // Only reached when nothing caught it; then it snaps home.
                    if (face) { face.x = 0; face.y = 0 }
                }
            }
        }
    }

    // One of the four places a pill can be. The three bar sections stand side
    // by side in the order they occupy the bar, so the editor is a picture of
    // the bar and not a stack of lists. Available sits underneath, off the bar
    // entirely -- which is exactly what it means.
    component Zone: ColumnLayout {
        id: zone
        property string section: ""
        property string caption: ""
        property var ids: []
        // Every plate is the same size, always. One that grew with its
        // contents made the three bar sections different heights depending on
        // what happened to be in them, and the row stopped reading as three
        // equal places you may put a pill.
        readonly property int plateH: 3 * 28 + 2 * 6 + 20
        // Slot the chip in the air would drop into; -1 when nothing is over
        // this plate.
        property int dropIndex: -1
        Layout.fillWidth: true
        // Equal thirds when three of these share a RowLayout: fillWidth alone
        // hands the wider zone more room and the picture stops being to scale.
        Layout.preferredWidth: 1
        spacing: 5
        // Lift the zone holding the chip being dragged, so its face is not
        // drawn underneath a neighbouring plate on the way out.
        z: (tab.draggingId !== "" && zone.ids.indexOf(tab.draggingId) !== -1) ? 10 : 0

        Text {
            text: zone.caption
            color: Services.Colors.ash
            font.pixelSize: Services.Sizes.fsMeta
            font.bold: true
            font.family: "JetBrainsMono NF"
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: zone.plateH
            // No clip, however tempting: the chip being dragged is a child of
            // this plate until it is dropped, and clipping would cut it off at
            // the edge on the way out.
            radius: Services.Sizes.cardR
            color: dropZone.containsDrag ? Services.Colors.fillRest
                                         : Services.Colors.fillInset
            border.color: dropZone.containsDrag ? Services.Colors.fillSunken : "transparent"
            border.width: 1
            Behavior on color { ColorAnimation { duration: Services.Sizes.msMicro } }

            DropArea {
                id: dropZone
                anchors.fill: parent
                // Tracked while the chip is still in the air, not only on
                // release: dropping used to be blind -- you let go and only
                // then found out which side of its neighbour it had landed on.
                onPositionChanged: function(drag) {
                    zone.dropIndex = zone.indexAt(drag.x, drag.y)
                }
                onEntered: function(drag) {
                    zone.dropIndex = zone.indexAt(drag.x, drag.y)
                }
                onExited: zone.dropIndex = -1
                onDropped: function(drop) {
                    zone.dropIndex = -1
                    const id = drop.source ? (drop.source.pillId || "") : ""
                    if (id === "") return
                    Services.Prefs.moveBarPill(id, zone.section, zone.indexAt(drop.x, drop.y))
                    drop.accept()
                }
            }

            // Where it would go if you let go now: a caret standing in the gap
            // the chip would open. It slides between slots rather than
            // blinking from one to the next, so the eye follows it instead of
            // having to find it again after every move.
            Rectangle {
                id: caret
                visible: dropZone.containsDrag && zone.dropIndex >= 0
                // The pill's own size, straddling the gap it would drop into.
                // Drawn OVER the row, never inserted into it: a placeholder in
                // the model rebuilds the chip under the pointer, and killing
                // the drag's own target wedges the editor.
                z: 5
                // Never wider than the room it is previewing, and never past
                // the plate's own padding: centred on the gap it used to hang
                // half a pill outside the plate and lie across its neighbours.
                width: Math.min(chipFlow.width, Math.max(28, tab.draggingW))
                height: 28
                radius: Services.Sizes.innerR
                // A ghost, not a plate: it stands in a gap it has to share with
                // the chips already there until the drop actually moves them.
                color: Services.Colors.fillLine
                border.color: Services.Colors.ghostAlpha(0.55)
                border.width: 1
                // It opens the gap to its RIGHT, which is where the pill goes,
                // and stays inside the flow whatever the pointer does.
                x: Math.max(chipFlow.x,
                            Math.min(chipFlow.x + chipFlow.width - width,
                                     zone.caretX(zone.dropIndex) + 1))
                y: zone.caretY(zone.dropIndex) - 3
                // Only while it is already up: on the frame it appears, its
                // position comes from wherever it was left in some other
                // plate, and animating that would fly it across the editor
                // before settling where it actually belongs.
                Behavior on x { enabled: caret.visible; SmoothedAnimation { duration: Services.Sizes.msMicro } }
                Behavior on y { enabled: caret.visible; SmoothedAnimation { duration: Services.Sizes.msMicro } }
            }

            Flow {
                id: chipFlow
                // A third of the drawer is too narrow for a single row, so the
                // chips wrap. Order is reading order -- left to right, then
                // down -- and that is the order they take on the bar.
                x: 10
                y: 10
                width: parent.width - 20
                spacing: 6

                Repeater {
                    model: zone.ids
                    delegate: PillChip {
                        required property var modelData
                        required property int index
                        pillId: modelData
                        maxWidth: chipFlow.width
                        // Everything from the drop point on slides right by the
                        // width of what is about to land, plus the gap it will
                        // want -- so the preview sits in real room instead of
                        // lying across its neighbours.
                        shift: (dropZone.containsDrag && zone.dropIndex >= 0
                                && index >= zone.dropIndex)
                               ? Math.min(caret.width + chipFlow.spacing,
                                          zone.slackFrom(zone.dropIndex)) : 0
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: zone.ids.length === 0
                text: "drop here"
                color: Services.Colors.ash
                font.pixelSize: Services.Sizes.fsMeta
                font.family: "JetBrainsMono NF"
            }
        }

        // Where in the flow a drop at (px, py) belongs, in reading order. Rows have
        // to be settled first: with wrapping, x alone puts a drop at the end of the
        // last row before everything on the rows under it.
        function indexAt(px, py) {
            const kids = chipFlow.children
            let n = 0
            for (let i = 0; i < kids.length; i++) {
                const c = kids[i]
                if (!c || c.width === undefined || c.width === 0) continue
                const cx = chipFlow.x + c.x
                const cy = chipFlow.y + c.y
                if (py < cy) return n
                if (py <= cy + c.height && px < cx + c.width / 2) return n
                n++
            }
            return n
        }

        // The chip that would end up AFTER the drop, or null when the drop
        // goes at the very end. The Repeater is itself a child of the flow and
        // has no size, so it is skipped the same way indexAt skips it.
        function chipAt(n) {
            const kids = chipFlow.children
            let seen = 0
            for (let i = 0; i < kids.length; i++) {
                const c = kids[i]
                if (!c || c.width === undefined || c.width === 0) continue
                if (seen === n) return c
                seen++
            }
            return null
        }
        function lastChip() { return zone.chipAt(zone.ids.length - 1) }

        // How far the chips from `n` on can step aside. The tightest of them
        // decides: a Flow lays out once and a transform does not re-wrap it, so
        // a shift wider than what the narrowest row has left would push that
        // row out of the plate instead of onto the next line. Measured per
        // chip, because the last one may be sitting on a half-empty row while
        // the one above it is against the edge.
        function slackFrom(n) {
            const kids = chipFlow.children
            let seen = 0
            let room = chipFlow.width
            for (let i = 0; i < kids.length; i++) {
                const c = kids[i]
                if (!c || c.width === undefined || c.width === 0) continue
                if (seen >= n) room = Math.min(room, chipFlow.width - (c.x + c.width))
                seen++
            }
            return Math.max(0, room)
        }

        // The caret stands in the gap: half the flow's spacing before the chip
        // it would push along, or past the end of the last one. An empty plate
        // has neither, so it sits where the first chip would start.
        function caretX(n) {
            const c = zone.chipAt(n)
            if (c) return chipFlow.x + c.x - chipFlow.spacing / 2 - 1
            const last = zone.lastChip()
            if (last) return chipFlow.x + last.x + last.width + chipFlow.spacing / 2 - 1
            return chipFlow.x
        }
        function caretY(n) {
            const c = zone.chipAt(n) || zone.lastChip()
            if (c) return chipFlow.y + c.y + (c.height - 22) / 2
            return chipFlow.y + 3
        }
    }

    Card {
        title: "Layout"

        // On the bar, in bar order.
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Zone { section: "left";   caption: "LEFT";   ids: Services.Prefs.barPills("left") }
            Zone { section: "centre"; caption: "CENTRE"; ids: Services.Prefs.barPills("centre") }
            Zone { section: "right";  caption: "RIGHT";  ids: Services.Prefs.barPills("right") }
        }

        // Off the bar. Full width, under everything, because it belongs nowhere.
        Zone {
            section: ""
            caption: "AVAILABLE"
            ids: tab.availablePills
            Layout.topMargin: 4
        }

        Item { Layout.preferredHeight: 2 }

        Text {
            text: "Reset to the shipped arrangement"
            color: resetHover.containsMouse ? Services.Colors.snow : Services.Colors.ash
            font.pixelSize: Services.Sizes.fsMeta
            font.family: "JetBrainsMono NF"
            Behavior on color { ColorAnimation { duration: Services.Sizes.msMicro } }
            MouseArea {
                id: resetHover
                anchors.fill: parent
                anchors.margins: -4
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Services.Prefs.resetBarLayout()
            }
        }
    }
}
