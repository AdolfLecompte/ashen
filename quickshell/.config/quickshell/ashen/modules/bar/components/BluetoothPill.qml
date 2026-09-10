import Quickshell
import QtQuick

import "root:/modules/widgets" as Widgets
import "root:/services" as Services

// The bluetooth readout. Was a chip on the system plate until that plate was taken apart, so it
// could be arranged like every other pill on the bar.
Rectangle {
    id: root

    readonly property bool vertical: Services.Sizes.barVertical
    // How this pill draws itself, chosen per pill in Settings > Bar > Layout.
    readonly property string content: Services.Pills.contentOf("bluetooth")
    readonly property bool outlined: Services.Pills.isOutlined("bluetooth")

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
        pillKey: "bluetooth"
        minLabelW: 46
        maxLabelW: 108
        active: Services.Network.btEnabled
        open: Services.AppState.bluetoothVisible
        // Connected wears the linked mark, a live radio with nothing on it
        // the plain one, off the struck-through one. There was no connected
        // glyph before, so a paired headset and an idle adapter looked
        // exactly the same on the bar.
        glyph: Services.Network.btDevice !== "" ? "\ue1a8"
             : (Services.Network.btEnabled ? "\ue1a7" : "\ue1a9")
        // Compact says only what is CONNECTED. "Scanning" and "Off" are states
        // the glyph already carries, and a pill asked to be compact has said it
        // does not want a word for them.
        label: root.content === "icon" ? ""
             : root.content === "compact" ? Services.Network.btDevice
             : (Services.Network.btDevice !== "" ? Services.Network.btDevice
             : (Services.Network.btEnabled ? Services.I18n.t("net.scanning") : Services.I18n.t("net.disabled")))
        onActivated: Services.AppState.togglePanel("bluetoothVisible")
    }
}
