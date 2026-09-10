import QtQuick
import "../../quickshell/.config/quickshell/ashen/modules/widgets" as W

Window {
    id: win
    visible: true
    width: 760; height: 220
    color: "#000000"

    W.AshenMark {
        id: mark
        anchors.centerIn: parent
        pixelSize: 16
        color: "#ffffff"
    }

    Timer {
        interval: 600; running: true
        onTriggered: mark.grabToImage(function (r) { r.saveToFile("mark.png"); Qt.quit() })
    }
}
