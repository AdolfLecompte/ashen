import Quickshell
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "root:/services" as Services
import "root:/modules/widgets" as Widgets
import "root:/modules/settings/components"

// The furniture on the wallpaper: the dock, which widgets are out, what shape
// each one wears, and how they land when you drop them. Was BarDesktopPage,
// back when the bar and the desktop shared a tab.
Section {
    id: tab

    // ── Desktop widgets ──────────────────────────────────────
    // Turning one on, choosing its shape and putting it somewhere all happen
    // on the desktop itself now -- this card is the door, not the controls.
    Card {
        glyph: "\ue1bc"
        title: Services.I18n.t("settings.tab.desktop")

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            RowGlyph { glyph: "\ue1bd" }

            ColumnLayout {
                spacing: 0
                Text {
                    textFormat: Text.PlainText
                    text: Services.I18n.t("settings.desktop.widgets")
                    color: Services.Colors.snow
                    font.pixelSize: Services.Sizes.fsInput
                    font.family: "JetBrainsMono NF"
                }
                Text {
                    textFormat: Text.PlainText
                    // Read off the live layout, so it follows a wallpaper
                    // profile arriving as much as your own switches.
                    text: {
                        const cat = Services.Desktop.catalogue.filter(w => !w.multi)
                        let on = 0
                        for (const w of cat) if (Services.Desktop.shown(w.id)) on++
                        const pics = Services.Desktop.idsOf("image").length
                        return Services.I18n.t("settings.desktop.count", { n: on, m: cat.length })
                             + (pics > 0 ? "  \u00b7  " + Services.I18n.t(pics === 1 ? "settings.desktop.picture" : "settings.desktop.pictures", { n: pics }) : "")
                    }
                    color: Services.Colors.ash
                    font.pixelSize: Services.Sizes.fsMeta
                    font.family: "JetBrainsMono NF"
                }
            }
            // Without this the button sits against its own name instead of
            // the edge of the card.
            Item { Layout.fillWidth: true }
            ActionBtn {
                label: Services.Desktop.editMode ? Services.I18n.t("common.done") : Services.I18n.t("settings.desktop.arrange")
                accent: Services.Desktop.editMode
                onGo: {
                    Services.Desktop.editMode = !Services.Desktop.editMode
                    // The drawer covers the half of the screen the widgets are
                    // on; arranging them behind it is arranging them blind.
                    if (Services.Desktop.editMode) Services.AppState.settingsVisible = false
                }
            }
        }

    }


    Item { Layout.preferredHeight: 8 }

    // ── Dock ─────────────────────────────────────────────────
    // The other surface that stands on an edge. It lives beside the desktop
    // rather than beside the bar because, like the widgets, it is furniture the
    // windows have to live with rather than part of the bar's own shape.
    Card {
        glyph: "\uf7e6"   // dock_to_bottom
        title: Services.I18n.t("settings.dock.title")

        // First, because everything under it is moot if this is off.
        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            RowGlyph { glyph: "\ue5d3" }        // apps
            Text {
                textFormat: Text.PlainText
                Layout.fillWidth: true
                text: Services.I18n.t("settings.dock.enable")
                color: Services.Colors.snow
                font.pixelSize: Services.Sizes.fsInput
                font.family: "JetBrainsMono NF"
            }
            Toggle {
                checked: Services.Prefs.dockEnabled
                onToggled: Services.Prefs.dockEnabled = !Services.Prefs.dockEnabled
            }
        }

        SectionLabel { text: Services.I18n.t("settings.bar.position") }

        // Never the bar's own edge: two surfaces claiming one edge is a fight
        // neither wins, and the dock is the one that can move. SHOWN and
        // greyed, not dropped: a picker that silently offers three of the four
        // sides reads as a missing feature, and the one side that is missing is
        // whichever one the bar happens to be on today -- so the answer changes
        // under you. Dimmed, the row says why. Same rule the power profiles
        // follow: an option's absence is information too.
        Segmented {
            options: ["top", "bottom", "left", "right"].map(e => ({
                id: e,
                label: Services.I18n.t("settings.bar." + e),
                available: e !== Services.Sizes.barPosition
            }))
            current: Services.Prefs.dockEdge
            onPicked: id => Services.Prefs.dockEdge = id
        }

        Text {
            textFormat: Text.PlainText
            Layout.fillWidth: true
            text: Services.I18n.t("settings.dock.barEdge")
            color: Services.Colors.ash
            font.pixelSize: Services.Sizes.fsMeta
            font.family: "JetBrainsMono NF"
            wrapMode: Text.WordWrap
        }

        // How the dock shows: always, only when called, or by itself.
        Segmented {
            Layout.topMargin: 4
            stacked: true
            options: [
                { id: "fixed", icon: "\uf7e6", label: Services.I18n.t("settings.dock.fixed") },   // dock_to_bottom
                { id: "hide", icon: "\ue4f7", label: Services.I18n.t("settings.dock.hide") },     // web_asset_off
                { id: "smart", icon: "\ue65f", label: Services.I18n.t("settings.dock.smart") }    // auto_awesome
            ]
            current: !Services.Prefs.dockAutohide ? "fixed" : Services.Prefs.dockSmart ? "smart" : "hide"
            onPicked: id => {
                Services.Prefs.dockAutohide = id !== "fixed"
                Services.Prefs.dockSmart = id === "smart"
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            RowGlyph { glyph: "\ue8e8" }        // format_size
            Text {
                textFormat: Text.PlainText
                Layout.fillWidth: true
                text: Services.I18n.t("settings.dock.size")
                color: Services.Colors.snow
                font.pixelSize: Services.Sizes.fsInput
                font.family: "JetBrainsMono NF"
            }
            StepBtn {
                glyph: "\ue15b"
                onClicked: Services.Prefs.dockIconSize = Math.max(28, Services.Prefs.dockIconSize - 4)
            }
            Text {
                textFormat: Text.PlainText
                Layout.preferredWidth: 34
                horizontalAlignment: Text.AlignHCenter
                text: Services.Prefs.dockIconSize
                color: Services.Colors.ghost
                font.pixelSize: Services.Sizes.fsInput
                font.bold: true
                font.family: "JetBrainsMono NF"
            }
            StepBtn {
                glyph: "\ue145"
                onClicked: Services.Prefs.dockIconSize = Math.min(72, Services.Prefs.dockIconSize + 4)
            }
        }

        // ── What is pinned ───────────────────────────────────────────
        // Right-clicking the dock is how you pin what is already open. This is
        // the other half: the applications that are NOT open, which you cannot
        // right-click because they are not there to click.
        SectionLabel { text: Services.I18n.t("settings.dock.apps"); Layout.topMargin: 4 }

        // Dragged into place, no arrows: the rows stand at fixed slots and
        // step aside for the one being carried. Let go over the drop zone
        // below and it is unpinned.
        Item {
            id: pinList
            Layout.fillWidth: true
            readonly property int rowH: 38
            readonly property int count: Services.Prefs.dockPinList.length
            Layout.preferredHeight: pinList.count * pinList.rowH
            // The order on screen: the one the drag proposes, else the saved one.
            // Derived, never a Qt.binding made in a row: the rows are rebuilt
            // on every move, and a binding born in one dies with it -- the
            // list kept the old order and the next drag grabbed the wrong row.
            property var proposed: null
            readonly property var order: pinList.proposed || Services.Prefs.dockPinList
            property string carried: ""
            property bool overDrop: false

            Repeater {
                model: Services.Prefs.dockPinList
                delegate: Item {
                    id: pinRow
                    required property var modelData
                    required property int index
                    // byId first, byClass after: a pin made by right-clicking a
                    // running window is stored under what Hyprland calls it, which
                    // is not always the .desktop id -- `codium` is `vscodium`.
                    readonly property var entry: Services.Apps.byId(pinRow.modelData)
                                              || Services.Apps.byClass(pinRow.modelData)
                    readonly property bool carried: pinList.carried === pinRow.modelData
                    width: pinList.width
                    height: pinList.rowH
                    z: pinRow.carried ? 2 : 1
                    property real dragY: 0
                    y: pinRow.carried ? pinRow.dragY : pinList.order.indexOf(pinRow.modelData) * pinList.rowH
                    Behavior on y {
                        enabled: !pinRow.carried
                        Widgets.Anim { speed: Services.Sizes.msMicro }
                    }
                    opacity: pinRow.carried && pinList.overDrop ? 0.45 : 1
                    scale: pinRow.carried ? 1.02 : 1
                    Behavior on scale { Widgets.Anim { speed: Services.Sizes.msMicro } }

                    // The one being carried gets a plate, so it reads as lifted.
                    Rectangle {
                        anchors.fill: parent
                        radius: Services.Sizes.innerR
                        color: Services.Colors.fillRest
                        visible: pinRow.carried
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 4
                        anchors.rightMargin: 4
                        spacing: 10

                        Text {
                            textFormat: Text.PlainText
                            text: "\ue945"
                            color: grab.containsMouse || pinRow.carried ? Services.Colors.ghost : Services.Colors.ash
                            font.pixelSize: 18
                            font.family: "Material Symbols Rounded"
                        }
                        // A pin whose .desktop is gone keeps its slot with the generic icon.
                        Widgets.AppIcon {
                            Layout.preferredWidth: 22
                            Layout.preferredHeight: 22
                            icon: pinRow.entry ? pinRow.entry.icon : ""
                        }
                        Text {
                            textFormat: Text.PlainText
                            Layout.fillWidth: true
                            text: pinRow.entry ? pinRow.entry.name : pinRow.modelData
                            color: !pinRow.entry ? Services.Colors.ash
                                 : grab.containsMouse || pinRow.carried ? Services.Colors.snow : Services.Colors.mist
                            elide: Text.ElideRight
                            font.pixelSize: Services.Sizes.fsInput
                            font.family: "JetBrainsMono NF"
                        }
                    }

                    MouseArea {
                        id: grab
                        anchors.fill: parent
                        hoverEnabled: true
                        // The page scrolls on a vertical drag too; this one is ours.
                        preventStealing: true
                        cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                        property real grabY: 0
                        onPressed: mouse => {
                            grab.grabY = mouse.y
                            pinRow.dragY = pinRow.y
                            pinList.carried = pinRow.modelData
                        }
                        onPositionChanged: mouse => {
                            if (!pressed) return
                            const top = pinRow.mapToItem(pinList, 0, mouse.y).y - grab.grabY
                            pinRow.dragY = top
                            const pt = pinRow.mapToItem(dropZone, mouse.x, mouse.y)
                            pinList.overDrop = dropZone.contains(Qt.point(pt.x, pt.y))
                            const slot = Math.max(0, Math.min(pinList.count - 1, Math.round(top / pinList.rowH)))
                            let next = Services.Prefs.dockPinList.filter(x => x !== pinRow.modelData)
                            next.splice(slot, 0, pinRow.modelData)
                            pinList.proposed = next
                        }
                        // State first, the list after: changing the pins rebuilds
                        // every row, this one included, and whatever came after
                        // it in here never ran -- the new row was born carried,
                        // at the top, over the first one.
                        onReleased: {
                            const id = pinRow.modelData
                            const unpin = pinList.overDrop
                            const to = pinList.order.indexOf(id)
                            pinList.carried = ""
                            pinList.overDrop = false
                            pinList.proposed = null
                            Qt.callLater(() => unpin ? Services.Prefs.dockUnpin(id)
                                                     : Services.Prefs.dockMovePin(id, to))
                        }
                        onCanceled: {
                            pinList.carried = ""
                            pinList.overDrop = false
                            pinList.proposed = null
                        }
                    }
                }
            }
        }

        Text {
            textFormat: Text.PlainText
            Layout.fillWidth: true
            visible: Services.Prefs.dockPinList.length === 0
            text: Services.Voice.pick("dock.empty")
            color: Services.Colors.ash
            font.pixelSize: Services.Sizes.fsMeta
            font.family: "JetBrainsMono NF"
        }

        // ── Adding one ───────────────────────────────────────────────
        // A search rather than the whole list: there are 1300 packages on this
        // machine and a scroll of every .desktop is not a chooser.
        // Where a carried pin is let go to unpin it. It stands in the search
        // field's place, since nobody types while dragging.
        Rectangle {
            id: dropZone
            Layout.fillWidth: true
            Layout.topMargin: 4
            Layout.preferredHeight: appQuery.implicitHeight + 8
            visible: pinList.carried !== ""
            radius: Services.Sizes.innerR
            color: "transparent"
            border.width: 1
            border.color: pinList.overDrop ? Services.Colors.ghost : Services.Colors.fillOutline
            Row {
                anchors.centerIn: parent
                spacing: 8
                Text {
                    textFormat: Text.PlainText
                    anchors.verticalCenter: parent.verticalCenter
                    text: "\ue872"
                    color: pinList.overDrop ? Services.Colors.ghost : Services.Colors.mist
                    font.pixelSize: 18
                    font.family: "Material Symbols Rounded"
                }
                Text {
                    textFormat: Text.PlainText
                    anchors.verticalCenter: parent.verticalCenter
                    text: Services.I18n.t("settings.dock.dropUnpin")
                    color: pinList.overDrop ? Services.Colors.snow : Services.Colors.mist
                    font.pixelSize: Services.Sizes.fsInput
                    font.family: "JetBrainsMono NF"
                }
            }
        }
        TextField {
            visible: pinList.carried === ""
            id: appQuery
            Keys.onPressed: e => { if (Services.Readline.handle(e, appQuery)) e.accepted = true }
            Layout.fillWidth: true
            Layout.topMargin: 4
            placeholderText: Services.I18n.t("settings.dock.search")
            placeholderTextColor: Services.Colors.ash
            color: Services.Colors.snow
            font.pixelSize: Services.Sizes.fsInput
            font.family: "JetBrainsMono NF"
            background: Rectangle {
                radius: Services.Sizes.innerR
                color: Services.Colors.fillRest
                border.width: appQuery.activeFocus ? 1 : 0
                border.color: Services.Colors.ghost
            }
        }

        Repeater {
            // Only when asked: an empty query listing everything would bury the
            // rest of the card under the application menu.
            model: {
                const q = appQuery.text.trim().toLowerCase()
                if (q === "") return []
                const pins = Services.Prefs.dockPinList
                return Services.Apps.all
                    .filter(a => !a.noDisplay && a.id !== "" && pins.indexOf(a.id) === -1
                                 && a.name.toLowerCase().indexOf(q) !== -1)
                    .slice(0, 6)
            }
            delegate: RowLayout {
                id: hit
                required property var modelData
                Layout.fillWidth: true
                spacing: 10

                Widgets.AppIcon {
                    Layout.preferredWidth: 20
                    Layout.preferredHeight: 20
                    icon: hit.modelData.icon || ""
                }
                Text {
                    textFormat: Text.PlainText
                    Layout.fillWidth: true
                    text: hit.modelData.name
                    color: hitArea.hovered ? Services.Colors.snow : Services.Colors.mist
                    elide: Text.ElideRight
                    font.pixelSize: Services.Sizes.fsInput
                    font.family: "JetBrainsMono NF"
                    Behavior on color { Widgets.ColorAnim { speed: Services.Sizes.msMicro } }
                }
                StepBtn {
                    glyph: "\ue145"        // add
                    onClicked: {
                        Services.Prefs.dockPin(hit.modelData.id)
                        appQuery.text = ""
                    }
                }
                // A handler, not a MouseArea: this only listens for the pointer,
                // and an anchored item inside a RowLayout is undefined behaviour
                // Qt warns about on every build of the list.
                HoverHandler { id: hitArea }
            }
        }

        Text {
            textFormat: Text.PlainText
            Layout.fillWidth: true
            text: Services.I18n.t("settings.dock.hint")
            color: Services.Colors.ash
            wrapMode: Text.WordWrap
            font.pixelSize: Services.Sizes.fsMeta
            font.family: "JetBrainsMono NF"
        }

    }

    Item { Layout.preferredHeight: 8 }

    // ── Past the applications ────────────────────────────────────
    // The Layout editor's language, laid out the same way: what is in the
    // dock on top, everything else under it, chips carried between the two
    // (or clicked across). A pill may stand on the bar and in the dock at
    // once; from the dock its panel arrives from the edge.
    Card {
        glyph: "\ue11f"
        title: Services.I18n.t("settings.dock.pills")

        SideRow { pref: "dockPillsSide" }
        DockZone {
            group: "pill"; side: "in"
            caption: Services.I18n.t("settings.dock.inDock")
            items: Services.DockItems.pills.map(id => ({ key: id, glyph: Services.Pills.glyph(id), label: Services.Pills.label(id) }))
            onMove: key => Services.DockItems.togglePill(key)
        }
        DockZone {
            group: "pill"; side: "out"
            caption: Services.I18n.t("settings.layout.available")
            items: Services.DockItems.dockablePills.filter(id => !Services.DockItems.hasPill(id))
                .map(id => ({ key: id, glyph: Services.Pills.glyph(id), label: Services.Pills.label(id) }))
            onMove: key => Services.DockItems.togglePill(key)
        }
    }

    Item { Layout.preferredHeight: 8 }

    // Shell actions and commands of your own. A command dropped on Available
    // is gone: there is nowhere else for it to wait.
    Card {
        glyph: "\uea0b"
        title: Services.I18n.t("settings.dock.links")

        SideRow { pref: "dockLinksSide" }
        DockZone {
            group: "link"; side: "in"
            caption: Services.I18n.t("settings.dock.inDock")
            items: Services.DockItems.links.map((l, i) => ({
                key: l.a ? "a:" + l.a : "i:" + i,
                glyph: Services.DockItems.linkGlyph(l),
                label: Services.DockItems.linkLabel(l) }))
            onMove: key => {
                if (key.startsWith("a:")) Services.DockItems.toggleAction(key.slice(2))
                else Services.DockItems.removeLink(parseInt(key.slice(2)))
            }
        }
        DockZone {
            group: "link"; side: "out"
            caption: Services.I18n.t("settings.layout.available")
            items: Services.DockItems.actions.filter(a => !Services.DockItems.hasAction(a.id))
                .map(a => ({ key: "a:" + a.id, glyph: a.glyph, label: Services.I18n.t("dock.action." + a.id) }))
            onMove: key => Services.DockItems.toggleAction(key.slice(2))
        }

        // A command of your own: a glyph (click to change it), a name, the line.
        SectionLabel { text: Services.I18n.t("settings.dock.custom"); Layout.topMargin: 6 }
        RowLayout {
            id: newLink
            Layout.fillWidth: true
            spacing: 10
            property int glyphAt: 0
            // The glyph it will wear, on the same filled square as a chip.
            Rectangle {
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34
                radius: Services.Sizes.innerR
                color: Services.Colors.fillRest
                scale: Services.Sizes.hoverScale(glyphArea.containsMouse, glyphArea.pressed)
                Behavior on scale { Widgets.Anim { speed: Services.Sizes.msMicro } }
                Text {
                    textFormat: Text.PlainText
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: 1
                    text: Services.DockItems.linkGlyphs[newLink.glyphAt]
                    color: glyphArea.containsMouse ? Services.Colors.snow : Services.Colors.ghost
                    font.pixelSize: 18
                    font.family: "Material Symbols Rounded"
                }
                MouseArea {
                    id: glyphArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: newLink.glyphAt = (newLink.glyphAt + 1) % Services.DockItems.linkGlyphs.length
                }
            }
            TextField {
                id: linkName
                Layout.preferredWidth: 140
                Layout.preferredHeight: 34
                placeholderText: Services.I18n.t("settings.dock.linkName")
                placeholderTextColor: Services.Colors.ash
                color: Services.Colors.snow
                leftPadding: 10
                font.pixelSize: Services.Sizes.fsInput
                font.family: "JetBrainsMono NF"
                Keys.onPressed: e => { if (Services.Readline.handle(e, linkName)) e.accepted = true }
                background: Rectangle {
                    radius: Services.Sizes.innerR
                    color: Services.Colors.fillRest
                    border.width: linkName.activeFocus ? 1 : 0
                    border.color: Services.Colors.ghost
                }
            }
            TextField {
                id: linkCmd
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                placeholderText: Services.I18n.t("settings.dock.linkCmd")
                placeholderTextColor: Services.Colors.ash
                color: Services.Colors.snow
                leftPadding: 10
                font.pixelSize: Services.Sizes.fsInput
                font.family: "JetBrainsMono NF"
                Keys.onPressed: e => { if (Services.Readline.handle(e, linkCmd)) e.accepted = true }
                onAccepted: newLink.add()
                background: Rectangle {
                    radius: Services.Sizes.innerR
                    color: Services.Colors.fillRest
                    border.width: linkCmd.activeFocus ? 1 : 0
                    border.color: Services.Colors.ghost
                }
            }
            StepBtn {
                glyph: "\ue145"        // add
                onClicked: newLink.add()
            }
            function add() {
                if (linkCmd.text.trim() === "") return
                Services.DockItems.addCommand(linkName.text, linkCmd.text,
                                              Services.DockItems.linkGlyphs[newLink.glyphAt])
                linkName.text = ""
                linkCmd.text = ""
            }
        }
    }

    // Which side of the apps a group stands on; the arrows follow the dock's
    // own axis.
    component SideRow: Segmented {
        property string pref: ""
        options: [
            { id: "before", icon: tab.dockVertical ? "\ue5d8" : "\ue5c4", label: Services.I18n.t("settings.dock.before") },
            { id: "after", icon: tab.dockVertical ? "\ue5db" : "\ue5c8", label: Services.I18n.t("settings.dock.after") }
        ]
        current: Services.Prefs[pref]
        onPicked: id => Services.Prefs[pref] = id
    }

    // One side of a dock editor: a sunk plate of chips, like a Layout zone.
    // `move` sends a chip to the other side: clicked, or carried over and
    // dropped there.
    component DockZone: ColumnLayout {
        id: zone
        property string group: ""
        property string side: ""
        property string caption: ""
        property var items: []
        signal move(string key)
        Layout.fillWidth: true
        Layout.preferredWidth: 1
        Layout.alignment: Qt.AlignTop
        spacing: 5
        z: tab.dockDragFrom === zone.group + ":" + zone.side ? 10 : 0

        Text {
            textFormat: Text.PlainText
            text: zone.caption
            color: Services.Colors.ash
            font.pixelSize: Services.Sizes.fsMeta
            font.bold: true
            font.family: "JetBrainsMono NF"
        }
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(28 + 20, zoneFlow.implicitHeight + 20)
            radius: Services.Sizes.cardR
            color: zoneDrop.containsDrag ? Services.Colors.fillRest : Services.Colors.fillInset
            border.color: zoneDrop.containsDrag ? Services.Colors.fillSunken : "transparent"
            border.width: 1
            Behavior on color { Widgets.ColorAnim { speed: Services.Sizes.msMicro } }

            DropArea {
                id: zoneDrop
                anchors.fill: parent
                keys: [zone.group]
                onDropped: drop => {
                    const src = drop.source
                    if (!src || src.fromSide === zone.side || !src.sendAway) return
                    src.sendAway(src.key)
                    drop.accept()
                }
            }
            Flow {
                id: zoneFlow
                x: 10; y: 10
                width: parent.width - 20
                spacing: 6
                Repeater {
                    model: zone.items
                    delegate: ZoneChip {
                        required property var modelData
                        key: modelData.key
                        glyph: modelData.glyph
                        label: modelData.label
                        group: zone.group
                        fromSide: zone.side
                        maxWidth: zoneFlow.width
                        sendAway: k => zone.move(k)
                    }
                }
            }
            Text {
                textFormat: Text.PlainText
                anchors.centerIn: parent
                visible: zone.items.length === 0
                text: Services.I18n.t("settings.layout.drop")
                color: Services.Colors.ash
                font.pixelSize: Services.Sizes.fsMeta
                font.family: "JetBrainsMono NF"
            }
        }
    }

    // The dock's real edge is never the bar's (see Dock.qml).
    readonly property bool dockVertical: {
        const e = Services.Prefs.dockEdge === Services.Sizes.barPosition
            ? (Services.Sizes.barPosition === "left" || Services.Sizes.barPosition === "right" ? "left" : "top")
            : Services.Prefs.dockEdge
        return e === "left" || e === "right"
    }

    // Which side a chip is being carried out of, so that plate draws on top.
    property string dockDragFrom: ""

    // The Layout editor's chip: icon then name, filled at rest, accent while
    // carried. A click sends it to the other side.
    component ZoneChip: Item {
        id: slot
        property string key: ""
        property string glyph: ""
        property string label: ""
        property string group: ""
        property string fromSide: ""
        property real maxWidth: 0
        property var sendAway: null
        width: face.width
        height: 28

        Rectangle {
            id: face
            implicitWidth: gly.implicitWidth + chipInner.spacing + lab.implicitWidth + 18
            width: slot.maxWidth > 0 ? Math.min(implicitWidth, slot.maxWidth) : implicitWidth
            height: 28
            radius: Services.Sizes.innerR
            z: dragArea.drag.active ? 100 : 0
            color: dragArea.drag.active ? Services.Colors.ghost : Services.Colors.fillRest
            Behavior on color { Widgets.ColorAnim { speed: Services.Sizes.msMicro } }
            scale: dragArea.drag.active ? 1.0 : Services.Sizes.hoverScale(dragArea.containsMouse, dragArea.pressed)
            Behavior on scale { NumberAnimation { duration: Services.Sizes.pillHoverMs; easing.type: Services.Sizes.easeOut } }

            // What the other plate reads on the drop.
            property string key: slot.key
            property string fromSide: slot.fromSide
            property var sendAway: slot.sendAway
            Drag.active: dragArea.drag.active
            Drag.dragType: Drag.Internal
            Drag.keys: [slot.group]
            Drag.hotSpot.x: width / 2
            Drag.hotSpot.y: height / 2
            Behavior on x { enabled: !dragArea.drag.active; Widgets.Anim { speed: Services.Sizes.msMicro } }
            Behavior on y { enabled: !dragArea.drag.active; Widgets.Anim { speed: Services.Sizes.msMicro } }

            Row {
                id: chipInner
                anchors.centerIn: parent
                spacing: 6
                Text {
                    id: gly
                    textFormat: Text.PlainText
                    anchors.verticalCenter: parent.verticalCenter
                    text: slot.glyph
                    color: dragArea.drag.active ? Services.Colors.accentText : Services.Colors.ghost
                    font.pixelSize: 14
                    font.family: "Material Symbols Rounded"
                }
                Text {
                    id: lab
                    textFormat: Text.PlainText
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, Math.max(0, face.width - 18 - gly.width - chipInner.spacing))
                    elide: Text.ElideRight
                    text: slot.label
                    color: dragArea.drag.active ? Services.Colors.accentText : Services.Colors.snow
                    font.pixelSize: Services.Sizes.fsBody
                    font.family: "JetBrainsMono NF"
                }
            }

            MouseArea {
                id: dragArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                drag.target: face
                drag.smoothed: false
                property bool moved: false
                onPressed: { dragArea.moved = false; tab.dockDragFrom = slot.group + ":" + slot.fromSide }
                onPositionChanged: if (drag.active) dragArea.moved = true
                // Flag first, drop after: a drop rewrites the list and this
                // chip is destroyed mid-handler. A press that never moved is
                // a click.
                onReleased: {
                    tab.dockDragFrom = ""
                    if (!dragArea.moved) { slot.sendAway(slot.key); return }
                    face.Drag.drop()
                    if (face) { face.x = 0; face.y = 0 }
                }
            }
        }
    }
}
