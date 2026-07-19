import Quickshell
import Quickshell.Io
import QtQuick
import Qt5Compat.GraphicalEffects
import QtQuick.Layouts
import QtQuick.Controls
import "root:/services" as Services

Item {
    anchors.fill: parent

    // Profile picture and Wallpaper are the same card: a rounded preview of an
    // image, a glyph while there is none, a label pinned beside it and one
    // action button.
    component PreviewCard: Rectangle {
        id: card
        property string source: ""
        property string fallbackGlyph: ""
        property string title: ""
        property string subtitle: ""
        property string action: ""
        // Square + crop suits a face; a wallpaper needs a wide tile and a fit,
        // since they run from near-square to 2.76 ultrawide and cropping would
        // hide most of the picture.
        property int previewWidth: 80
        property int previewFill: Image.PreserveAspectCrop
        signal triggered()

        Layout.fillWidth: true
        height: 110
        radius: 12
        color: cardHover.containsMouse ? Services.Colors.ghostAlpha(0.18) : Services.Colors.ghostAlpha(0.1)
        Behavior on color { ColorAnimation { duration: 150 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            // Small gap only: the label belongs to the picture, so it sits next
            // to it rather than drifting into the middle of the card.
            spacing: 12

            Rectangle {
                id: preview
                width: card.previewWidth; height: 80
                radius: 12
                color: Services.Colors.ghostAlpha(0.2)
                clip: true

                Image {
                    id: previewImg
                    anchors.fill: parent
                    source: card.source
                    fillMode: card.previewFill
                    asynchronous: true
                    visible: false
                    // paths are stable while the file behind them changes
                    cache: false
                }
                Rectangle {
                    id: previewMask
                    anchors.fill: previewImg
                    radius: preview.radius
                    visible: false
                }
                OpacityMask {
                    anchors.fill: previewImg
                    source: previewImg
                    maskSource: previewMask
                    visible: previewImg.status === Image.Ready
                }
                Text {
                    anchors.centerIn: parent
                    text: card.fallbackGlyph
                    color: Services.Colors.ghost
                    font.pixelSize: 40
                    font.family: "Material Symbols Rounded"
                    visible: previewImg.status !== Image.Ready
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3
                Text {
                    text: card.title
                    color: Services.Colors.snow
                    font.pixelSize: 15
                    font.bold: true
                    font.family: "JetBrainsMono NF"
                    Layout.alignment: Qt.AlignLeft
                }
                Text {
                    text: card.subtitle
                    color: Services.Colors.mist
                    font.pixelSize: 10
                    font.family: "JetBrainsMono NF"
                    elide: Text.ElideMiddle
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignLeft
                }
            }

            Rectangle {
                width: 90; height: 36
                radius: 8
                color: Services.Colors.ghost
                Text {
                    anchors.centerIn: parent
                    text: card.action
                    color: Services.Colors.abyss
                    font.pixelSize: 12
                    font.bold: true
                    font.family: "JetBrainsMono NF"
                }
            }
        }
        MouseArea {
            id: cardHover
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: card.triggered()
        }
    }

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

            // kitty appends "-<pid>" to the listen_on socket, so we have to walk
            // whichever ones exist instead of assuming the exact path.
            readonly property string kittySockets: "/tmp/kitty-ashen.sock-*"

    property var schemes: {
        "classic": { abyss: "#080809", void_: "#0f0f11", crypt: "#16161a", surface: "#1c1c21", raised: "#242428", elevated: "#2e2e34", snow: "#e8e8ec", mist: "#9090a0", ash: "#4a4a54", ghost: "#6e6e7a", shade: "#4e4e5a", error_: "#c87a7a", neutral: "#8a8a96", papirusColor: "grey" },
        // Strictly greyscale -- no hue anywhere, error_ included (it stays
        // readable through brightness, not colour).
        "monochrome": { abyss: "#050505", void_: "#0d0d0d", crypt: "#131313", surface: "#1a1a1a", raised: "#242424", elevated: "#2e2e2e", snow: "#f2f2f2", mist: "#9e9e9e", ash: "#4d4d4d", ghost: "#d4d4d4", shade: "#8c8c8c", error_: "#b3b3b3", neutral: "#c4c4c4", papirusColor: "grey" },
        "cyberpunk": { abyss: "#0d0221", void_: "#150829", crypt: "#1a0b2e", surface: "#241b3d", raised: "#2d2347", elevated: "#3a2d5c", snow: "#f0f0ff", mist: "#b8a9d9", ash: "#5e4b8b", ghost: "#ff2e97", shade: "#cc1f7a", error_: "#ff3860", neutral: "#00fff2", papirusColor: "magenta" },
        "edgerunners": { abyss: "#05070a", void_: "#080c12", crypt: "#0c1119", surface: "#111827", raised: "#172032", elevated: "#1e2a3f", snow: "#eaf6ff", mist: "#5ef2a4", ash: "#3d5166", ghost: "#fcee0a", shade: "#c9be00", error_: "#ff003c", neutral: "#00e5ff", papirusColor: "yellow" },
        "tokyonight": { abyss: "#16161e", void_: "#1a1b26", crypt: "#1f2335", surface: "#24283b", raised: "#292e42", elevated: "#364a82", snow: "#c0caf5", mist: "#a9b1d6", ash: "#565f89", ghost: "#7aa2f7", shade: "#3d59a1", error_: "#f7768e", neutral: "#bb9af7", papirusColor: "blue" },
        "dracula": { abyss: "#21222c", void_: "#282a36", crypt: "#2d2f3f", surface: "#343746", raised: "#44475a", elevated: "#4d5066", snow: "#f8f8f2", mist: "#9ba0c4", ash: "#6272a4", ghost: "#bd93f9", shade: "#9580c9", error_: "#ff5555", neutral: "#ff79c6", papirusColor: "violet" },
        "nord": { abyss: "#2e3440", void_: "#3b4252", crypt: "#434c5e", surface: "#434c5e", raised: "#4c566a", elevated: "#4c566a", snow: "#eceff4", mist: "#d8dee9", ash: "#4c566a", ghost: "#88c0d0", shade: "#5e81ac", error_: "#bf616a", neutral: "#b48ead", papirusColor: "cyan" },
    }

    function applyScheme(schemeId) {
        let c = tab.schemes[schemeId]
        if (!c) return
        let json = JSON.stringify({
            abyss: c.abyss, void_: c.void_, crypt: c.crypt, surface: c.surface,
            raised: c.raised, elevated: c.elevated, snow: c.snow, mist: c.mist,
            ash: c.ash, ghost: c.ghost, shade: c.shade, error_: c.error_, neutral: c.neutral
        })
        let b64 = Qt.btoa(json)
        let borderHex = c.ghost.replace("#", "") + "ff"
        Quickshell.execDetached(["sh", "-c",
            "echo '" + b64 + "' | base64 -d > /home/adolf/.cache/ashen_scheme.json && " +
            "echo '" + schemeId + "' > /home/adolf/.cache/ashen_scheme_mode.txt && " +
            "hyprctl eval \"hl.config({ general = { col = { active_border = { colors = {'rgba(" + borderHex + ")'} } } } })\" && " +
            "sed -i 's/active_border = { colors = {\"rgba([^)]*)\"} }/active_border = { colors = {\"rgba(" + borderHex + ")\"} }/' /home/adolf/ashen/hypr/.config/hypr/conf/general.lua"
        ])
        tab.applyGtkTheme(c)
        tab.applyKittyTheme(c)
        tab.applyP10kTheme(c)
    }

    function applyKittyTheme(c) {
        let conf = '# Generated by Ashen -- do NOT edit by hand, regenerated when the scheme changes\n' +
            'foreground            ' + c.snow + '\n' +
            'background            ' + c.abyss + '\n' +
            'selection_foreground  ' + c.abyss + '\n' +
            'selection_background  ' + c.ghost + '\n' +
            'cursor                ' + c.ghost + '\n' +
            'color0  ' + c.abyss + '\n' +
            'color1  ' + c.error_ + '\n' +
            'color2  #5a7a6a\n' +
            'color3  #8a7a5a\n' +
            // ANSI blue is the scheme accent (same as in p10k), so whatever the
            // terminal paints as "blue" follows the theme: fastfetch,
            // prompt, etc.
            'color4  ' + c.ghost + '\n' +
            'color5  #a89bc8\n' +
            'color6  #5a7a8a\n' +
            'color7  ' + c.mist + '\n' +
            'color8  ' + c.ash + '\n' +
            'color9  ' + c.error_ + '\n' +
            'color10 #7a9e7e\n' +
            'color11 #c4a882\n' +
            'color12 ' + c.neutral + '\n' +
            'color13 #c8b8e8\n' +
            'color14 #7aaabb\n' +
            'color15 ' + c.snow + '\n'
        let b64 = Qt.btoa(conf)
        Quickshell.execDetached(["sh", "-c",
            "echo '" + b64 + "' | base64 -d > \"$HOME/.config/kitty/ashen-colors.conf\" && " +
            "for s in " + tab.kittySockets + "; do kitten @ --to \"unix:$s\" set-colors --all " +
            "foreground=" + c.snow + " background=" + c.abyss + " " +
            "selection_foreground=" + c.abyss + " selection_background=" + c.ghost + " " +
            "cursor=" + c.ghost + " color0=" + c.abyss + " color1=" + c.error_ + " " +
            "color7=" + c.mist + " color8=" + c.ash + " color9=" + c.error_ + " color15=" + c.snow + " " +
            "2>/dev/null; done"
        ])
    }

    function applyP10kTheme(c) {
        Quickshell.execDetached(["sh", "-c",
            "sed -i \"s/^  local grey=.*/  local grey='" + c.mist + "'/\" /home/adolf/.p10k.zsh && " +
            "sed -i \"s/^  local red=.*/  local red='" + c.error_ + "'/\" /home/adolf/.p10k.zsh && " +
            "sed -i \"s/^  local yellow=.*/  local yellow='" + c.neutral + "'/\" /home/adolf/.p10k.zsh && " +
            "sed -i \"s/^  local blue=.*/  local blue='" + c.ghost + "'/\" /home/adolf/.p10k.zsh && " +
            "sed -i \"s/^  local magenta=.*/  local magenta='" + c.ghost + "'/\" /home/adolf/.p10k.zsh && " +
            "sed -i \"s/^  local cyan=.*/  local cyan='" + c.shade + "'/\" /home/adolf/.p10k.zsh && " +
            "sed -i \"s/^  local white=.*/  local white='" + c.snow + "'/\" /home/adolf/.p10k.zsh && " +
            "for s in " + tab.kittySockets + "; do kitten @ --to \"unix:$s\" send-text --match all $'source ~/.p10k.zsh\r' 2>/dev/null; done"
        ])
    }

    function applyGtkTheme(c) {
        let css = '/* ══════════════════════════════════════\n' +
            '   Ashen Ghost -- GTK3 overrides for Nemo\n' +
            '   ══════════════════════════════════════ */\n' +
            'toolbar, GtkToolbar {\n' +
            '    background-color: transparent;\n' +
            '    background-image: none;\n' +
            '    box-shadow: none;\n' +
            '    border: none;\n' +
            '}\n' +
            '.sidebar row:selected,\n' +
            '.sidebar row:selected:focus {\n' +
            '    background-color: ' + c.ghost + ';\n' +
            '    color: ' + c.abyss + ';\n' +
            '}\n' +
            'iconview.view:selected,\n' +
            'iconview.view:selected:focus,\n' +
            '.view:selected,\n' +
            '.view:selected:focus {\n' +
            '    background-color: alpha(' + c.ghost + ', 0.35);\n' +
            '    color: ' + c.snow + ';\n' +
            '    border-radius: 6px;\n' +
            '}\n' +
            'window, .background {\n' +
            '    background-color: alpha(' + c.void_ + ', 0.001);\n' +
            '    color: ' + c.snow + ';\n' +
            '}\n' +
            '.sidebar {\n' +
            '    background-color: ' + c.surface + ';\n' +
            '}\n' +
            '.view,\n' +
            'iconview.view,\n' +
            'iconview {\n' +
            '    background-color: alpha(' + c.void_ + ', 0.001);\n' +
            '}\n' +
            '.sidebar,\n' +
            '.sidebar .view,\n' +
            'placessidebar {\n' +
            '    background-color: alpha(' + c.surface + ', 0.15);\n' +
            '}\n' +
            'button {\n' +
            '    border-radius: 8px;\n' +
            '}\n' +
            'dialog,\n' +
            'window.dialog,\n' +
            '.background.csd {\n' +
            '    border-radius: 12px;\n' +
            '}\n' +
            'button.suggested-action {\n' +
            '    background-color: ' + c.ghost + ';\n' +
            '    background-image: none;\n' +
            '    color: ' + c.abyss + ';\n' +
            '    border-color: ' + c.ghost + ';\n' +
            '}\n' +
            'button.suggested-action:hover {\n' +
            '    background-color: ' + c.neutral + ';\n' +
            '}\n' +
            'button.suggested-action:active {\n' +
            '    background-color: ' + c.shade + ';\n' +
            '}\n' +
            'list row:selected,\n' +
            'list row:selected:focus,\n' +
            'treeview:selected,\n' +
            'treeview:selected:focus {\n' +
            '    background-color: ' + c.ghost + ';\n' +
            '    color: ' + c.abyss + ';\n' +
            '}\n' +
            'check:checked,\n' +
            'radio:checked,\n' +
            'switch:checked {\n' +
            '    background-color: ' + c.ghost + ';\n' +
            '    border-color: ' + c.ghost + ';\n' +
            '}\n' +
            'selection,\n' +
            'entry selection,\n' +
            'textview text selection,\n' +
            'label selection {\n' +
            '    background-color: ' + c.ghost + ';\n' +
            '    color: ' + c.abyss + ';\n' +
            '}\n' +
            '.floating-bar {\n' +
            '    background-color: alpha(' + c.surface + ', 0.92);\n' +
            '    color: ' + c.snow + ';\n' +
            '    border: 1px solid alpha(' + c.ghost + ', 0.3);\n' +
            '    border-radius: 10px;\n' +
            '    padding: 4px 10px;\n' +
            '    box-shadow: none;\n' +
            '}\n' +
            '.floating-bar:backdrop {\n' +
            '    background-color: alpha(' + c.surface + ', 0.75);\n' +
            '}\n'
        let b64 = Qt.btoa(css)
        let papirusCmd = c.papirusColor ? ("papirus-folders -C " + c.papirusColor + " 2>/dev/null; ") : ""
        Quickshell.execDetached(["sh", "-c",
            "mkdir -p /home/adolf/.config/gtk-3.0 && " +
            "echo '" + b64 + "' | base64 -d > /home/adolf/.config/gtk-3.0/gtk.css && " +
            papirusCmd
        ])
    }
    Text {
        text: "Theme"
        color: Services.Colors.snow
        font.pixelSize: 20
        font.bold: true
        font.family: "JetBrainsMono NF"
    }

    PreviewCard {
        source: Services.AppState.facePath
        fallbackGlyph: "\uf0d3"
        title: "Profile Picture"
        subtitle: Services.AppState.userLabel
        action: "Change"
        onTriggered: facePickProc.running = true
    }

    Process {
        id: facePickProc
        command: ["sh", "-c", "zenity --file-selection --title='Choose profile picture' --file-filter='Images | *.png *.jpg *.jpeg' 2>/dev/null"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let path = text.trim()
                if (path.length > 0 && Services.AppState.homeDir !== "") {
                    faceCopyProc.command = ["cp", path, Services.AppState.homeDir + "/.face"]
                    faceCopyProc.running = true
                }
            }
        }
    }
    Process {
        id: faceCopyProc
        running: false
        onExited: Services.AppState.faceVersion = Date.now()
    }

    Rectangle { Layout.fillWidth: true; height: 1; color: Services.Colors.ghostAlpha(0.15) }

    PreviewCard {
        // Shows the wallpaper actually on screen; video/gif resolve to the
        // frame ashen-wallpaper.sh extracts, and the glyph covers "none yet".
        // Wide tile + fit: shows the whole wallpaper, whatever its ratio
        previewWidth: 142
        previewFill: Image.PreserveAspectFit
        source: Services.Wallpaper.stillUrl
        fallbackGlyph: "\ue1bc"
        title: "Wallpaper"
        // The picker only lists what is already in the folder -- it has no
        // import, so promising "add" here would be a lie.
        subtitle: Services.Wallpaper.path !== ""
            ? Services.Wallpaper.path.split("/").pop()
            : "Pick one from ~/Pictures/Wallpapers"
        action: "Open"
        onTriggered: {
            Services.AppState.settingsVisible = false
            Services.AppState.wallpaperVisible = true
        }
    }

    Rectangle { Layout.fillWidth: true; height: 1; color: Services.Colors.ghostAlpha(0.15) }

    ColumnLayout {
        id: schemeSection
        Layout.fillWidth: true
        spacing: 8

        property string activeScheme: "classic"
        readonly property bool dynamicActive: activeScheme === "dynamic"

        Process {
            id: schemeModeReadProc
            command: ["sh", "-c", "cat /home/adolf/.cache/ashen_scheme_mode.txt 2>/dev/null"]
            running: false
            stdout: StdioCollector {
                onStreamFinished: {
                    let s = text.trim()
                    if (s.length > 0) schemeSection.activeScheme = s
                }
            }
        }

        property string dynamicType: "scheme-tonal-spot"
        // Single source for the pills below and the validity check on load
        readonly property var dynamicTypes: [
            { id: "scheme-neutral", label: "Neutral" },
            { id: "scheme-tonal-spot", label: "Tonal Spot" },
            { id: "scheme-vibrant", label: "Vibrant" },
            { id: "scheme-expressive", label: "Expressive" },
            { id: "scheme-fidelity", label: "Fidelity" },
            { id: "scheme-content", label: "Content" },
            { id: "scheme-rainbow", label: "Rainbow" },
            { id: "scheme-fruit-salad", label: "Fruit Salad" },
        ]

        Component.onCompleted: {
            schemeModeReadProc.running = true
            dynTypeProc.running = true
        }
        Process {
            id: dynTypeProc
            command: ["sh", "-c", "cat /home/adolf/.cache/ashen_dynamic_type.txt 2>/dev/null"]
            running: false
            stdout: StdioCollector {
                onStreamFinished: {
                    let t = text.trim()
                    // A cache written before monochrome moved out of Dynamic
                    // would name a type that no longer exists: no pill would
                    // light up and matugen would still be handed it.
                    if (t.length > 0 && schemeSection.dynamicTypes.some(d => d.id === t)) {
                        schemeSection.dynamicType = t
                    } else if (t.length > 0) {
                        schemeSection.setDynamicType("scheme-tonal-spot")
                    }
                }
            }
        }
        function setDynamicType(t) {
            schemeSection.dynamicType = t
            Quickshell.execDetached(["sh", "-c", "echo '" + t + "' > /home/adolf/.cache/ashen_dynamic_type.txt"])
        }

        // Re-run matugen from the current wallpaper (frame for gif/video) with
        // the saved style. No-ops unless in dynamic mode. Called when a style
        // pill or the Dynamic tile is clicked so the change lands immediately.
        function recolor() {
            Quickshell.execDetached([Quickshell.env("HOME") + "/ashen/scripts/ashen-recolor.sh"])
        }

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
                    { id: "monochrome", label: "Monochrome", subtitle: "Black & white", swatches: ["#050505", "#1a1a1a", "#d4d4d4", "#f2f2f2"] },
                    { id: "cyberpunk", label: "Cyberpunk", subtitle: "Neon nights", swatches: ["#0d0221", "#241b3d", "#ff2e97", "#00fff2"] },
                    { id: "edgerunners", label: "Edgerunners", subtitle: "Chrome dreams", swatches: ["#080c12", "#fcee0a", "#00e5ff", "#5ef2a4"] },
                    { id: "tokyonight", label: "Tokyo Night", subtitle: "Calm blues", swatches: ["#1a1b26", "#24283b", "#7aa2f7", "#bb9af7"] },
                    { id: "dracula", label: "Dracula", subtitle: "Classic dark", swatches: ["#282a36", "#343746", "#bd93f9", "#ff79c6"] },
                    { id: "nord", label: "Nord", subtitle: "Arctic cool", swatches: ["#2e3440", "#434c5e", "#88c0d0", "#b48ead"] },
                    { id: "dynamic", label: "Dynamic", subtitle: "From wallpaper", swatches: [] },
                ]
                delegate: Rectangle {
                    required property var modelData
                    readonly property bool active: schemeSection.activeScheme === modelData.id
                    width: 150; height: 80
                    radius: 12
                    // Declarative hover: assigning color in onEntered would kill this binding
                    color: active ? Services.Colors.ghostAlpha(0.28)
                        : schemeHover.containsMouse ? Services.Colors.ghostAlpha(0.3)
                        : Services.Colors.ghostAlpha(0.15)
                    border.color: active ? Services.Colors.ghost : "transparent"
                    border.width: active ? 2 : 0
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
                    Rectangle {
                        visible: parent.active
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 6
                        width: 18; height: 18
                        radius: 9
                        color: Services.Colors.ghost
                        Text {
                            anchors.centerIn: parent
                            text: ""
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 11
                            color: Services.Colors.abyss
                        }
                    }
                    MouseArea {
                        id: schemeHover
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: {
                            if (modelData.id === "dynamic") {
                                schemeSection.activeScheme = "dynamic"
                                // Switch into dynamic mode, then recolour from
                                // the wallpaper's frame -- awww query fails on
                                // video (mpvpaper, not awww, is running).
                                Quickshell.execDetached(["sh", "-c",
                                    "echo 'dynamic' > " + Quickshell.env("HOME") + "/.cache/ashen_scheme_mode.txt && " +
                                    Quickshell.env("HOME") + "/ashen/scripts/ashen-recolor.sh"
                                ])
                            } else {
                                schemeSection.activeScheme = modelData.id
                                tab.applyScheme(modelData.id)
                            }
                        }
                    }
                }
            }
        }

        // ── Dynamic Style: only has any effect while Dynamic is the active
        //    scheme, so it is visibly subordinate to it and dims when it is not.
        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: 6
            radius: 12
            color: Services.Colors.ghostAlpha(0.06)
            implicitHeight: dynCol.implicitHeight + 24
            opacity: schemeSection.dynamicActive ? 1.0 : 0.45
            Behavior on opacity { NumberAnimation { duration: 200 } }

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
                    Text { text: "Dynamic Style"; color: Services.Colors.snow; font.pixelSize: 12; font.bold: true; font.family: "JetBrainsMono NF" }
                }
                Text {
                    // Clicking Dynamic re-runs matugen against the *current*
                    // wallpaper -- it does not open the picker.
                    text: schemeSection.dynamicActive
                        ? "How aggressively matugen pulls color from the wallpaper"
                        : "Select the Dynamic scheme above to use these"
                    color: Services.Colors.ash
                    font.pixelSize: 10
                    font.family: "JetBrainsMono NF"
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                Flow {
                    Layout.fillWidth: true
                    Layout.topMargin: 2
                    spacing: 8
                    Repeater {
                        model: schemeSection.dynamicTypes
                        delegate: Rectangle {
                            required property var modelData
                            readonly property bool active: schemeSection.dynamicType === modelData.id
                            width: dynRow.implicitWidth + 20
                            height: 32
                            radius: 8
                            color: active ? Services.Colors.ghost : Services.Colors.ghostAlpha(0.12)
                            Behavior on color { ColorAnimation { duration: 150 } }
                            RowLayout {
                                id: dynRow
                                anchors.centerIn: parent
                                spacing: 5
                                Text {
                                    visible: parent.parent.active
                                    text: ""
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 11
                                    color: Services.Colors.abyss
                                }
                                Text {
                                    text: modelData.label
                                    font.pixelSize: 11
                                    font.family: "JetBrainsMono NF"
                                    color: parent.parent.active ? Services.Colors.abyss : Services.Colors.snow
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: { schemeSection.setDynamicType(modelData.id); schemeSection.recolor() }
                            }
                        }
                    }
                }
            }
        }
    }


    Item { Layout.preferredHeight: 8 }
        }
    }
}
