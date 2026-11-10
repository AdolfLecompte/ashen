import Quickshell
import Quickshell.Wayland
import QtQuick
import "root:/services" as Services
import "root:/modules/widgets" as Widgets
import "root:/modules/settings/components"

// The small card the tour talks from. It is its own window, as big as itself,
// above every panel it opens, and parked in the corner AWAY from the bar:
// panels grow out of the bar, so that is the side they rarely reach.
PanelWindow {
    id: win
    screen: Services.Screens.active
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: Services.Tour.active ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    readonly property bool shown: Services.Tour.active
    visible: shown || hold.running
    onShownChanged: if (!shown) hold.restart()
    Timer { id: hold; interval: Services.Sizes.msPanel }

    readonly property bool atTop: Services.Prefs.barPosition === "bottom"
    // A corner, not the middle: the launcher and the pickers are tall and centred.
    readonly property bool atLeft: Services.Prefs.barPosition === "right"
    anchors { top: atTop; bottom: !atTop; left: atLeft; right: !atLeft }
    margins { top: 32; bottom: 32; left: 32; right: 32 }
    implicitWidth: 480
    implicitHeight: card.height

    // The step on screen follows the real one on the slide's commit, so the old
    // text leaves before the new arrives (same SlideSwap as every section change).
    property int shownStep: 0
    Widgets.SlideSwap {
        id: swap
        axis: "horizontal"
        travel: 24
        index: Services.Tour.index
        onCommit: win.shownStep = Services.Tour.index
    }
    readonly property var cur: Services.Tour.steps[win.shownStep]

    FocusScope {
        anchors.fill: parent
        focus: win.shown
        Keys.onEscapePressed: Services.Tour.stop()
        Keys.onRightPressed: Services.Tour.next()
        Keys.onReturnPressed: Services.Tour.next()
        Keys.onLeftPressed: Services.Tour.prev()
    }

    Rectangle {
        id: card
        width: parent.width
        height: col.implicitHeight + 36
        radius: Services.Sizes.panelR
        color: Services.Colors.surfacePanel
        border.width: Services.Colors.panelEdgeW
        border.color: Services.Colors.fillOutline
        opacity: win.shown ? 1 : 0
        transform: Translate { y: win.shown ? 0 : (win.atTop ? -14 : 14) }
        Behavior on opacity { Widgets.Anim { speed: Services.Sizes.msPanel } }

        Column {
            id: col
            x: 20; y: 18
            width: parent.width - 40
            spacing: 12

            // What it is, and the way out.
            Item {
                width: parent.width
                height: 28
                Row {
                    spacing: 10
                    anchors.verticalCenter: parent.verticalCenter
                    opacity: swap.fade
                    transform: Translate { x: swap.offX }
                    Text {
                        textFormat: Text.PlainText
                        anchors.verticalCenter: parent.verticalCenter
                        text: win.cur.glyph
                        color: Services.Colors.ghost
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 22
                    }
                    Text {
                        textFormat: Text.PlainText
                        anchors.verticalCenter: parent.verticalCenter
                        text: Services.I18n.t("tour." + win.cur.id + ".title")
                        color: Services.Colors.snow
                        font.pixelSize: Services.Sizes.fsSectionTitle
                        font.bold: true
                        font.family: "JetBrainsMono NF"
                    }
                }
                Widgets.CtlChip {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    size: 26
                    glyph: ""
                    tip: Services.I18n.t("tour.close")
                    onTriggered: Services.Tour.stop()
                }
            }

            Text {
                textFormat: Text.PlainText
                width: parent.width
                wrapMode: Text.WordWrap
                text: Services.I18n.t("tour." + win.cur.id + ".body")
                color: Services.Colors.mist
                font.pixelSize: Services.Sizes.fsInput
                font.family: "JetBrainsMono NF"
                lineHeight: 1.2
                opacity: swap.fade
                transform: Translate { x: swap.offX }
            }

            // The real key for this step, when it has one.
            Rectangle {
                readonly property string txt: Services.Tour.keyText(win.cur.key)
                visible: txt !== ""
                width: chip.implicitWidth + 24
                height: 26
                radius: Services.Sizes.innerR
                color: Services.Colors.fillLine
                opacity: swap.fade
                Text {
                    id: chip
                    textFormat: Text.PlainText
                    anchors.centerIn: parent
                    text: parent.txt
                    color: Services.Colors.ghost
                    font.pixelSize: Services.Sizes.fsMeta
                    font.bold: true
                    font.family: "JetBrainsMono NF"
                }
            }

            // Where you are in it, and the two ways to move.
            Item {
                width: parent.width
                height: 34
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 5
                    Repeater {
                        model: Services.Tour.steps.length
                        delegate: Rectangle {
                            required property int index
                            width: index === Services.Tour.index ? 18 : 6
                            height: 6
                            radius: 3
                            color: index === Services.Tour.index ? Services.Colors.ghost : Services.Colors.fillLine
                            Behavior on width { Widgets.Anim { speed: Services.Sizes.msMicro } }
                            Behavior on color { Widgets.ColorAnim { speed: Services.Sizes.msMicro } }
                        }
                    }
                }
                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8
                    Widgets.CtlChip {
                        anchors.verticalCenter: parent.verticalCenter
                        size: 30
                        glyph: ""
                        tip: Services.I18n.t("tip.prev")
                        available: Services.Tour.index > 0
                        onTriggered: Services.Tour.prev()
                    }
                    ActionBtn {
                        anchors.verticalCenter: parent.verticalCenter
                        accent: true
                        label: Services.I18n.t(Services.Tour.last ? "tour.done" : "tour.next")
                        onGo: Services.Tour.next()
                    }
                }
            }
        }
    }
}
