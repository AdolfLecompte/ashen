import Quickshell
import QtQuick

import "root:/modules/widgets" as Widgets
import "root:/services" as Services

// What the machine is doing, on the bar. The numbers are SysMon's -- this only
// asks for them while it is on screen, through the same claim the process panel
// and the desktop widget use, so an unplaced pill costs nothing at all.
Rectangle {
    id: root

    readonly property bool vertical: Services.Sizes.barVertical
    readonly property string content: Services.Pills.contentOf("sys")
    readonly property bool outlined: Services.Pills.isOutlined("sys")

    // Sampling is refcounted, not a flag: the panel and the desktop widget may
    // want it at the same time, and whoever leaves first must not switch it off
    // under the one still looking.
    Component.onCompleted: Services.SysMon.claim("barpill", true, "light")
    Component.onDestruction: Services.SysMon.claim("barpill", false)

    // Padded to a fixed count of characters. A reading whose width changes every
    // second and a half would animate the whole bar around it forever, which is
    // the one thing a number on a bar must not do.
    function pc(v) {
        const n = Math.max(0, Math.min(99, Math.round(v)))
        return (n < 10 ? " " : "") + n + "%"
    }
    readonly property real ramPercent: Services.SysMon.ramTotalMB > 0
        ? 100 * Services.SysMon.ramUsedMB / Services.SysMon.ramTotalMB : 0
    // Compact says the loudest of the three rather than a chosen one: the point
    // of a small reading is the number you would have gone looking for.
    readonly property string hottest: {
        const c = Services.SysMon.cpuPercent, m = root.ramPercent
        return root.pc(c >= m ? c : m)
    }

    width: root.vertical ? Services.Sizes.pillH
         : root.content === "icon" ? Services.Sizes.pillH
         : chip.width + 16
    height: root.vertical ? chip.height + 16 : Services.Sizes.pillH
    radius: Services.Sizes.pillR
    color: root.outlined ? Services.Colors.surfaceGlass
         : (chip.open && Services.Pills.fills) ? Services.Colors.ghost : Services.Colors.pillPlate
    gradient: (!root.outlined && Services.Prefs.useGradients && Services.Pills.fills && chip.open)
              ? Services.Colors.accentGradient : null
    border.width: root.outlined ? Services.Sizes.outlineW : 0
    border.color: chip.open ? Services.Colors.ghost : Services.Colors.fillOutline
    Behavior on color { Widgets.ColorAnim { speed: Services.Sizes.msEmphasis } }

    scale: Services.Sizes.hoverScale(chip.hovered, chip.pressed)
    Behavior on scale { Widgets.Anim { speed: Services.Sizes.pillHoverMs } }

    SystemChip {
        id: chip
        anchors.centerIn: parent
        bare: true
        pillKey: "sys"
        // The processes panel is where these numbers live in full, so this is
        // the capsule it grows out of.
        open: Services.AppState.processVisible
        glyph: "\ue322"
        // cpu and memory, and nothing else: those are two reads of /proc. The
        // temperature, the GPU and the network rate live in the panel, where
        // something is actually looking at them -- asking for them here woke a
        // sensor probe and nvidia-smi every second and a half.
        altGlyph: root.content === "full" ? "\ue30d" : ""
        altLabel: root.content === "full" ? root.pc(root.ramPercent) : ""
        label: root.content === "icon" ? ""
             : root.content === "compact" ? root.hottest
             : root.pc(Services.SysMon.cpuPercent)
        onActivated: Services.AppState.togglePanel("processVisible")
    }
}
