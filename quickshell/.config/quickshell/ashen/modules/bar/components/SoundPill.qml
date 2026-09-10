import Quickshell
import QtQuick

import "root:/modules/widgets" as Widgets
import "root:/services" as Services

// Sound, and brightness on its second face. Was a chip on the system plate until that plate was taken apart, so it
// could be arranged like every other pill on the bar.
Rectangle {
    id: root

    readonly property bool vertical: Services.Sizes.barVertical
    // How this pill draws itself, chosen per pill in Settings > Bar > Layout.
    readonly property string content: Services.Pills.contentOf("volume")
    readonly property bool outlined: Services.Pills.isOutlined("volume")

    // Icon-only is a SQUARE -- but this pill carries TWO glyphs, sound and
    // brightness, so it is two squares. One square for two icons crushed them
    // together and read as a single mangled symbol; the pill says what it holds
    // by being as wide as what it holds.
    readonly property bool twoUp: root.content === "icon"
                                  && Services.Brightness.icon(Services.Brightness.level) !== ""
    width: root.vertical ? Services.Sizes.pillH
         : root.content === "icon"
             ? (root.twoUp ? Services.Sizes.pillH * 2 - Services.Sizes.barGap
                           : Services.Sizes.pillH)
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
        pillKey: "volume"
        active: !Services.Audio.muted && Services.Audio.volume > 0
        open: Services.AppState.volumeVisible
        glyph: Services.Audio.icon(Services.Audio.volume, Services.Audio.muted, Services.Audio.headphones)
        label: root.content === "icon" ? "" : (Services.Audio.muted ? Services.I18n.t("audio.mute") : Services.Audio.volume + "%")
        // Compact keeps the volume and drops the brightness half: the dual chip
        // exists to save a slot on the bar, and a pill asked to be compact is
        // saying it would rather have the room back.
        altGlyph: root.content === "compact" ? "" : Services.Brightness.icon(Services.Brightness.level)
        altLabel: (root.content === "icon" || root.content === "compact")
                  ? "" : (Services.Brightness.level + "%")
        onActivated: Services.AppState.togglePanel("volumeVisible")
    }
}
