import Quickshell
import QtQuick

import "root:/modules/widgets" as Widgets
import "root:/services" as Services

// The network readout. Was a chip on the system plate until that plate was taken apart, so it
// could be arranged like every other pill on the bar.
Rectangle {
    id: root

    readonly property bool vertical: Services.Sizes.barVertical
    // How this pill draws itself, chosen per pill in Settings > Bar > Layout.
    readonly property string content: Services.Pills.contentOf("network")
    readonly property bool outlined: Services.Pills.isOutlined("network")

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
        pillKey: "network"
        // A network name is whatever the router was called, so this one
        // gets a width band; the readings below do not need one.
        maxLabelW: 108
        // Lit whenever the radio is on, connected or not — the bluetooth
        // chip keys on its radio alone and these two have to agree.
        active: Services.Network.online || Services.Network.wifiEnabled
        open: Services.AppState.networkVisible
        glyph: Services.Network.wifiSsid !== "" ? (Services.Network.wifiSignal >= 75 ? "\ue1ba" : Services.Network.wifiSignal >= 50 ? "\uebe1" : Services.Network.wifiSignal >= 25 ? "\uebd6" : "\uebe4") : (Services.Network.ethConnection !== "" ? "\ueb2f" : (Services.Network.wifiEnabled ? "\ueb31" : "\ue1da"))
        // These say what the radio is DOING; "On"/"Off" only repeated what the
        // fill already shows. With the radio simply on, NetworkManager sweeps every
        // so often, so "Searching" is the intent, not a live state.
        label: root.content === "icon" ? ""
             : root.content === "compact" ? (Services.Network.wifiSsid !== "" ? Services.Network.wifiSignal + "%" : "")
             : Services.Network.wifiSsid !== "" ? Services.Network.wifiSsid
             : (Services.Network.ethConnection !== "" ? Services.Network.ethDevice
             : (Services.Network.wifiEnabled ? Services.I18n.t("net.searching") : Services.I18n.t("net.disabled")))
        onActivated: {
            Services.AppState.networkTab = "wifi"
            Services.AppState.togglePanel("networkVisible")
        }
    }
}
