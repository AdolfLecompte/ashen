import QtQuick

// A stand-in for the greeter, so the theme can be loaded and its errors READ.
// sddm-greeter injects `config`, `sddm`, `userModel`, `sessionModel`, `keyboard`
// and `textConstants` as context properties and reports QML errors to its own
// log -- which, on a failure to build the scene, can come out empty. Loading the
// theme here prints the error like any other QML file.
Window {
    id: win
    visible: true
    width: 1600; height: 900
    color: "#000"

    property QtObject config: QtObject {
        property string background: Qt.resolvedUrl("../../../sddm/ashen/backgrounds/ashen.jpg")
        property string surface: "#12121a"
        property string elevated: "#2e2e34"
        property string snow: "#e8e8ec"
        property string mist: "#9090a0"
        property string ash: "#4a4a54"
        property string ghost: "#6e6e7a"
        property string accentText: "#12121a"
        property string error: "#c87a7a"
        property string radius: "22"
        property string innerRadius: "10"
        property string fieldWidth: "300"
    }
    property QtObject sddm: QtObject {
        property bool loginInProgress: false
        property bool canPowerOff: true
        property bool canReboot: true
        property bool canSuspend: true
        property bool canHibernate: true
        signal loginFailed()
        function login(u, p, s) {}
        function powerOff() {} function reboot() {}
        function suspend() {} function hibernate() {}
    }
    property QtObject textConstants: QtObject {
        property string prompt: "Authenticate"
        property string password: "Password"
        property string login: "Unlock"
        property string loginFailed: "Login failed"
    }
    property var userModel: ListModel {
        property int lastIndex: 0
        property int count: 1
        ListElement { name: "adolf" }
    }
    property var sessionModel: ListModel {
        property int lastIndex: 0
        ListElement { name: "Hyprland" }
        ListElement { name: "Hyprland (uwsm)" }
    }
    property QtObject keyboard: QtObject {
        property var layouts: []
        property int currentLayout: 0
    }

    Loader {
        id: theme
        anchors.fill: parent
        source: "../../../sddm/ashen/Main.qml"
    }

    // The proof is the picture: qml6 here prints load errors but not
    // console.log, so "it rendered" is the only report that carries.
    Timer {
        interval: 900; running: true
        onTriggered: win.contentItem.grabToImage(function (r) {
            r.saveToFile("theme.png"); Qt.exit(theme.status === Loader.Ready ? 0 : 1)
        })
    }
}
