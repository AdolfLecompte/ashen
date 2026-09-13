import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "root:/modules/widgets" as Widgets
import "root:/services" as Services
import "root:/modules/settings/components"

PanelWindow {
    id: win
    anchors { top: true; left: true; right: true; bottom: true }
    screen: Services.Screens.active
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    // Everything but the bar's strip: a click on a pill has to reach it,
    // or changing panels costs two. See widgets/ShellMask.qml.
    mask: Widgets.ShellMask { winW: win.width; winH: win.height }
    // stays mapped through the close animation, so the exit plays in reverse
    readonly property bool shown: Services.AppState.settingsVisible
    visible: shown || closeDelay.running
    onShownChanged: if (!shown) closeDelay.restart()
    Timer { id: closeDelay; interval: card.closeMs }

    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    // One tab per question the user is actually asking; Wi-Fi and Bluetooth
    // share one, since they are the same question.
    // Where the section you picked sits in the rail, so the slide knows which
    // way it moved.
    readonly property int tabIndex: {
        for (let i = 0; i < win.categories.length; i++)
            if (win.categories[i].id === win.activeId) return i
        return 0
    }

    // Every section there is, on one rail under four headings. Seven rows with
    // a second row of tabs inside three of them meant the thing you wanted was
    // hidden behind a category you had to guess -- Wi-Fi lived inside
    // "Devices", and nothing on screen said so. Flat, they are all one click
    // Seven rows, and what belongs together is IN the row rather than behind
    // a second set of tabs inside it. Desktop is the bar, its layout and the
    // wallpaper's widgets; Panels is everything that talks to you; Network is
    // the two radios side by side. Nothing here opens another rail.
    property var categories: [
        // The order walks from what you SEE to what the machine IS: the four
        // surfaces first, then the two senses, then what goes in and out, then
        // the machine itself. Not alphabetical, and not the order they were
        // written in.
        { id: "look",    icon: "\ue40a", label: Services.I18n.t("settings.tab.look") },
        { id: "bar",     icon: "\ue8f1", label: Services.I18n.t("settings.tab.bar") },
        { id: "desktop", icon: "\ue1bd", label: Services.I18n.t("settings.tab.desktop") },
        { id: "panels",  icon: "\ue7f5", label: Services.I18n.t("settings.tab.panels") },
        { id: "display", icon: "\ueb97", label: Services.I18n.t("settings.tab.screen") },
        { id: "sound",   icon: "\ue050", label: Services.I18n.t("settings.tab.sound") },
        { id: "input",   icon: "\ue312", label: Services.I18n.t("settings.tab.input") },
        { id: "network", icon: "\ue1ba", label: Services.I18n.t("settings.tab.network") },
        { id: "system",  icon: "\ue429", label: Services.I18n.t("settings.tab.system") },
        { id: "about",   icon: "\ue88e", label: Services.I18n.t("settings.tab.about") },
    ]


    // Every id the shell has ever answered to still resolves: keybinds,
    // launcher entries and `qs ipc call settings tab <name>` outlive a rail.
    // The names on the left of each line are what the rail uses now; the rest
    // are the ones that used to name a whole tab.
    function tabSource(id) {
        if (id === "look" || id === "theme") return "SettingsLookTab.qml"
        // `bar` and `desktop` are two tabs now. The old ids still land where
        // the thing they name actually lives, so a keybind written last month
        // does not break: shape and layout are the bar, widgets are the desktop.
        if (id === "bar" || id === "shape" || id === "layout") return "BarPage.qml"
        if (id === "desktop" || id === "widgets" || id === "dock") return "DesktopPage.qml"
        if (id === "panels" || id === "notifications" || id === "notify"
            || id === "clock" || id === "media") return "PanelsPage.qml"
        if (id === "display") return "SettingsDisplayTab.qml"
        // "Devices" held sound and nothing else -- the keyboard is in Input and
        // the radios are in Network -- so it is called Sound now. The old id
        // still opens it.
        if (id === "sound" || id === "devices") return "DevicesPage.qml"
        if (id === "input" || id === "keyboard") return "InputPage.qml"
        if (id === "apps") return "SystemPage.qml"
        if (id === "network" || id === "wifi" || id === "bluetooth") return "NetworkPage.qml"
        if (id === "system") return "SystemPage.qml"
        if (id === "about") return "AboutPage.qml"
        return "SettingsLookTab.qml"
    }

    // An old id lights the row that took it over.
    readonly property string activeId: {
        const t = Services.AppState.settingsTab
        if (t === "wifi" || t === "bluetooth" || t === "network") return "network"
        if (t === "theme") return "look"
        if (t === "devices") return "sound"
        if (t === "keyboard") return "input"
        if (t === "apps") return "system"
        if (t === "shape" || t === "layout") return "bar"
        if (t === "widgets" || t === "dock") return "desktop"
        if (t === "notifications" || t === "notify" || t === "clock" || t === "media") return "panels"
        return t
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        // Off while the panel is closing: the window stays mapped for the
        // animation, and a live dismiss layer ate the next click.
        enabled: Services.AppState.settingsVisible
        onClicked: Services.AppState.settingsVisible = false
    }

    FocusScope {
        anchors.fill: parent
        focus: win.shown
        Keys.onEscapePressed: Services.AppState.settingsVisible = false
    }

    // Out of the settings chip on the utility pill, like Process and Clipboard;
    // it used to slide in from the right edge with nothing behind it. Read live
    // from the pill, never written at click time: a keybind never clicks, and
    // the panel used to grow from wherever the last click left the numbers.
        readonly property string srcEdge: Services.Sizes.overlayEdge
    // Its chip: on the utility pill of that edge, or on the bar.
    // No capsule since the utility pill went: this panel arrives from the
    // screen edge. The rect is still read while that is decided, so it is a
    // zero rect and not null -- reading .cx off null throws four times a frame.
    readonly property var chipRect: ({ cx: 0, cy: 0, w: 44, h: 44 })
    readonly property real openXCalc: srcEdge === "" ? NaN
        : srcEdge === "left" ? Services.Sizes.panelTop
        : srcEdge === "right" ? win.width - card.openW - Services.Sizes.panelTop
        : (win.width - card.openW) / 2
    readonly property real openYCalc: srcEdge === "" ? NaN
        : srcEdge === "top" ? Services.Sizes.panelTop
        : srcEdge === "bottom" ? win.height - card.openH - Math.max(68, Services.Sizes.marginBottom + 18)
        : (win.height - card.openH) / 2

    Widgets.PanelHost {
        id: card
        shown: win.shown
        sourceEdge: win.srcEdge
        openXOverride: win.openXCalc
        openYOverride: win.openYCalc

        pillCX: win.chipRect.cx
        pillCY: win.chipRect.cy
        pillW: win.chipRect.w
        pillH: win.chipRect.h

        // Wide, with the rail down the side: nine icon-only tabs in a row
        // said nothing about where you were. Sized off the bar layout editor,
        // the widest thing in here -- under 1240 its three drop plates take
        // one chip per line and stop reading as a picture of the bar.
        // As big as the screen sensibly allows: a row of settings that does not
        // fit is a row you have to go looking for. It keeps a margin so it still
        // reads as a card and not as an application.
        // One size for every section, deliberately. A card that resized itself
        // to each page was tried and taken out: it is a delight once and a
        // twitch by the tenth time, because you navigate settings far more than
        // you look at them. Panels that resize because their CONTENTS changed
        // still travel (PanelHost animates it); a window that resizes because
        // you walked to another room does not.
        // The rail, one column at Sizes.readMeasure, and the margins either
        // side. It used to be 1460, which left the content floating in a third
        // of a screen of nothing -- the panel was sized to the screen instead of
        // to what it holds.
        openW: Math.min(Services.Sizes.readMeasure + 260, win.width - 80)
        openH: Math.min(920, win.height - 90)
        cardRadius: Services.Sizes.panelR

        pillKey: "settings"
        restSide: "right"

        body: Component {
            Item {
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 16

                    // ── Left: where you are ────────────────────────────
                    // One accent that TRAVELS between sections, the way the workspace strip
                    // does. A box around every item made nine outlines compete with the
                    // content; with the indicator doing the work the rail is just words.
                    Item {
                        Layout.fillWidth: false
                        Layout.preferredWidth: 190
                        Layout.fillHeight: true

                        readonly property int rowH: 36
                        readonly property int gap: 2

                        Rectangle {
                            id: slide
                            width: parent.width
                            height: parent.rowH
                            radius: Services.Sizes.innerR
                            color: Services.Colors.ghost
                            gradient: Services.Prefs.useGradients ? Services.Colors.accentGradient : null
                            y: win.tabIndex * (parent.rowH + parent.gap)
                            Behavior on y { SmoothedAnimation { duration: Services.Sizes.msPronounced } }
                        }

                        Column {
                            anchors.fill: parent
                            spacing: parent.gap

                            Repeater {
                                model: win.categories

                                delegate: Item {
                                    id: railItem
                                    required property var modelData
                                    readonly property bool active: win.activeId === railItem.modelData.id
                                    width: parent.width
                                    height: 36

                                    readonly property color fg: railItem.active
                                        ? Services.Colors.accentText
                                        : (railHover.containsMouse ? Services.Colors.snow
                                                                   : Services.Colors.mist)

                                    Row {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 12
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 10
                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: railItem.modelData.icon
                                            color: railItem.fg
                                            font.pixelSize: 16
                                            font.family: "Material Symbols Rounded"
                                            Behavior on color { Widgets.ColorAnim { speed: Services.Sizes.msMicro } }
                                        }
                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: railItem.modelData.label
                                            color: railItem.fg
                                            font.pixelSize: Services.Sizes.fsBody
                                            font.bold: true
                                            font.family: "JetBrainsMono NF"
                                            Behavior on color { Widgets.ColorAnim { speed: Services.Sizes.msMicro } }
                                        }
                                    }

                                    MouseArea {
                                        id: railHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Services.AppState.settingsTab = railItem.modelData.id
                                    }
                                }
                            }
                        }
                    }

                    // ── Right: the section itself ──────────────────────
                    // The rail runs down the side, so a section leaves upwards
                    // or downwards, whichever way you moved along it.
                    Widgets.SlideSwap {
                        id: sectionSlide
                        axis: "vertical"
                        index: win.tabIndex
                        onCommit: tabLoader.source = win.tabSource(Services.AppState.settingsTab)
                    }

                    Loader {
                        id: tabLoader
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        opacity: sectionSlide.fade
                        transform: Translate { y: sectionSlide.offY }
                        Component.onCompleted: source = win.tabSource(Services.AppState.settingsTab)
                        onStatusChanged: if (status === Loader.Error)
                            console.warn("[SettingsPanel] ERROR loading", source)
                    }
                }
            }
        }
    }
}
