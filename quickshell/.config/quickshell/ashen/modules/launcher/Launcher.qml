import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import "root:/modules/widgets" as Widgets
import "root:/services" as Services

Scope {
    id: root

    Component.onCompleted: Services.Apps.scan()

    PanelWindow {
        id: win
        anchors { top: true; left: true; right: true; bottom: true }
        screen: Services.Screens.active
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        // Everything but the bar's strip: a click on a pill has to reach it,
        // or changing panels costs two. See widgets/ShellMask.qml.
        mask: Widgets.ShellMask { winW: win.width; winH: win.height }
        // stays mapped through the close animation, so the exit plays in reverse
        readonly property bool shown: Services.AppState.launcherVisible

        // The two things this panel says when it has nothing to show. Picked on
        // the opening and on the miss, never per keystroke: a line rewriting
        // itself under the cursor reads as the list still searching.
        property string idleLine: Services.Voice.pick("launcher.idle")
        property string missLine: Services.Voice.pick("launcher.noHits")
        readonly property bool missed: win.searchText !== "" && win.filteredApps.length === 0
        onMissedChanged: if (win.missed) win.missLine = Services.Voice.pick("launcher.noHits")

        visible: shown || closeDelay.running
        onShownChanged: {
            if (!shown) { closeDelay.restart(); return }
            win.idleLine = Services.Voice.pick("launcher.idle")
            searchField.text = ""
            focusArm.restart()
            // Rescan every open, not just the first: picks up installs/uninstalls
            // without needing a shell restart. Guard against overlapping runs.
            Services.Apps.scan()
        }
        // Long enough for the whole exit: the window used to unmap at 300 ms
        // while the collapse still had 220 to run, which cut it dead.
        Timer { id: closeDelay; interval: arrive.holdMs }
        // The card's contents are held back until the drop has landed, and an
        // item that is not on screen cannot take focus.
        Timer {
            id: focusArm
            interval: Services.Sizes.panelArmMs + 40
            onTriggered: searchField.forceActiveFocus()
        }

        WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        property string searchText: ""
        // Read through, never copied: a second list is a second thing to keep
        // in step.
        readonly property var allApps: Services.Apps.all
        property string activeCategory: "All"
        property int selectedIndex: 0

        function moveCategory(dir) {
            let ids = win.categories.map(c => c.id)
            let idx = ids.indexOf(win.activeCategory)
            idx = (idx + dir + ids.length) % ids.length
            win.activeCategory = ids[idx]
            win.selectedIndex = 0
        }
        function moveSelection(dir) {
            let count = win.filteredApps.length
            if (count === 0) return
            win.selectedIndex = Math.max(0, Math.min(count - 1, win.selectedIndex + dir))
            appList.positionViewAtIndex(win.selectedIndex, ListView.Contain)
        }
        function launchSelected() {
            if (win.filteredApps.length === 0) return
            let app = win.filteredApps[Math.min(win.selectedIndex, win.filteredApps.length - 1)]
            Quickshell.execDetached(["sh", "-c", app.exec])
            Services.AppState.launcherVisible = false
        }
        property var categories: [
           { id: "All", icon: "\ue5c3" },
           { id: "Internet", icon: "\ue80b" },
           { id: "Development", icon: "\ue86f" },
           { id: "System", icon: "\ue322" },
           { id: "Utility", icon: "\ue869" },
           { id: "Games", icon: "\uea28" },
           { id: "Graphics", icon: "\ue3f4" },
           { id: "Office", icon: "\uef42" },
           { id: "Other", icon: "\ue5d3" },
       ]

        property var filteredApps: {
            let apps = allApps
            if (activeCategory !== "All") {
                apps = apps.filter(a => a.category === activeCategory)
            }
            if (searchText.length > 0) {
                let q = searchText.toLowerCase()
                // Rank by how the query matches the NAME first; a comment-only hit
                // is kept but sinks to the bottom. Lower score = better. allApps is
                // already alphabetical and the sort is stable, so ties stay A→Z.
                function score(a) {
                    let n = a.name.toLowerCase()
                    if (n === q) return 0                                       // exact
                    if (n.startsWith(q)) return 1                               // name starts with query
                    if (n.split(/[\s\-_]+/).some(w => w.startsWith(q))) return 2 // a word starts with query
                    if (n.includes(q)) return 3                                 // name contains query
                    if (a.comment.toLowerCase().includes(q)) return 4           // only the description matches
                    return 5                                                    // no match
                }
                apps = apps.map(a => ({ app: a, s: score(a) }))
                           .filter(x => x.s < 5)
                           .sort((x, y) => x.s - y.s)
                           .map(x => x.app)
            }
            return apps.slice(0, 50)
        }

        // The list itself lives in Services.Apps: Settings offers the same
        // programs when you pick a browser or a terminal, and two scans would
        // disagree the moment one went stale. Re-asked on every open, which is
        // what picks up an install since last time.
        Timer {
            id: themeTimer
            interval: 150
            repeat: false
            onTriggered: Services.AppState.wallpaperVisible = true
        }


        MouseArea {
            anchors.fill: parent
            z: -1
            // Off while the panel is closing: the window stays mapped for the
            // animation, and a live dismiss layer ate the next click.
            enabled: Services.AppState.launcherVisible
            onClicked: Services.AppState.launcherVisible = false
        }

        // Which end of the screen it rests at: the one the bar is not on.
        readonly property string srcEdge:
            Services.Sizes.barPosition === "bottom" ? "top" : "bottom"

        // Rests near that edge, at the same offset as the drawer and Process,
        // so all of them sit at the same height.
        readonly property real openYCalc: win.srcEdge === "bottom"
            ? win.height - card.fullH - Math.max(68, Services.Sizes.marginBottom + 18)
            : Services.Sizes.panelTop

        // Contents assemble in three beats once the box has opened.
        function stage(i) {
            const start = Math.min(0.5, i * 0.14)
            return Math.max(0, Math.min(1, (arrive.contentAmt - start) / (1 - start)))
        }
        function riseOf(i) { return (1 - win.stage(i)) * 10 }

        Widgets.PanelArrive {
            id: arrive
            shown: win.shown
            // Comes up off the bottom, whichever end it rests at.
            rise: 48
        }

        Rectangle {
            id: card
            // What it opens to; the box unfolds into these.
            readonly property int fullW: 700
            readonly property int fullH: contentCol.height + 32

            x: arrive.boxX((win.width - fullW) / 2, fullW)
            y: arrive.boxY(win.openYCalc, fullH)
            width: arrive.boxW(fullW)
            height: arrive.boxH(fullH)
            radius: Services.Sizes.panelR
            color: Services.Colors.surfacePanel
            border.width: Services.Colors.panelEdgeW
            border.color: Services.Colors.fillOutline
            clip: true
            opacity: arrive.fade
            transform: Translate { y: arrive.offY }

            MouseArea { anchors.fill: parent; onClicked: {} }

            Column {
                id: contentCol
                // Sized to the card's final width, not anchored to it: while the
                // pill grows, anchoring would re-wrap the whole list per frame.
                x: 16
                y: 16
                width: card.fullW - 32
                spacing: 12

                // Search bar
                Rectangle {
                    opacity: win.stage(0)
                    transform: Translate { y: win.riseOf(0) }
                    width: parent.width
                    height: 52
                    radius: 10
                    color: Services.Colors.fillLine
                    border.color: searchField.activeFocus ? Services.Colors.ghost : Services.Colors.ghostAlpha(0.2)
                    border.width: 1
                    Behavior on border.color { Widgets.ColorAnim { speed: Services.Sizes.msMicro } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        spacing: 12

                        Text {
                            textFormat: Text.PlainText
                            text: "\ue8b6"
                            color: Services.Colors.ghost
                            font.pixelSize: 22
                            font.family: "Material Symbols Rounded"
                        }

                        Item {
                            Layout.fillWidth: true
                            height: 30

                            Text {
                                textFormat: Text.PlainText
                                anchors.verticalCenter: parent.verticalCenter
                                text: win.idleLine
                                color: Services.Colors.ash
                                font.pixelSize: Services.Sizes.fsSectionTitle
                                font.family: "JetBrainsMono NF"
                                visible: searchField.text.length === 0
                            }

                            TextInput {
                                id: searchField
                                anchors.fill: parent
                                color: Services.Colors.snow
                                font.pixelSize: Services.Sizes.fsSectionTitle
                                font.family: "JetBrainsMono NF"
                                focus: Services.AppState.launcherVisible
                                verticalAlignment: TextInput.AlignVCenter
                                onTextChanged: { win.searchText = text; win.selectedIndex = 0 }
                                Keys.onEscapePressed: Services.AppState.launcherVisible = false
                                Keys.onReturnPressed: win.launchSelected()
                                Keys.onUpPressed: win.moveSelection(-1)
                                Keys.onDownPressed: win.moveSelection(1)
                                Keys.onLeftPressed: win.moveCategory(-1)
                                Keys.onRightPressed: win.moveCategory(1)
                            }
                        }

                        Widgets.IconButton {
                            size: 24
                            glyph: "\ue5cd"
                            visible: searchField.text.length > 0
                            onActivated: searchField.text = ""
                        }
                    }
                }

                // Categories -- sliding indicator, workspace-style.
                Item {
                    id: catSelect
                    opacity: win.stage(1)
                    transform: Translate { y: win.riseOf(1) }
                    width: parent.width
                    height: 30
                    property Item activeCat: null

                    // Sliding highlight behind the active category (workspace-style)
                    Rectangle {
                        visible: catSelect.activeCat !== null
                        x: catSelect.activeCat ? catSelect.activeCat.x : 0
                        width: catSelect.activeCat ? catSelect.activeCat.width : 0
                        height: 30
                        radius: 8
                        color: Services.Colors.ghost
                        gradient: Services.Prefs.useGradients ? Services.Colors.accentGradient : null
                        Behavior on x { SmoothedAnimation { duration: Services.Sizes.msPronounced } }
                    }

                    RowLayout {
                        anchors.fill: parent
                        spacing: 6
                        Repeater {
                            model: win.categories
                            delegate: Rectangle {
                                required property var modelData
                                readonly property bool active: win.activeCategory === modelData.id
                                onActiveChanged: if (active) catSelect.activeCat = this
                                Component.onCompleted: if (active) catSelect.activeCat = this
                                Layout.fillWidth: true
                                height: 30
                                radius: 8
                                // Only the sliding indicator carries the active fill;
                                // idle slots are bare -- hover only brightens them,
                                // it never paints a plate.
                                color: "transparent"
                                Behavior on color { Widgets.ColorAnim { speed: Services.Sizes.msMicro } }

                                Text {
                                    textFormat: Text.PlainText
                                    anchors.fill: parent
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    text: modelData.icon
                                    color: active ? Services.Colors.accentText
                                         : catHover.containsMouse ? Services.Colors.snow
                                         : Services.Colors.mist
                                    font.pixelSize: 16
                                    font.family: "Material Symbols Rounded"
                                }

                                MouseArea {
                                    id: catHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: win.activeCategory = modelData.id
                                }
                            }
                        }
                    }
                }

                // The app list, last to assemble.
                Rectangle {
                    id: listBox
                    opacity: win.stage(2)
                    transform: Translate { y: win.riseOf(2) }
                    width: parent.width
                    height: 6 * 62
                    color: "transparent"
                    clip: true

                    // A search that matched nothing. Not an error and not an
                    // empty box: the panel says so itself, where the rows
                    // would have been.
                    Column {
                        anchors.centerIn: parent
                        spacing: 8
                        opacity: win.missed ? 1 : 0
                        visible: opacity > 0.01
                        Behavior on opacity { Widgets.Anim {} }

                        Text {
                            textFormat: Text.PlainText
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "\ue8b6"
                            color: Services.Colors.ghost
                            font.pixelSize: 28
                            font.family: "Material Symbols Rounded"
                        }
                        Text {
                            textFormat: Text.PlainText
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: win.missLine
                            color: Services.Colors.mist
                            font.pixelSize: Services.Sizes.fsBody
                            font.family: "JetBrainsMono NF"
                        }
                    }

                    ListView {
                        id: appList
                        anchors.fill: parent
                        model: win.filteredApps
                        spacing: 2
                        clip: true

                        ScrollBar.vertical: ScrollBar {
                            policy: appList.contentHeight > appList.height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
                            width: 4
                        }

                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            width: appList.width
                            height: 60
                            radius: 8
                            // Fill alone marks the selection; the outline read as
                            // a glow and nothing else in the shell frames a row.
                            color: index === win.selectedIndex ? Services.Colors.fillRest : "transparent"
                            border.width: 0
                            Behavior on color { Widgets.ColorAnim { speed: Services.Sizes.msInstant } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 14

                                // ── Icono: comando (glyph directo) o app (imagen + fallback) ──
                                Rectangle {
                                    width: 40; height: 40
                                    radius: 10
                                    color: Services.Colors.fillLine

                                    Image {
                                        id: appImg
                                        anchors.fill: parent
                                        anchors.margins: 6
                                        // No size overload exists -- iconPath is
                                        // (icon), (icon, check: bool) or (icon,
                                        // fallback: string), so the 48 that used
                                        // to sit here was landing on `check`.
                                        // A missing icon loads as Ready with Qt's
                                        // placeholder rather than failing, so the
                                        // glyph behind this never got its turn:
                                        // the theme's generic app icon is the
                                        // honest fallback.
                                        source: modelData.icon
                                            ? (modelData.icon.startsWith("/")
                                               ? ("file://" + modelData.icon)
                                               : Quickshell.iconPath(modelData.icon, "application-x-executable"))
                                            : ""
                                        fillMode: Image.PreserveAspectFit
                                        visible: status === Image.Ready
                                        opacity: 0.85
                                    }

                                    Text {
                                        textFormat: Text.PlainText
                                        anchors.centerIn: parent
                                        text: "\ue5c3"
                                        color: Services.Colors.ghost
                                        font.pixelSize: 22
                                        font.family: "Material Symbols Rounded"
                                        visible: appImg.status !== Image.Ready
                                    }
                                }

                                Column {
                                    Layout.fillWidth: true
                                    spacing: 3

                                    Text {
                                        textFormat: Text.PlainText
                                        text: modelData.name
                                        color: Services.Colors.snow
                                        font.pixelSize: Services.Sizes.fsCardTitle
                                        font.family: "JetBrainsMono NF"
                                        font.bold: true
                                        elide: Text.ElideRight
                                        width: parent.width
                                    }
                                    Text {
                                        textFormat: Text.PlainText
                                        text: modelData.comment
                                        color: Services.Colors.mist
                                        font.pixelSize: Services.Sizes.fsBody
                                        font.family: "JetBrainsMono NF"
                                        elide: Text.ElideRight
                                        width: parent.width
                                        visible: modelData.comment.length > 0
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onEntered: win.selectedIndex = index
                                onClicked: {
                                    Quickshell.execDetached(["sh", "-c", modelData.exec])
                                    Services.AppState.launcherVisible = false
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
