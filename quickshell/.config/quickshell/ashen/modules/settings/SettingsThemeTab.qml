import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "root:/services" as Services

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

    property string currentFont: "JetBrainsMono NF"

    property var schemes: {
        "classic": { abyss: "#080809", void_: "#0f0f11", crypt: "#16161a", surface: "#1c1c21", raised: "#242428", elevated: "#2e2e34", snow: "#e8e8ec", mist: "#9090a0", ash: "#4a4a54", ghost: "#6e6e7a", shade: "#4e4e5a", error_: "#c87a7a", neutral: "#8a8a96" },
        "cyberpunk": { abyss: "#0d0221", void_: "#150829", crypt: "#1a0b2e", surface: "#241b3d", raised: "#2d2347", elevated: "#3a2d5c", snow: "#f0f0ff", mist: "#b8a9d9", ash: "#5e4b8b", ghost: "#ff2e97", shade: "#cc1f7a", error_: "#ff3860", neutral: "#00fff2" },
        "tokyonight": { abyss: "#16161e", void_: "#1a1b26", crypt: "#1f2335", surface: "#24283b", raised: "#292e42", elevated: "#364a82", snow: "#c0caf5", mist: "#a9b1d6", ash: "#565f89", ghost: "#7aa2f7", shade: "#3d59a1", error_: "#f7768e", neutral: "#bb9af7" },
        "dracula": { abyss: "#21222c", void_: "#282a36", crypt: "#2d2f3f", surface: "#343746", raised: "#44475a", elevated: "#4d5066", snow: "#f8f8f2", mist: "#9ba0c4", ash: "#6272a4", ghost: "#bd93f9", shade: "#9580c9", error_: "#ff5555", neutral: "#ff79c6" },
        "nord": { abyss: "#2e3440", void_: "#3b4252", crypt: "#434c5e", surface: "#434c5e", raised: "#4c566a", elevated: "#4c566a", snow: "#eceff4", mist: "#d8dee9", ash: "#4c566a", ghost: "#88c0d0", shade: "#5e81ac", error_: "#bf616a", neutral: "#b48ead" },
    }

    Component.onCompleted: fontCheckProc.running = true
    Process {
        id: fontCheckProc
        command: ["sh", "-c", "grep -o '<string>[^<]*</string>' /home/adolf-arch/.config/fontconfig/fonts.conf 2>/dev/null | tail -1 | sed 's/<[^>]*>//g'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let f = text.trim()
                if (f.length > 0) tab.currentFont = f
            }
        }
    }

    function applyFont(fontName) {
        tab.currentFont = fontName
        let xml = fontName === 'JetBrainsMono NF'
            ? '<?xml version="1.0"?><!DOCTYPE fontconfig SYSTEM "fonts.dtd"><fontconfig></fontconfig>'
            : '<?xml version="1.0"?><!DOCTYPE fontconfig SYSTEM "fonts.dtd"><fontconfig><match target="pattern"><test name="family"><string>JetBrainsMono NF</string></test><edit name="family" mode="assign" binding="strong"><string>' + fontName + '</string></edit></match></fontconfig>'
        let b64 = Qt.btoa(xml)
        Quickshell.execDetached(["sh", "-c",
            "mkdir -p ~/.config/fontconfig && echo '" + b64 + "' | base64 -d > ~/.config/fontconfig/fonts.conf && fc-cache -f && pkill -9 quickshell; sleep 0.3; quickshell -c ashen &"
        ])
    }

    function applyScheme(schemeId) {
        let c = tab.schemes[schemeId]
        if (!c) return
        let qml = 'pragma Singleton\nimport Quickshell\nimport QtQuick\nSingleton {\n' +
            '    id: root\n' +
            '    readonly property color abyss:   "' + c.abyss + '"\n' +
            '    readonly property color void_:   "' + c.void_ + '"\n' +
            '    readonly property color crypt:   "' + c.crypt + '"\n' +
            '    readonly property color surface:  "' + c.surface + '"\n' +
            '    readonly property color raised:   "' + c.raised + '"\n' +
            '    readonly property color elevated: "' + c.elevated + '"\n' +
            '    readonly property color snow:     "' + c.snow + '"\n' +
            '    readonly property color mist:     "' + c.mist + '"\n' +
            '    readonly property color ash:      "' + c.ash + '"\n' +
            '    readonly property color ghost:    "' + c.ghost + '"\n' +
            '    readonly property color shade:    "' + c.shade + '"\n' +
            '    readonly property color error_:   "' + c.error_ + '"\n' +
            '    readonly property color neutral:  "' + c.neutral + '"\n' +
            '    function ghostAlpha(a) { return Qt.rgba(ghost.r, ghost.g, ghost.b, a) }\n' +
            '    function surfaceAlpha(a) { return Qt.rgba(surface.r, surface.g, surface.b, a) }\n' +
            '    function snowAlpha(a) { return Qt.rgba(snow.r, snow.g, snow.b, a) }\n' +
            '}\n'
        let b64 = Qt.btoa(qml)
        let borderHex = c.ghost.replace("#", "") + "ff"
        Quickshell.execDetached(["sh", "-c",
            "echo '" + b64 + "' | base64 -d > /home/adolf-arch/ashen/quickshell/.config/quickshell/ashen/services/Colors.qml && " +
            "echo '" + schemeId + "' > /home/adolf-arch/.cache/ashen_scheme_mode.txt && " +
            "hyprctl eval \"hl.config({ general = { col = { active_border = { colors = {'rgba(" + borderHex + ")'} } } } })\" && " +
            "sed -i 's/active_border = { colors = {\"rgba([^)]*)\"} }/active_border = { colors = {\"rgba(" + borderHex + ")\"} }/' /home/adolf-arch/ashen/hypr/.config/hypr/conf/general.lua && " +
            "pkill -9 quickshell; sleep 0.3; quickshell -c ashen &"
        ])
    }

    Text {
        text: "Theme"
        color: Services.Colors.snow
        font.pixelSize: 20
        font.bold: true
        font.family: "JetBrainsMono NF"
    }
    ColumnLayout {
        id: schemeSection
        Layout.fillWidth: true
        spacing: 8
        RowLayout {
            spacing: 10
            Text { text: ""; font.family: "Material Symbols Rounded"; font.pixelSize: 18; color: Services.Colors.ghost }
            Text { text: "Color Scheme"; color: Services.Colors.snow; font.pixelSize: 13; font.bold: true; font.family: "JetBrainsMono NF" }
        }

        Flow {
            Layout.fillWidth: true
            spacing: 10
            Repeater {
                model: [
                    { id: "classic", label: "Classic", subtitle: "Ashen Ghost", swatches: ["#080809", "#1c1c21", "#6e6e7a", "#e8e8ec"] },
                    { id: "cyberpunk", label: "Cyberpunk", subtitle: "Neon nights", swatches: ["#0d0221", "#241b3d", "#ff2e97", "#00fff2"] },
                    { id: "tokyonight", label: "Tokyo Night", subtitle: "Calm blues", swatches: ["#1a1b26", "#24283b", "#7aa2f7", "#bb9af7"] },
                    { id: "dracula", label: "Dracula", subtitle: "Classic dark", swatches: ["#282a36", "#343746", "#bd93f9", "#ff79c6"] },
                    { id: "nord", label: "Nord", subtitle: "Arctic cool", swatches: ["#2e3440", "#434c5e", "#88c0d0", "#b48ead"] },
                    { id: "dynamic", label: "Dynamic", subtitle: "From wallpaper", swatches: [] },
                ]
                delegate: Rectangle {
                    required property var modelData
                    width: 150; height: 80
                    radius: 12
                    color: Services.Colors.ghostAlpha(0.15)
                    Behavior on color { ColorAnimation { duration: 150 } }
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 6
                        ColumnLayout {
                            spacing: 2
                            Text { text: modelData.label; color: Services.Colors.snow; font.pixelSize: 13; font.bold: true; font.family: "JetBrainsMono NF"; Layout.alignment: Qt.AlignHCenter }
                            Text { text: modelData.subtitle; color: Services.Colors.mist; font.pixelSize: 10; font.family: "JetBrainsMono NF"; Layout.alignment: Qt.AlignHCenter }
                        }
                        Row {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 4
                            visible: modelData.swatches.length > 0
                            Repeater {
                                model: modelData.swatches
                                delegate: Rectangle {
                                    required property string modelData
                                    width: 16; height: 16
                                    radius: 5
                                    color: modelData
                                    border.color: Qt.rgba(1, 1, 1, 0.15)
                                    border.width: 1
                                }
                            }
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onEntered: parent.color = Services.Colors.ghostAlpha(0.3)
                        onExited: parent.color = Services.Colors.ghostAlpha(0.15)
                        onClicked: {
                            if (modelData.id === "dynamic") {
                                Quickshell.execDetached(["sh", "-c",
                                    "echo 'dynamic' > /home/adolf-arch/.cache/ashen_scheme_mode.txt && " +
                                    "matugen image \"$(awww query | grep -o 'image: .*' | cut -d' ' -f2)\" --mode dark --source-color-index 0 --type $(cat /home/adolf-arch/.cache/ashen_dynamic_type.txt 2>/dev/null || echo scheme-tonal-spot)"
                                ])
                            } else {
                                tab.applyScheme(modelData.id)
                            }
                        }
                    }
                }
            }
        }
        Text { text: "'Dynamic' opens the wallpaper picker -- colors regenerate automatically when you pick one"; color: Services.Colors.ash; font.pixelSize: 10; font.family: "JetBrainsMono NF"; wrapMode: Text.WordWrap; Layout.fillWidth: true }

        Text { text: "Dynamic Style"; color: Services.Colors.snow; font.pixelSize: 12; font.bold: true; font.family: "JetBrainsMono NF"; Layout.topMargin: 10 }
        Text { text: "How aggressively Dynamic pulls color from the wallpaper"; color: Services.Colors.ash; font.pixelSize: 10; font.family: "JetBrainsMono NF" }

        property string dynamicType: "scheme-tonal-spot"
        Component.onCompleted: dynTypeProc.running = true
        Process {
            id: dynTypeProc
            command: ["sh", "-c", "cat /home/adolf-arch/.cache/ashen_dynamic_type.txt 2>/dev/null"]
            running: false
            stdout: StdioCollector {
                onStreamFinished: {
                    let t = text.trim()
                    if (t.length > 0) schemeSection.dynamicType = t
                }
            }
        }
        function setDynamicType(t) {
            schemeSection.dynamicType = t
            Quickshell.execDetached(["sh", "-c", "echo '" + t + "' > /home/adolf-arch/.cache/ashen_dynamic_type.txt"])
        }

        Flow {
            Layout.fillWidth: true
            spacing: 8
            Repeater {
                model: [
                    { id: "scheme-monochrome", label: "Monochrome" },
                    { id: "scheme-neutral", label: "Neutral" },
                    { id: "scheme-tonal-spot", label: "Tonal Spot" },
                    { id: "scheme-vibrant", label: "Vibrant" },
                    { id: "scheme-expressive", label: "Expressive" },
                    { id: "scheme-fidelity", label: "Fidelity" },
                    { id: "scheme-content", label: "Content" },
                    { id: "scheme-rainbow", label: "Rainbow" },
                    { id: "scheme-fruit-salad", label: "Fruit Salad" },
                ]
                delegate: Rectangle {
                    required property var modelData
                    width: dynRow.implicitWidth + 20
                    height: 32
                    radius: 8
                    color: schemeSection.dynamicType === modelData.id ? Services.Colors.ghost : Services.Colors.ghostAlpha(0.12)
                    Behavior on color { ColorAnimation { duration: 150 } }
                    RowLayout {
                        id: dynRow
                        anchors.centerIn: parent
                        spacing: 5
                        Text {
                            visible: schemeSection.dynamicType === modelData.id
                            text: ""
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 11
                            color: Services.Colors.abyss
                        }
                        Text {
                            text: modelData.label
                            font.pixelSize: 11
                            font.family: "JetBrainsMono NF"
                            color: schemeSection.dynamicType === modelData.id ? Services.Colors.abyss : Services.Colors.snow
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: schemeSection.setDynamicType(modelData.id)
                    }
                }
            }
        }
    }

    Rectangle { Layout.fillWidth: true; height: 1; color: Services.Colors.ghostAlpha(0.15) }

    RowLayout {
        Layout.fillWidth: true
        spacing: 12
        Text { text: ""; font.family: "Material Symbols Rounded"; font.pixelSize: 20; color: Services.Colors.ghost }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Text { text: "Wallpaper"; color: Services.Colors.snow; font.pixelSize: 13; font.bold: true; font.family: "JetBrainsMono NF" }
            Text { text: "Choose or add wallpapers"; color: Services.Colors.mist; font.pixelSize: 10; font.family: "JetBrainsMono NF" }
        }
        Rectangle {
            width: 90; height: 34
            radius: 8
            color: Services.Colors.ghostAlpha(0.15)
            Behavior on color { ColorAnimation { duration: 150 } }
            Text { anchors.centerIn: parent; text: "Open"; color: Services.Colors.snow; font.pixelSize: 12; font.family: "JetBrainsMono NF" }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onEntered: parent.color = Services.Colors.ghostAlpha(0.3)
                onExited: parent.color = Services.Colors.ghostAlpha(0.15)
                onClicked: {
                    Services.AppState.settingsVisible = false
                    Services.AppState.wallpaperVisible = true
                }
            }
        }
    }

    Rectangle { Layout.fillWidth: true; height: 1; color: Services.Colors.ghostAlpha(0.15) }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 8
        RowLayout {
            spacing: 10
            Text { text: ""; font.family: "Material Symbols Rounded"; font.pixelSize: 18; color: Services.Colors.ghost }
            Text { text: "System Font"; color: Services.Colors.snow; font.pixelSize: 13; font.bold: true; font.family: "JetBrainsMono NF" }
        }
        Text { text: "Restarts the shell to apply"; color: Services.Colors.ash; font.pixelSize: 10; font.family: "JetBrainsMono NF" }

        Flow {
            Layout.fillWidth: true
            spacing: 8
            Repeater {
                model: [
                    "JetBrainsMono NF",
                    "FiraCode Nerd Font",
                    "Hack Nerd Font",
                    "CaskaydiaCove Nerd Font",
                    "Iosevka Nerd Font",
                    "MesloLGS Nerd Font",
                    "ProggyClean Nerd Font",
                ]
                delegate: Rectangle {
                    required property string modelData
                    width: fontLabelRow.implicitWidth + 24
                    height: 36
                    radius: 8
                    color: tab.currentFont === modelData ? Services.Colors.ghost : Services.Colors.ghostAlpha(0.12)
                    Behavior on color { ColorAnimation { duration: 150 } }
                    RowLayout {
                        id: fontLabelRow
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            visible: tab.currentFont === modelData
                            text: "\uf0be"
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 12
                            color: Services.Colors.abyss
                        }
                        Text {
                            text: modelData
                            font.pixelSize: 12
                            font.family: modelData
                            color: tab.currentFont === modelData ? Services.Colors.abyss : Services.Colors.snow
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: tab.applyFont(modelData)
                    }
                }
            }
        }
    }

    Item { Layout.preferredHeight: 8 }
        }
    }
}
