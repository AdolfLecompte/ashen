import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQml.Models

import "root:/modules/desktop/widgets"
import "root:/modules/widgets" as Widgets
import "root:/services" as Services

// The wallpaper's own layer: it sits above whatever is painting the background
// (awww or mpvpaper) and below every window, so the widgets are furniture, not
// an overlay. One per screen; each widget lives on exactly one of them.
PanelWindow {
    id: desk

    property var modelData
    screen: desk.modelData
    // This screen as Desktop records know it, and whether it is the main one.
    readonly property string hostKey: desk.screen ? Services.Displays.keyFor(desk.screen.name) : ""
    readonly property bool isPrimary: desk.hostKey === Services.Desktop.primaryScreen
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
    // By name: monitorFor() inside a Variants delegate loops on the model.
    readonly property var monitor: desk.screen
        ? Hyprland.monitors.values.find(m => m.name === desk.screen.name) || null : null
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

    // In rest the layer takes the pointer only over the widgets themselves;
    // arranging, or an open widget menu, takes the whole screen. Numbers, never
    // `item:` -- a region following an animated item commits once and then
    // goes quiet.
    readonly property bool menuOpen: Services.Desktop.menuFor !== ""
    Instantiator {
        id: holes
        // Only the widgets that live on this screen cut holes in it.
        model: ["clock", "weather", "media", "system", "battery", "calendar", "sun",
                "timer", "usage", "notify", "updates", "disks", "machine", "visualizer"]
               .concat(Services.Desktop.idsOf("image"))
               .filter(id => Services.Desktop.screenOf(id) === desk.hostKey)
        delegate: Hole {
            required property string modelData
            wid: modelData
        }
    }
    mask: Region {
        x: 0
        y: 0
        width: desk.editing || desk.menuOpen ? desk.width : 0
        height: desk.editing || desk.menuOpen ? desk.height : 0
        regions: {
            let out = []
            for (let i = 0; i < holes.count; i++) out.push(holes.objectAt(i))
            return out
        }
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

        // A click anywhere off the open menu closes it.
        MouseArea {
            anchors.fill: parent
            enabled: desk.menuOpen
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: Services.Desktop.menuFor = ""
        }

        // A slot each rather than a Repeater: they are four different things,
        // not four rows of one. The slot fills the field so a widget's own row
        // of shapes still lands inside its ancestors' bounds.
        WidgetSlot { wid: "clock";   hostKey: desk.hostKey; live: desk.awake; source: Component { ClockWidget {} } }
        WidgetSlot { wid: "weather"; hostKey: desk.hostKey; live: desk.awake; source: Component { WeatherWidget {} } }
        WidgetSlot { wid: "media";   hostKey: desk.hostKey; live: desk.awake; source: Component { MediaWidget {} } }
        WidgetSlot { wid: "system";  hostKey: desk.hostKey; live: desk.awake; source: Component { SysWidget {} } }
        WidgetSlot { wid: "battery";  hostKey: desk.hostKey; live: desk.awake; source: Component { BatteryWidget {} } }
        WidgetSlot { wid: "calendar"; hostKey: desk.hostKey; live: desk.awake; source: Component { CalendarWidget {} } }
        WidgetSlot { wid: "sun";      hostKey: desk.hostKey; live: desk.awake; source: Component { SunWidget {} } }
        WidgetSlot { wid: "timer";    hostKey: desk.hostKey; live: desk.awake; source: Component { TimerWidget {} } }
        WidgetSlot { wid: "usage";    hostKey: desk.hostKey; live: desk.awake; source: Component { UsageWidget {} } }
        WidgetSlot { wid: "notify";   hostKey: desk.hostKey; live: desk.awake; source: Component { NotifyWidget {} } }
        WidgetSlot { wid: "updates";  hostKey: desk.hostKey; live: desk.awake; source: Component { UpdatesWidget {} } }
        WidgetSlot { wid: "disks";    hostKey: desk.hostKey; live: desk.awake; source: Component { DisksWidget {} } }
        WidgetSlot { wid: "machine";  hostKey: desk.hostKey; live: desk.awake; source: Component { MachineWidget {} } }
        WidgetSlot { wid: "visualizer"; hostKey: desk.hostKey; live: desk.awake; source: Component { VisualizerWidget {} } }

        // The one you can have several of: a slot per record, not per entry in
        // the catalogue.
        Repeater {
            model: Services.Desktop.idsOf("image")

            WidgetSlot {
                required property string modelData
                wid: modelData
                hostKey: desk.hostKey
                live: desk.awake
                // The Component captures this delegate's scope, so the copy it
                // builds knows which record it is.
                source: Component { ImageWidget { wid: modelData } }
            }
        }

        // Adding widgets is done from the main screen only.
        EditBar {
            id: editBar
            visible: desk.isPrimary && opacity > 0
            anchors.horizontalCenter: parent.horizontalCenter
            y: Services.Sizes.barPosition === "top" ? Services.Sizes.barH + 16 : 24
        }

        // Below the bar, never inside it: a row painted outside its ancestors'
        // bounds gets no clicks at all.
        WidgetTray {
            visible: desk.isPrimary && opacity > 0
            anchors.horizontalCenter: parent.horizontalCenter
            y: editBar.y + editBar.height + 10
            // Capped rather than "as wide as the screen": thirteen tiles in one
            // row is a ribbon, and a palette reads as a block.
            maxWidth: Math.min(760, field.width - 80)
        }
    }
}
