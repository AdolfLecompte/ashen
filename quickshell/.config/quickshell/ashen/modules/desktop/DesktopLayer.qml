import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick

import "root:/modules/desktop/widgets"
import "root:/modules/widgets" as Widgets
import "root:/services" as Services

// The wallpaper's own layer: it sits above whatever is painting the background
// (awww or mpvpaper) and below every window, so the widgets are furniture, not
// an overlay. One screen only -- widgets exist once.
PanelWindow {
    id: desk

    screen: Services.Screens.primary
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "ashen:desktop"
    // Furniture claims no room: windows tile over the whole screen as before.
    exclusionMode: ExclusionMode.Ignore
    // Arranging is the only time the desktop wants the keyboard, and only to
    // hear Escape.
    WlrLayershell.keyboardFocus: Services.Desktop.editMode
        ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    color: "transparent"

    anchors { top: true; bottom: true; left: true; right: true }

    readonly property bool editing: Services.Desktop.editMode

    // The hole one widget cuts in the layer's deafness, named by its record.
    component Hole: Region {
        property string wid: ""
        readonly property var r: Services.Desktop.inputRect(wid)
        intersection: Intersection.Combine
        x: r.x; y: r.y; width: r.w; height: r.h
    }

    // A window filling the screen is showing something; widgets underneath it
    // are not seen, and their canvases have no business painting.
    readonly property var monitor: desk.screen ? Hyprland.monitorFor(desk.screen) : null
    readonly property int activeWs: desk.monitor && desk.monitor.activeWorkspace
        ? desk.monitor.activeWorkspace.id : -1
    readonly property bool covered: {
        if (desk.activeWs < 0) return false
        for (const t of Hyprland.toplevels.values) {
            const o = t.lastIpcObject
            if (!o || !o.workspace) continue
            if (o.workspace.id === desk.activeWs && o.fullscreen) return true
        }
        return false
    }

    // Game mode takes them down the same way a fullscreen window does: their
    // canvases are the shell's only permanent painters.
    visible: desk.editing || (!desk.covered && !Services.Game.on)
    // What the widgets ask before running anything on a clock.
    // Every Item has a `layer` group of its own, and inside a Component that
    // one wins over an outer id -- which is why this window is not called that.
    readonly property bool awake: desk.visible && !desk.covered

    // In rest the layer takes no input at all: a click on the desktop goes
    // where it always went, and no widget can be shoved by accident. Numbers,
    // never `item:` -- a region following an animated item commits once and
    // then goes quiet.
    // In rest the layer takes input ONLY over the widgets that have something
    // to press -- today that is the music transport. Everywhere else a
    // click on the desktop goes where it always went, and no widget can be
    // shoved by accident. Arranging opens the whole screen. Numbers, never
    // `item:` -- a region following an animated item commits once and then goes
    // quiet.
    mask: Region {
        x: 0
        y: 0
        width: desk.editing ? desk.width : 0
        height: desk.editing ? desk.height : 0

        // Holes for the pressable ones, added on top of that. A widget that is
        // off -- or whose shape has no buttons -- publishes no box, so its hole
        // is 0x0 and takes nothing. One line each rather than a Repeater: a
        // Region is a plain object, not an Item, and nothing can build a list
        // of them from a model.
        Hole { wid: "clock" }
        Hole { wid: "weather" }
        Hole { wid: "media" }
        Hole { wid: "system" }
        Hole { wid: "battery" }
        Hole { wid: "calendar" }
        Hole { wid: "sun" }
        Hole { wid: "timer" }
        Hole { wid: "notify" }
        Hole { wid: "updates" }
        Hole { wid: "disks" }
        Hole { wid: "machine" }
        Hole { wid: "visualizer" }
    }

    Item {
        id: field
        anchors.fill: parent
        // Everything at once, so a wallpaper change takes the whole desktop
        // out and brings it back rather than blinking widget by widget.
        opacity: Services.Desktop.hushed ? 0 : 1
        Behavior on opacity {
            Widgets.Anim { speed: Services.Sizes.msPanel }
        }
        focus: desk.editing
        Keys.onEscapePressed: Services.Desktop.editMode = false

        Guides { anchors.fill: parent }

        // A slot each rather than a Repeater: they are four different things,
        // not four rows of one. The slot fills the field so a widget's own row
        // of shapes still lands inside its ancestors' bounds.
        WidgetSlot { wid: "clock";   live: desk.awake; source: Component { ClockWidget {} } }
        WidgetSlot { wid: "weather"; live: desk.awake; source: Component { WeatherWidget {} } }
        WidgetSlot { wid: "media";   live: desk.awake; source: Component { MediaWidget {} } }
        WidgetSlot { wid: "system";  live: desk.awake; source: Component { SysWidget {} } }
        WidgetSlot { wid: "battery";  live: desk.awake; source: Component { BatteryWidget {} } }
        WidgetSlot { wid: "calendar"; live: desk.awake; source: Component { CalendarWidget {} } }
        WidgetSlot { wid: "sun";      live: desk.awake; source: Component { SunWidget {} } }
        WidgetSlot { wid: "timer";    live: desk.awake; source: Component { TimerWidget {} } }
        WidgetSlot { wid: "notify";   live: desk.awake; source: Component { NotifyWidget {} } }
        WidgetSlot { wid: "updates";  live: desk.awake; source: Component { UpdatesWidget {} } }
        WidgetSlot { wid: "disks";    live: desk.awake; source: Component { DisksWidget {} } }
        WidgetSlot { wid: "machine";  live: desk.awake; source: Component { MachineWidget {} } }
        WidgetSlot { wid: "visualizer"; live: desk.awake; source: Component { VisualizerWidget {} } }

        // The one you can have several of: a slot per record, not per entry in
        // the catalogue.
        Repeater {
            model: Services.Desktop.idsOf("image")

            WidgetSlot {
                required property string modelData
                wid: modelData
                live: desk.awake
                // The Component captures this delegate's scope, so the copy it
                // builds knows which record it is.
                source: Component { ImageWidget { wid: modelData } }
            }
        }

        EditBar {
            id: editBar
            anchors.horizontalCenter: parent.horizontalCenter
            y: Services.Sizes.barPosition === "top" ? Services.Sizes.barH + 16 : 24
        }

        // Below the bar, never inside it: a row painted outside its ancestors'
        // bounds gets no clicks at all.
        WidgetTray {
            anchors.horizontalCenter: parent.horizontalCenter
            y: editBar.y + editBar.height + 10
            // Capped rather than "as wide as the screen": thirteen tiles in one
            // row is a ribbon, and a palette reads as a block.
            maxWidth: Math.min(760, field.width - 80)
        }
    }
}
