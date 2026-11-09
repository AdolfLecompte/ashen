import Quickshell
import QtQuick

import "root:/modules/widgets" as Widgets
import "root:/services" as Services

// Opens the timer panel. Not seated by default: on offer in Settings > Bar >
// Layout. Lit while anything is running, so a parked-then-seated pill also
// says that a timer is going.
Rectangle {
    id: root
    property var spec: Services.Sizes.first

    readonly property bool vertical: Services.Sizes.barVertical
    readonly property bool outlined: root.spec.outlined("timer")

    width: Services.Sizes.pillH
    height: Services.Sizes.pillH
    radius: Services.Sizes.pillR
    color: root.outlined ? Services.Colors.surfaceGlass
         : (chip.open && root.spec.fills && !Services.Pills.wearsFace) ? Services.Colors.ghost : root.spec.pillPlate
    gradient: (!root.outlined && Services.Prefs.useGradients && root.spec.fills && chip.open && !Services.Pills.wearsFace)
              ? Services.Colors.accentGradient : null
    border.width: root.outlined ? Services.Sizes.outlineW : 0
    border.color: chip.open ? Services.Colors.ghost : Services.Colors.fillOutline
    Behavior on color { Widgets.ColorAnim { speed: Services.Sizes.msEmphasis } }

    scale: Services.Sizes.hoverScale(chip.hovered, chip.pressed)
    Behavior on scale { Widgets.Anim { speed: Services.Sizes.pillHoverMs } }

    SystemChip {
        spec: root.spec
        id: chip
        anchors.centerIn: parent
        bare: true
        pillKey: "timer"
        open: Services.AppState.timerVisible
        glyph: "\ue425"
        label: ""
        onActivated: Services.AppState.togglePanel("timerVisible")
    }
}
