import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import "root:/services" as Services
import "root:/modules/widgets" as Widgets

// Dwell on a workspace chip and it grows into a live view of that workspace.
// The pictures are real: toplevel-export hands over a window's contents even
// when its workspace is not on screen, and windows sit at their true positions,
// scaled by the monitor.
//
// It arrives the way every other panel does -- PanelHost picks the drop out of
// the chip or the unfold, depending on `Prefs.panelStyle` and on whether the
// workspaces pill is even on the bar. It used to roll its own morph, which is
// how it ended up with a bounce the rest of the shell had given up and no
// answer at all to the style setting.
PanelWindow {
    id: root
    anchors { top: true; left: true; right: true; bottom: true }
    screen: Services.Screens.active
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    // Takes no input, ever. The preview opens directly under the pointer's own
    // chip; if this window swallowed the pointer the chip would lose hover and
    // the preview would close itself the instant it appeared.
    mask: Region { width: 0; height: 0 }

    readonly property bool shown: Services.AppState.wsPreviewId !== 0
    visible: shown || closeDelay.running

    // Latched: the id clears the moment the pointer leaves, but the content
    // has to stay on screen until the shrink finishes.
    property int heldId: 0
    property string heldLabel: ""
    // The card is only told to open once the surface is really up.
    property bool armed: false

    // Opening is a function, not just a signal handler: LazyPanel may build
    // this panel with `shown` ALREADY true (the preload timer and the first
    // hover can land in either order), and a property that is born at its new
    // value never emits a change. Without this the preview simply never armed.
    function beginOpen() {
        heldId = Services.AppState.wsPreviewId
        heldLabel = Services.AppState.wsPreviewLabel
        arm.restart()
    }
    Component.onCompleted: if (shown) beginOpen()

    onShownChanged: {
        if (shown) {
            beginOpen()
        } else {
            arm.stop()
            root.armed = false
            closeDelay.restart()
        }
    }
    // A layer surface is not presented on the frame it is asked for; hold the
    // chip until the surface has landed. It doubles as the grace period the
    // captures need to produce a first frame.
    Timer {
        id: arm
        interval: 200
        onTriggered: {
            root.armed = true
        }
    }
    Timer { id: closeDelay; interval: card.holdMs }

    // The chip's label steps aside only while the card is actually over the
    // chip: set at arm time, the chip sat empty until the card started to grow
    // -- a blank square before anything appeared. This window takes no input,
    // so the pointer stays on the chip underneath.
    Binding {
        target: Services.AppState
        property: "wsPreviewMorphing"
        value: card.fromPill && card.cardItem !== null && card.cardItem.card !== undefined
               && card.cardItem.card.fall > 0.02
    }

    // ── The monitor being miniaturised ──────────────────────────────────
    readonly property var mon: Hyprland.focusedMonitor ? Hyprland.focusedMonitor.lastIpcObject : null
    readonly property real monW: (mon && mon.width) ? mon.width : 1920
    readonly property real monH: (mon && mon.height) ? mon.height : 1080
    readonly property real monX: (mon && mon.x) ? mon.x : 0
    readonly property real monY: (mon && mon.y) ? mon.y : 0

    readonly property real viewW: 340
    readonly property real viewH: Math.round(viewW * monH / monW)
    readonly property real pad: 16
    readonly property real labelH: 24

    // Every window living on the previewed workspace
    readonly property var wins: {
        if (heldId === 0) return []
        return Hyprland.toplevels.values.filter(t => t.workspace && t.workspace.id === root.heldId)
    }

    // The caption is whatever the chip showed -- a number, an app glyph, a
    // kanji, Pac-Man's ghost -- and has to be set in the font that drew it.
    readonly property string labelFont: {
        const c = root.heldLabel.length > 0 ? root.heldLabel.charCodeAt(0) : 0
        if (c >= 0xe000 && c <= 0xf8ff) return "Material Symbols Rounded"
        if (c >= 0x3000 && c <= 0x9fff) return "Noto Sans CJK JP"
        return "JetBrainsMono NF"
    }

    Widgets.PanelHost {
        id: card
        shown: root.armed
        // The chip it grew out of is a workspace chip, so the pill it belongs
        // to is the workspaces capsule: parked, the preview unfolds instead.
        pillKey: "workspaces"
        pillCX: Services.AppState.wsPreviewX + card.pillW / 2
        pillCY: Services.AppState.wsPreviewY + card.pillH / 2
        pillW: Math.max(1, Services.AppState.wsPreviewW)
        pillH: Math.max(1, Services.AppState.wsPreviewH)
        // The chip under the pointer is a plate like the rest of the bar's, and
        // it carries its own number or icon across to the caption.
        pillColor: Services.Colors.surfacePill
        startColor: Services.AppState.wsPreviewColor
        pillLabel: root.heldLabel
        openW: root.viewW + root.pad * 2
        openH: root.viewH + root.labelH + 10 + root.pad * 2
        cardRadius: 16
        restSide: "center"

        body: Component {
            Item {
                id: bodyRoot
                // The miniature carries its own dark ground: shown in a box
                // still half grown it read as a cut-off scrap of workspace. It
                // waits until the box is nearly whole.
                readonly property real grown: card.cardItem && card.cardItem.card
                    ? card.cardItem.card.stretch : 1
                readonly property real show: card.contentAmt
                    * Math.max(0, Math.min(1, (bodyRoot.grown - 0.85) / 0.15))
                anchors.fill: parent
                // Where the chip's own label lands.
                readonly property Item labelTarget: labelSlot

                // ── The miniature ───────────────────────────────────────
                Rectangle {
                    id: view
                    x: root.pad
                    y: root.pad
                    width: root.viewW
                    height: root.viewH
                    radius: 10
                    color: Services.Colors.abyss
                    clip: true
                    // With the rest of the contents, in one fade.
                    opacity: bodyRoot.show

                    Repeater {
                        model: root.wins

                        delegate: Item {
                            required property var modelData
                            readonly property var io: modelData.lastIpcObject
                            readonly property real sx: view.width / root.monW
                            readonly property real sy: view.height / root.monH
                            readonly property bool placed: !!(io && io.at && io.size)

                            visible: placed
                            x: placed ? (io.at[0] - root.monX) * sx : 0
                            y: placed ? (io.at[1] - root.monY) * sy : 0
                            width: placed ? io.size[0] * sx : 0
                            height: placed ? io.size[1] * sy : 0


                            ScreencopyView {
                                id: shot
                                anchors.fill: parent
                                captureSource: modelData.wayland
                                // Only while the preview is up: a live capture
                                // per window is real GPU work and there is no
                                // reason to pay for it against a closed panel.
                                live: root.shown
                                visible: hasContent
                            }

                            // Until the first frame lands -- and for anything
                            // that never hands one over -- the shape and the app
                            // are still most of what a preview is for.
                            Rectangle {
                                anchors.fill: parent
                                visible: !shot.hasContent
                                radius: 4
                                color: Services.Colors.surfacePanel
                                border.color: Services.Colors.ghostAlpha(0.25)
                                border.width: 1
                                Text {
                                    textFormat: Text.PlainText
                                    anchors.centerIn: parent
                                    text: Services.Windows.iconForClass(
                                        parent.parent.io ? parent.parent.io["class"] : "")
                                    color: Services.Colors.ghost
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: Math.max(10, Math.min(22, parent.height * 0.45))
                                }
                            }
                        }
                    }

                    // An empty workspace never opens a preview, but a workspace
                    // can go empty while one is open.
                    Text {
                        textFormat: Text.PlainText
                        anchors.centerIn: parent
                        visible: root.wins.length === 0
                        // Picked once with the tile: a word that re-rolls while
                        // you hover reads as the preview still loading.
                        readonly property string emptyWord: Services.Voice.pick("workspace.empty")
                        text: emptyWord
                        color: Services.Colors.ash
                        font.pixelSize: 11
                        font.family: "JetBrainsMono NF"
                    }
                }

                // ── Caption ─────────────────────────────────────────────
                // The chip's own label lands here, so the thing you were
                // pointing at is still the thing you are looking at.
                Item {
                    id: labelRow
                    x: root.pad
                    y: root.pad + root.viewH + 10
                    width: root.viewW
                    height: root.labelH

                    Text {
                        textFormat: Text.PlainText
                        id: labelSlot
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        // Drawn only where there is no chip to fly one in: with
                        // a drop, the travelling copy IS this label.
                        opacity: card.morphingLabel ? 0 : bodyRoot.show
                        text: root.heldLabel
                        color: Services.Colors.snow
                        font.pixelSize: 13
                        font.bold: true
                        font.family: root.labelFont
                    }

                    Text {
                        textFormat: Text.PlainText
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        opacity: bodyRoot.show
                        text: Services.I18n.t(root.wins.length === 1 ? "ws.window" : "ws.windows", { n: root.wins.length })
                        color: Services.Colors.ash
                        font.pixelSize: 10
                        font.family: "JetBrainsMono NF"
                    }
                }
            }
        }
    }
}
