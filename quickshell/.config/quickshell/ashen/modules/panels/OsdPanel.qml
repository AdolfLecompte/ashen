import Quickshell
import Quickshell.Io
import QtQuick
import "root:/services" as Services
import "root:/modules/widgets" as Widgets

Scope {
    id: root

    IpcHandler {
        target: "osd"
        function volume() {
            // Live, not a snapshot: the keybind sets the volume and calls this
            // in the same breath, so the graph may still be a few ms behind.
            // `volumeOsd` keeps following it while the OSD is up.
            root.volumeOsd = true
            win.shown = true
            hideTimer.restart()
        }
        function brightness() {
            // The key already ran brightnessctl; the service goes and reads
            // what it did, and the OSD follows that number live.
            Services.Brightness.refresh()
            root.volumeOsd = false
            win.shown = true
            hideTimer.restart()
        }
    }

    // Whichever side the OSD is showing, what it draws is a binding on the live
    // service value rather than a number copied into it once -- so a key held
    // down never shows a stale step. Brightness reads its own process in
    // services/Brightness; there is no second one here.
    property bool volumeOsd: false

    PanelWindow {
        id: win
        anchors { top: true; right: true; bottom: true }
        screen: Services.Screens.active
        implicitWidth: 90
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        visible: shown || unmapDelay.running

        readonly property real drawLevel: root.volumeOsd
            ? (Services.Audio.muted ? 0 : Services.Audio.volume / 100)
            : Services.Brightness.level / 100
        readonly property string drawIcon: root.volumeOsd
            ? Services.Audio.icon(Services.Audio.muted ? 0 : Services.Audio.volume,
                                  Services.Audio.muted, Services.Audio.headphones)
            : Services.Brightness.icon(Services.Brightness.level)
        // Own flag instead of the timer: restart() drops running to false for an
        // instant, and anything bound to it unmapped and rebuilt the OSD on every
        // key press. Held down, only the bar should move.
        property bool shown: false

        Timer {
            id: hideTimer
            interval: 1400
            onTriggered: { win.shown = false; unmapDelay.restart() }
        }
        // keep the window mapped a bit longer so the fade-out is visible,
        // then actually unmap it so it does not block clicks
        Timer {
            id: unmapDelay
            interval: 250
        }

        Rectangle {
            // Clears whichever edge the bar is on
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: Math.max(20, Services.Sizes.marginRight)
            width: 48
            height: 250
            radius: 14
            color: Services.Colors.surfacePanel
            border.color: Services.Colors.fillOutline
            border.width: Services.Colors.panelEdgeW

            opacity: win.shown ? 1.0 : 0.0
            scale: win.shown ? 1.0 : 0.85
            Behavior on opacity { Widgets.Anim {} }
            Behavior on scale { NumberAnimation { duration: Services.Sizes.msStandard; easing.type: Easing.OutBack; easing.overshoot: Services.Sizes.overshoot } }

            Column {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: win.drawIcon
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 20
                    color: Services.Colors.ghost
                }

                Rectangle {
                    width: 8
                    height: parent.height - 70
                    anchors.horizontalCenter: parent.horizontalCenter
                    radius: 4
                    color: Services.Colors.fillLine

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        radius: 4
                        color: Services.Colors.ghost
                        // Down the bar, not across it: the fill IS vertical.
                        gradient: Services.Prefs.useGradients ? Services.Colors.accentGradientV : null
                        height: parent.height * Math.max(0, Math.min(1, win.drawLevel))
                        // Short: at 260 ms every tap on the volume key restarted
                        // an animation the next tap interrupted, so the bar
                        // crawled a step behind the key being held down.
                        Behavior on height { Widgets.Anim { speed: Services.Sizes.msMicro } }
                    }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Math.round(win.drawLevel * 100) + "%"
                    font.family: "JetBrainsMono NF"
                    font.pixelSize: 11
                    font.bold: true
                    color: Services.Colors.snow
                }
            }
        }
    }
}
