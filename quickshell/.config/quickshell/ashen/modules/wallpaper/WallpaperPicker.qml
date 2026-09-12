import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

import "root:/modules/widgets" as Widgets
import "root:/services" as Services

Scope {
    id: root

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
        readonly property bool shown: Services.AppState.wallpaperVisible
        visible: shown || closeDelay.running
        Timer { id: closeDelay; interval: card.closeMs }

        WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        // Every file found, unfiltered
        property var allWallpapers: []
        property bool scanned: false

        // Path of the wallpaper actually on screen (written by ashen-wallpaper.sh),
        // so the picker can open centred on it instead of at the far left.
        property string currentWallpaperPath: ""

        // Which screen the next pick lands on, by output NAME because that is
        // what awww and mpvpaper take. Empty means all of them, and that is
        // where every opening starts.
        property string targetOutput: ""
        // The same screen as the layout knows it: a description, because a port
        // name moves between reboots. See Displays.keyFor.
        readonly property string targetKey: win.targetOutput === ""
            ? "" : Services.Displays.keyFor(win.targetOutput)
        // What the chosen screen is wearing right now.
        function targetWallpaper() {
            return win.targetOutput === "" ? win.currentWallpaperPath
                                           : Services.Wallpaper.forKey(win.targetKey)
        }
        // Point the carousel at the newly chosen screen's own wallpaper.
        function retarget(name) {
            win.targetOutput = name
            win.positionAtCurrent()
        }

        // "static" = png/jpg/jpeg/webp (awww) | "animated" = gif (awww) + mp4/webm/mkv/mov (mpvpaper)
        property string category: "static"

        function isAnimated(p) {
            let l = p.toLowerCase()
            return l.endsWith(".gif") || l.endsWith(".mp4") || l.endsWith(".webm")
                || l.endsWith(".mkv") || l.endsWith(".mov")
        }
        function isVideo(p) {
            let l = p.toLowerCase()
            return l.endsWith(".mp4") || l.endsWith(".webm") || l.endsWith(".mkv") || l.endsWith(".mov")
        }

        // Every card reads the cached thumb: videos cannot be decoded by
        // Image at all, and a 4K png costs a full decode per card otherwise.
        function previewFor(p) {
            let name = p.split("/").pop()
            return "file://" + Quickshell.env("HOME") + "/.cache/ashen_wall_thumbs/" + name + ".jpg"
        }
        // Fallback while the thumb is still being written (first run).
        function originalFor(p) {
            return isVideo(p) ? "" : "file://" + p
        }

        // `category` is the tab you pressed; `shownCategory` is what the
        // carousel is showing. It turns over halfway through the slide, while
        // nothing is legible. Assigned, never bound: a binding would track the
        // tab live and the cards would swap under the animation.
        property string shownCategory: "static"
        // True while the picker places the category itself.
        property bool settling: false
        // What the search box holds. The picker opens with it empty every time:
        // a filter you cannot see the reason for is a picker that lost half your
        // wallpapers.
        property string query: ""
        function matches(p) {
            return win.query === ""
                || p.split("/").pop().toLowerCase().indexOf(win.query.toLowerCase()) >= 0
        }

        readonly property var wallpapers: allWallpapers.filter(p =>
            (shownCategory === "animated" ? isAnimated(p) : !isAnimated(p)) && win.matches(p))
        // Counted through the search too, or the tab promises wallpapers the
        // carousel is no longer willing to show.
        readonly property int animatedCount: allWallpapers.filter(p => isAnimated(p) && win.matches(p)).length
        readonly property int staticCount: allWallpapers.filter(p => !isAnimated(p) && win.matches(p)).length

        property int currentIndex: 0
        // Portrait cards: tall enough that the picture inside can slide
        // behind the frame without the crop turning into a letterbox.
        readonly property real skew: -0.07
        readonly property real cardH: Math.min(460, height * 0.46)
        // cardW is the pitch of the carousel, not the card: the front one
        // widens to cardWide and the rest sit at cardNarrow.
        // The pitch is the narrow card plus the gap; the widening in the
        // middle is paid for by pushing its neighbours aside (slot.shift), so
        // the gap reads the same everywhere. A fixed pitch alone left a wide
        // hole out at the sides and a tight one in the middle.
        readonly property real cardGap: 16
        readonly property real cardNarrow: 258
        readonly property real cardW: cardNarrow + cardGap

        // The card you are choosing is as wide as its picture is: a frame cut
        // to the image's own shape crops nothing, so the wallpaper is shown
        // WHOLE instead of through a portrait slot. The neighbours stay narrow
        // strips -- that contrast is what says which one you are on.
        //
        // The shape is read off the thumbnails as they decode (they are scaled
        // preserving aspect, so a thumb's shape IS the original's) and kept
        // here, because a card cannot ask another card how wide to stand.
        property var ratios: ({})
        function noteRatio(path, r) {
            if (!path || !(r > 0.05) || win.ratios[path] === r) return
            const m = win.ratios
            m[path] = r
            win.ratios = m
        }
        // 16:9 until the picture says otherwise: the overwhelming majority are,
        // so the guess is usually already right and nothing moves.
        function ratioOf(i) {
            const p = win.wallpapers.length > i ? win.wallpapers[i] : ""
            return (p && win.ratios[p]) ? win.ratios[p] : 16 / 9
        }
        // Every card has to read the SAME number or the gaps stop being equal,
        // so this is the front card's width and nobody computes their own.
        // Capped: an ultrawide wallpaper would otherwise push its neighbours
        // clean off the screen.
        readonly property real cardWideRaw:
            Math.min(win.cardH * win.ratioOf(win.currentIndex), Math.max(win.cardNarrow, win.width - 2 * win.cardW))
        property real cardWide: win.cardNarrow
        Behavior on cardWide { NumberAnimation { duration: Services.Sizes.msStandard; easing.type: Services.Sizes.easeOut } }
        onCardWideRawChanged: win.cardWide = win.cardWideRaw
        Component.onCompleted: win.cardWide = win.cardWideRaw
        readonly property real bandHeight: cardH + 24

        // The carousel is inside the card's body, which is rebuilt on every
        // open, so it is reached through what the body publishes -- never held
        // onto. It is absent until the card has built it.
        readonly property Item listView: card.bodyItem ? card.bodyItem.listView : null

        onShownCategoryChanged: {
            // While the picker is placing itself the index is already chosen;
            // resetting it here is what dragged the carousel off its target.
            if (win.landing) return
            currentIndex = 0
            if (!win.listView) return
            win.listView.currentIndex = 0
            win.listView.positionViewAtBeginning()
        }

        // The list under the carousel just changed length, so whatever it was
        // centred on is not there any more. Start over at the front.
        onQueryChanged: {
            win.currentIndex = 0
            win.pendingIndex = 0
            settleTimer.tries = 0
            settleTimer.ticks = 0
            win.settleAt()
        }

        onShownChanged: {
            if (shown) {
                win.query = ""
                win.targetOutput = ""
                // Re-read the on-screen wallpaper first; its handler kicks off
                // the scan, and positionAtCurrent() runs once the list is in.
                stateReader.running = true
                focusItem.forceActiveFocus()
            } else {
                closeDelay.restart()
            }
        }

        // Centre the carousel on the wallpaper currently on screen. Switches the
        // static/animated tab to match so the entry is in the filtered list.
        function positionAtCurrent() {
            let cur = win.targetWallpaper()
            if (cur && cur.length > 0) {
                // No slide on the way in: landing on the category of the
                // wallpaper you already have is not a change you asked for,
                // and it played on top of the panel's own opening.
                win.settling = true
                win.category = win.isAnimated(cur) ? "animated" : "static"
                win.shownCategory = win.category
                Qt.callLater(function() { win.settling = false })
            }
            let idx = cur ? win.wallpapers.indexOf(cur) : -1
            if (idx < 0) idx = 0
            win.currentIndex = idx
            win.pendingIndex = idx
            settleTimer.tries = 0
            settleTimer.ticks = 0
            win.settleAt()
        }

        // Where the carousel still has to land, -1 once it is there.
        property int pendingIndex: -1
        // True while the picker places itself. The strict range animates every
        // correction it makes, so the entrance has to be silent: the carousel
        // must open ON the wallpaper you wear, not travel to it.
        readonly property bool landing: pendingIndex >= 0

        // The one door to the selection. The view owns currentIndex and writes
        // back through onCurrentIndexChanged; binding it the other way too
        // closed a loop that fought every imperative move.
        function select(i) {
            if (win.wallpapers.length === 0) return
            const t = Math.max(0, Math.min(win.wallpapers.length - 1, i))
            if (win.listView) win.listView.currentIndex = t
            else win.currentIndex = t
        }

        // positionViewAtIndex answers with whatever the view has realised so
        // far, and the strict range then drags it somewhere else -- it opened
        // several cards off the wallpaper you are actually wearing. So the
        // landing is arithmetic instead, on the view's own numbers: with a
        // strict highlight range the items are laid out from content x 0 and
        // the header sits OUTSIDE that origin, so a card's content x is
        // index * cardW -- the header width is not in it. Centring it means
        // pulling back half a viewport minus half a card.
        //
        // Flickable does not clamp an assigned contentX on the spot; it fixes
        // it up a frame later, once the delegates around it exist. So the
        // check reads what the PREVIOUS tick actually left behind before
        // asserting the position again -- at the ends of the list that fixup
        // is what moved it, since there the view had nothing realised yet to
        // hold the position against.
        function centreX(i) {
            const lv = win.listView
            if (!lv) return 0
            // The realised card is the ground truth; the arithmetic is the
            // guess that realises it in the first place.
            const it = lv.itemAtIndex(i)
            const x = it ? it.x : i * win.cardW
            const w = it ? it.width : win.cardW
            return x - (lv.width - w) / 2
        }

        function settleAt() {
            const lv = win.listView
            if (!lv || win.pendingIndex < 0) return
            settleTimer.ticks++
            // Give up rather than spin: better a carousel one card off than a
            // timer running behind a closed panel.
            if (settleTimer.ticks > 40) { win.landed(lv); return }
            if (lv.width <= 0 || lv.count <= win.pendingIndex) { settleTimer.restart(); return }

            const target = win.centreX(win.pendingIndex)
            const put = Math.abs(lv.contentX - target) < 0.5 && !lv.moving && !lv.flicking
            settleTimer.tries = put ? settleTimer.tries + 1 : 0
            if (settleTimer.tries >= 3) { win.landed(lv); return }

            lv.contentX = target
            lv.forceLayout()
            settleTimer.restart()
        }

        function landed(lv) {
            settleTimer.stop()
            const i = win.pendingIndex
            // Cleared first: the view's index is a choice again from here on.
            win.pendingIndex = -1
            if (!lv) return
            lv.currentIndex = i
            win.currentIndex = i
        }

        Timer {
            id: settleTimer
            interval: 50
            // Consecutive ticks that found the view where it was put.
            property int tries: 0
            // Every tick, landed or not -- the deadline.
            property int ticks: 0
            onTriggered: win.settleAt()
        }

        // awww vs mpvpaper, gif frames for matugen, killing the other backend:
        // all of that lives in the script, this just hands it a path
        function applyWallpaper(path) {
            if (!path) return
            // Which screen the colours come from is the shell's call, not the
            // script's: the layout lives here. Everything, or the primary on
            // its own, repaints the shell; a secondary screen changes only its
            // own picture.
            const args = [Services.Paths.script("ashen-wallpaper.sh"), path]
            const leads = win.targetOutput === "" || win.targetKey === Services.Displays.primaryKey
            if (win.targetOutput !== "") {
                args.push("--output", win.targetOutput)
                if (leads) args.push("--palette")
            }
            // The look this wallpaper remembers goes on FIRST: the script runs
            // matugen itself, and it reads the mode and the style off disk. Only
            // for the screen the palette follows -- a profile pulled in by a
            // secondary screen would repaint the whole shell.
            if (leads) Services.Looks.prepare(path)
            Quickshell.execDetached(args)
            // The picker goes the instant you choose, and the script takes
            // seconds to repaint everything: without a word the shell just
            // changes colour under you.
            Services.Notifications.addSystemToast(Services.Voice.pick("wallpaper.applied"),
                                                  "\ue40b", false, "wallpaper",
                                                  { title: Services.I18n.t("wall.set") })
            Services.AppState.wallpaperVisible = false
        }

        // Reads the on-screen wallpaper path, then triggers the (re)scan; the
        // scanner positions the carousel once its list is ready.
        Process {
            id: stateReader
            command: ["cat", Quickshell.env("HOME") + "/.cache/ashen_wallpaper.txt"]
            running: false
            stdout: StdioCollector {
                onStreamFinished: {
                    win.currentWallpaperPath = text.trim()
                    wallpaperScanner.running = true
                }
            }
        }

        Process {
            id: wallpaperScanner
            // The folder is a setting now, so it rides as an argument
            command: [Services.Paths.script("ashen-wallpaper-thumbs.sh"),
                      Services.Prefs.wallpaperDir !== "" ? Services.Prefs.wallpaperDir : Services.Paths.wallpapers]
            running: false
            stdout: StdioCollector {
                onStreamFinished: {
                    let files = text.trim().split("\n").filter(f => f.length > 0)
                    win.allWallpapers = files
                    win.scanned = true
                    win.positionAtCurrent()
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.0)
            MouseArea {
                anchors.fill: parent
                // Off while it is closing: the window stays mapped for the
                // animation, and a live dismiss layer ate the next click.
                enabled: Services.AppState.wallpaperVisible
                onClicked: Services.AppState.wallpaperVisible = false
            }
        }

        FocusScope {
            id: focusItem
            anchors.fill: parent
            focus: true

            // The search box has no TextInput of its own on purpose. The card's
            // body is rebuilt on every open, so a field in there would have to
            // be handed the focus after it exists, and while it held the focus
            // this scope's arrows -- which ARE the carousel -- would be dead.
            // Routing the printable keys here instead keeps the picker's whole
            // keyboard in one place. Runs before the named handlers below, so
            // it must only claim what they do not: Return, Escape and the
            // arrows all carry text under 0x20 or none at all.
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Backspace) {
                    win.query = win.query.slice(0, -1)
                    event.accepted = true
                } else if (event.text.length === 1 && event.text.charCodeAt(0) >= 0x20) {
                    win.query += event.text
                    event.accepted = true
                }
            }

            // Wrap at both ends, then let select() do the moving.
            Keys.onLeftPressed: win.select(win.currentIndex > 0 ? win.currentIndex - 1
                                                                : win.wallpapers.length - 1)
            Keys.onRightPressed: win.select(win.currentIndex < win.wallpapers.length - 1
                                            ? win.currentIndex + 1 : 0)
            // Up/Down switch category
            Keys.onUpPressed: win.category = "static"
            Keys.onDownPressed: win.category = "animated"
            Keys.onReturnPressed: {
                if (win.wallpapers.length > 0) win.applyWallpaper(win.wallpapers[win.currentIndex])
            }
            // One step back at a time: a search you typed is worth more than
            // the panel being open, so Escape drops it first.
            Keys.onEscapePressed: {
                if (win.query !== "") win.query = ""
                else Services.AppState.wallpaperVisible = false
            }
        }


        // Never had a capsule of its own, so it unfolds where it lives instead
        // of dropping out of a chip -- and it is a card now, not a band welded
        // to the bottom of the screen.
        Widgets.PanelHost {
            id: card
            shown: win.shown
            restSide: "bottom"
            rise: 40
            // Same clearance the other bottom panels keep, so it does not sit
            // welded to the edge the way the old band did.
            openYOverride: win.height - card.openH - Math.max(68, Services.Sizes.marginBottom + 18)

            // Edge to edge, the way the old band ran: the carousel is meant to
            // sweep the whole screen, and a narrower card just cropped it.
            openW: win.width
            openXOverride: 0
            // toolbar + carousel + dots, and the padding between them
            openH: 20 + 46 + 16 + win.bandHeight + 14 + 7 + 20
            cardRadius: 22
            // No plate: the wallpapers ARE the surface here, and a panel
            // behind them only got in the way.
            cardColor: "transparent"

            body: Component {
                Item {
                    id: bodyRoot
                    // The window drives the carousel (positionAtCurrent) and a
                    // Component is a boundary for ids, so it is handed out here.
                    readonly property Item listView: view

                    // Its own arrival. The shared stage() is spaced for a card
                    // whose box you can watch unfold; this one is invisible, so
                    // the pieces themselves have to carry the entrance, and they
                    // need real distance between them to read as an order.
                    property real intro: 0
                    function piece(i) {
                        const start = i * 0.26
                        return Math.max(0, Math.min(1, (bodyRoot.intro - start) / (1 - start)))
                    }
                    NumberAnimation {
                        id: introIn
                        target: bodyRoot; property: "intro"; to: 1
                        duration: 520; easing.type: Services.Sizes.easeOut
                    }
                    NumberAnimation {
                        id: introOut
                        target: bodyRoot; property: "intro"; to: 0
                        duration: 150; easing.type: Services.Sizes.easeIn
                    }
                    // Explicit, never Behaviors: in and out are different
                    // shapes, and starting one does not stop the other.
                    Connections {
                        target: win
                        function onShownChanged() {
                            if (win.shown) { introOut.stop(); introIn.restart() }
                            else { introIn.stop(); introOut.restart() }
                        }
                    }
                    // The body is rebuilt on every open, and a property born
                    // with its value never emits a change.
                    Component.onCompleted: if (win.shown) introIn.restart()

                    // Categories, above the carousel. The three pieces come in
                    // one after another rather than as one slab, and leave the
                    // same way -- the card itself is invisible here, so the
                    // arrival IS the content.
                    Item {
                        id: tabsWrap
                        anchors.top: parent.top
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: toolbar.width
                        height: toolbar.height
                        z: 30
                        property Item activeTab: null

                        readonly property real amt: bodyRoot.piece(0)
                        opacity: amt
                        transform: Translate { y: (1 - tabsWrap.amt) * -14 }

                        // ONE bar, not a line of thin pills. Three separate
                        // plates 34 high read as nothing over a photograph:
                        // this is a panel surface with its own edge, and the
                        // three jobs inside it are told apart by a hairline
                        // rather than by a gap.
                        Rectangle {
                            id: toolbar
                            anchors.centerIn: parent
                            width: zones.width
                            height: 46
                            radius: 16
                            color: Services.Colors.surfacePanel
                            border.width: Services.Colors.panelEdgeW
                            border.color: Services.Colors.fillOutline

                        Row {
                            id: zones
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 0

                        // Filters by file name. It is a readout, not a field:
                        // the typing arrives from the window's key handler, see
                        // the comment on Keys.onPressed there.
                        Item {
                            id: searchZone
                            anchors.verticalCenter: parent.verticalCenter
                            width: 236
                            height: toolbar.height

                            Row {
                                anchors.left: parent.left
                                anchors.leftMargin: 16
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 9

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "\ue8b6"
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 17
                                    // Never accentText here: that colour is for
                                    // a label sitting ON the accent fill, and on
                                    // a dark plate it comes out near-black --
                                    // the icon looked like it had switched off.
                                    // Not ghost either: that is the accent, and
                                    // a dark accent would dim it all over again.
                                    // Typing has to make it BRIGHTER, always.
                                    color: win.query === "" ? Services.Colors.mist : Services.Colors.snow
                                }
                                Text {
                                    id: queryText
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: Math.min(implicitWidth, searchZone.width - 60)
                                    elide: Text.ElideLeft
                                    text: win.query === "" ? Services.I18n.t("wall.search") : win.query
                                    color: win.query === "" ? Services.Colors.ash : Services.Colors.snow
                                    font.pixelSize: 12
                                    font.family: "JetBrainsMono NF"
                                }
                                // Nothing to click: the picker always has the
                                // keyboard, so this box is always the one
                                // listening. The caret says so.
                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 1.5
                                    height: 15
                                    radius: 1
                                    color: Services.Colors.ghost
                                    visible: win.query !== ""
                                    SequentialAnimation on opacity {
                                        running: parent.visible && Services.Sizes.motion
                                        loops: Animation.Infinite
                                        NumberAnimation { to: 0.15; duration: 520 }
                                        NumberAnimation { to: 1.0;  duration: 520 }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 1
                            height: 22
                            color: Services.Colors.fillLine
                        }

                        // Both tabs share the bar's plate now, so only the
                        // sliding indicator paints -- workspace style.
                        Item {
                            id: container
                            anchors.verticalCenter: parent.verticalCenter
                            width: tabs.width + 16
                            height: toolbar.height

                            // Sliding highlight behind the active tab (workspace-style)
                            Rectangle {
                                visible: tabsWrap.activeTab !== null
                                x: 8 + (tabsWrap.activeTab ? tabsWrap.activeTab.x : 0)
                                width: tabsWrap.activeTab ? tabsWrap.activeTab.width : 0
                                height: 30
                                anchors.verticalCenter: parent.verticalCenter
                                radius: 11
                                color: Services.Colors.ghost
                                gradient: Services.Prefs.useGradients ? Services.Colors.accentGradient : null
                                Behavior on x { SmoothedAnimation { duration: Services.Sizes.msPronounced } }
                                Behavior on width { SmoothedAnimation { duration: Services.Sizes.msStandard } }
                            }

                            Row {
                            id: tabs
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            spacing: 8


                        Repeater {
                            model: [
                                { id: "static",   label: Services.I18n.t("wall.static"),   icon: "\ue3f4" },
                                { id: "animated", label: Services.I18n.t("wall.animated"), icon: "\ue02c" }
                            ]

                            delegate: Rectangle {
                                required property var modelData
                                readonly property bool active: win.category === modelData.id
                                readonly property int count: modelData.id === "animated" ? win.animatedCount : win.staticCount
                                onActiveChanged: if (active) tabsWrap.activeTab = this
                                Component.onCompleted: if (active) tabsWrap.activeTab = this

                                height: 30
                                width: tabRow.implicitWidth + 22
                                radius: 11
                                // Only the sliding indicator carries the active fill;
                                // idle tabs are bare -- hover only brightens them,
                                // it never paints a plate.
                                color: "transparent"

                                Behavior on color { ColorAnimation { duration: Services.Sizes.msMicro } }

                                Row {
                                    id: tabRow
                                    anchors.centerIn: parent
                                    spacing: 6

                                    Text {
                                        text: parent.parent.modelData.icon
                                        color: parent.parent.active ? Services.Colors.accentText
                                             : tabHover.containsMouse ? Services.Colors.snow
                                             : Services.Colors.mist
                                        font.pixelSize: 15
                                        font.family: "Material Symbols Rounded"
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Text {
                                        text: parent.parent.modelData.label + "  " + parent.parent.count
                                        color: parent.parent.active ? Services.Colors.accentText
                                             : tabHover.containsMouse ? Services.Colors.snow
                                             : Services.Colors.mist
                                        font.pixelSize: 12
                                        font.bold: parent.parent.active
                                        font.family: "JetBrainsMono NF"
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }

                                MouseArea {
                                    id: tabHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: win.category = parent.modelData.id
                                }
                            }
                        }
                    }
                    }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: screenZone.visible
                            width: 1
                            height: 22
                            color: Services.Colors.fillLine
                        }

                        // Which screen the next pick lands on. It only exists
                        // with a second monitor plugged in: on one screen there
                        // is nothing to choose and the picker is the old one.
                        Item {
                            id: screenZone
                            anchors.verticalCenter: parent.verticalCenter
                            visible: Services.Displays.monitors.length > 1
                            width: visible ? 218 : 0
                            height: toolbar.height

                            Widgets.DevicePicker {
                                id: screenPick
                                anchors.left: parent.left
                                anchors.leftMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                width: 202
                                // Matches the pills beside it and borrows the
                                // bar's own plate, so the toolbar stays one
                                // surface instead of a control parked on it.
                                rowH: 30
                                headPlate: "transparent"
                                overlay: true
                                glyph: "\ue30c"
                                current: win.targetOutput
                                devices: {
                                    const rows = [{ name: "", desc: Services.I18n.t("wall.allScreens") }]
                                    for (const m of Services.Displays.monitors)
                                        rows.push({ name: m.name,
                                                    desc: m.description && m.description !== ""
                                                          ? m.name + " · " + m.description : m.name })
                                    return rows
                                }
                                onPicked: name => win.retarget(name)
                            }
                        }
                    }
                    }
                    }

                    // Message shown when the category is empty
                    Text {
                        anchors.centerIn: band
                        z: 20
                        visible: win.scanned && win.wallpapers.length === 0
                        readonly property string dir: Services.Prefs.wallpaperDir !== ""
                            ? Services.Prefs.wallpaperDir : Services.Paths.wallpapers
                        text: win.category === "animated"
                            ? Services.I18n.t("wall.noneAnimated", { d: dir })
                            : Services.I18n.t("wall.none", { d: dir })
                        color: Services.Colors.mist
                        font.pixelSize: 12
                        font.family: "JetBrainsMono NF"
                    }


                    // Changing category slides, the same as every other set of
                    // sections in the shell.
                    Widgets.SlideSwap {
                        id: catSlide
                        axis: "horizontal"
                        travel: 56
                        index: win.category === "animated" ? 1 : 0
                        animate: !win.settling
                        onCommit: win.shownCategory = win.category
                    }

                    Item {
                        id: band
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: tabsWrap.bottom
                        anchors.topMargin: 16
                        height: win.bandHeight
                        clip: true
                        z: 10

                        // One card per notch: a horizontal list ignores the
                        // vertical wheel, and that is the wheel people have.
                        WheelHandler {
                            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                            property real acc: 0
                            function step(d) { win.select(win.currentIndex + d) }
                            onWheel: event => {
                                acc += event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x
                                while (acc >= 120) { acc -= 120; step(-1) }
                                while (acc <= -120) { acc += 120; step(1) }
                            }
                        }

                        readonly property real amt: bodyRoot.piece(1)
                        opacity: catSlide.fade * band.amt
                        transform: Translate { x: catSlide.offX; y: (1 - band.amt) * 34 }

                        ListView {
                            id: view
                            anchors.fill: parent
                            orientation: ListView.Horizontal
                            clip: false
                            spacing: 0
                            model: win.wallpapers.length

                            // Preload neighbouring cards so scrolling has no gaps
                            cacheBuffer: Math.round(win.cardW * 4)
                            reuseItems: true

                            highlightRangeMode: ListView.StrictlyEnforceRange
                            preferredHighlightBegin: width / 2 - win.cardW / 2
                            preferredHighlightEnd: width / 2 + win.cardW / 2
                            // Every correction the strict range makes is animated,
                            // so the opening slide is this number: zero while the
                            // picker is placing itself.
                            highlightMoveDuration: win.landing ? 0 : Services.Sizes.msPronounced

                            header: Item { width: view.width / 2 - win.cardW / 2 }
                            footer: Item { width: view.width / 2 - win.cardW / 2 }

                            // The view is the source of truth for the selection;
                            // while landing its index is still being placed, so it
                            // is not a choice anyone made.
                            onCurrentIndexChanged: if (!win.landing) win.currentIndex = currentIndex
                            // Delegates and geometry both arrive late, and either
                            // one moves the ground under the landing.
                            onCountChanged: win.settleAt()
                            onWidthChanged: win.settleAt()

                            delegate: Item {
                                id: slot
                                required property int index
                                property bool isCurrent: index === win.currentIndex

                                // Distance from the middle in cards, off the LIVE scroll position rather
                                // than the index: index distance is a whole number, so the cards jumped a
                                // step at a time however slowly you dragged.
                                readonly property real dist:
                                    (slot.x + win.cardW / 2 - view.contentX - view.width / 2) / win.cardW
                                // 1 dead centre, 0 two cards out. Falls off fast
                                // on purpose: the one you are choosing has to be
                                // obviously bigger than its neighbours.
                                readonly property real prox: Math.max(0, 1 - Math.abs(slot.dist) / 2)
                                // 1 only for the card in front, 0 a card out.
                                readonly property real front: Math.max(0, 1 - Math.abs(slot.dist))
                                // What the widening in the middle costs this card.
                                // Each step out owes half of the extra width on
                                // either side of it, and the fronts always sum to
                                // 1, so the whole sum collapses to this clamp --
                                // equal gaps at any scroll position.
                                readonly property real shift:
                                    (win.cardWide - win.cardNarrow) / 2 * Math.max(-1, Math.min(1, slot.dist))

                                width: win.cardW
                                height: view.height
                                // The pitch is tighter than the widened card, so
                                // the front one laps over its neighbours -- it has
                                // to paint on top of them.
                                z: slot.prox

                                Item {
                                    id: cardRoot
                                    // The one you are choosing widens towards the
                                    // wallpaper's own shape; the pitch stays fixed,
                                    // so the extra width eats the gap, not the list.
                                    width: win.cardNarrow + (win.cardWide - win.cardNarrow) * slot.front
                                    // Fixed frame: the card is a window, and a
                                    // window that also squashes hides the very
                                    // thing the picture sliding behind it shows.
                                    height: win.cardH

                                    anchors.centerIn: parent
                                    anchors.horizontalCenterOffset: slot.shift

                                    // The nearer it is, the bigger it gets --
                                    // no Behaviors, because `prox` is already
                                    // continuous and smoothing it only adds lag.
                                    // Hover rides on top with its own easing.
                                    property real hoverBoost: cardHover.containsMouse ? 0.03 : 0
                                    Behavior on hoverBoost { NumberAnimation { duration: Services.Sizes.msMicro } }

                                    // Gentler than before: the width already
                                    // carries most of "this is the one".
                                    scale: 0.88 + 0.12 * slot.prox + cardRoot.hoverBoost
                                    opacity: 0.34 + 0.66 * slot.prox

                                    transform: Matrix4x4 {
                                        matrix: Qt.matrix4x4(
                                            1, win.skew, 0, 0,
                                            0, 1,        0, 0,
                                            0, 0,        1, 0,
                                            0, 0,        0, 1
                                        )
                                    }

                                    // The window: the frame travels, the picture
                                    // behind it does not, so a card off to the
                                    // side shows another part of its own image.
                                    Item {
                                        id: imgWrap
                                        anchors.fill: parent
                                        // Keeps the effect's capture to the frame;
                                        // the picture inside overflows on purpose.
                                        clip: true
                                        visible: false

                                        // How far off centre, over a card and a half.
                                        readonly property real off: Math.max(-1, Math.min(1, slot.dist / 1.5))
                                        // Only the cards around the middle pan; past
                                        // two out the picture is parked, so the far
                                        // ones stay quiet while the near ones run.
                                        readonly property real near: Math.max(0, Math.min(1, (2 - Math.abs(slot.dist)) / 0.5))
                                        // Zero dead centre: the front card frames
                                        // its wallpaper straight, nothing else does.
                                        readonly property real ovr: 0.3 * Math.abs(imgWrap.off) * imgWrap.near

                                        Image {
                                            id: img
                                            y: 0
                                            height: parent.height
                                            width: parent.width * (1 + 2 * imgWrap.ovr)
                                            x: -imgWrap.ovr * parent.width * (1 + imgWrap.off)

                                            readonly property string path: win.wallpapers.length > index ? win.wallpapers[index] : ""
                                            property bool fellBack: false
                                            source: img.path === "" ? "" : win.previewFor(img.path)
                                            // The thumb may still be baking on the
                                            // first run; videos have no fallback.
                                            onStatusChanged: if (status === Image.Error && !fellBack) {
                                                fellBack = true
                                                source = win.originalFor(img.path)
                                            }
                                            onPathChanged: fellBack = false
                                            // implicitSize is the decoded
                                            // thumb's, and the thumbs keep the
                                            // original's aspect.
                                            onImplicitHeightChanged:
                                                if (implicitHeight > 0)
                                                    win.noteRatio(img.path, implicitWidth / implicitHeight)

                                            // Width only: pinning both fits the thumb
                                            // inside that box and threw away the
                                            // resolution the cache had just baked.
                                            sourceSize.width: 1000
                                            fillMode: Image.PreserveAspectCrop
                                            smooth: true
                                            asynchronous: true
                                            cache: true
                                        }
                                    }

                                    // What the tilt has to rasterise is the MASK's
                                    // edge, and an edge sitting exactly on the item
                                    // bounds is cut hard -- stair steps down the
                                    // slanted sides. Inset by a pixel and a half the
                                    // alpha ramp lives inside the texture, so the
                                    // skew samples a soft edge instead of a cliff.
                                    Item {
                                        id: maskRect
                                        anchors.fill: parent
                                        visible: false
                                        Rectangle {
                                            anchors.fill: parent
                                            anchors.margins: 1.5
                                            radius: 18
                                            antialiasing: true
                                        }
                                    }

                                    OpacityMask {
                                        anchors.fill: parent
                                        source: imgWrap
                                        maskSource: maskRect
                                        visible: img.status === Image.Ready
                                        opacity: img.status === Image.Ready ? 1.0 : 0.0
                                        Behavior on opacity { NumberAnimation { duration: Services.Sizes.msMicro } }
                                    }

                                    // Placeholder while decoding, avoids the black gap
                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 18
                                        // Not a card background: a veil over a thumbnail
                                        // that has not decoded yet, deliberately see-through
                                        // so the tile does not flash solid and then fill in.
                                        // The only surfaceAlpha left in the tree.
                                        color: Services.Colors.surfaceAlpha(0.5)
                                        visible: img.status !== Image.Ready
                                    }

                                    // Name of the file, in the corner, only
                                    // legible on the card you are looking at.
                                    // It sits ON the picture now that the card
                                    // shows the whole of it, so it stays as
                                    // small as a label can be and gets out of
                                    // the way of the image.
                                    Rectangle {
                                        anchors.right: parent.right
                                        anchors.top: parent.top
                                        anchors.margins: 10
                                        height: 22
                                        width: Math.min(nameText.implicitWidth + 18, parent.width - 20)
                                        radius: 7
                                        color: Qt.rgba(0, 0, 0, 0.55)
                                        opacity: slot.prox
                                        visible: opacity > 0.02

                                        Text {
                                            id: nameText
                                            anchors.centerIn: parent
                                            width: parent.width - 14
                                            horizontalAlignment: Text.AlignHCenter
                                            elide: Text.ElideMiddle
                                            text: {
                                                if (win.wallpapers.length <= index) return ""
                                                const n = win.wallpapers[index].split("/").pop()
                                                const dot = n.lastIndexOf(".")
                                                return dot > 0 ? n.substring(0, dot) : n
                                            }
                                            color: Services.Colors.snow
                                            font.pixelSize: 10
                                            font.family: "JetBrainsMono NF"
                                        }
                                    }

                                    // Marks what the card actually is, since a
                                    // video shows a still frame. Moved aside to
                                    // leave the right-hand corner to the name.
                                    Rectangle {
                                        visible: win.wallpapers.length > index && win.isAnimated(win.wallpapers[index])
                                        anchors.left: parent.left
                                        anchors.top: parent.top
                                        anchors.margins: 10
                                        height: 20
                                        width: badgeRow.implicitWidth + 12
                                        radius: 6
                                        color: Qt.rgba(0, 0, 0, 0.62)

                                        Row {
                                            id: badgeRow
                                            anchors.centerIn: parent
                                            spacing: 4

                                            Text {
                                                text: ""
                                                color: Services.Colors.snow
                                                font.pixelSize: 11
                                                font.family: "Material Symbols Rounded"
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                            Text {
                                                text: win.wallpapers.length > index && win.isVideo(win.wallpapers[index]) ? "VIDEO" : "GIF"
                                                color: Services.Colors.snow
                                                font.pixelSize: 9
                                                font.bold: true
                                                font.family: "JetBrainsMono NF"
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: cardHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (slot.isCurrent) win.applyWallpaper(win.wallpapers[win.currentIndex])
                                            else win.select(slot.index)
                                        }
                                    }
                                }
                            }
                        }
                    }


                    Row {
                        id: dotsRow
                        anchors.top: band.bottom
                        anchors.topMargin: 14

                        readonly property real amt: bodyRoot.piece(2)
                        opacity: catSlide.fade * dotsRow.amt
                        transform: Translate { x: catSlide.offX; y: (1 - dotsRow.amt) * 16 }
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 8
                        z: 30
                        visible: win.wallpapers.length > 1

                        // Ten dots at most, and the run STARTS OVER once you go
                        // past them: with 46 wallpapers the marker used to fall
                        // off the end at the eleventh and nothing was lit at all.
                        readonly property int dotCount: Math.min(win.wallpapers.length, 10)
                        readonly property int litDot: dotCount > 0 ? win.currentIndex % dotCount : 0
                        readonly property int runStart: dotCount > 0
                            ? Math.floor(win.currentIndex / dotCount) * dotCount : 0

                        Repeater {
                            model: dotsRow.dotCount
                            delegate: Rectangle {
                                required property int index
                                readonly property bool lit: dotsRow.litDot === index
                                width: lit ? 20 : 7
                                height: 7; radius: 4
                                color: lit ? Services.Colors.ghost : Services.Colors.snowAlpha(0.2)
                                gradient: Services.Prefs.useGradients && lit ? Services.Colors.accentGradient : null
                                Behavior on width { NumberAnimation { duration: Services.Sizes.msStandard } }
                                Behavior on color { ColorAnimation { duration: Services.Sizes.msStandard } }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    // Within the run you are on, so a dot still
                                    // takes you where it looks like it will.
                                    onClicked: win.select(dotsRow.runStart + index)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
