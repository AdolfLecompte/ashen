import Quickshell
import QtQuick

import "root:/modules/widgets" as Widgets
import "root:/services" as Services

// The battery readout. Was a chip on the system plate until that plate was taken apart, so it
// could be arranged like every other pill on the bar.
Rectangle {
    id: root

    readonly property bool vertical: Services.Sizes.barVertical
    // How this pill draws itself, chosen per pill in Settings > Bar > Layout.
    readonly property string content: Services.Pills.contentOf("battery")
    readonly property bool outlined: Services.Pills.isOutlined("battery")

    // Icon-only is a SQUARE, the size of the notification pill beside it:
    // a glyph with a word's worth of padding on both sides reserved half a
    // pill of nothing, and a row of those reads as a row of gaps.
    width: root.vertical ? Services.Sizes.pillH
         : root.content === "icon" ? Services.Sizes.pillH
         : chip.width + 16
    height: root.vertical ? chip.height + 16 : Services.Sizes.pillH
    radius: Services.Sizes.pillR
    // One plate, drawn here: the chip inside is bare. Same fill language as
    // every other pill -- accent while its panel is open, plate at rest.
    color: root.outlined ? Services.Colors.surfaceGlass
         : (chip.open && Services.Pills.fills) ? Services.Colors.ghost : Services.Colors.pillPlate
    gradient: (!root.outlined && Services.Prefs.useGradients && Services.Pills.fills && chip.open)
              ? Services.Colors.accentGradient : null
    border.width: root.outlined ? Services.Sizes.outlineW : 0
    border.color: chip.open ? Services.Colors.ghost : Services.Colors.fillOutline
    Behavior on color { Widgets.ColorAnim { speed: Services.Sizes.msEmphasis } }

    // The bar's one hover language, from Sizes. The chip does not scale: two
    // things growing at once doubles it.
    scale: Services.Sizes.hoverScale(chip.hovered, chip.pressed)
    Behavior on scale { Widgets.Anim { speed: Services.Sizes.pillHoverMs } }

    SystemChip {
        id: chip
        anchors.centerIn: parent
        bare: true
        pillKey: "battery"
        active: Services.Battery.charging
        open: Services.AppState.batteryVisible
        glyph: Services.Battery.icon(Services.Battery.level, Services.Battery.charging)
        label: root.content === "icon" ? "" : (Services.Battery.level + "%")
        // Below a fifth it stops being a reading and starts being a warning --
        // and then it is the warning that colours BOTH the number and the
        // glyph, over the wallpaper's tone. Above it, the number rests at mist
        // so hover still has somewhere to go.
        idleColor: Services.Battery.level >= 20 ? Services.Colors.mist
                                                : Services.Colors.error_
        idleSolid: Services.Battery.level >= 20 ? Services.Colors.mist
                                                : Services.Colors.error_
        glyphTint: Services.Battery.level >= 20 ? Services.Colors.neutral
                                                : Services.Colors.error_
        onActivated: Services.AppState.togglePanel("batteryVisible")
    }
}
