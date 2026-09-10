import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Ashen's login screen: the shell logs you in.
//
// Not a login form on a wallpaper -- it is Ashen's own bar, at the numbers
// services/Sizes.qml uses (barH 56, pillH 44, pillR 10, gap 6), the ASCII mark
// the terminal and the installer print, and the workspace dot strip counting
// keystrokes. Everything here already exists in the session you are opening.
//
// NOT SddmComponents: that module ships its own ComboBox, Button and TextField
// which shadow QtQuick.Controls' and carry a different API -- importing it made
// the theme fail to load with "Cannot assign to non-existent property
// currentIndex", and SDDM silently fell back to its default theme.
//
// The palette is theme.conf, NOT the live scheme: sddm runs as its own user and
// a home is drwx------, so ~/.cache/ashen_scheme.json cannot be read from here.
Rectangle {
    id: root
    width: 1920; height: 1080
    color: config.surface

    readonly property int barH: 56
    readonly property int pillH: 44
    readonly property int pillR: 10
    readonly property int gap: 6
    // services/Colors.qml: surfacePill is the surface at 0.82, and every
    // capsule on this screen stands on it.
    readonly property color base: Qt.color(config.surface)
    readonly property color plate: Qt.rgba(root.base.r, root.base.g, root.base.b, 0.82)

    QtObject { id: clock; property var now: new Date() }
    Timer { interval: 1000; running: true; repeat: true; onTriggered: clock.now = new Date() }

    Image { anchors.fill: parent; source: config.background; fillMode: Image.PreserveAspectCrop; visible: status === Image.Ready }
    Rectangle { anchors.fill: parent; color: Qt.rgba(0, 0, 0, 0.62) }

    // A bar capsule. Every pill on this screen is this one shape.
    component Pill: Rectangle {
        radius: root.pillR
        color: root.plate
        implicitHeight: root.pillH
    }

    // The pickers. The control itself is invisible -- the pill above it is its
    // face -- but a popup is NOT covered by that opacity: it is its own item,
    // so it arrived in Qt's default style, white and square, on top of Ashen.
    // Everything it draws is spelled out here.
    component Picker: ComboBox {
        id: pick
        opacity: 0
        HoverHandler { cursorShape: pick.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor }
        // The list stands on a panel, not a pill: it is a surface with rows.
        popup: Popup {
            y: pick.height + 6
            width: Math.max(pick.width, 200)
            implicitHeight: Math.min(contentItem.implicitHeight + 12, 320)
            padding: 6
            background: Rectangle {
                radius: root.pillR
                color: Qt.rgba(root.base.r, root.base.g, root.base.b, 0.95)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.08)
            }
            contentItem: ListView {
                clip: true
                implicitHeight: contentHeight
                model: pick.popup.visible ? pick.delegateModel : null
                currentIndex: pick.highlightedIndex
                boundsBehavior: Flickable.StopAtBounds
            }
        }
        delegate: ItemDelegate {
            id: row
            width: ListView.view ? ListView.view.width : 0
            height: 34
            // Hover brightens the text, it does not fill the row: the shell's
            // rule for every capsule in the bar.
            contentItem: Text {
                text: pick.textRole ? (Array.isArray(pick.model)
                        ? modelData[pick.textRole]
                        : model[pick.textRole])
                    : modelData
                color: row.hovered || pick.currentIndex === index ? config.snow : config.mist
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                font.pixelSize: 12
                font.family: "JetBrainsMono NF"
                leftPadding: 10
            }
            background: Rectangle {
                radius: 8
                color: pick.currentIndex === index ? Qt.rgba(1, 1, 1, 0.07) : "transparent"
            }
        }
    }

    // ---- The bar --------------------------------------------------------
    Item {
        id: bar
        anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
        height: root.barH

        Pill {
            id: sessionPill
            anchors.left: parent.left; anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: sessRow.implicitWidth + 32

            RowLayout {
                id: sessRow
                anchors.centerIn: parent
                spacing: 8
                Text {
                    text: sessionList.currentText; color: config.snow
                    font.pixelSize: 13; font.family: "JetBrainsMono NF"
                }
                Text {
                    text: ""; color: config.mist
                    font.pixelSize: 15; font.family: "Material Symbols Rounded"
                }
            }
            Picker {
                id: sessionList
                objectName: "sessionPicker"
                anchors.fill: parent
                model: sessionModel; textRole: "name"; currentIndex: sessionModel.lastIndex
            }
        }

        // The clock pill, seconds stacked small: the shell's own ClockText.
        Pill {
            anchors.centerIn: parent
            implicitWidth: clockRow.implicitWidth + 34

            Row {
                id: clockRow
                anchors.centerIn: parent
                spacing: 0
                Text {
                    text: Qt.formatTime(clock.now, "HH:mm"); color: config.snow
                    font.pixelSize: 17; font.weight: Font.Bold; font.letterSpacing: -0.5
                    font.family: "JetBrainsMono NF"
                }
                Column {
                    anchors.bottom: parent.bottom; anchors.bottomMargin: 3; leftPadding: 3
                    Text {
                        text: Qt.formatTime(clock.now, "ss"); color: Qt.rgba(0.91, 0.91, 0.93, 0.4)
                        font.pixelSize: 10; font.weight: Font.Bold; font.family: "JetBrainsMono NF"
                    }
                }
            }
        }

        // The ways out, as chips inside ONE plate -- the way the system pills
        // group in the bar, not as four separate buttons.
        Pill {
            id: powerPlate
            anchors.right: parent.right; anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: powerRow.implicitWidth + 16

            Row {
                id: powerRow
                anchors.centerIn: parent
                spacing: 2
                Repeater {
                    model: [
                        { g: "", act: "poweroff" },
                        { g: "", act: "reboot" },
                        { g: "", act: "suspend" },
                        { g: "", act: "hibernate" }
                    ]
                    Rectangle {
                        id: chip
                        width: 38; height: 34; radius: 8
                        color: "transparent"
                        // Hover = grow and brighten, never a fill: the shell's rule.
                        scale: ma.containsMouse ? 1.06 : 1
                        Behavior on scale { NumberAnimation { duration: 150 } }
                        Text {
                            anchors.centerIn: parent
                            text: modelData.g
                            color: ma.containsMouse ? config.snow : config.mist
                            font.pixelSize: 17; font.family: "Material Symbols Rounded"
                        }
                        MouseArea {
                            id: ma
                            anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modelData.act === "poweroff") sddm.powerOff()
                                else if (modelData.act === "reboot") sddm.reboot()
                                else if (modelData.act === "suspend") sddm.suspend()
                                else sddm.hibernate()
                            }
                        }
                    }
                }
            }
        }
    }

    // ---- The mark, and the way in ---------------------------------------
    ColumnLayout {
        anchors.centerIn: parent
        spacing: 26

        // The same rows install/lib/logo.sh and fastfetch/ashen.txt print. The
        // line height is pinned to the cell or the blocks stop touching.
        // The mark stands on a plate like every other Ashen surface: over a
        // wallpaper it would otherwise sit on whatever happens to be behind it,
        // and this one is dithered blocks -- the first thing a busy photo eats.
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: markArt.implicitWidth + 44
            implicitHeight: markArt.implicitHeight + 26
            radius: root.pillR
            color: root.plate
        Text {
            id: markArt
            anchors.centerIn: parent
            color: config.snow
            // 12px, not a hero size: the smoke ramp is dithering, and past
            // ~14px the blocks separate into dots and the word stops reading.
            // Measured -- docs/probes/sddm/mark-sizes.png.
            font.pixelSize: 12
            font.family: "JetBrainsMono NF"
            // No renderType or layer here on purpose: the block art shows RGB
            // fringes on the greeter, but so does the running bar in the live
            // session -- it is this machine's subpixel antialiasing, not the
            // theme, and the login matches the desktop it opens.
            lineHeight: Math.round(12 * 1.18)
            lineHeightMode: Text.FixedHeight
            textFormat: Text.PlainText
            text: " ░░░░░╗ ░░░░░░░╗░░╗  ░░╗░░░░░░░╗░░░╗   ░░╗\n░░╔══░░╗░░╔════╝░░║  ░░║░░╔════╝░░░░╗  ░░║\n▒▒▒▒▒▒▒║▒▒▒▒▒▒▒╗▒▒▒▒▒▒▒║▒▒▒▒▒╗  ▒▒╔▒▒╗ ▒▒║\n▓▓╔══▓▓║╚════▓▓║▓▓╔══▓▓║▓▓╔══╝  ▓▓║╚▓▓╗▓▓║\n██║  ██║███████║██║  ██║███████╗██║ ╚████║\n╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝"
        }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: root.gap

            // Who, as its own capsule -- a picker when there is a choice.
            Pill {
                implicitWidth: userText.implicitWidth + 34
                Text {
                    id: userText
                    anchors.centerIn: parent
                    text: userList.currentText.toUpperCase()
                    color: config.snow
                    font.pixelSize: 12; font.bold: true; font.letterSpacing: 1.4
                    font.family: "JetBrainsMono NF"
                }
                Picker {
                    id: userList
                    objectName: "userPicker"
                    anchors.fill: parent
                    // One user is not a choice: a popup with a single row is
                    // furniture. The gate lives HERE and not on a MouseArea
                    // underneath, because the control is on top and takes the
                    // press itself -- the MouseArea never ran.
                    enabled: userModel.count > 1
                    model: userModel; textRole: "name"; currentIndex: userModel.lastIndex
                }
            }

            // The word. Same capsule, wider, with the focus ring as the only
            // thing on this screen that carries the accent.
            Pill {
                implicitWidth: 420
                border.width: password.activeFocus ? 2 : 0
                border.color: config.ghost

                // The field takes the keys but draws nothing: what you see is
                // the dot row below, which is the shell's own workspace strip.
                TextField {
                    id: password
                    objectName: "password"   // the probe types into it by name
                    anchors.fill: parent
                    echoMode: TextInput.Password
                    color: "transparent"
                    cursorDelegate: Item {}
                    font.pixelSize: 1
                    focus: true
                    background: null
                    onAccepted: root.tryLogin()
                    Keys.onEscapePressed: password.text = ""
                }

                // Ashen's workspace indicator, counting keystrokes. Every dot is
                // the same size: one wider than the rest reads as a mistake
                // rather than as a marker. The newest is brighter instead.
                Row {
                    anchors.centerIn: parent
                    spacing: 7
                    visible: password.text !== ""
                    Repeater {
                        model: Math.min(password.text.length, 14)
                        Rectangle {
                            readonly property bool last: index === Math.min(password.text.length, 14) - 1
                            width: 7
                            height: 7
                            radius: 3.5
                            color: last ? config.snow : Qt.rgba(0.91, 0.91, 0.93, 0.4)
                            anchors.verticalCenter: parent.verticalCenter
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }
                }
                // Our own placeholder: the Basic style hides its own while the
                // field has focus, and this field has focus from frame one.
                Text {
                    anchors.centerIn: parent
                    visible: password.text === ""
                    // Literal, NOT textConstants: sddm-greeter-qt6 0.21 does not
                    // hand this theme a `textConstants`, so reading it throws and
                    // the binding leaves the text empty -- a field with no label
                    // and no error anywhere. Verified on the real greeter.
                    text: "PASSWORD"
                    // mist, not ash: on the plate ash is about 1.6:1 and simply
                    // is not there -- the one label saying what to type.
                    color: config.mist
                    font.pixelSize: 12; font.letterSpacing: 2
                    font.family: "JetBrainsMono NF"
                }
            }

            // Enter, as a chip: the button is the smallest thing here because
            // the keyboard is how this is actually used.
            Pill {
                implicitWidth: root.pillH
                color: password.text === "" ? root.plate : config.snow
                Behavior on color { ColorAnimation { duration: 150 } }
                Text {
                    anchors.centerIn: parent
                    text: "→"
                    color: password.text === "" ? config.ash : config.accentText
                    font.pixelSize: 18; font.family: "JetBrainsMono NF"
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.tryLogin() }
            }
        }

        // The row keeps its height whether or not it says anything: a message
        // that appears must not shove the field you are typing into upwards.
        Text {
            id: message
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: 14
            opacity: text !== "" ? 1 : 0
            color: config.error
            font.pixelSize: 11; font.family: "JetBrainsMono NF"
        }
    }

    // The shell's own line, where the terminal prints it.
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom; anchors.bottomMargin: 40
        text: "a  g h o s t  i n  t h e  s h e l l"
        color: config.ash
        font.pixelSize: 11; font.letterSpacing: 1
        font.family: "JetBrainsMono NF"
    }

    function tryLogin() {
        message.text = ""
        sddm.login(userList.currentText, password.text, sessionList.currentIndex)
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            message.text = "wrong word"   // literal, for the reason noted above
            password.text = ""
            password.forceActiveFocus()
        }
    }

    Component.onCompleted: password.forceActiveFocus()
}
