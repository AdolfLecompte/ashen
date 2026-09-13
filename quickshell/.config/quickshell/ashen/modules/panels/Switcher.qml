import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import "root:/modules/widgets" as Widgets
import "root:/services" as Services

// Alt-tab, with the windows themselves rather than a list of names. The
// pictures are the same toplevel-export captures the workspace preview uses,
// so a window sitting on another workspace still shows what is on it.
PanelWindow {
    id: root
    property string emptyLine: Services.Voice.pick("switcher.empty")

    anchors { top: true; left: true; right: true; bottom: true }
    screen: Services.Screens.active
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    // Everything but the bar's strip: a click on a pill has to reach it,
    // or changing panels costs two. See widgets/ShellMask.qml.
    mask: Widgets.ShellMask { winW: root.width; winH: root.height }
    readonly property bool shown: Services.AppState.switcherVisible
    visible: shown || closeDelay.running
    Timer { id: closeDelay; interval: host.holdMs }

    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    // Frozen while it is up: windows opening or closing mid-press would move
    // the tile under the selection.
    property var wins: []
    function collect() {
        // A toplevel without a class or a workspace is not a window anyone can
        // switch to: the list carries more handles than `hyprctl clients` does.
        const all = Hyprland.toplevels.values.filter(t =>
            t.lastIpcObject && t.lastIpcObject["class"] && t.workspace)
        // Stable order, and the one a user can predict: by workspace, then by
        // where the window sits on it.
        return all.slice().sort((a, b) => {
            const wa = a.workspace ? a.workspace.id : 0
            const wb = b.workspace ? b.workspace.id : 0
            if (wa !== wb) return wa - wb
            const pa = a.lastIpcObject.at || [0, 0]
            const pb = b.lastIpcObject.at || [0, 0]
            return pa[0] !== pb[0] ? pa[0] - pb[0] : pa[1] - pb[1]
        })
    }

    readonly property int sel: Services.AppState.switcherIndex

    // The panel is built lazily, so the keybind's first step is waiting in
    // AppState by the time this runs: start on the window you are ON, then
    // play back what was asked while there was nothing to ask.
    function arm() {
        root.wins = root.collect()
        Services.AppState.switcherCount = root.wins.length
        const active = Hyprland.activeToplevel
        let at = 0
        for (let i = 0; i < root.wins.length; i++)
            if (active && root.wins[i] === active) at = i
        Services.AppState.switcherIndex = at
        const pending = Services.AppState.switcherPending
        Services.AppState.switcherPending = 0
        if (pending !== 0) Services.AppState.stepSwitcher(pending)
    }

    // `shown` may already be true when the panel is finally built, and a
    // property born at its new value emits no change -- the same trap the
    // workspace preview documents.
    Component.onCompleted: if (shown) arm()
    onShownChanged: {
        if (shown) {
            arm()
        } else {
            Services.AppState.switcherCount = 0
            Services.AppState.switcherPending = 0
            closeDelay.restart()
        }
    }

    // Alt-tab without holding a key: it stays up until it is told to go.
    // Nothing closes it on its own -- Enter/Space or a click commit, Escape
    // and a click outside cancel.
    function step(d) {
        if (root.wins.length === 0) return
        const n = root.wins.length
        Services.AppState.switcherIndex = (Services.AppState.switcherIndex + d + n) % n
    }

    function focusAt(i) {
        const w = root.wins[i]
        if (!w || !w.lastIpcObject) return
        Quickshell.execDetached(["sh", "-c",
            "hyprctl dispatch 'hl.dsp.focus({ window = \"address:"
            + w.lastIpcObject.address + "\" })'"])
    }

    // The panel holds the keyboard while it is up, and Hyprland hands focus
    // back to whatever had it the moment that layer lets go -- which landed
    // ON TOP of the window we had just focused, so every switch bounced
    // straight back. So: let go first, focus after.
    property int pendingFocus: -1
    Timer {
        id: focusAfter
        // Past the close animation, not just past the click: the layer surface
        // stays mapped while the card shrinks, and Hyprland restores focus to
        // the previous window when it finally goes. Focusing before that and
        // the restore lands on top of us -- which is the bounce this had.
        interval: host.holdMs + 80
        onTriggered: {
            root.focusAt(root.pendingFocus)
            root.pendingFocus = -1
        }
    }

    function commit() {
        root.pendingFocus = root.sel
        root.close()
        focusAfter.restart()
    }
    function close() {
        Services.AppState.switcherVisible = false
    }

    Rectangle {
        anchors.fill: parent
        color: Services.Colors.scrim
        opacity: root.shown ? 1.0 : 0.0
        Behavior on opacity { Widgets.Anim { speed: Services.Sizes.msPronounced } }
        MouseArea { anchors.fill: parent; enabled: root.shown; onClicked: root.close() }
    }

    FocusScope {
        anchors.fill: parent
        focus: root.shown
        Keys.onEscapePressed: root.close()
        Keys.onTabPressed: root.step(1)
        Keys.onBacktabPressed: root.step(-1)
        Keys.onRightPressed: root.step(1)
        Keys.onLeftPressed: root.step(-1)
        Keys.onReturnPressed: root.commit()
        Keys.onEnterPressed: root.commit()
        Keys.onSpacePressed: root.commit()
    }

    Widgets.PanelHost {
        id: host
        shown: root.shown
        // No pill: it is opened by a key, so it unfolds where it rests.
        pillKey: ""
        restSide: "center"
        cardRadius: Services.Sizes.panelR

        readonly property int gap: 18
        readonly property int pad: 18
        readonly property int count: Math.max(1, root.wins.length)
        // Room for every window at once: with many open the tiles shrink
        // rather than the strip running off the edge.
        readonly property int maxRow: root.width - 160
        readonly property int tileW: Math.max(150, Math.min(240,
            (host.maxRow - host.pad * 2 - host.gap * (host.count - 1)) / host.count))
        readonly property int shotH: Math.round(tileW * 9 / 16)
        readonly property int tileH: shotH + 26

        openW: host.count * tileW + (host.count - 1) * gap + pad * 2
        openH: tileH + pad * 2
        // Tiles standing on their own, like the power menu: no plate around
        // them and none under the chosen one. What marks it is that it grew.
        cardColor: "transparent"

        body: Component {
            Item {
                id: card

                // The tiles land one after another out of the card's single
                // content driver -- the power menu's arrival, four windows deep.
                function stage(i) {
                    const start = Math.min(0.5, i * 0.1)
                    return Math.max(0, Math.min(1, (host.contentAmt - start) / (1 - start)))
                }

                Row {
                    x: host.pad
                    y: host.pad
                    spacing: host.gap

                    Repeater {
                        model: root.wins

                        delegate: Item {
                            id: tile
                            required property var modelData
                            required property int index
                            readonly property var io: modelData.lastIpcObject
                            readonly property bool picked: root.sel === tile.index

                            width: host.tileW
                            height: host.tileH

                            opacity: card.stage(index)
                            // The shell's one hover language, and the chosen
                            // window wears it whether the pointer or the key
                            // put it there.
                            scale: (0.92 + 0.08 * card.stage(index))
                                   * Services.Sizes.hoverScale(tile.picked, hover.pressed)
                            Behavior on scale {
                                NumberAnimation {
                                    duration: Services.Sizes.pillHoverMs
                                    easing.type: Services.Sizes.easeOut
                                }
                            }

                            MouseArea {
                                id: hover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: Services.AppState.switcherIndex = tile.index
                                onClicked: root.commit()
                            }

                            ClippingRectangle {
                                id: frame
                                width: parent.width
                                height: host.shotH
                                radius: 12
                                color: Services.Colors.abyss
                                // A hairline, not a plate: with four shots side
                                // by side, growing alone does not say which one
                                // the key is on.
                                border.width: 2
                                border.color: tile.picked ? Services.Colors.ghost : "transparent"
                                Behavior on border.color { Widgets.ColorAnim { speed: Services.Sizes.msMicro } }

                                ScreencopyView {
                                    id: shot
                                    anchors.fill: parent
                                    anchors.margins: 2
                                    captureSource: tile.modelData.wayland
                                    // Real GPU work per window: only while the
                                    // switcher is actually on screen.
                                    live: root.shown
                                    visible: hasContent
                                }

                                // Until a frame lands -- and for anything that
                                // never hands one over -- the app is still most
                                // of what a tile is for.
                                Text {
                                    anchors.centerIn: parent
                                    visible: !shot.hasContent
                                    text: Services.Windows.iconForClass(tile.io ? tile.io["class"] : "")
                                    color: Services.Colors.ghost
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 28
                                }
                            }

                            Text {
                                anchors.top: frame.bottom
                                anchors.topMargin: 7
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: parent.width - 8
                                horizontalAlignment: Text.AlignHCenter
                                text: (tile.io && tile.io.title) ? tile.io.title
                                                                 : (tile.io ? tile.io["class"] : "")
                                color: tile.picked ? Services.Colors.snow : Services.Colors.ash
                                font.pixelSize: 10
                                font.bold: tile.picked
                                font.family: "JetBrainsMono NF"
                                elide: Text.ElideRight
                            }
                        }
                    }
                }

                // Nothing to switch to is a state, not an empty card.
                Text {
                    anchors.centerIn: parent
                    visible: root.wins.length === 0
                    opacity: host.contentAmt
                    text: root.emptyLine.toUpperCase()
                    color: Services.Colors.ash
                    font.pixelSize: 11
                    font.bold: true
                    font.family: "JetBrainsMono NF"
                }
            }
        }
    }
}
