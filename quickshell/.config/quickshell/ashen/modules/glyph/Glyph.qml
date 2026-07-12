import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import "root:/services" as Services

Scope {
    id: root

    IpcHandler {
        target: "glyph"
        function toggle() {
            Services.AppState.toggleOverlay("glyphVisible")
            if (Services.AppState.glyphVisible) {
                searchField.text = ""
                searchField.forceActiveFocus()
                if (win.materialIcons.length === 0) materialLoader.running = true
            }
        }
    }

    PanelWindow {
        id: win
        anchors { top: true; left: true; right: true; bottom: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        visible: Services.AppState.glyphVisible

        WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        property string searchText: ""
        property string activeTab: "Nerd Font"
        property int selectedIndex: 0
        property bool copied: false
        property var materialIcons: []

        property var nerdFontIcons: [
                { name: "archlinux", code: "f303" },
                { name: "debian", code: "f306" },
                { name: "ubuntu", code: "f31b" },
                { name: "fedora", code: "f30a" },
                { name: "centos", code: "f304" },
                { name: "opensuse", code: "f314" },
                { name: "gentoo", code: "f30d" },
                { name: "manjaro", code: "f312" },
                { name: "nixos", code: "f313" },
                { name: "linuxmint", code: "f30e" },
                { name: "redhat", code: "f316" },
                { name: "kali_linux", code: "f327" },
                { name: "alpine", code: "f300" },
                { name: "void", code: "f32e" },
                { name: "freebsd", code: "f30c" },
                { name: "tux", code: "f31a" },
                { name: "raspberry_pi", code: "f315" },
                { name: "endeavour", code: "f322" },
                { name: "garuda", code: "f337" },
                { name: "pop_os", code: "f32a" },
                { name: "elementary", code: "f309" },
                { name: "zorin", code: "f32f" },
                { name: "apple", code: "f302" },
                { name: "windows", code: "f0a35" },
                { name: "hyprland", code: "f359" },
                { name: "gnome", code: "f361" },
                { name: "kde", code: "f373" },
                { name: "xfce", code: "f368" },
                { name: "i3", code: "f35a" },
                { name: "sway", code: "f35d" },
                { name: "bspwm", code: "f355" },
                { name: "awesome", code: "f354" },
                { name: "dwm", code: "f356" },
                { name: "qtile", code: "f35c" },
                { name: "wayland", code: "f367" },
                { name: "xorg", code: "f369" },
                { name: "git", code: "e702" },
                { name: "github", code: "e709" },
                { name: "gitlab", code: "e7eb" },
                { name: "docker", code: "e7b0" },
                { name: "vim", code: "e62b" },
                { name: "neovim", code: "e7c5" },
                { name: "vscode", code: "e70c" },
                { name: "sublime", code: "e7aa" },
                { name: "linux", code: "e712" },
                { name: "terminal", code: "e795" },
                { name: "database", code: "e706" },
                { name: "python", code: "e73c" },
                { name: "javascript", code: "e781" },
                { name: "typescript", code: "e8ca" },
                { name: "rust", code: "e7a8" },
                { name: "go", code: "e724" },
                { name: "java", code: "e738" },
                { name: "c", code: "e61e" },
                { name: "cpp", code: "e61d" },
                { name: "csharp", code: "e7b2" },
                { name: "ruby", code: "e739" },
                { name: "php", code: "e73d" },
                { name: "lua", code: "e826" },
                { name: "swift", code: "e755" },
                { name: "kotlin", code: "e634" },
                { name: "html5", code: "e736" },
                { name: "css3", code: "e749" },
                { name: "haskell", code: "e777" },
                { name: "elixir", code: "e62d" },
                { name: "clojure", code: "e768" },
                { name: "scala", code: "e737" },
                { name: "dart", code: "e798" },
                { name: "r", code: "e881" },
                { name: "react", code: "e7ba" },
                { name: "vuejs", code: "e8dc" },
                { name: "angular", code: "e753" },
                { name: "nodejs", code: "e719" },
                { name: "django", code: "e71d" },
                { name: "flask", code: "e7dc" },
                { name: "rails", code: "e73b" },
                { name: "laravel", code: "e73f" },
                { name: "nextjs", code: "e83e" },
                { name: "svelte", code: "e8b7" },
                { name: "tailwindcss", code: "e8ba" },
                { name: "aws", code: "e7ad" },
                { name: "kubernetes", code: "e81d" },
                { name: "terraform", code: "e8bd" },
                { name: "ansible", code: "e723" },
                { name: "nginx", code: "e776" },
                { name: "mysql", code: "e704" },
                { name: "postgresql", code: "e76e" },
                { name: "mongodb", code: "e7a4" },
                { name: "redis", code: "e76d" },
                { name: "cod_terminal", code: "ea85" },
                { name: "cod_folder", code: "ea83" },
                { name: "cod_folder_opened", code: "eaf7" },
                { name: "cod_file", code: "ea7b" },
                { name: "cod_gear", code: "eaf8" },
                { name: "cod_settings", code: "eb52" },
                { name: "cod_search", code: "ea6d" },
                { name: "cod_home", code: "eb06" },
                { name: "cod_gist_secret", code: "eafa" },
                { name: "cod_lock", code: "ea75" },
                { name: "cod_key", code: "eb11" },
                { name: "cod_person", code: "ea67" },
                { name: "cod_bell", code: "eaa2" },
                { name: "cod_check", code: "eab2" },
                { name: "cod_close", code: "ea76" },
                { name: "cod_add", code: "ea60" },
                { name: "cod_trash", code: "ea81" },
                { name: "cod_edit", code: "ea73" },
                { name: "cod_save", code: "eb4b" },
                { name: "cod_star_full", code: "eb59" },
                { name: "cod_heart", code: "eb05" },
                { name: "cod_bug", code: "eaaf" },
                { name: "cod_git_merge", code: "eafe" },
                { name: "cod_git_commit", code: "eafc" },
                { name: "cod_git_pull_request", code: "ea64" },
                { name: "cod_source_control", code: "ea68" },
                { name: "cod_error", code: "ea87" },
                { name: "cod_warning", code: "ea6c" },
                { name: "cod_info", code: "ea74" },
                { name: "cod_play", code: "eb2c" },
                { name: "cod_debug_start", code: "ead3" },
                { name: "cod_link", code: "eb15" },
                { name: "cod_globe", code: "eb01" },
                { name: "cod_mail", code: "eb1c" },
                { name: "cod_calendar", code: "eab0" },
                { name: "fa_home", code: "f015" },
                { name: "fa_user", code: "f007" },
                { name: "fa_users", code: "f0c0" },
                { name: "fa_search", code: "f002" },
                { name: "fa_cog", code: "f013" },
                { name: "fa_gear", code: "f013" },
                { name: "fa_star", code: "f005" },
                { name: "fa_heart", code: "f004" },
                { name: "fa_bell", code: "f0f3" },
                { name: "fa_envelope", code: "f0e0" },
                { name: "fa_lock", code: "f023" },
                { name: "fa_unlock", code: "f09c" },
                { name: "fa_check", code: "f00c" },
                { name: "fa_times", code: "f00d" },
                { name: "fa_plus", code: "f067" },
                { name: "fa_minus", code: "f068" },
                { name: "fa_arrow_left", code: "f060" },
                { name: "fa_arrow_right", code: "f061" },
                { name: "fa_arrow_up", code: "f062" },
                { name: "fa_arrow_down", code: "f063" },
                { name: "fa_chevron_left", code: "f053" },
                { name: "fa_chevron_right", code: "f054" },
                { name: "fa_chevron_up", code: "f077" },
                { name: "fa_chevron_down", code: "f078" },
                { name: "fa_folder", code: "f07b" },
                { name: "fa_folder_open", code: "f07c" },
                { name: "fa_file", code: "f15b" },
                { name: "fa_download", code: "f019" },
                { name: "fa_upload", code: "f093" },
                { name: "fa_trash", code: "f1f8" },
                { name: "fa_edit", code: "f044" },
                { name: "fa_save", code: "f0c7" },
                { name: "fa_wifi", code: "f1eb" },
                { name: "fa_battery_full", code: "f240" },
                { name: "fa_bluetooth", code: "f293" },
                { name: "fa_volume_up", code: "f028" },
                { name: "fa_volume_off", code: "f026" },
                { name: "fa_camera", code: "f030" },
                { name: "fa_music", code: "f001" },
                { name: "fa_video_camera", code: "f03d" },
                { name: "fa_microphone", code: "f130" },
                { name: "fa_calendar", code: "f073" },
                { name: "fa_clock_o", code: "f017" },
                { name: "fa_map_marker", code: "f041" },
                { name: "fa_globe", code: "f0ac" },
                { name: "fa_link", code: "f0c1" },
                { name: "fa_paperclip", code: "f0c6" },
                { name: "fa_print", code: "f02f" },
                { name: "fa_share", code: "f064" },
                { name: "fa_thumbs_up", code: "f164" },
                { name: "fa_thumbs_down", code: "f165" },
                { name: "fa_comment", code: "f075" },
                { name: "fa_flag", code: "f024" },
                { name: "fa_bolt", code: "f0e7" },
                { name: "fa_fire", code: "f06d" },
                { name: "fa_leaf", code: "f06c" },
                { name: "fa_tree", code: "f1bb" },
                { name: "fa_moon_o", code: "f186" },
                { name: "fa_sun_o", code: "f185" },
                { name: "fa_cloud", code: "f0c2" },
                { name: "fa_umbrella", code: "f0e9" },
                { name: "fa_shopping_cart", code: "f07a" },
                { name: "fa_credit_card", code: "f09d" },
                { name: "fa_gift", code: "f06b" },
                { name: "fa_trophy", code: "f091" },
                { name: "fa_gamepad", code: "f11b" },
                { name: "fa_puzzle_piece", code: "f12e" },
                { name: "fa_rocket", code: "f135" },
                { name: "fa_bug", code: "f188" },
                { name: "fa_terminal", code: "f120" },
                { name: "fa_code", code: "f121" },
                { name: "fa_database", code: "f1c0" },
                { name: "fa_server", code: "f233" },
                { name: "fa_cloud_upload", code: "f0ee" },
                { name: "fa_cloud_download", code: "f0ed" },
                { name: "fa_desktop", code: "f108" },
                { name: "fa_laptop", code: "f109" },
                { name: "fa_mobile", code: "f10b" },
                { name: "fa_tablet", code: "ed2e" },
                { name: "fa_keyboard_o", code: "f11c" },
                { name: "fa_power_off", code: "f011" },
                { name: "fa_refresh", code: "f021" },
                { name: "fa_spinner", code: "f110" },
                { name: "fa_check_circle", code: "f058" },
                { name: "fa_times_circle", code: "f057" },
                { name: "fa_exclamation_triangle", code: "f071" },
                { name: "fa_question_circle", code: "f059" },
                { name: "fa_info_circle", code: "f05a" },
                { name: "fa_eye", code: "f06e" },
                { name: "fa_eye_slash", code: "f070" },
                { name: "fa_filter", code: "f0b0" },
                { name: "fa_sort", code: "f0dc" },
                { name: "fa_list", code: "f03a" },
                { name: "fa_th_list", code: "f00b" },
                { name: "fa_th", code: "f00a" },
                { name: "fa_bars", code: "f0c9" },
                { name: "fa_ellipsis_v", code: "f142" },
        ]

        Process {
            id: materialLoader
            command: ["sh", "-c", "cat /home/adolf-arch/ashen/quickshell/.config/quickshell/ashen/modules/glyph/data/material_symbols.txt"]
            running: false
            stdout: StdioCollector {
                onStreamFinished: {
                    let lines = text.trim().split("\n")
                    let list = []
                    for (let line of lines) {
                        let parts = line.trim().split(/\s+/)
                        if (parts.length === 2) list.push({ name: parts[0], code: parts[1] })
                    }
                    win.materialIcons = list
                }
            }
        }

        property var currentList: activeTab === "Nerd Font" ? nerdFontIcons : materialIcons
        property var filtered: {
            let list = currentList
            if (searchText.length > 0) {
                let q = searchText.toLowerCase()
                list = list.filter(i => i.name.toLowerCase().includes(q))
            }
            return list
        }

        function codeToChar(code) {
            let n = parseInt(code, 16)
            if (n > 0xFFFF) {
                // par sustituto para puntos de codigo fuera del BMP (ej. Material Icons nuevos)
                n -= 0x10000
                let hi = 0xD800 + (n >> 10)
                let lo = 0xDC00 + (n & 0x3FF)
                return String.fromCharCode(hi, lo)
            }
            return String.fromCharCode(n)
        }

        function moveSelection(dir) {
            if (filtered.length === 0) return
            selectedIndex = Math.max(0, Math.min(filtered.length - 1, selectedIndex + dir))
            grid.positionViewAtIndex(selectedIndex, GridView.Contain)
        }
        function copySelected() {
            if (filtered.length === 0) return
            let g = filtered[Math.min(selectedIndex, filtered.length - 1)]
            let ch = win.codeToChar(g.code)
            copyProc.command = ["sh", "-c", "printf '%s' '" + ch + "' | wl-copy"]
            copyProc.running = true
            win.copied = true
            copiedTimer.restart()
        }

        Process { id: copyProc; running: false }
        Timer { id: copiedTimer; interval: 900; onTriggered: win.copied = false }

        MouseArea {
            anchors.fill: parent
            z: -1
            onClicked: Services.AppState.glyphVisible = false
        }

        Rectangle {
            anchors.centerIn: parent
            width: 560
            height: 480
            radius: 16
            color: Services.Colors.surfaceAlpha(0.96)
            border.color: Services.Colors.ghostAlpha(0.2)
            border.width: 1
            clip: true

            opacity: Services.AppState.glyphVisible ? 1.0 : 0.0
            scale: Services.AppState.glyphVisible ? 1.0 : 0.96
            Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

            MouseArea { anchors.fill: parent; onClicked: {} }

            Column {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 16
                spacing: 12

                RowLayout {
                    width: parent.width
                    spacing: 8
                    Repeater {
                        model: ["Nerd Font", "Material Icon"]
                        delegate: Rectangle {
                            required property string modelData
                            height: 32
                            Layout.fillWidth: true
                            radius: 8
                            color: win.activeTab === modelData ? Services.Colors.ghost : Services.Colors.ghostAlpha(0.15)
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                color: win.activeTab === modelData ? Services.Colors.abyss : Services.Colors.mist
                                font.pixelSize: 12
                                font.bold: true
                                font.family: "JetBrainsMono NF"
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    win.activeTab = modelData
                                    win.selectedIndex = 0
                                    if (modelData === "Material Icon" && win.materialIcons.length === 0) materialLoader.running = true
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    width: parent.width
                    Rectangle {
                        Layout.fillWidth: true
                        height: 48
                        radius: 10
                        color: Services.Colors.ghostAlpha(0.1)
                        border.color: searchField.activeFocus ? Services.Colors.ghost : Services.Colors.ghostAlpha(0.2)
                        border.width: 1
                        Behavior on border.color { ColorAnimation { duration: 150 } }
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            spacing: 10
                            Text { text: "\ue8b6"; color: Services.Colors.ghost; font.pixelSize: 18; font.family: "Material Symbols Rounded" }
                            Item {
                                Layout.fillWidth: true
                                height: 28
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Search icon name..."
                                    color: Services.Colors.ash
                                    font.pixelSize: 14
                                    font.family: "JetBrainsMono NF"
                                    visible: searchField.text.length === 0
                                }
                                TextInput {
                                    id: searchField
                                    anchors.fill: parent
                                    color: Services.Colors.snow
                                    font.pixelSize: 14
                                    font.family: "JetBrainsMono NF"
                                    verticalAlignment: TextInput.AlignVCenter
                                    onTextChanged: { win.searchText = text; win.selectedIndex = 0 }
                                    Keys.onEscapePressed: Services.AppState.glyphVisible = false
                                    Keys.onReturnPressed: win.copySelected()
                                    Keys.onUpPressed: win.moveSelection(-8)
                                    Keys.onDownPressed: win.moveSelection(8)
                                    Keys.onLeftPressed: win.moveSelection(-1)
                                    Keys.onRightPressed: win.moveSelection(1)
                                }
                            }
                        }
                    }
                    Text {
                        text: win.copied ? "Copied!" : ""
                        color: Services.Colors.ghost
                        font.pixelSize: 12
                        font.family: "JetBrainsMono NF"
                        Layout.leftMargin: 8
                    }
                }

                Text {
                    text: win.filtered.length + " icons"
                    color: Services.Colors.ash
                    font.pixelSize: 10
                    font.family: "JetBrainsMono NF"
                }

                Rectangle {
                    width: parent.width
                    height: 320
                    color: "transparent"
                    clip: true

                    GridView {
                        id: grid
                        anchors.fill: parent
                        model: win.filtered
                        cellWidth: parent.width / 7
                        cellHeight: 64

                        ScrollBar.vertical: ScrollBar {
                            policy: grid.contentHeight > grid.height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
                            width: 4
                        }

                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            width: grid.cellWidth - 4
                            height: grid.cellHeight - 4
                            radius: 8
                            color: index === win.selectedIndex ? Services.Colors.ghostAlpha(0.25) : "transparent"
                            border.color: index === win.selectedIndex ? Services.Colors.ghostAlpha(0.4) : "transparent"
                            border.width: 1

                            Column {
                                anchors.centerIn: parent
                                spacing: 2
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: win.codeToChar(modelData.code)
                                    font.pixelSize: 22
                                    font.family: win.activeTab === "Nerd Font" ? "JetBrainsMono NF" : "Material Symbols Rounded"
                                    color: Services.Colors.snow
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onEntered: win.selectedIndex = index
                                onClicked: win.copySelected()
                            }
                        }
                    }
                }
            }
        }
    }
}
