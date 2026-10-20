import Quickshell
import QtQuick

import "root:/modules/widgets" as Widgets
import "root:/services" as Services

// Today's screen time, on the bar. Not seated by default: it is on offer in
// Settings > Bar > Layout for whoever wants the number in view.
Rectangle {
    id: root
    // The bar this pill stands on (Bar.qml hands it in).
    property var spec: Services.Sizes.first

    readonly property bool vertical: Services.Sizes.barVertical
    readonly property string content: Services.Pills.contentOf("usage")
    readonly property bool outlined: root.spec.outlined("usage")

    // The running span is not booked until the minute flush, so the reading is
    // re-asked once a minute -- a number of minutes changes no faster.
    property int beat: 0
    Timer { interval: 60000; running: true; repeat: true; onTriggered: root.beat++ }
    readonly property string reading: {
        root.beat; Services.Usage.revision
        return Services.Usage.span(Services.Usage.today().total)
    }

    width: root.vertical ? Services.Sizes.pillH
         : root.content === "icon" ? Services.Sizes.pillH
         : chip.width + 16
    height: root.vertical ? chip.height + 16 : Services.Sizes.pillH
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
        pillKey: "usage"
        open: Services.AppState.usageVisible
        glyph: ""
        label: root.content === "icon" ? "" : root.reading
        onActivated: Services.AppState.togglePanel("usageVisible")
    }
}
