import QtQuick

import "root:/modules/desktop"
import "root:/modules/widgets" as Widgets
import "root:/services" as Services

// The countdown and the stopwatch, out where you can see them -- and operated
// from here: a clock you can watch but not start is a clock you open the panel
// for anyway. Both services outlive their panel, so what this shows and what
// these buttons touch is the same run the clock pill is counting.
DesktopWidget {
    id: root
    wid: "timer"

    // Every shape has buttons, so the layer cuts its hole whichever one is on.
    wantsInput: true


    // ── One reading: the caption, the figure, and the track under it ────
    component Face: Item {
        id: fc
        property string caption: ""
        property string figure: ""
        property real value: 0
        property bool live_: false
        // A track only says something where there is a whole to be part of:
        // a stopwatch counts up forever and has no end to draw.
        property bool tracked: true

        // Wide enough that the buttons stand clear of the figure.
        implicitWidth: 340
        implicitHeight: fc.tracked ? 88 : 76

        Text {
            textFormat: Text.PlainText
            id: cap
            anchors.left: parent.left
            anchors.top: parent.top
            text: fc.caption
            color: fc.live_ ? Services.Colors.ghost : Services.Colors.mist
            font.pixelSize: Services.Sizes.fsCaption
            font.bold: true
            font.letterSpacing: 1.4
            font.family: "JetBrainsMono NF"
            Behavior on color { Widgets.ColorAnim {} }
        }

        Text {
            textFormat: Text.PlainText
            id: figureText
            anchors.left: parent.left
            anchors.top: cap.bottom
            anchors.topMargin: 2
            text: fc.figure
            color: Services.Colors.snow
            font.pixelSize: 46
            font.bold: true
            font.family: "JetBrainsMono NF"
        }


        Rectangle {
            visible: fc.tracked
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 8
            radius: 4
            color: Services.Colors.fillLine

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, fc.value))
                height: parent.height
                radius: parent.radius
                color: Services.Colors.ghost
                gradient: Services.Prefs.useGradients ? Services.Colors.accentGradient : null
                Behavior on width {
                    Widgets.Anim {}
                }
            }
        }
    }

    // Where "RUNNING / PAUSED" used to be written out. The play glyph says the
    // same thing and does something about it, and the caption already lights up
    // while it runs.
    component Controls: Row {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: -3
        spacing: 6
    }
    component Btn: Widgets.CtlChip {
        size: 30
        glyphSize: 17
    }

    component Timer_: Face {
        caption: Services.I18n.t("widget.timer")
        figure: Services.Countdown.display
        // Full when it is aimed and empty when it rings, which is the way a
        // timer is read -- the service already publishes it that way.
        value: Services.Countdown.progress
        live_: Services.Countdown.running

        Controls {
            Btn {
                glyph: Services.Countdown.running ? "\ue034" : "\ue037"
                active: Services.Countdown.running
                onTriggered: Services.Countdown.toggle()
            }
            // Aim it without opening the panel: a minute at a time, either way.
            Btn {
                glyph: "\ue15b"
                available: Services.Countdown.remaining > 60000
                onTriggered: Services.Countdown.bump(-60000)
            }
            Btn {
                glyph: "\ue145"
                onTriggered: Services.Countdown.bump(60000)
            }
            Btn {
                glyph: "\ue042"
                available: Services.Countdown.active
                onTriggered: Services.Countdown.reset()
            }
        }
    }

    component Watch: Face {
        caption: Services.I18n.t("widget.stopwatch")
        figure: Services.Stopwatch.displayShort
        tracked: false
        live_: Services.Stopwatch.running

        Controls {
            Btn {
                glyph: Services.Stopwatch.running ? "\ue034" : "\ue037"
                active: Services.Stopwatch.running
                onTriggered: Services.Stopwatch.toggle()
            }
            Btn {
                glyph: "\ue153"
                available: Services.Stopwatch.running
                onTriggered: Services.Stopwatch.lap()
            }
            Btn {
                glyph: "\ue042"
                available: !Services.Stopwatch.idle
                onTriggered: Services.Stopwatch.reset()
            }
        }
    }

    component PomoFace: Face {
        caption: Services.I18n.t("pomodoro." + Services.Pomodoro.phase).toUpperCase()
        figure: Services.Pomodoro.engaged ? Services.Countdown.display : Services.Countdown.format(25 * 60000)
        value: Services.Pomodoro.engaged ? Services.Countdown.progress : 1
        live_: Services.Countdown.running

        Controls {
            Btn {
                glyph: Services.Countdown.running ? "\ue034" : "\ue037"
                active: Services.Countdown.running
                onTriggered: Services.Pomodoro.toggle()
            }
            Btn {
                glyph: "\ue044"
                available: Services.Pomodoro.engaged
                onTriggered: Services.Pomodoro.next()
            }
            Btn {
                glyph: "\ue042"
                available: Services.Pomodoro.engaged
                onTriggered: Services.Pomodoro.reset()
            }
        }
    }

    component Both: Column {
        spacing: 16
        Timer_ {}
        Widgets.Divider { width: 340 }
        Watch {}
    }

    Component { id: timerShape; Timer_ {} }
    Component { id: watchShape; Watch {} }
    Component { id: bothShape; Both {} }
    Component { id: pomoShape; PomoFace {} }

    Loader {
        sourceComponent: root.style === "stopwatch" ? watchShape
                       : root.style === "both" ? bothShape
                       : root.style === "pomodoro" ? pomoShape
                       : timerShape
    }
}
