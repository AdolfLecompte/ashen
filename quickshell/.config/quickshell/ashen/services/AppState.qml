pragma Singleton
import Quickshell
import QtQuick

Singleton {
    id: root
    property bool powerMenuVisible: false
    property bool calendarVisible: false
    property bool networkVisible: false
    property bool bluetoothVisible: false
    property string networkTab: "wifi"
}
