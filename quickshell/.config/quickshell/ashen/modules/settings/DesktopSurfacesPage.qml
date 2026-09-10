import Quickshell
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "root:/services" as Services
import "root:/modules/widgets" as Widgets
import "root:/modules/settings/components"

// The furniture on the wallpaper: the dock, which widgets are out, what shape
// each one wears, and how they land when you drop them. Was BarDesktopPage,
// back when the bar and the desktop shared a tab.
Section {
    id: tab

    // ── Desktop widgets ──────────────────────────────────────
    // Turning one on, choosing its shape and putting it somewhere all happen
    // on the desktop itself now -- this card is the door, not the controls.
    Card {
        title: Services.I18n.t("settings.tab.desktop")

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            RowGlyph { glyph: "\ue1bd" }

            ColumnLayout {
                spacing: 0
                Text {
                    text: Services.I18n.t("settings.desktop.widgets")
                    color: Services.Colors.snow
                    font.pixelSize: Services.Sizes.fsInput
                    font.family: "JetBrainsMono NF"
                }
                Text {
                    // Read off the live layout, so it follows a wallpaper
                    // profile arriving as much as your own switches.
                    text: {
                        const cat = Services.Desktop.catalogue.filter(w => !w.multi)
                        let on = 0
                        for (const w of cat) if (Services.Desktop.shown(w.id)) on++
                        const pics = Services.Desktop.idsOf("image").length
                        return Services.I18n.t("settings.desktop.count", { n: on, m: cat.length })
                             + (pics > 0 ? "  \u00b7  " + Services.I18n.t(pics === 1 ? "settings.desktop.picture" : "settings.desktop.pictures", { n: pics }) : "")
                    }
                    color: Services.Colors.ash
                    font.pixelSize: Services.Sizes.fsMeta
                    font.family: "JetBrainsMono NF"
                }
            }
            // Without this the button sits against its own name instead of
            // the edge of the card.
            Item { Layout.fillWidth: true }
            ActionBtn {
                label: Services.Desktop.editMode ? Services.I18n.t("common.done") : Services.I18n.t("settings.desktop.arrange")
                accent: Services.Desktop.editMode
                onGo: {
                    Services.Desktop.editMode = !Services.Desktop.editMode
                    // The drawer covers the half of the screen the widgets are
                    // on; arranging them behind it is arranging them blind.
                    if (Services.Desktop.editMode) Services.AppState.settingsVisible = false
                }
            }
        }

        // Same edge the bar and the panels can wear, on the third surface.
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 4
            spacing: 12
            RowGlyph { glyph: "\ue3c6" }        // border_outer
            Text {
                Layout.fillWidth: true
                text: Services.I18n.t("settings.layout.outline")
                color: Services.Colors.snow
                font.pixelSize: Services.Sizes.fsInput
                font.family: "JetBrainsMono NF"
            }
            Toggle {
                checked: Services.Prefs.widgetOutline
                onToggled: Services.Prefs.widgetOutline = !Services.Prefs.widgetOutline
            }
        }
    }


    Item { Layout.preferredHeight: 8 }

    // ── Dock ─────────────────────────────────────────────────
    // The other surface that stands on an edge. It lives beside the desktop
    // rather than beside the bar because, like the widgets, it is furniture the
    // windows have to live with rather than part of the bar's own shape.
    Card {
        title: Services.I18n.t("settings.dock.title")

        // First, because everything under it is moot if this is off.
        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            RowGlyph { glyph: "\ue5d3" }        // apps
            Text {
                Layout.fillWidth: true
                text: Services.I18n.t("settings.dock.enable")
                color: Services.Colors.snow
                font.pixelSize: Services.Sizes.fsInput
                font.family: "JetBrainsMono NF"
            }
            Toggle {
                checked: Services.Prefs.dockEnabled
                onToggled: Services.Prefs.dockEnabled = !Services.Prefs.dockEnabled
            }
        }

        SectionLabel { text: Services.I18n.t("settings.bar.position") }

        // Never the bar's own edge: two surfaces claiming one edge is a fight
        // neither wins, and the dock is the one that can move. SHOWN and
        // greyed, not dropped: a picker that silently offers three of the four
        // sides reads as a missing feature, and the one side that is missing is
        // whichever one the bar happens to be on today -- so the answer changes
        // under you. Dimmed, the row says why. Same rule the power profiles
        // follow: an option's absence is information too.
        Segmented {
            options: ["top", "bottom", "left", "right"].map(e => ({
                id: e,
                label: Services.I18n.t("settings.bar." + e),
                available: e !== Services.Sizes.barPosition
            }))
            current: Services.Prefs.dockEdge
            onPicked: id => Services.Prefs.dockEdge = id
        }

        Text {
            Layout.fillWidth: true
            text: Services.I18n.t("settings.dock.barEdge")
            color: Services.Colors.ash
            font.pixelSize: Services.Sizes.fsMeta
            font.family: "JetBrainsMono NF"
            wrapMode: Text.WordWrap
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 4
            spacing: 12
            RowGlyph { glyph: "\ue8f5" }        // visibility_off
            Text {
                Layout.fillWidth: true
                text: Services.I18n.t("settings.bar.autohide")
                color: Services.Colors.snow
                font.pixelSize: Services.Sizes.fsInput
                font.family: "JetBrainsMono NF"
            }
            Toggle {
                checked: Services.Prefs.dockAutohide
                onToggled: Services.Prefs.dockAutohide = !Services.Prefs.dockAutohide
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            RowGlyph { glyph: "\ue3f4" }        // image
            Text {
                Layout.fillWidth: true
                text: Services.I18n.t("settings.dock.outline")
                color: Services.Colors.snow
                font.pixelSize: Services.Sizes.fsInput
                font.family: "JetBrainsMono NF"
            }
            Toggle {
                checked: Services.Prefs.dockGlass
                onToggled: Services.Prefs.dockGlass = !Services.Prefs.dockGlass
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            RowGlyph { glyph: "\ue8e8" }        // format_size
            Text {
                Layout.fillWidth: true
                text: Services.I18n.t("settings.dock.size")
                color: Services.Colors.snow
                font.pixelSize: Services.Sizes.fsInput
                font.family: "JetBrainsMono NF"
            }
            StepBtn {
                glyph: "\ue15b"
                onClicked: Services.Prefs.dockIconSize = Math.max(28, Services.Prefs.dockIconSize - 4)
            }
            Text {
                Layout.preferredWidth: 34
                horizontalAlignment: Text.AlignHCenter
                text: Services.Prefs.dockIconSize
                color: Services.Colors.ghost
                font.pixelSize: Services.Sizes.fsInput
                font.bold: true
                font.family: "JetBrainsMono NF"
            }
            StepBtn {
                glyph: "\ue145"
                onClicked: Services.Prefs.dockIconSize = Math.min(72, Services.Prefs.dockIconSize + 4)
            }
        }

        // ── What is pinned ───────────────────────────────────────────
        // Right-clicking the dock is how you pin what is already open. This is
        // the other half: the applications that are NOT open, which you cannot
        // right-click because they are not there to click.
        SectionLabel { text: Services.I18n.t("settings.dock.apps"); Layout.topMargin: 4 }

        Repeater {
            model: Services.Prefs.dockPinList
            delegate: RowLayout {
                id: pinRow
                required property var modelData
                required property int index
                // byId first, byClass after: a pin made by right-clicking a
                // running window is stored under what Hyprland calls it, which
                // is not always the .desktop id -- `codium` is `vscodium`.
                readonly property var entry: Services.Apps.byId(pinRow.modelData)
                                          || Services.Apps.byClass(pinRow.modelData)
                Layout.fillWidth: true
                spacing: 10

                Image {
                    Layout.preferredWidth: 22
                    Layout.preferredHeight: 22
                    fillMode: Image.PreserveAspectFit
                    // A pin whose .desktop is gone still holds its slot, and
                    // the generic icon is what says so -- a blank gap would
                    // leave nothing to click to get rid of it.
                    source: {
                        const ic = pinRow.entry ? pinRow.entry.icon : ""
                        if (!ic) return Quickshell.iconPath("application-x-executable")
                        return ic.startsWith("/") ? ("file://" + ic)
                                                  : Quickshell.iconPath(ic, "application-x-executable")
                    }
                }
                Text {
                    Layout.fillWidth: true
                    text: pinRow.entry ? pinRow.entry.name : pinRow.modelData
                    color: pinRow.entry ? Services.Colors.snow : Services.Colors.ash
                    elide: Text.ElideRight
                    font.pixelSize: Services.Sizes.fsInput
                    font.family: "JetBrainsMono NF"
                }
                // Order is the dock's order, so it is changed here rather than
                // by dragging an icon on a dock that may be hidden.
                StepBtn {
                    glyph: "\ue5d8"        // arrow_upward
                    enabled: pinRow.index > 0
                    opacity: enabled ? 1 : 0.35
                    onClicked: Services.Prefs.dockMovePin(pinRow.modelData, pinRow.index - 1)
                }
                StepBtn {
                    glyph: "\ue5db"        // arrow_downward
                    enabled: pinRow.index < Services.Prefs.dockPinList.length - 1
                    opacity: enabled ? 1 : 0.35
                    onClicked: Services.Prefs.dockMovePin(pinRow.modelData, pinRow.index + 1)
                }
                StepBtn {
                    glyph: "\ue15b"        // remove
                    onClicked: Services.Prefs.dockUnpin(pinRow.modelData)
                }
            }
        }

        Text {
            Layout.fillWidth: true
            visible: Services.Prefs.dockPinList.length === 0
            text: Services.Voice.pick("dock.empty")
            color: Services.Colors.ash
            font.pixelSize: Services.Sizes.fsMeta
            font.family: "JetBrainsMono NF"
        }

        // ── Adding one ───────────────────────────────────────────────
        // A search rather than the whole list: there are 1300 packages on this
        // machine and a scroll of every .desktop is not a chooser.
        TextField {
            id: appQuery
            Layout.fillWidth: true
            Layout.topMargin: 4
            placeholderText: Services.I18n.t("settings.dock.search")
            placeholderTextColor: Services.Colors.ash
            color: Services.Colors.snow
            font.pixelSize: Services.Sizes.fsInput
            font.family: "JetBrainsMono NF"
            background: Rectangle {
                radius: Services.Sizes.innerR
                color: Services.Colors.fillRest
                border.width: appQuery.activeFocus ? 1 : 0
                border.color: Services.Colors.ghost
            }
        }

        Repeater {
            // Only when asked: an empty query listing everything would bury the
            // rest of the card under the application menu.
            model: {
                const q = appQuery.text.trim().toLowerCase()
                if (q === "") return []
                const pins = Services.Prefs.dockPinList
                return Services.Apps.all
                    .filter(a => !a.noDisplay && a.id !== "" && pins.indexOf(a.id) === -1
                                 && a.name.toLowerCase().indexOf(q) !== -1)
                    .slice(0, 6)
            }
            delegate: RowLayout {
                id: hit
                required property var modelData
                Layout.fillWidth: true
                spacing: 10

                Image {
                    Layout.preferredWidth: 20
                    Layout.preferredHeight: 20
                    fillMode: Image.PreserveAspectFit
                    source: {
                        const ic = hit.modelData.icon
                        if (!ic) return Quickshell.iconPath("application-x-executable")
                        return ic.startsWith("/") ? ("file://" + ic)
                                                  : Quickshell.iconPath(ic, "application-x-executable")
                    }
                }
                Text {
                    Layout.fillWidth: true
                    text: hit.modelData.name
                    color: hitArea.containsMouse ? Services.Colors.snow : Services.Colors.mist
                    elide: Text.ElideRight
                    font.pixelSize: Services.Sizes.fsInput
                    font.family: "JetBrainsMono NF"
                    Behavior on color { ColorAnimation { duration: Services.Sizes.msMicro } }
                }
                StepBtn {
                    glyph: "\ue145"        // add
                    onClicked: {
                        Services.Prefs.dockPin(hit.modelData.id)
                        appQuery.text = ""
                    }
                }
                MouseArea {
                    id: hitArea
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                }
            }
        }

        Text {
            Layout.fillWidth: true
            text: Services.I18n.t("settings.dock.hint")
            color: Services.Colors.ash
            wrapMode: Text.WordWrap
            font.pixelSize: Services.Sizes.fsMeta
            font.family: "JetBrainsMono NF"
        }
    }
}
