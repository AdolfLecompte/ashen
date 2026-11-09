// Ashen — Pomodoro cycle on top of the Countdown service.
pragma Singleton
import Quickshell
import QtQuick
import "root:/services" as Services

// Focus 25 / short break 5, a long break 15 after every fourth focus. It owns
// no clock: each phase is a Countdown run, and Countdown.rang advances it.
Singleton {
    id: root

    // "focus" | "short" | "long"
    property string phase: "focus"
    // Focus blocks finished in the current set of four
    property int done: 0
    // True from the first start until reset; keeps Countdown's end from being
    // taken for a plain timer finishing.
    property bool engaged: false

    readonly property var minutes: ({ "focus": 25, "short": 5, "long": 15 })

    function begin() {
        if (!engaged) { engaged = true; Services.Countdown.startFor(minutes[phase] * 60000) }
        else Services.Countdown.start()
    }
    function toggle() { Services.Countdown.running ? Services.Countdown.pause() : begin() }

    // Move to the phase that follows the current one and start it.
    function next() {
        if (phase === "focus") {
            done++
            if (done >= 4) { done = 0; phase = "long" } else phase = "short"
        } else phase = "focus"
        engaged = true
        Services.Countdown.startFor(minutes[phase] * 60000)
    }
    function reset() {
        engaged = false
        phase = "focus"
        done = 0
        Services.Countdown.reset()
        Services.Countdown.setPreset(minutes.focus * 60000)
    }

    Connections {
        target: Services.Countdown
        function onRang() { if (root.engaged) root.next() }
    }
}
