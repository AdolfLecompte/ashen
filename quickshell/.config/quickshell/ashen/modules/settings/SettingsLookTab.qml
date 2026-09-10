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
        visible: false   // the drawer header carries the section name
        text: Services.I18n.t("settings.look.theme")
        color: Services.Colors.snow
        font.pixelSize: Services.Sizes.fsPanelTitle
        font.bold: true
        font.family: "JetBrainsMono NF"
    }


    // A box, not a rule.
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
                scale: Services.Sizes.hoverScaleFor(width, dynHover.containsMouse, dynHover.pressed)
                Behavior on scale { NumberAnimation { duration: Services.Sizes.pillHoverMs; easing.type: Services.Sizes.easeOut } }
                border.color: active ? Services.Colors.ghost : "transparent"
                border.width: active ? 2 : 0
                Behavior on color { ColorAnimation { duration: Services.Sizes.msMicro } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 12

                    Text {
                        text: ""
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 18
                        color: Services.Colors.ghost
                    }
                    ColumnLayout {
                        spacing: 1
                        Text { text: Services.I18n.t("settings.look.dynamic"); color: Services.Colors.snow; font.pixelSize: Services.Sizes.fsInput; font.bold: true; font.family: "JetBrainsMono NF" }
                        Text { text: Services.I18n.t("settings.look.fromWallpaper"); color: Services.Colors.mist; font.pixelSize: Services.Sizes.fsMeta; font.family: "JetBrainsMono NF" }
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
                        Behavior on color { ColorAnimation { duration: Services.Sizes.msMicro } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            spacing: 10

                            Text {
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
                Behavior on opacity { NumberAnimation { duration: Services.Sizes.msStandard } }

                ColumnLayout {
                    id: dynCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 12
                    spacing: 6

                    RowLayout {
                        spacing: 8
                        Text { text: "\ue65f"; font.family: "Material Symbols Rounded"; font.pixelSize: 15; color: Services.Colors.ghost }
                        Text { text: Services.I18n.t("settings.look.dynStyle"); color: Services.Colors.snow; font.pixelSize: Services.Sizes.fsBody; font.bold: true; font.family: "JetBrainsMono NF" }
                    }
                    Text {
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

                    // Four across, two rows: eight chips of their own width left a
                    // ragged hole at the end of the last row.
                    GridLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 2
                        columns: 4
                        columnSpacing: 8
                        rowSpacing: 8
                        Repeater {
                            model: Services.Theme.dynamicTypes
                            delegate: Rectangle {
                                required property var modelData
                                readonly property bool active: Services.Theme.dynamicType === modelData.id
                                Layout.fillWidth: true
                                Layout.preferredWidth: 1
                                Layout.preferredHeight: 32
                                height: 32
                                radius: Services.Sizes.innerR
                                color: active ? Services.Colors.ghost : Services.Colors.fillLine
                                gradient: Services.Prefs.useGradients && (active) ? Services.Colors.accentGradient : null
                                Behavior on color { ColorAnimation { duration: Services.Sizes.msMicro } }
                                scale: Services.Sizes.hoverScaleFor(width, dynTypeHover.containsMouse, dynTypeHover.pressed)
                                Behavior on scale { NumberAnimation { duration: Services.Sizes.pillHoverMs; easing.type: Services.Sizes.easeOut } }
                                RowLayout {
                                    id: dynRow
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    spacing: 5
                                    Text {
                                        visible: parent.parent.active
                                        text: ""
                                        font.family: "Material Symbols Rounded"
                                        font.pixelSize: 11
                                        color: Services.Colors.accentText
                                    }
                                    Text {
                                        text: modelData.label
                                        font.pixelSize: Services.Sizes.fsBody
                                        font.family: "JetBrainsMono NF"
                                        color: parent.parent.active ? Services.Colors.accentText : Services.Colors.snow
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                }
                                MouseArea {
                                    id: dynTypeHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: { Services.Theme.setDynamicType(modelData.id); Services.Theme.recolor() }
                                }
                            }
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
                    Text { text: ""; font.family: "Material Symbols Rounded"; font.pixelSize: 15; color: Services.Colors.ghost }
                    Text { text: Services.I18n.t("settings.look.gradients"); color: Services.Colors.snow; font.pixelSize: Services.Sizes.fsBody; font.bold: true; font.family: "JetBrainsMono NF" }
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

        // The panels' own outline. Not the bar's: the bar is a strip you look
        // past all day, a panel is a room you opened on purpose, and wanting
        // one drawn and the other filled is a real preference.
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
                checked: Services.Prefs.panelOutline
                onToggled: Services.Prefs.panelOutline = !Services.Prefs.panelOutline
            }
        }
    }


    // ── This wallpaper's own look ───────────────────────────────────────
    Card {
        title: Services.I18n.t("settings.look.profile")

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
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

        Text {
            // Which wallpaper is wearing the look, or nothing at all.
            visible: text !== ""
            text: Services.Looks.remembering
                ? Services.I18n.t("settings.look.follows", { w: Services.Looks.current.split("/").pop() }) : ""
            color: Services.Colors.ash
            font.pixelSize: Services.Sizes.fsMeta
            font.family: "JetBrainsMono NF"
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
    }


    Item { Layout.preferredHeight: 8 }
        }
    }
}
