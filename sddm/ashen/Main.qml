import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Login screen: the time huge on the left with who you are and the way in on
// one plate under it, the ways out in a row at the top right, the month on a
// big plate, the session at the foot. The widgets are the lock's:
// plates, a round face with its ring, the sunk dots of the password.
// The mountains behind are drawn (Ridges.qml).
//
// The login does NOT follow the wallpaper: it wears one of the palettes below,
// named in theme.conf. No name on it, so it suits any desktop.
//
// NOT SddmComponents: that module ships its own ComboBox, Button and TextField
// which shadow QtQuick.Controls' and carry a different API -- importing it made
// the theme fail to load and SDDM silently fell back to its default theme.
Rectangle {
    id: root
    width: 1920; height: 1080
    color: pal.surface

    readonly property int pillH: 44
    readonly property int pillR: 10
    readonly property int cardR: 14

    // The palettes. `hue` and `sat` set the scene (every layer of the mountains
    // is a step of lightness on that one hue); the rest are the plates' colours.
    readonly property var presets: ({
        dusk: { hue: 0.012, sat: 0.50, surface: "#271d1c", abyss: "#1a1110", snow: "#f6dedb", mist: "#d9c2bf",
                ash: "#a48f8c", ghost: "#ffb4ab", neutral: "#e8c29c", accentText: "#561e19", error: "#ff5449" },
        forest: { hue: 0.40, sat: 0.34, surface: "#1b241d", abyss: "#111812", snow: "#dcebdc", mist: "#b4c7b5",
                ash: "#7f927f", ghost: "#a6d6a2", neutral: "#e0d4a0", accentText: "#0f3a14", error: "#ffb4ab" },
        midnight: { hue: 0.64, sat: 0.40, surface: "#1b1f2b", abyss: "#10131c", snow: "#e0e4f3", mist: "#b5bcd3",
                ash: "#80879f", ghost: "#aac7ff", neutral: "#f0d2a8", accentText: "#0b2e5c", error: "#ffb4ab" },
        amber: { hue: 0.10, sat: 0.50, surface: "#261f17", abyss: "#19130c", snow: "#f4e6d3", mist: "#d4c3a9",
                ash: "#a09078", ghost: "#ffb870", neutral: "#f2d29a", accentText: "#4a2800", error: "#ffb4ab" },
        ash: { hue: 0.70, sat: 0.16, surface: "#1c1c21", abyss: "#101015", snow: "#e8e8ec", mist: "#9090a0",
                ash: "#4a4a54", ghost: "#b8b8cc", neutral: "#b0a090", accentText: "#12121a", error: "#c87a7a" }
    })
    readonly property var scheme: presets[config.preset] || presets.dusk
    QtObject {
        id: pal
        readonly property color surface: root.scheme.surface
        readonly property color abyss: root.scheme.abyss
        readonly property color snow: root.scheme.snow
        readonly property color mist: root.scheme.mist
        readonly property color ash: root.scheme.ash
        readonly property color ghost: root.scheme.ghost
        readonly property color neutral: root.scheme.neutral
        readonly property color accentText: root.scheme.accentText
        readonly property color error: root.scheme.error
    }

    readonly property color base: Qt.color(pal.surface)
    // A plate: the surface at 0.82, as everywhere in the session.
    readonly property color plate: Qt.rgba(root.base.r, root.base.g, root.base.b, 0.82)
    readonly property color faint: Qt.rgba(0.91, 0.91, 0.93, 0.4)
    function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }
    function mix(a, b, t) { return Qt.tint(a, Qt.rgba(b.r, b.g, b.b, t)) }
    function tone(l) { return Qt.hsla(root.scheme.hue, root.scheme.sat, l, 1) }

    // Where the round copy of the face lives (scripts/ashen-sddm-face.sh): the
    // one folder sddm can read. Older installs named it through palettePath.
    readonly property string faceDir: config.faceDir ? config.faceDir
        : (config.palettePath ? config.palettePath.replace(/\/[^\/]*$/, "") : "")
    readonly property string facePath: root.faceDir ? "file://" + root.faceDir + "/face.png" : ""

    QtObject { id: clock; property var now: new Date() }
    Timer { interval: 1000; running: true; repeat: true; onTriggered: clock.now = new Date() }

    Ridges {
        anchors.fill: parent
        skyTop: root.tone(0.20)
        skyMid: root.tone(0.34)
        skyHorizon: root.tone(0.82)
        // The one warm touch: the sun, and the light it throws.
        sun: root.mix(root.tone(0.95), pal.neutral, 0.22)
        glow: root.mix(root.tone(0.9), pal.neutral, 0.3)
        haze: root.tone(0.78)
        ridgeColors: [root.tone(0.70), root.tone(0.62), root.tone(0.54), root.tone(0.45), root.tone(0.34), root.tone(0.20)]
    }
    // Keeps the clock and the plates readable over the lightest band.
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: root.alpha(pal.abyss, 0.10) }
            GradientStop { position: 0.55; color: root.alpha(pal.abyss, 0.20) }
            GradientStop { position: 1.0; color: root.alpha(pal.abyss, 0.08) }
        }
    }

    component Pill: Rectangle {
        radius: root.pillR
        color: root.plate
        implicitHeight: root.pillH
    }

    // A compact plate for an action: a chip with its glyph and a word. Hover =
    // grow and brighten, never a fill.
    component ChipPlate: Rectangle {
        id: cp
        property string glyph
        property string title
        signal activated()
        width: 190; height: 60; radius: root.cardR
        color: root.plate
        scale: hov.hovered ? 1.05 : 1
        Behavior on scale { NumberAnimation { duration: 150 } }
        HoverHandler { id: hov; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: cp.activated() }
        Row {
            anchors.centerIn: parent
            spacing: 12
            Rectangle {
                width: 38; height: 38; radius: 10
                color: root.alpha(pal.ghost, 0.16)
                Text {
                    anchors.centerIn: parent
                    text: cp.glyph
                    color: hov.hovered ? pal.snow : pal.ghost
                    font.pixelSize: 22; font.family: "Material Symbols Rounded"
                }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: cp.title
                color: hov.hovered ? pal.snow : pal.mist
                font.pixelSize: 16; font.bold: true
                font.family: "JetBrainsMono NF"
            }
        }
    }

    // The pickers. The control itself is invisible -- the plate is its face --
    // but its popup is its own item, so everything it draws is spelled out.
    component Picker: ComboBox {
        id: pick
        opacity: 0
        HoverHandler { cursorShape: pick.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor }
        popup: Popup {
            // Opens upwards when the control sits low on the screen.
            y: pick.openUp ? -implicitHeight - 6 : pick.height + 6
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
        property bool openUp: false
        delegate: ItemDelegate {
            id: row
            width: ListView.view ? ListView.view.width : 0
            height: 34
            // Hover brightens the text, it does not fill the row.
            contentItem: Text {
                text: pick.textRole ? (Array.isArray(pick.model)
                        ? modelData[pick.textRole]
                        : model[pick.textRole])
                    : modelData
                color: row.hovered || pick.currentIndex === index ? pal.snow : pal.mist
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

    // The whole composition lives in a 1920x1080 box and is scaled to fit, so
    // every size below is the one the design was drawn at.
    Item {
        id: stage
        width: 1920; height: 1080
        anchors.centerIn: parent
        scale: Math.min(root.width / 1920, root.height / 1080)

        // ---- Left: the time, the date, and who you are -----------------------
        Column {
            x: 170; y: 190
            spacing: 18

            // The time, huge, its colon in the accent.
            Item {
                width: timeRow.width; height: 200
                Row {
                    id: timeRow
                    anchors.verticalCenter: parent.verticalCenter
                    Text {
                        text: Qt.formatTime(clock.now, "HH")
                        color: pal.snow
                        font.pixelSize: 236; font.weight: Font.Bold; font.letterSpacing: -6
                        font.family: "JetBrainsMono NF"
                    }
                    Text {
                        text: ":"
                        color: pal.ghost
                        font.pixelSize: 236; font.weight: Font.Bold
                        font.family: "JetBrainsMono NF"
                    }
                    Text {
                        text: Qt.formatTime(clock.now, "mm")
                        color: pal.snow
                        font.pixelSize: 236; font.weight: Font.Bold; font.letterSpacing: -6
                        font.family: "JetBrainsMono NF"
                    }
                }
            }

            Pill {
                implicitWidth: dateText.implicitWidth + 40
                Text {
                    id: dateText
                    anchors.centerIn: parent
                    text: Qt.formatDate(clock.now, "dddd · MMM d").toUpperCase()
                    color: pal.snow
                    font.pixelSize: 14; font.bold: true; font.letterSpacing: 1.5
                    font.family: "JetBrainsMono NF"
                }
            }

            Item { width: 1; height: 22 }

            // Who you are and the way in: ONE plate, like the lock's.
            Rectangle {
                width: 500
                height: whoCol.implicitHeight + 48
                radius: root.cardR
                color: root.plate

                Column {
                    id: whoCol
                    x: 26; y: 24
                    width: parent.width - 52
                    spacing: 16

                    Row {
                        spacing: 16
                        // The face, round, with its ring: at rest a plain edge, the
                        // accent while it checks, the error when it said no.
                        Rectangle {
                            id: faceRing
                            width: 64; height: 64; radius: width / 2
                            color: root.alpha(pal.ghost, 0.12)
                            border.width: 2
                            border.color: message.text !== "" ? pal.error
                                : root.loggingIn ? pal.ghost : root.alpha(pal.ghost, 0.20)
                            Behavior on border.color { ColorAnimation { duration: 150 } }
                            // Already round (scripts/ashen-sddm-face.sh), so it is only
                            // shown: a mask would be a shader, and a greeter on software
                            // rendering draws none -- an empty circle.
                            Image {
                                id: faceImg
                                anchors.fill: parent; anchors.margins: 2
                                source: root.facePath
                                sourceSize: Qt.size(256, 256)
                                fillMode: Image.PreserveAspectFit
                                cache: false
                            }
                            Text {
                                anchors.centerIn: parent
                                text: "\ue7fd"   // person
                                color: pal.ghost
                                font.pixelSize: 32; font.family: "Material Symbols Rounded"
                                visible: faceImg.status !== Image.Ready
                            }
                        }

                        // Who: the name, and a picker over it when there is a choice.
                        Item {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 360; height: 40
                            Text {
                                id: userText
                                anchors.verticalCenter: parent.verticalCenter
                                text: userList.currentText
                                color: pal.snow
                                font.pixelSize: 24; font.bold: true; font.letterSpacing: 1
                                font.family: "JetBrainsMono NF"
                            }
                            Picker {
                                id: userList
                                objectName: "userPicker"
                                anchors.fill: parent
                                // One user is not a choice.
                                enabled: userModel.count > 1
                                model: userModel; textRole: "name"; currentIndex: userModel.lastIndex
                            }
                        }
                    }

                    // The way in, sunk into the plate: lock at one end, the way in
                    // at the other, the dots and the prompt on its own centre. It
                    // shakes on a wrong password.
                    Rectangle {
                        id: passField
                        width: parent.width; height: 56
                        radius: root.cardR
                        color: root.alpha(pal.ghost, 0.08)
                        border.width: 1
                        border.color: message.text !== "" ? pal.error
                            : password.activeFocus ? pal.ghost : root.alpha(pal.ghost, 0.20)
                        Behavior on border.color { ColorAnimation { duration: 150 } }
                        transform: Translate { id: shakeT; x: 0 }

                        SequentialAnimation {
                            id: shakeAnim
                            NumberAnimation { target: shakeT; property: "x"; to: 9; duration: 55 }
                            NumberAnimation { target: shakeT; property: "x"; to: -8; duration: 55 }
                            NumberAnimation { target: shakeT; property: "x"; to: 6; duration: 55 }
                            NumberAnimation { target: shakeT; property: "x"; to: -4; duration: 55 }
                            NumberAnimation { target: shakeT; property: "x"; to: 0; duration: 55 }
                        }

                        // The field takes the keys but draws nothing: the dots below do.
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

                        Text {
                            anchors.left: parent.left; anchors.leftMargin: 20
                            anchors.verticalCenter: parent.verticalCenter
                            text: "\ue897"   // lock
                            color: message.text !== "" ? pal.error : pal.ghost
                            font.pixelSize: 20; font.family: "Material Symbols Rounded"
                        }

                        // The lock's own dots. The model is a CONSTANT (a number that
                        // changes rebuilds every delegate and replays the entry on all
                        // of them): 16 slots, each told whether it is filled. A slot
                        // opens, a dash appears in it and closes into a dot; the row
                        // recentres as it grows.
                        Row {
                            anchors.centerIn: parent
                            Repeater {
                                model: 16
                                delegate: Item {
                                    required property int index
                                    readonly property bool on: index < Math.min(password.text.length, 16)
                                    width: on ? 17 : 0
                                    height: 11
                                    Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutQuint } }
                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: parent.on ? 11 : 9
                                        height: parent.on ? 11 : 2
                                        radius: height / 2
                                        opacity: parent.on ? 1 : 0
                                        color: pal.ghost
                                        Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutQuint } }
                                        Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutQuint } }
                                        Behavior on opacity { NumberAnimation { duration: 120 } }
                                    }
                                }
                            }
                        }
                        // Literal, NOT textConstants: sddm-greeter-qt6 0.21 does not hand
                        // this theme a `textConstants`.
                        Text {
                            anchors.centerIn: parent
                            visible: password.text === ""
                            text: "enter password..."
                            color: pal.mist
                            font.pixelSize: 14
                            font.family: "JetBrainsMono NF"
                        }

                        Text {
                            anchors.right: parent.right; anchors.rightMargin: 20
                            anchors.verticalCenter: parent.verticalCenter
                            text: "\ue5c8"   // arrow_forward
                            color: root.loggingIn || password.text !== "" ? pal.ghost : pal.mist
                            font.pixelSize: 20; font.family: "Material Symbols Rounded"
                            Behavior on color { ColorAnimation { duration: 150 } }
                            MouseArea {
                                anchors.fill: parent; anchors.margins: -8
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.tryLogin()
                            }
                        }
                    }

                    // Keeps its height either way: a message must not shove the field.
                    Item {
                        width: parent.width; height: 16
                        Text {
                            id: message
                            anchors.centerIn: parent
                            color: pal.error
                            font.pixelSize: 12; font.family: "JetBrainsMono NF"
                        }
                        // Caps Lock is where a password fails without saying why.
                        Text {
                            anchors.centerIn: parent
                            visible: message.text === "" && !!(keyboard && keyboard.capsLock)
                            text: "caps lock is on"
                            color: pal.mist
                            font.pixelSize: 12; font.family: "JetBrainsMono NF"
                        }
                    }
                }
            }
        }

        // ---- Top right: the ways out, in a row -------------------------------
        Row {
            anchors.right: parent.right; anchors.rightMargin: 170
            y: 64
            spacing: 14
            ChipPlate {
                glyph: "\uf159"; title: "sleep"
                onActivated: sddm.suspend()
            }
            ChipPlate {
                glyph: "\uf053"; title: "reboot"
                onActivated: sddm.reboot()
            }
            ChipPlate {
                glyph: "\uf8c7"; title: "shutdown"
                onActivated: sddm.powerOff()
            }
        }

        // ---- Right: the month, a big plate -----------------------------------
        Rectangle {
            id: cal
            x: 1430; y: 330
            width: 320; height: calCol.implicitHeight + 46
            radius: root.cardR
            color: root.plate
            readonly property var d: clock.now
            readonly property int first: new Date(d.getFullYear(), d.getMonth(), 1).getDay()
            readonly property int days: new Date(d.getFullYear(), d.getMonth() + 1, 0).getDate()
            readonly property int rows: Math.ceil((first + days) / 7)

            Column {
                id: calCol
                x: 23; y: 23
                spacing: 12
                Text {
                    text: Qt.formatDate(cal.d, "MMMM yyyy").toUpperCase()
                    color: pal.mist
                    font.pixelSize: 12; font.bold: true; font.letterSpacing: 1.5
                    font.family: "JetBrainsMono NF"
                }
                Grid {
                    columns: 7
                    Repeater {
                        model: ["S", "M", "T", "W", "T", "F", "S"]
                        Text {
                            required property string modelData
                            width: 38; height: 24
                            horizontalAlignment: Text.AlignHCenter
                            text: modelData
                            color: pal.ash
                            font.pixelSize: 11; font.bold: true
                            font.family: "JetBrainsMono NF"
                        }
                    }
                    Repeater {
                        model: cal.rows * 7
                        Item {
                            required property int index
                            readonly property int day: index - cal.first + 1
                            readonly property bool real: day >= 1 && day <= cal.days
                            readonly property bool today: real && day === cal.d.getDate()
                            width: 38; height: 36
                            // Today is the one filled chip, as in the shell's calendar.
                            Rectangle {
                                anchors.centerIn: parent
                                width: 32; height: 32; radius: 10
                                color: pal.ghost
                                visible: parent.today
                            }
                            Text {
                                anchors.centerIn: parent
                                text: parent.real ? parent.day : "-"
                                opacity: parent.real ? 1 : 0
                                color: parent.today ? pal.accentText : pal.snow
                                font.pixelSize: 14; font.bold: parent.today
                                font.family: "JetBrainsMono NF"
                            }
                        }
                    }
                }
            }
        }

        // ---- Bottom left: the session -----------------------------------------
        Pill {
            x: 170; y: 1080 - 44 - 44
            implicitWidth: sessRow.implicitWidth + 36
            Row {
                id: sessRow
                anchors.centerIn: parent
                spacing: 8
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "\ue30a"   // computer
                    color: pal.mist
                    font.pixelSize: 17; font.family: "Material Symbols Rounded"
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: sessionList.currentText.toLowerCase(); color: pal.snow
                    font.pixelSize: 13; font.family: "JetBrainsMono NF"
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "\ue5cf"   // expand_more
                    color: pal.mist
                    font.pixelSize: 15; font.family: "Material Symbols Rounded"
                }
            }
            Picker {
                id: sessionList
                objectName: "sessionPicker"
                anchors.fill: parent
                openUp: true
                model: sessionModel; textRole: "name"; currentIndex: sessionModel.lastIndex
            }
        }
    }

    property bool loggingIn: false

    function tryLogin() {
        message.text = ""
        root.loggingIn = true
        sddm.login(userList.currentText, password.text, sessionList.currentIndex)
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            root.loggingIn = false
            message.text = "wrong password"   // literal, for the reason noted above
            password.text = ""
            shakeAnim.restart()
            password.forceActiveFocus()
        }
    }

    Component.onCompleted: password.forceActiveFocus()
}
