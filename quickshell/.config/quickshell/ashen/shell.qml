import Quickshell
import QtQuick

import "root:/modules/bar"
import "root:/modules/lock"

ShellRoot {
    Bar {}
    PowerMenu {}
    Calendar {}
    NetworkPanel {}
    BluetoothPanel {}
    LockScreen {}
}
