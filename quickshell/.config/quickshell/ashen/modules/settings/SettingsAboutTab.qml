import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "root:/services" as Services
import "root:/modules/widgets" as Widgets
import "root:/modules/settings/components"

// TabPage, like every other tab: on its own this was a bare ColumnLayout with
// no Flickable, so it was the one section in Settings that could not be
// scrolled and anything past the fold was simply unreachable.
Section {
    id: tab

    // The specs live in services/Machine.qml now: the desktop's Machine widget
    // asks the same questions, and two copies of eight processes is two copies
    // of the same answer.
    readonly property string osName: Services.Machine.osName
    readonly property string kernel: Services.Machine.kernel
    readonly property string hostname: Services.Machine.hostname
    readonly property string uptime: Services.Machine.uptime
    readonly property string product: Services.Machine.product
    readonly property string board: Services.Machine.board
    readonly property string cpuInfo: Services.Machine.cpuInfo
    readonly property string gpuInfo: Services.Machine.gpuInfo
    readonly property string memInfo: Services.Machine.memInfo
    readonly property string diskInfo: Services.Machine.diskInfo
    readonly property string pkgInfo: Services.Machine.pkgInfo
    readonly property string monitorInfo: Services.Machine.monitorInfo
    property bool copied: false

    // Uptime moves; the rest are settled by the time the tab is open.
    Component.onCompleted: Services.Machine.watch(true)
    Component.onDestruction: Services.Machine.watch(false)

    Process { id: copyProc; running: false }
    function copyInfo() {
        let info = "OS: " + tab.osName + "\\n" +
            "Kernel: " + tab.kernel + "\\n" +
            "Host: " + tab.hostname + "\\n" +
            "Product: " + tab.product + "\\n" +
            "Board: " + tab.board + "\\n" +
            "Uptime: " + tab.uptime + "\\n" +
            "CPU: " + tab.cpuInfo + "\\n" +
            "GPU: " + tab.gpuInfo + "\\n" +
            "Memory: " + tab.memInfo + "\\n" +
            "Disk: " + tab.diskInfo + "\\n" +
            "Packages: " + tab.pkgInfo + "\\n" +
            "Monitor: " + tab.monitorInfo
        copyProc.command = ["sh", "-c", "printf %s \"$1\" | wl-copy", "sh", info]
        copyProc.running = true
        tab.copied = true
        copiedTimer.restart()
    }
    Timer { id: copiedTimer; interval: 1500; onTriggered: tab.copied = false }

    RowLayout {
        Layout.fillWidth: true
        Text {
            visible: false   // the drawer header carries the section name
            text: Services.I18n.t("settings.tab.about")
            color: Services.Colors.snow
            font.pixelSize: Services.Sizes.fsPanelTitle
            font.bold: true
            font.family: "JetBrainsMono NF"
            Layout.fillWidth: true
        }
        Rectangle {
            width: copyRow.implicitWidth + 18
            height: 32
            radius: Services.Sizes.innerR
            color: tab.copied ? Services.Colors.ghost : Services.Colors.fillLine
            gradient: Services.Prefs.useGradients && (tab.copied) ? Services.Colors.accentGradient : null
            Behavior on color { Widgets.ColorAnim { speed: Services.Sizes.msMicro } }
            RowLayout {
                id: copyRow
                anchors.centerIn: parent
                spacing: 6
                Text {
                    text: tab.copied ? "" : ""
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 14
                    color: tab.copied ? Services.Colors.accentText : Services.Colors.ghost
                }
                Text {
                    text: tab.copied ? Services.I18n.t("settings.about.copied") : Services.I18n.t("settings.about.copy")
                    color: tab.copied ? Services.Colors.accentText : Services.Colors.snow
                    font.pixelSize: Services.Sizes.fsBody
                    font.family: "JetBrainsMono NF"
                }
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: tab.copyInfo()
            }
        }
    }


    // ── This build ───────────────────────────────────────────────────────
    // About named the machine and never named the shell. The version was only
    // ever visible in the release notes, which had no door of their own.
    Card {
        // No title: the mark IS the name, and printing both says it twice.
        // Same rows the terminal and the installer draw, at 12px because the
        // smoke ramp is dithering and larger it separates into dots.
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            Widgets.AshenMark {
                pixelSize: 12
                color: Services.Colors.snow
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Text {
                    text: Services.Release.version === "" ? "—" : Services.Release.version
                    color: Services.Colors.ghost
                    font.pixelSize: Services.Sizes.fsInput
                    font.bold: true
                    font.family: "JetBrainsMono NF"
                }
                Text {
                    Layout.fillWidth: true
                    text: Services.I18n.t("app.tagline")
                    color: Services.Colors.ash
                    elide: Text.ElideRight
                    font.pixelSize: Services.Sizes.fsMeta
                    font.family: "JetBrainsMono NF"
                }
            }
            // The repo is part of what this build IS, so it lives with the mark
            // and the version instead of stranded at the bottom of a tab you
            // have to scroll to reach.
            Rectangle {
                Layout.topMargin: 6
                implicitWidth: repoRow.implicitWidth + 24
                implicitHeight: 36
                radius: Services.Sizes.innerR
                color: Services.Colors.fillRest

                RowLayout {
                    id: repoRow
                    anchors.centerIn: parent
                    spacing: 8
                    // The box holds still and the word grows, like every other
                    // button in Settings.
                    scale: Services.Sizes.hoverScale(linkHover.containsMouse, linkHover.pressed)
                    Behavior on scale { NumberAnimation { duration: Services.Sizes.pillHoverMs; easing.type: Services.Sizes.easeOut } }
                    Text {
                        text: "\ue157"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 15
                        color: linkHover.containsMouse ? Services.Colors.snow : Services.Colors.ghost
                        Behavior on color { Widgets.ColorAnim {} }
                    }
                    Text {
                        text: "github.com/AdolfLecompte/ashen"
                        color: linkHover.containsMouse ? Services.Colors.snow : Services.Colors.surfaceText
                        font.pixelSize: Services.Sizes.fsBody
                        font.family: "JetBrainsMono NF"
                        Behavior on color { Widgets.ColorAnim {} }
                    }
                    Text {
                        text: "\ue89e"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 13
                        color: Services.Colors.mist
                    }
                }
                MouseArea {
                    id: linkHover
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: Quickshell.execDetached(["sh", "-c", "xdg-open https://github.com/AdolfLecompte/ashen"])
                }
            }

        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 2
            spacing: 12
            RowGlyph { glyph: "\ue8b2" }        // history
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                Text {
                    text: Services.I18n.t("settings.about.whatsNew")
                    color: Services.Colors.snow
                    font.pixelSize: Services.Sizes.fsInput
                    font.family: "JetBrainsMono NF"
                }
                Text {
                    text: Services.Voice.pick("about.notes")
                    color: Services.Colors.ash
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    font.pixelSize: Services.Sizes.fsMeta
                    font.family: "JetBrainsMono NF"
                }
            }
            // A door, not a room: the notes screen already exists and reads the
            // CHANGELOG the repo ships.
            ActionBtn {
                label: Services.I18n.t("settings.about.read")
                onGo: {
                    Services.AppState.introMode = "notes"
                    Services.AppState.introVisible = true
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            RowGlyph { glyph: "\ue8d7" }        // system_update
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                Text {
                    text: Services.I18n.t("settings.about.updates")
                    color: Services.Colors.snow
                    font.pixelSize: Services.Sizes.fsInput
                    font.family: "JetBrainsMono NF"
                }
                // The state IS the report: there is nowhere else on this row to
                // say the network was away or that this build is ahead of the
                // newest tag, which a checkout often is. It comes from the
                // phrase bank -- a remark, not a label -- except when there is
                // a version to name, which is information and cannot be a joke.
                Text {
                    // fillWidth or the column shrinks to the phrase and the
                    // button walks left, out of line with the row above it.
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    visible: text !== ""
                    text: Services.Release.checkState === "available"
                          ? Services.Release.statusLine + " \u2014 " + Services.Release.latest
                          : Services.Release.statusLine
                    color: Services.Release.checkState === "available" ? Services.Colors.ghost
                         : Services.Release.checkState === "failed" ? Services.Colors.error_
                         : Services.Colors.ash
                    font.pixelSize: Services.Sizes.fsMeta
                    font.family: "JetBrainsMono NF"
                }
            }
            ActionBtn {
                // Always "Update", never "Check": nobody opens this row wanting
                // to know, they open it wanting the newer one. Looking is the
                // first half of updating, so the button does that half first
                // and the line underneath reports what it found.
                label: Services.I18n.t("settings.about.update")
                accent: Services.Release.checkState === "available"
                onGo: {
                    if (Services.Release.checkState !== "available") { Services.Release.check(); return }
                    // Running the installer again IS the update. The terminal is
                    // whichever one Settings was told to open, never a name.
                    Quickshell.execDetached(["sh", "-c",
                        "ashen-app terminal -e sh -c 'bash \"$HOME/ashen/install/run.sh\"; read -n1'"])
                }
            }
        }
    }

    // A box, not a rule: the panel says where one thing ends by
    // starting the next one, the way every other tab does.
    Card {
        title: Services.I18n.t("settings.about.machine")
        ColumnLayout {
            Layout.topMargin: 6
            spacing: 5

            Repeater {
                model: [
                    { label: Services.I18n.t("settings.about.os"), value: tab.osName },
                    { label: Services.I18n.t("settings.about.kernel"), value: tab.kernel },
                    { label: Services.I18n.t("settings.about.host"), value: tab.hostname },
                    { label: Services.I18n.t("settings.about.product"), value: tab.product },
                    { label: Services.I18n.t("settings.about.board"), value: tab.board },
                    { label: Services.I18n.t("settings.about.uptime"), value: tab.uptime },
                    { label: Services.I18n.t("settings.about.cpu"), value: tab.cpuInfo },
                    { label: Services.I18n.t("settings.about.gpu"), value: tab.gpuInfo },
                    { label: Services.I18n.t("settings.about.memory"), value: tab.memInfo },
                    { label: Services.I18n.t("settings.about.disk"), value: tab.diskInfo },
                    { label: Services.I18n.t("settings.about.packages"), value: tab.pkgInfo },
                    { label: Services.I18n.t("settings.about.monitor"), value: tab.monitorInfo },
                ]
                delegate: RowLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 10
                    Text {
                        text: modelData.label
                        color: Services.Colors.mist
                        font.pixelSize: Services.Sizes.fsBody
                        font.family: "JetBrainsMono NF"
                        Layout.preferredWidth: 80
                    }
                    Text {
                        text: modelData.value
                        color: Services.Colors.snow
                        font.pixelSize: Services.Sizes.fsBody
                        font.family: "JetBrainsMono NF"
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
            }
        }
    }

}
