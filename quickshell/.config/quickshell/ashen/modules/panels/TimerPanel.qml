import Quickshell
import Quickshell.Wayland
import QtQuick
import "root:/services" as Services
import "root:/modules/widgets" as Widgets

// Stopwatch, countdown and pomodoro, apart from the clock. While it is open
// the toast under the bar steps aside (AppState.timerBoxOut).
PanelWindow {
    id: win
    anchors { top: true; left: true; right: true; bottom: true }
    screen: Services.Screens.active
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    mask: Widgets.ShellMask { winW: win.width; winH: win.height; keepRect: card.restRect }
    readonly property bool shown: Services.AppState.timerVisible
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    visible: shown || closeDelay.running
    onShownChanged: if (!shown) closeDelay.restart()
    Timer { id: closeDelay; interval: card.closeMs }

    MouseArea {
        anchors.fill: parent
        z: -1
        enabled: Services.AppState.timerVisible
        onClicked: Services.AppState.timerVisible = false
    }

    Widgets.PanelHost {
        id: card
        shown: Services.AppState.timerVisible
        pillKey: "timer"
        restSide: "center"
        pillCX: Services.AppState.timerPillCenterX
        pillCY: Services.AppState.timerPillCenterY
        pillW: Services.AppState.timerPillW
        pillH: Services.AppState.timerPillH
        pillActive: false
        pillGlyph: Services.AppState.pillGlyph("timer")
        pillLabel: Services.AppState.pillLabel("timer")

        readonly property int pad: 22
        openW: 400 + pad * 2
        openH: 400 + pad * 2
        cardRadius: 22

        body: Component {
            Item {
                readonly property Item glyphTarget: null
                readonly property Item labelTarget: null

                Widgets.TimerCard {
                    x: card.pad
                    y: card.pad
                    stageFn: i => Math.max(0, Math.min(1, (card.contentAmt - Math.min(0.5, i * 0.09)) / (1 - Math.min(0.5, i * 0.09))))
                }
            }
        }
    }
}
