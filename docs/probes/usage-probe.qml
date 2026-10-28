import QtQuick
import "../../quickshell/.config/quickshell/ashen/services/usageBook.js" as Book

// Runs the code Usage books with, and answers by exit code (qml6 prints
// nothing here): 0 when every case holds, the failing case's number if not.
Window {
    id: root
    visible: true
    width: 1; height: 1

    function at(y, mo, d, h, mi) { return new Date(y, mo - 1, d, h, mi).getTime() }
    function check() {
        // 1. 23:50 -> 00:10 is ten minutes on each day.
        let days = Book.book({}, "kitty", at(2026, 10, 26, 23, 50), at(2026, 10, 27, 0, 10))
        if (days["2026-10-26"].apps.kitty !== 600 || days["2026-10-27"].apps.kitty !== 600) return 1
        // 2. ...and in the right hours.
        if (days["2026-10-26"].hours[23] !== 600 || days["2026-10-27"].hours[0] !== 600) return 2
        // 3. 10:30 -> 12:15 shares 30, 60 and 15 minutes among three hours.
        days = Book.book({}, "brave", at(2026, 10, 27, 10, 30), at(2026, 10, 27, 12, 15))
        const h = days["2026-10-27"].hours
        if (h[10] !== 1800 || h[11] !== 3600 || h[12] !== 900 || days["2026-10-27"].total !== 6300) return 3
        // 4. A second booking adds to what is there, per app, and leaves the input alone.
        const before = days
        days = Book.book(days, "kitty", at(2026, 10, 27, 12, 15), at(2026, 10, 27, 12, 20))
        if (days["2026-10-27"].total !== 6600 || days["2026-10-27"].apps.kitty !== 300) return 4
        if (before["2026-10-27"].total !== 6300) return 5
        // 6. An empty span books nothing.
        if (Object.keys(Book.book({}, "x", 1000, 1000)).length !== 0) return 6
        return 0
    }
    Timer { interval: 0; running: true; onTriggered: Qt.exit(root.check()) }
}
