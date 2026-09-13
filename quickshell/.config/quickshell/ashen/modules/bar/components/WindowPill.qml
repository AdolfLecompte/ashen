import Quickshell
import Quickshell.Hyprland
import QtQuick

import "root:/services" as Services
import "root:/modules/widgets" as Widgets

// What you are actually looking at: the bar could tell you the time, the
// weather and the state of four radios, but not the name of the window in
// front of you. A readout, not a button -- it does not grow under the pointer
// and takes no clicks, so the strip stays clickable through it.
Rectangle {
    id: root

    // How this pill draws itself, chosen in Settings > Bar > Layout.
    readonly property string content: Services.Pills.contentOf("window")
    readonly property bool outlined: Services.Pills.isOutlined("window")
    // Nothing focused, no readout, no slot.
    readonly property bool wanted: root.opacity > 0
    visible: root.wanted

    readonly property bool vertical: Services.Sizes.barVertical

    readonly property var active: Hyprland.activeToplevel
    readonly property var ipc: active ? active.lastIpcObject : null
    readonly property string appClass: ipc && ipc.class ? ipc.class : ""
    readonly property string rawTitle: ipc && ipc.title ? ipc.title : ""
    // A window is worth naming only when there is one. On an empty workspace
    // Hyprland still hands back the last thing that had focus, so the class is
    // what decides, not the title.
    readonly property bool present: root.appClass !== ""

    readonly property string glyph: Services.Windows.iconForClass(root.appClass)
    // Chromium and friends put the document first and the program last, which
    // is the wrong way round for a strip you read at a glance: the tail is the
    // part that is the same for every window of that app.
    readonly property string appName: {
        const t = root.rawTitle
        const cut = t.lastIndexOf(" — ") >= 0 ? t.lastIndexOf(" — ")
                  : t.lastIndexOf(" - ")
        if (cut > 0) return t.substring(cut + 3)
        return root.appClass
    }

    // Collapses along the bar's own axis, like the USB and recording pills:
    // nothing to say, no pill.
    height: root.vertical ? (root.present ? Services.Sizes.pillH : 0)
                          : Services.Sizes.pillH
    width: root.vertical ? Services.Sizes.pillH
                         : (root.present ? Math.min(240, inner.implicitWidth + 24) : 0)
    radius: Services.Sizes.pillR
    border.width: root.outlined ? Services.Sizes.outlineW : 0
    border.color: Services.Colors.fillOutline
    color: root.outlined ? Services.Colors.surfaceGlass : (Services.Colors.pillPlate)
    clip: true
    opacity: root.present ? 1.0 : 0.0

    Behavior on width { enabled: !Services.Sizes.hidden; Widgets.Anim {} }
    Behavior on height { enabled: !Services.Sizes.hidden; Widgets.Anim {} }
    Behavior on opacity { Widgets.Anim { speed: Services.Sizes.msMicro } }

    Row {
        id: inner
        anchors.centerIn: parent
        spacing: 8

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.glyph
            color: Services.Colors.ghost
            font.pixelSize: 18
            font.family: "Material Symbols Rounded"
        }
        Text {
            id: nameText
            // On a side bar there is no room for a name, and the glyph already
            // says which program it is. `icon` says the same thing on purpose.
            visible: !root.vertical && root.content !== "icon"
            // Measured apart from the Text: an elided Text recomputes its
            // implicitWidth from the width it was given, so capping one with
            // the other is a binding loop the log reports on every new title.
            width: visible ? Math.min(Math.ceil(nameMetrics.advanceWidth), 180) : 0
            anchors.verticalCenter: parent.verticalCenter
            text: root.appName
            color: Services.Colors.mist
            font.pixelSize: Services.Sizes.fsBody
            font.bold: true
            font.family: "JetBrainsMono NF"
            elide: Text.ElideRight
        }
        TextMetrics {
            id: nameMetrics
            font: nameText.font
            text: nameText.text
        }
    }

    // Hyprland only refreshes its toplevel list when asked; the title changes
    // without any window being opened or closed, so the focus signal alone is
    // not enough to keep this current.
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "activewindow" || event.name === "windowtitle"
                || event.name === "activewindowv2")
                Hyprland.refreshToplevels()
        }
    }
}
