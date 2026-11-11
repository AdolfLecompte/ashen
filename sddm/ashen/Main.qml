import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Login screen, laid out like the session's own lock screen: the time large in
// the middle, who and the password under it, the session and the ways out
// in the bottom corners. No name on it, so it suits any desktop.
//
// NOT SddmComponents: that module ships its own ComboBox, Button and TextField
// which shadow QtQuick.Controls' and carry a different API -- importing it made
// the theme fail to load and SDDM silently fell back to its default theme.
//
// The palette is theme.conf: sddm runs as its own user and cannot read a home.
Rectangle {
    id: root
    width: 1920; height: 1080
    color: pal.surface

    readonly property int pillH: 44
    readonly property int pillR: 10
    readonly property int gap: 6
    readonly property color base: Qt.color(pal.surface)
    // A capsule's plate: the surface at 0.82, as everywhere in the session.
    readonly property color plate: Qt.rgba(root.base.r, root.base.g, root.base.b, 0.82)
    readonly property color faint: Qt.rgba(0.91, 0.91, 0.93, 0.4)

    QtObject { id: clock; property var now: new Date() }
    Timer { interval: 1000; running: true; repeat: true; onTriggered: clock.now = new Date() }

    // The session's live palette, when sddm is allowed to see it: matugen
    // writes a QML file into a folder this user can read (see install/lib/
    // sddm.sh). If it is missing the theme.conf palette stands in, so the
    // login never depends on it.
    Loader {
        id: live
        visible: false
        source: config.palettePath ? "file://" + config.palettePath : ""
    }
    QtObject {
        id: pal
        readonly property var src: live.status === Loader.Ready ? live.item : null
        property color surface: src ? src.surface : config.surface
        property color abyss: src ? src.abyss : config.abyss
        property color elevated: src ? src.elevated : config.elevated
        property color snow: src ? src.snow : config.snow
        property color mist: src ? src.mist : config.mist
        property color ash: src ? src.ash : config.ash
        property color ghost: src ? src.ghost : config.ghost
        property color shade: src ? src.shade : config.shade
        property color neutral: src ? src.neutral : config.neutral
        property color error: src ? src.error_ : config.error
        // Text on a snow-coloured chip.
        property color accentText: src ? src.abyss : config.accentText
    }
    function mix(a, b, t) { return Qt.tint(a, Qt.rgba(b.r, b.g, b.b, t)) }
    // One hue in steps of lightness: the palette's accent, kept soft. Every
    // layer of the scene is a step on this ramp, never a colour of its own.
    readonly property real hue: pal.ghost.hslHue >= 0 ? pal.ghost.hslHue : 0.6
    readonly property real sat: Math.min(0.5, Math.max(0.16, pal.ghost.hslSaturation * 0.6))
    function tone(l) { return Qt.hsla(root.hue, root.sat, l, 1) }

    Seascape {
        id: sea
        anchors.fill: parent
        skyTop: root.tone(0.22)
        skyMid: root.tone(0.36)
        skyHorizon: root.tone(0.84)
        // The one warm touch: the sun, and the light it throws.
        sun: root.mix(root.tone(0.95), pal.neutral, 0.22)
        glow: root.mix(root.tone(0.9), pal.neutral, 0.3)
        hillFar: root.tone(0.70)
        hillMid: root.tone(0.55)
        hillNear: root.tone(0.42)
        headland: root.tone(0.26)
        waterTop: root.tone(0.66)
        waterBottom: root.tone(0.14)
        shoreHigh: root.tone(0.34)
        shoreMid: root.tone(0.22)
        shoreLow: root.tone(0.14)
    }
    // Keeps the clock and the field readable over the lightest band.
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(pal.abyss.r, pal.abyss.g, pal.abyss.b, 0.08) }
            GradientStop { position: 0.55; color: Qt.rgba(pal.abyss.r, pal.abyss.g, pal.abyss.b, 0.16) }
            GradientStop { position: 1.0; color: Qt.rgba(pal.abyss.r, pal.abyss.g, pal.abyss.b, 0.06) }
        }
    }

    component Pill: Rectangle {
        radius: root.pillR
        color: root.plate
        implicitHeight: root.pillH
    }

    // The pickers. The control itself is invisible -- the pill is its face --
    // but its popup is its own item, so everything it draws is spelled out.
    component Picker: ComboBox {
        id: pick
        opacity: 0
        HoverHandler { cursorShape: pick.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor }
        popup: Popup {
            // Opens upwards when the pill sits at the bottom of the screen.
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

    // ---- One column on one axis: time, who, the way in -------------------
    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.height * 0.24
        spacing: 0

        // The hour large, the seconds small beside it: the lock's own clock.
        Row {
            Layout.alignment: Qt.AlignHCenter
            spacing: 0
            Text {
                text: Qt.formatTime(clock.now, "HH:mm")
                color: pal.snow
                font.pixelSize: 104; font.weight: Font.Bold; font.letterSpacing: -2
                font.family: "JetBrainsMono NF"
            }
            Text {
                anchors.bottom: parent.bottom; anchors.bottomMargin: 20
                leftPadding: 8
                text: Qt.formatTime(clock.now, "ss")
                color: root.faint
                font.pixelSize: 26; font.weight: Font.Bold
                font.family: "JetBrainsMono NF"
            }
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDate(clock.now, "dddd, d MMMM").toLowerCase()
            color: pal.mist
            font.pixelSize: 15
            font.family: "JetBrainsMono NF"
        }

        Item { Layout.preferredHeight: 44 }

        // Who: a glyph and the name; a picker over it when there is a choice.
        Item {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: whoRow.implicitWidth + 24
            implicitHeight: 28
            Row {
                id: whoRow
                anchors.centerIn: parent
                spacing: 8
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "\ue7fd"   // person
                    color: pal.mist
                    font.pixelSize: 18; font.family: "Material Symbols Rounded"
                }
                Text {
                    id: userText
                    anchors.verticalCenter: parent.verticalCenter
                    text: userList.currentText.toLowerCase()
                    color: pal.snow
                    font.pixelSize: 15; font.bold: true
                    font.family: "JetBrainsMono NF"
                }
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

        Item { Layout.preferredHeight: 14 }

        // The password capsule: lock at one end, the way in at the other, the
        // dots and the prompt on the capsule's own centre.
        Pill {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 380
            implicitHeight: 52
            border.width: password.activeFocus ? 2 : 0
            border.color: pal.ghost

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
                anchors.left: parent.left; anchors.leftMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                text: "\ue897"   // lock
                color: pal.mist
                font.pixelSize: 18; font.family: "Material Symbols Rounded"
            }

            // The lock's own dots. The model is a CONSTANT (a number that changes
            // rebuilds every delegate and replays the entry on all of them): 16
            // slots, each told whether it is filled. A slot opens, a dash
            // appears in it and closes into a dot; the row recentres as it grows.
            Row {
                anchors.centerIn: parent
                Repeater {
                    model: 16
                    delegate: Item {
                        required property int index
                        readonly property bool on: index < Math.min(password.text.length, 16)
                        readonly property bool last: on && index === Math.min(password.text.length, 16) - 1
                        width: on ? 17 : 0
                        height: 11
                        Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutQuint } }
                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.on ? 11 : 9
                            height: parent.on ? 11 : 2
                            radius: height / 2
                            opacity: parent.on ? 1 : 0
                            color: parent.last ? pal.snow : root.faint
                            Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutQuint } }
                            Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutQuint } }
                            Behavior on opacity { NumberAnimation { duration: 120 } }
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }
                }
            }
            // Literal, NOT textConstants: sddm-greeter-qt6 0.21 does not hand
            // this theme a `textConstants`.
            Text {
                anchors.centerIn: parent
                visible: password.text === ""
                text: "password"
                color: pal.mist
                font.pixelSize: 13
                font.family: "JetBrainsMono NF"
            }

            Rectangle {
                anchors.right: parent.right; anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                width: 36; height: 36; radius: 8
                color: password.text === "" ? "transparent" : pal.snow
                Behavior on color { ColorAnimation { duration: 150 } }
                Text {
                    anchors.centerIn: parent
                    text: "\ue5c8"   // arrow_forward
                    color: password.text === "" ? pal.ash : pal.accentText
                    font.pixelSize: 20; font.family: "Material Symbols Rounded"
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.tryLogin() }
            }
        }

        // Keeps its height either way: a message must not shove the field.
        Text {
            id: message
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 12
            Layout.preferredHeight: 14
            opacity: text !== "" ? 1 : 0
            color: pal.error
            font.pixelSize: 12; font.family: "JetBrainsMono NF"
        }
    }

    // ---- Bottom centre: the session and the ways out, one plate -----------
    Pill {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom; anchors.bottomMargin: 28
        implicitWidth: sessBox.width + 1 + powerRow.implicitWidth + 16

        Item {
            id: sessBox
            anchors.left: parent.left
            height: parent.height
            width: sessRow.implicitWidth + 32
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
                    text: sessionList.currentText; color: pal.snow
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

        Rectangle {
            x: sessBox.width
            anchors.verticalCenter: parent.verticalCenter
            width: 1; height: 22
            color: Qt.rgba(1, 1, 1, 0.12)
        }

        // The same three the session's power menu offers, with its glyphs.
        Row {
            id: powerRow
            anchors.right: parent.right; anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            Repeater {
                model: [
                    { g: "\uf159", act: "suspend" },
                    { g: "\uf053", act: "reboot" },
                    { g: "\uf8c7", act: "poweroff" }
                ]
                Rectangle {
                    width: 38; height: 34; radius: 8
                    color: "transparent"
                    // Hover = grow and brighten, never a fill.
                    scale: ma.containsMouse ? 1.06 : 1
                    Behavior on scale { NumberAnimation { duration: 150 } }
                    Text {
                        anchors.centerIn: parent
                        text: modelData.g
                        color: ma.containsMouse ? pal.snow : pal.mist
                        font.pixelSize: 17; font.family: "Material Symbols Rounded"
                    }
                    MouseArea {
                        id: ma
                        anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (modelData.act === "poweroff") sddm.powerOff()
                            else if (modelData.act === "reboot") sddm.reboot()
                            else sddm.suspend()
                        }
                    }
                }
            }
        }
    }

    function tryLogin() {
        message.text = ""
        sddm.login(userList.currentText, password.text, sessionList.currentIndex)
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            message.text = "wrong password"   // literal, for the reason noted above
            password.text = ""
            password.forceActiveFocus()
        }
    }

    Component.onCompleted: password.forceActiveFocus()
}
