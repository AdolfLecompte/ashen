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
    color: config.surface

    readonly property int pillH: 44
    readonly property int pillR: 10
    readonly property int gap: 6
    readonly property color base: Qt.color(config.surface)
    // A capsule's plate: the surface at 0.82, as everywhere in the session.
    readonly property color plate: Qt.rgba(root.base.r, root.base.g, root.base.b, 0.82)
    readonly property color faint: Qt.rgba(0.91, 0.91, 0.93, 0.4)

    QtObject { id: clock; property var now: new Date() }
    Timer { interval: 1000; running: true; repeat: true; onTriggered: clock.now = new Date() }

    Image { anchors.fill: parent; source: config.background; fillMode: Image.PreserveAspectCrop; visible: status === Image.Ready }
    Rectangle { anchors.fill: parent; color: Qt.rgba(0, 0, 0, 0.55) }

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

    // ---- The time, who, and the way in ----------------------------------
    ColumnLayout {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -40
        spacing: 0

        // The hour large, the seconds small beside it: the lock's own clock.
        Row {
            Layout.alignment: Qt.AlignHCenter
            spacing: 0
            Text {
                text: Qt.formatTime(clock.now, "HH:mm")
                color: config.snow
                font.pixelSize: 112; font.weight: Font.Bold; font.letterSpacing: -2
                font.family: "JetBrainsMono NF"
            }
            Text {
                anchors.bottom: parent.bottom; anchors.bottomMargin: 22
                leftPadding: 8
                text: Qt.formatTime(clock.now, "ss")
                color: root.faint
                font.pixelSize: 28; font.weight: Font.Bold
                font.family: "JetBrainsMono NF"
            }
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDate(clock.now, "dddd, d MMMM").toLowerCase()
            color: config.mist
            font.pixelSize: 16
            font.family: "JetBrainsMono NF"
        }

        Item { Layout.preferredHeight: 56 }

        // Who: plain text, and a picker over it when there is a choice.
        Item {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: userText.implicitWidth + 24
            implicitHeight: 28
            Text {
                id: userText
                anchors.centerIn: parent
                text: userList.currentText.toLowerCase()
                color: config.snow
                font.pixelSize: 15; font.bold: true
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

        Item { Layout.preferredHeight: 12 }

        // The password capsule, with the way in at its end.
        Pill {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 380
            implicitHeight: 48
            border.width: password.activeFocus ? 2 : 0
            border.color: config.ghost

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

            // One dot per key, the newest brighter.
            Row {
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: -18
                spacing: 7
                visible: password.text !== ""
                Repeater {
                    model: Math.min(password.text.length, 16)
                    Rectangle {
                        readonly property bool last: index === Math.min(password.text.length, 16) - 1
                        width: 7; height: 7; radius: 3.5
                        anchors.verticalCenter: parent.verticalCenter
                        color: last ? config.snow : root.faint
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }
            }
            // Literal, NOT textConstants: sddm-greeter-qt6 0.21 does not hand
            // this theme a `textConstants`.
            Text {
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: -18
                visible: password.text === ""
                text: "password"
                color: config.mist
                font.pixelSize: 13
                font.family: "JetBrainsMono NF"
            }

            Rectangle {
                anchors.right: parent.right; anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                width: 36; height: 36; radius: 8
                color: password.text === "" ? "transparent" : config.snow
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

        // Keeps its height either way: a message must not shove the field.
        Text {
            id: message
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 12
            Layout.preferredHeight: 14
            opacity: text !== "" ? 1 : 0
            color: config.error
            font.pixelSize: 12; font.family: "JetBrainsMono NF"
        }
    }

    // ---- Bottom left: the session ---------------------------------------
    Pill {
        anchors.left: parent.left; anchors.leftMargin: 28
        anchors.bottom: parent.bottom; anchors.bottomMargin: 28
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
                text: ""   // expand_more
                color: config.mist
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

    // ---- Bottom right: the ways out, chips in one plate ------------------
    Pill {
        anchors.right: parent.right; anchors.rightMargin: 28
        anchors.bottom: parent.bottom; anchors.bottomMargin: 28
        implicitWidth: powerRow.implicitWidth + 16

        Row {
            id: powerRow
            anchors.centerIn: parent
            spacing: 2
            Repeater {
                model: [
                    { g: "", act: "suspend" },
                    { g: "", act: "hibernate" },
                    { g: "", act: "reboot" },
                    { g: "", act: "poweroff" }
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
