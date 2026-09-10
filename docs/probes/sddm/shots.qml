import QtQuick
import QtQuick.Controls

// Three states of the login, without a greeter: idle, mid-password, rejected.
// Typing is done by hand -- offscreen has no keyboard -- so the field is found
// by objectName and written to directly.
Window {
    id: win
    visible: true
    width: 1600; height: 900
    color: "#000"

    property QtObject config: QtObject {
        property string background: Qt.resolvedUrl("../../../sddm/ashen/backgrounds/ashen.jpg")
        property string surface: "#1c1c21"
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
        property string loginFailed: "wrong word"
    }
    property var userModel: ListModel {
        property int lastIndex: 0
        property int count: 1
        ListElement { name: "adolf" }
    }
    property var sessionModel: ListModel {
        property int lastIndex: 0
        ListElement { name: "Hyprland" }
    }
    property QtObject keyboard: QtObject {
        property var layouts: []
        property int currentLayout: 0
    }

    Loader { id: theme; anchors.fill: parent; source: "../../../sddm/ashen/Main.qml" }

    function findByName(item, name) {
        if (!item) return null
        if (item.objectName === name) return item
        for (var i = 0; i < item.children.length; i++) {
            var f = findByName(item.children[i], name)
            if (f) return f
        }
        return null
    }

    property int shot: 0
    readonly property var names: ["idle", "typing", "rejected"]

    Timer {
        interval: 700; running: true; repeat: true
        onTriggered: {
            var f = win.findByName(theme.item, "password")
            if (win.shot === 1 && f) f.text = "correct"
            if (win.shot === 2) { if (f) f.text = ""; win.sddm.loginFailed() }
            win.contentItem.grabToImage(function (r) {
                r.saveToFile("shot-" + win.names[win.shot] + ".png")
                win.shot++
                if (win.shot >= 3) Qt.exit(theme.status === Loader.Ready ? 0 : 1)
            })
        }
    }
}
