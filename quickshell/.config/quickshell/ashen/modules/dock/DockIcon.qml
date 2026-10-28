import Quickshell
import QtQuick

import "root:/services" as Services
import "root:/modules/widgets" as Widgets

// One application in the dock: its icon, and a dot when it has a window.
Item {
    id: root

    property string appId: ""
    property var entry: null
    property bool running: false
    // The class Hyprland knows this application by, which is not always the id
    // it is pinned under. Empty when nothing of it is open.
    property string windowClass: ""
    property bool focused: false

    readonly property bool warm: hover.containsMouse
    implicitWidth: Services.Sizes.dockIcon
    implicitHeight: Services.Sizes.dockIcon

    // The bar's one hover language, from Sizes.
    scale: Services.Sizes.hoverScale(root.warm, hover.pressed)
    Behavior on scale { NumberAnimation { duration: Services.Sizes.pillHoverMs; easing.type: Services.Sizes.easeOut } }

    // Centred on the tile, not on the room above the dot: the plate centres
    // the tile, so anything else sits off its middle. The dot fits under it.
    // A pin whose .desktop is gone keeps its slot with the generic icon.
    Widgets.AppIcon {
        anchors.centerIn: parent
        width: parent.width - 14
        height: parent.height - 14
        icon: root.entry ? root.entry.icon : ""
        opacity: root.warm ? 1.0 : 0.88
        Behavior on opacity { Widgets.Anim { speed: Services.Sizes.msMicro } }
    }

    readonly property bool pinned: root.appId !== ""
        && Services.Prefs.dockPinList.indexOf(root.appId) !== -1

    // Has a window. A dot, not a fill: the dock says what is open, it does not
    // light up under the pointer -- that is what the growing is for.
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 2
        width: 4; height: 4; radius: 2
        color: Services.Colors.ghost
        opacity: root.running ? 1 : 0
        Behavior on opacity { Widgets.Anim {} }
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        // Three answers, in the order a dock is asked them:
        //   not running        -> launch it
        //   running, not here  -> bring it to the front
        //   running and focused-> put it away, into the special workspace
        // A dock that only ever launches is a launcher with nicer icons.
        onClicked: mouse => {
            // Right-click pins and unpins. No menu: a dock has one thing to
            // decide about an icon, and a menu to answer one question is a
            // second click for nothing.
            if (mouse.button === Qt.RightButton) {
                if (!root.appId) return
                const was = root.pinned
                if (was) Services.Prefs.dockUnpin(root.appId)
                else Services.Prefs.dockPin(root.appId)
                // The icon of an unpinned application that is still running
                // stays where it is, so without a word nothing happened.
                Services.Notifications.addSystemToast(
                    Services.Voice.pick(was ? "dock.unpinned" : "dock.pinned"),
                    // One glyph for both: this font has a push pin (keep) and
                    // no keep_off to pair it with -- checked by rendering, not
                    // by guessing -- and a wrong icon says more than none.
                    "\ue6aa", false, "dock")
                return
            }
            if (!root.running) {
                if (root.entry) Quickshell.execDetached(["sh", "-c", root.entry.exec])
                return
            }
            const cls = root.windowClass
            if (cls === "") return
            // Lua, because this Hyprland's config is Lua and so is its dispatch
            // argument: `hyprctl dispatch focuswindow class:^(x)$` answers
            // "')' expected near 'class'" and the dock quietly did nothing --
            // which is exactly how it behaved before this was found.
            // The class is the app's own choice: quoted, never pasted into the Lua.
            const target = JSON.stringify("class:" + cls)
            if (root.focused)
                Quickshell.execDetached(["hyprctl", "dispatch",
                    "hl.dsp.window.move({ window = " + target
                    + ", workspace = \"special:hidden\", silent = true })"])
            else
                Quickshell.execDetached(["hyprctl", "dispatch",
                    "hl.dsp.focus({ window = " + target + " })"])
        }
        // Nothing to launch and nothing to say about it: a dead pin is a
        // pointer that does not change, which is the honest affordance.
        cursorShape: root.entry ? Qt.PointingHandCursor : Qt.ArrowCursor
    }
}
