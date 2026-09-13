import Quickshell
import QtQuick
import QtQuick.Layouts
import "root:/services" as Services
import "root:/modules/widgets" as Widgets
import "root:/modules/settings/components"

// What the shell is allowed to interrupt you with, and how long it may stay.
Section {
    id: tab
    Card {
        title: Services.I18n.t("settings.notify.dnd")

        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            RowGlyph { glyph: "" }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text {
                    text: Services.I18n.t("settings.notify.silence")
                    color: Services.Colors.snow
                    font.pixelSize: Services.Sizes.fsInput
                    font.bold: true
                    font.family: "JetBrainsMono NF"
                }
            }
            Item { Layout.fillWidth: true }
            Toggle {
                checked: Services.AppState.doNotDisturb
                onToggled: Services.AppState.doNotDisturb = !Services.AppState.doNotDisturb
            }
        }
    }

    Card {
        title: Services.I18n.t("settings.notify.toasts")

        SectionLabel { text: Services.I18n.t("settings.notify.duration") }
        Segmented {
            options: [
                { id: "3", label: "3s" },
                { id: "6", label: "6s" },
                { id: "10", label: "10s" },
                { id: "20", label: "20s" }
            ]
            current: String(Services.Prefs.toastSeconds)
            onPicked: id => Services.Prefs.toastSeconds = parseInt(id)
        }
        SectionLabel { text: Services.I18n.t("settings.notify.stack") }
        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            Segmented {
                options: [
                    { id: "3", label: "3" },
                    { id: "5", label: "5" },
                    { id: "8", label: "8" }
                ]
                current: String(Services.Prefs.maxToasts)
                onPicked: id => Services.Prefs.maxToasts = parseInt(id)
            }
        }
    }

    // Lives here, not in Sound: every preference behind it belongs to
    // Notifications (`notifySound`, `notifySoundFile`, `soundVolume`), and the
    // Sound tab is about what the machine plays, not about what interrupts you.
    Card {
        title: Services.I18n.t("settings.notify.sound")

        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            RowGlyph { glyph: "" }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text {
                    text: Services.I18n.t("settings.notify.play")
                    color: Services.Colors.snow
                    font.pixelSize: Services.Sizes.fsInput
                    font.bold: true
                    font.family: "JetBrainsMono NF"
                }
            }
            Item { Layout.fillWidth: true }
            Toggle {
                checked: Services.Prefs.notifySound
                onToggled: Services.Prefs.notifySound = !Services.Prefs.notifySound
            }
        }

        Collapse {
            open: Services.Prefs.notifySound
            gap: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text {
                        text: Services.I18n.t("settings.notify.critical")
                        color: Services.Colors.snow
                        font.pixelSize: Services.Sizes.fsInput
                        font.bold: true
                        font.family: "JetBrainsMono NF"
                    }
                }
                Item { Layout.fillWidth: true }
                Toggle {
                    checked: Services.Prefs.notifySoundCriticalOnly
                    onToggled: Services.Prefs.notifySoundCriticalOnly = !Services.Prefs.notifySoundCriticalOnly
                }
            }

            // The slider speaks in whole percent, the preference in 0..1.
            Widgets.SliderRow {
                glyph: ""
                label: Services.I18n.t("common.volume")
                value: Math.round(Services.Prefs.soundVolume * 100)
                onMoved: pct => Services.Prefs.soundVolume = pct / 100
            }

            SectionLabel { text: Services.I18n.t("settings.notify.sound") }

            // The freedesktop set every distribution ships, plus whatever the
            // user points at. Picking one plays it: choosing a sound you cannot
            // hear is choosing blind.
            // Two columns of equal chips, not a row of their own widths: the
            // names are all different lengths and the last line ended wherever
            // it happened to end.
            Flow {
                id: soundFlow
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                    id: soundRep
                    model: Services.Notifications.soundChoices

                    delegate: Item {
                        id: chip
                        required property var modelData
                        required property int index
                        readonly property bool active:
                            Services.Notifications.soundFile === chip.modelData.path
                        readonly property bool warm: soundHover.containsMouse
                        // An odd count leaves the last one alone: it takes the
                        // whole row instead of half of it.
                        readonly property bool alone: chip.index === soundRep.count - 1
                                                      && soundRep.count % 2 === 1

                        implicitWidth: chip.alone ? soundFlow.width
                                                  : (soundFlow.width - soundFlow.spacing) / 2
                        implicitHeight: Services.Sizes.innerH
                        Rectangle {
                            anchors.fill: parent
                            radius: Services.Sizes.innerR
                            color: chip.active ? Services.Colors.ghost : Services.Colors.fillRest
                            gradient: Services.Prefs.useGradients && chip.active
                                ? Services.Colors.accentGradient : null
                            Behavior on color { Widgets.ColorAnim {} }
                        }

                        Text {
                            id: soundName
                            anchors.centerIn: parent
                            // The box holds still, the name grows: same as every
                            // other button in Settings.
                            scale: Services.Sizes.hoverScaleFor(chip.width, chip.warm, soundHover.pressed)
                            Behavior on scale { NumberAnimation { duration: Services.Sizes.pillHoverMs; easing.type: Services.Sizes.easeOut } }
                            width: parent.width - 16
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignHCenter
                            // The shell's own are marked: they travel with the
                            // rice, the rest are whatever this machine has.
                            text: (chip.modelData.mine ? "✦ " : "") + chip.modelData.name
                            color: chip.active ? Services.Colors.accentText
                                 : chip.warm ? Services.Colors.snow : Services.Colors.surfaceText
                            font.pixelSize: Services.Sizes.fsBody
                            font.family: "JetBrainsMono NF"
                            Behavior on color { Widgets.ColorAnim {} }
                        }
                        MouseArea {
                            id: soundHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Services.Prefs.notifySoundFile = chip.modelData.path
                                Services.Notifications.play(chip.modelData.path)
                            }
                        }
                    }
                }
            }
        }
    }

    Item { Layout.preferredHeight: 8 }
}
