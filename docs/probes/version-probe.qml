import QtQuick

// One case per run, judged by the EXIT CODE: qml6 on this machine prints
// nothing at all from console.log or console.warn, so a probe that reports by
// printing passes silently, which is the same as not running. The shell script
// names the cases; this only says yes or no.
//
// Usage: qml6 version-probe.qml -- <a> <b> <expected: 1|0>
Window {
    id: root
    visible: true
    width: 1; height: 1

    readonly property var argv: Qt.application.arguments
    readonly property string a: argv[argv.length - 3]
    readonly property string b: argv[argv.length - 2]
    readonly property bool want: argv[argv.length - 1] === "1"

    // Mirrors Release.newer. The probe asserts the RULE; the service copies the
    // function that passes it.
    function newer(x, y) {
        const px = String(x).replace(/^v/, "").split(".").map(Number)
        const py = String(y).replace(/^v/, "").split(".").map(Number)
        for (let i = 0; i < Math.max(px.length, py.length); i++) {
            const m = px[i] || 0, n = py[i] || 0
            if (m !== n) return m > n
        }
        return false
    }

    Timer {
        interval: 0; running: true
        onTriggered: Qt.exit(root.newer(root.a, root.b) === root.want ? 0 : 1)
    }
}
