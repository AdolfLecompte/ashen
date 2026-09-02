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
    // What the profile-picture card is doing right now: "" (idle), "picking"
    // while the file dialog is up, "done" / "failed" for a moment after. The
    // Copy Info button below works the same way -- a word in the button is the
    // only confirmation a card like this can give.
    property string faceState: ""

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
            text: "About"
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
            Behavior on color { ColorAnimation { duration: Services.Sizes.msMicro } }
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
                    text: tab.copied ? "Copied" : "Copy Info"
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


    // The face the lock screen shows. It belongs with who the machine is, not
    // with how it is painted.
    PreviewCard {
        source: Services.AppState.facePath
        fallbackGlyph: "\uf0d3"
        title: "Profile Picture"
        subtitle: Services.AppState.userLabel
        // The button IS the progress report: there is nowhere else on this card
        // to say that a dialog is open or that the copy landed.
        action: tab.faceState === "picking" ? "Choosing…"
              : tab.faceState === "done" ? "Updated"
              : tab.faceState === "failed" ? "Failed" : "Change"
        busy: tab.faceState === "picking"
        onTriggered: {
            tab.faceState = "picking"
            Services.Picker.open("profile", "")
        }
    }
    // Puts the word back to "Change" once it has been read.
    Timer {
        id: faceStateTimer
        interval: 1500
        onTriggered: tab.faceState = ""
    }

    // The shell's own picker, not zenity: same dialog as the widget pictures,
    // and it looks like the rest of the desktop.
    Connections {
        target: Services.Picker
        function onPicked(purpose, path) {
            if (purpose !== "profile") return
            if (path === "" || Services.AppState.homeDir === "") { tab.faceState = ""; return }
            faceCopyProc.command = ["cp", path, Services.AppState.homeDir + "/.face"]
            faceCopyProc.running = true
        }
        // Closed without choosing: not a failure, and not a change.
        function onVisibleChanged() {
            if (!Services.Picker.visible && tab.faceState === "picking") tab.faceState = ""
        }
    }

    Process {
        id: faceCopyProc
        running: false
        // The version bump is what every copy of the face repaints off, so it
        // is only earned when the copy actually succeeded -- it used to fire
        // even when nothing had been written.
        onExited: (code) => {
            if (code !== 0) {
                tab.faceState = "failed"
                faceStateTimer.restart()
                Services.Notifications.addSystemToast(
                    "COULD NOT SET PROFILE PICTURE", "\uf008", false, "face")
                return
            }
            Services.AppState.faceVersion = Date.now()
            tab.faceState = "done"
            faceStateTimer.restart()
            // Same shape as the screenshot toast: the picture you just chose,
            // shown back to you. One `typeKey`, so a second change replaces the
            // first instead of stacking.
            Services.Notifications.addSystemToast(
                "PROFILE PICTURE UPDATED", "\uf008", false, "face",
                { image: Services.AppState.facePath })
        }
    }

    // A box, not a rule: the panel says where one thing ends by
    // starting the next one, the way every other tab does.
    Card {
        title: "This machine"
        ColumnLayout {
            Layout.topMargin: 6
            spacing: 5

            Repeater {
                model: [
                    { label: "OS", value: tab.osName },
                    { label: "Kernel", value: tab.kernel },
                    { label: "Host", value: tab.hostname },
                    { label: "Product", value: tab.product },
                    { label: "Board", value: tab.board },
                    { label: "Uptime", value: tab.uptime },
                    { label: "CPU", value: tab.cpuInfo },
                    { label: "GPU", value: tab.gpuInfo },
                    { label: "Memory", value: tab.memInfo },
                    { label: "Disk", value: tab.diskInfo },
                    { label: "Packages", value: tab.pkgInfo },
                    { label: "Monitor", value: tab.monitorInfo },
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

    Widgets.Divider { Layout.topMargin: 10; Layout.bottomMargin: 4 }

    ColumnLayout {
        spacing: 4
        Text {
            text: "ASHEN"
            color: Services.Colors.snow
            font.pixelSize: Services.Sizes.fsReadout
            font.bold: true
            font.family: "JetBrainsMono NF"
            font.letterSpacing: 2
        }
        Text {
            text: "A monochrome Hyprland shell, built with Quickshell"
            color: Services.Colors.mist
            font.pixelSize: Services.Sizes.fsBody
            font.family: "JetBrainsMono NF"
        }
        Text {
            text: "by Adolf"
            color: Services.Colors.ash
            font.pixelSize: Services.Sizes.fsBody
            font.family: "JetBrainsMono NF"
            Layout.topMargin: 2
        }
    }

    Rectangle {
        Layout.topMargin: 12
        width: repoRow.implicitWidth + 24
        height: 40
        radius: Services.Sizes.pillR
        color: Services.Colors.fillRest
        scale: Services.Sizes.hoverScale(linkHover.containsMouse, linkHover.pressed)
        Behavior on scale { NumberAnimation { duration: Services.Sizes.pillHoverMs; easing.type: Services.Sizes.easeOut } }
        RowLayout {
            id: repoRow
            anchors.centerIn: parent
            spacing: 8
            Text {
                text: ""
                font.family: "Material Symbols Rounded"
                font.pixelSize: 16
                color: Services.Colors.ghost
            }
            Text {
                text: "github.com/AdolfLecompte/ashen"
                color: Services.Colors.snow
                font.pixelSize: Services.Sizes.fsBody
                font.family: "JetBrainsMono NF"
            }
            Text {
                text: ""
                font.family: "Material Symbols Rounded"
                font.pixelSize: 14
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
