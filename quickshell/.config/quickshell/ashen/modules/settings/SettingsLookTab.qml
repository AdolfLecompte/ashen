import Quickshell
import QtQuick
import QtQuick.Layouts
import "root:/services" as Services
import "root:/modules/settings/components"
import "root:/modules/widgets" as Widgets

// How the shell looks, and the picture it takes its colours from. The wallpaper
// used to live in a tab of its own next door, which meant choosing a look and
// choosing the thing the look is generated FROM were two different places.
Item {
    anchors.fill: parent

    Flickable {
        anchors.fill: parent
        anchors.margins: 28
        contentHeight: tab.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: tab
            width: parent.width
            spacing: 18

    // The picture leads the tab: the whole palette is made from it, so a page
    // about how the shell looks opens with the thing it looks like.
    WallpaperHero {
        onTriggered: {
            Services.AppState.settingsVisible = false
            Services.AppState.wallpaperVisible = true
        }
    }

    // Where the picker looks. Same shape as the recording folder row in Sound.
    DirField {
        glyph: "\ue2c7"
        title: Services.I18n.t("settings.look.wallFolder")
        value: Services.Prefs.wallpaperDir !== ""
            ? Services.Prefs.wallpaperDir : Services.Paths.wallpapers
        placeholder: Services.Paths.wallpapers
        Layout.topMargin: 4
        onCommitted: path => Services.Prefs.wallpaperDir = path
    }





    Text {
        textFormat: Text.PlainText
        visible: false   // the drawer header carries the section name
        text: Services.I18n.t("settings.look.theme")
        color: Services.Colors.snow
        font.pixelSize: Services.Sizes.fsPanelTitle
        font.bold: true
        font.family: "JetBrainsMono NF"
    }


    // A box, not a rule.
    // ── This wallpaper's own look ───────────────────────────────────────
    // Right under the wallpaper it belongs to: it decides what everything below
    // it does when the wallpaper changes, so it cannot sit at the bottom.
    Card {
        title: Services.I18n.t("settings.look.profile")

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                textFormat: Text.PlainText
                text: Services.I18n.t("settings.look.remember")
                color: Services.Colors.snow
                font.pixelSize: Services.Sizes.fsInput
                font.family: "JetBrainsMono NF"
            }
            Item { Layout.fillWidth: true }
            Toggle {
                checked: Services.Looks.remembering
                enabled: Services.Looks.current !== ""
                onToggled: Services.Looks.remember(!Services.Looks.remembering)
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                textFormat: Text.PlainText
                text: Services.I18n.t("settings.look.default")
                color: Services.Colors.snow
                font.pixelSize: Services.Sizes.fsInput
                font.family: "JetBrainsMono NF"
            }
            Item { Layout.fillWidth: true }
            ActionBtn {
                label: Services.I18n.t("settings.look.setCurrent")
                onGo: Services.Looks.saveBaseline()
            }
        }

    }

    Card {
        title: Services.I18n.t("settings.look.scheme")
        ColumnLayout {
            id: schemeSection
            Layout.fillWidth: true
            spacing: 8

            // The palettes and everything that applies them live in
            // Services.Theme: a wallpaper profile re-applies a scheme with this
            // tab closed, so none of it can hang off the tab.
            readonly property bool dynamicActive: Services.Theme.dynamicActive

            // Above the schemes, because it is not one of them: every scheme below
            // has a light and a dark face, and this picks which one you get.
            Segmented {
                Layout.fillWidth: true
                options: [
                    { id: "dark", icon: "\ue51c", label: Services.I18n.t("settings.look.dark") },
                    { id: "light", icon: "\ue518", label: Services.I18n.t("settings.look.light") },
                ]
                current: Services.Prefs.themeMode
                onPicked: id => Services.Theme.setMode(id)
            }

            // ── Dynamic, alone and across the full width ────────────────────
            // Not one more palette: it is the one with no fixed colours, so it gets a
            // bar rather than a cell. Its swatches are read live off Colors.
            Rectangle {
                id: dynRowCard
                readonly property bool active: schemeSection.dynamicActive
                Layout.fillWidth: true
                Layout.preferredHeight: 56
                radius: Services.Sizes.cardR
                color: active ? Services.Colors.fillSunken : Services.Colors.fillRest
                // No growth: a card the full width of its section is cut by the
                // tab's clip the moment it grows. Its words brighten instead.
                border.color: active ? Services.Colors.ghost : "transparent"
                border.width: active ? 2 : 0
                Behavior on color { Widgets.ColorAnim { speed: Services.Sizes.msMicro } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 12

                    Text {
                        textFormat: Text.PlainText
                        text: ""
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 18
                        color: Services.Colors.ghost
                    }
                    ColumnLayout {
                        spacing: 1
                        Text { textFormat: Text.PlainText; text: Services.I18n.t("settings.look.dynamic"); color: Services.Colors.snow; font.pixelSize: Services.Sizes.fsInput; font.bold: true; font.family: "JetBrainsMono NF" }
                        Text { textFormat: Text.PlainText; text: Services.I18n.t("settings.look.fromWallpaper"); color: dynHover.containsMouse ? Services.Colors.snow : Services.Colors.mist; font.pixelSize: Services.Sizes.fsMeta; font.family: "JetBrainsMono NF" }
                    }
                    Item { Layout.fillWidth: true }

                    Row {
                        spacing: 6
                        Repeater {
                            model: [Services.Colors.abyss, Services.Colors.surface,
                                    Services.Colors.ghost, Services.Colors.neutral,
                                    Services.Colors.snow]
                            delegate: Rectangle {
                                required property color modelData
                                width: 18; height: 18
                                radius: Services.Sizes.innerR
                                color: modelData
                                border.color: Qt.rgba(1, 1, 1, 0.15)
                                border.width: 1
                            }
                        }
                    }

                    // Holds its place whether or not it is showing, so the
                    // swatches do not shift sideways when the scheme changes.
                    Item {
                        Layout.preferredWidth: 18
                        Layout.preferredHeight: 18
                        Rectangle {
                            anchors.fill: parent
                            visible: dynRowCard.active
                            radius: Services.Sizes.innerR
                            color: Services.Colors.ghost
                            gradient: Services.Prefs.useGradients ? Services.Colors.accentGradient : null
                            Text {
                                textFormat: Text.PlainText
                                anchors.centerIn: parent
                                text: ""
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 11
                                color: Services.Colors.accentText
                            }
                        }
                    }
                }

                MouseArea {
                    id: dynHover
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: Services.Theme.setScheme("dynamic")
                }
            }

            // ── The fixed palettes ──────────────────────────────────────────
            // Name on the left, its colours on the right, one scheme per line.
            // Two columns, because a single column of full-width rows in a 1240 px
            // drawer is mostly empty space between the two things you read.
            Flow {
                id: schemeFlow
                Layout.fillWidth: true
                Layout.topMargin: 2
                spacing: 8

                Repeater {
                    model: Services.Theme.schemeCards
                    delegate: Rectangle {
                        id: schemeRow
                        required property var modelData
                        required property int index
                        readonly property bool active: Services.Theme.schemeId === modelData.id
                        // An odd count leaves the last card alone on its row; it
                        // takes the whole width rather than half a row of nothing.
                        readonly property bool alone: schemeRow.index === Services.Theme.schemeCards.length - 1
                                                      && Services.Theme.schemeCards.length % 2 === 1
                        width: schemeRow.alone ? schemeFlow.width
                                               : (schemeFlow.width - schemeFlow.spacing) / 2
                        height: 44
                        radius: Services.Sizes.pillR
                        color: active ? Services.Colors.fillSunken : Services.Colors.fillRest
                        scale: Services.Sizes.hoverScaleFor(width, schemeHover.containsMouse, schemeHover.pressed)
                        Behavior on scale { NumberAnimation { duration: Services.Sizes.pillHoverMs; easing.type: Services.Sizes.easeOut } }
                        border.color: active ? Services.Colors.ghost : "transparent"
                        border.width: active ? 2 : 0
                        Behavior on color { Widgets.ColorAnim { speed: Services.Sizes.msMicro } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            spacing: 10

                            Text {
                                textFormat: Text.PlainText
                                text: schemeRow.modelData.label
                                color: Services.Colors.snow
                                font.pixelSize: Services.Sizes.fsBody
                                font.bold: true
                                font.family: "JetBrainsMono NF"
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Row {
                                spacing: 5
                                Repeater {
                                    model: Services.Theme.swatchesOf(schemeRow.modelData.id)
                                    delegate: Rectangle {
                                        required property color modelData
                                        width: 16; height: 16
                                        radius: Services.Sizes.innerR
                                        color: modelData
                                        border.color: Qt.rgba(1, 1, 1, 0.15)
                                        border.width: 1
                                    }
                                }
                            }

                            Item {
                                Layout.preferredWidth: 16
                                Layout.preferredHeight: 16
                                Rectangle {
                                    anchors.fill: parent
                                    visible: schemeRow.active
                                    radius: Services.Sizes.innerR
                                    color: Services.Colors.ghost
                                    gradient: Services.Prefs.useGradients ? Services.Colors.accentGradient : null
                                    Text {
                                        textFormat: Text.PlainText
                                        anchors.centerIn: parent
                                        text: ""
                                        font.family: "Material Symbols Rounded"
                                        font.pixelSize: 10
                                        color: Services.Colors.accentText
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: schemeHover
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: Services.Theme.setScheme(schemeRow.modelData.id)
                        }
                    }
                }
            }

            // ── Dynamic Style: only has any effect while Dynamic is the active
            //    scheme, so it is visibly subordinate to it and dims when it is not.
            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 6
                radius: Services.Sizes.cardR
                color: Services.Colors.fillInset
                implicitHeight: dynCol.implicitHeight + 24
                opacity: schemeSection.dynamicActive ? 1.0 : 0.45
                Behavior on opacity { Widgets.Anim {} }

                ColumnLayout {
                    id: dynCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 12
                    spacing: 6

                    RowLayout {
                        spacing: 8
                        Text { textFormat: Text.PlainText; text: "\ue65f"; font.family: "Material Symbols Rounded"; font.pixelSize: 15; color: Services.Colors.ghost }
                        Text { textFormat: Text.PlainText; text: Services.I18n.t("settings.look.dynStyle"); color: Services.Colors.snow; font.pixelSize: Services.Sizes.fsBody; font.bold: true; font.family: "JetBrainsMono NF" }
                    }
                    Text {
                        textFormat: Text.PlainText
                        // Only the half that says why the chips are inert; the
                        // other half only described them.
                        visible: !schemeSection.dynamicActive
                        text: Services.I18n.t("settings.look.dynHint")
                        color: Services.Colors.ash
                        font.pixelSize: Services.Sizes.fsMeta
                        font.family: "JetBrainsMono NF"
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    // A list: matugen ships eight styles and adds more, and a grid
                    // of eight chips was already two rows of words.
                    Widgets.DevicePicker {
                        Layout.fillWidth: true
                        Layout.topMargin: 2
                        overlay: true
                        rowH: 34
                        enabled: schemeSection.dynamicActive
                        glyph: "\ue40a"
                        devices: Services.Theme.dynamicTypes.map(t => ({ name: t.id, desc: t.label }))
                        current: Services.Theme.dynamicType
                        onPicked: name => {
                            Services.Theme.setDynamicType(name)
                            Services.Theme.recolor()
                        }
                    }
                }
            }
        }
    }

        // ── Gradient Accents ────────────────────────────────────────────
        // How an active fill is painted, so it lives with the palette that decides
        // its colour.
        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: 6
            radius: Services.Sizes.cardR
            color: Services.Colors.fillInset
            implicitHeight: gradCol.implicitHeight + 24

            ColumnLayout {
                id: gradCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 12
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Text { textFormat: Text.PlainText; text: ""; font.family: "Material Symbols Rounded"; font.pixelSize: 15; color: Services.Colors.ghost }
                    Text { textFormat: Text.PlainText; text: Services.I18n.t("settings.look.gradients"); color: Services.Colors.snow; font.pixelSize: Services.Sizes.fsBody; font.bold: true; font.family: "JetBrainsMono NF" }
                    Item { Layout.fillWidth: true }
                    Toggle {
                        checked: Services.Prefs.useGradients
                        onToggled: Services.Prefs.useGradients = !Services.Prefs.useGradients
                    }
                }

                // The switch showing what it does, rather than a sentence
                // describing it: the same fill every active pill will wear.
                Rectangle {
                    Layout.fillWidth: true
                    Layout.topMargin: 2
                    Layout.preferredHeight: 22
                    radius: Services.Sizes.innerR
                    color: Services.Colors.ghost
                    gradient: Services.Prefs.useGradients ? Services.Colors.accentGradient : null
                }
            }
        }


    // What every shell surface is made of: solid, or glass like the terminal.
    Card {
        title: Services.I18n.t("settings.look.surface")

        Segmented {
            options: [
                { id: "solid", label: Services.I18n.t("settings.look.solid") },
                { id: "blur", label: Services.I18n.t("settings.look.blur") },
            ]
            current: Services.Prefs.surfaceStyle
            onPicked: id => Services.Prefs.surfaceStyle = id
        }
    }

    // Every outline in the shell, in one place: all of it, none, or part by part.
    Card {
        id: outlineCard
        title: Services.I18n.t("settings.layout.outline")

        readonly property var flags: [Services.Prefs.barOutline, Services.Prefs.panelOutline,
                                      Services.Prefs.widgetOutline, Services.Prefs.dockGlass]
        readonly property string derived: flags.every(f => f) ? "all"
                                        : flags.every(f => !f) ? "none" : "custom"
        property bool customOpen: false

        Segmented {
            options: [
                { id: "none", label: Services.I18n.t("settings.look.outlineNone") },
                { id: "all", label: Services.I18n.t("settings.look.outlineAll") },
                { id: "custom", label: Services.I18n.t("settings.look.outlineCustom") }
            ]
            current: outlineCard.customOpen ? "custom" : outlineCard.derived
            onPicked: id => {
                outlineCard.customOpen = id === "custom"
                if (id === "custom") return
                const on = id === "all"
                Services.Prefs.barOutline = on
                Services.Prefs.panelOutline = on
                Services.Prefs.widgetOutline = on
                Services.Prefs.dockGlass = on
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: 4
            spacing: 8
            visible: outlineCard.customOpen || outlineCard.derived === "custom"
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                RowGlyph { glyph: "\ue9f7" }        // toolbar
                Text {
                    textFormat: Text.PlainText
                    Layout.fillWidth: true
                    text: Services.I18n.t("settings.tab.bar")
                    color: Services.Colors.snow
                    font.pixelSize: Services.Sizes.fsInput
                    font.family: "JetBrainsMono NF"
                }
                Toggle {
                    checked: Services.Prefs.barOutline
                    onToggled: Services.Prefs.barOutline = !Services.Prefs.barOutline
                }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                RowGlyph { glyph: "\ue069" }        // web_asset
                Text {
                    textFormat: Text.PlainText
                    Layout.fillWidth: true
                    text: Services.I18n.t("settings.tab.panels")
                    color: Services.Colors.snow
                    font.pixelSize: Services.Sizes.fsInput
                    font.family: "JetBrainsMono NF"
                }
                Toggle {
                    checked: Services.Prefs.panelOutline
                    onToggled: Services.Prefs.panelOutline = !Services.Prefs.panelOutline
                }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                RowGlyph { glyph: "\ue1bd" }        // widgets
                Text {
                    textFormat: Text.PlainText
                    Layout.fillWidth: true
                    text: Services.I18n.t("settings.tab.desktop")
                    color: Services.Colors.snow
                    font.pixelSize: Services.Sizes.fsInput
                    font.family: "JetBrainsMono NF"
                }
                Toggle {
                    checked: Services.Prefs.widgetOutline
                    onToggled: Services.Prefs.widgetOutline = !Services.Prefs.widgetOutline
                }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                RowGlyph { glyph: "\uf7e6" }        // dock_to_bottom
                Text {
                    textFormat: Text.PlainText
                    Layout.fillWidth: true
                    text: Services.I18n.t("settings.dock.title")
                    color: Services.Colors.snow
                    font.pixelSize: Services.Sizes.fsInput
                    font.family: "JetBrainsMono NF"
                }
                Toggle {
                    checked: Services.Prefs.dockGlass
                    onToggled: Services.Prefs.dockGlass = !Services.Prefs.dockGlass
                }
            }
        }
    }

    Card {
        title: Services.I18n.t("settings.tab.panels")

        SectionLabel { text: Services.I18n.t("settings.look.howOpen") }

        Segmented {
            options: [
                { id: "morph", label: Services.I18n.t("settings.look.transform") },
                { id: "plain", label: Services.I18n.t("settings.look.window") },
            ]
            current: Services.Prefs.panelStyle
            onPicked: id => Services.Prefs.panelStyle = id
        }
    }




    Item { Layout.preferredHeight: 8 }
        }
    }
}
