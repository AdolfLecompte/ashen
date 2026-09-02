pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// What this machine IS: the answers that do not change while it is running,
// asked once. It was living inside the About tab, which meant the desktop
// widget would have had to ask the same eight questions all over again.
Singleton {
    id: root

    property string osName: ""
    property string kernel: ""
    property string hostname: ""
    property string uptime: ""
    property string product: ""
    property string board: ""
    property string cpuInfo: ""
    property string gpuInfo: ""
    property string memInfo: ""
    property string diskInfo: ""
    property string pkgInfo: ""
    property string monitorInfo: ""

    // Anything that wants a live uptime says so; nothing polls for a panel
    // that is not on screen.
    property int watchers: 0
    function watch(on) { root.watchers = Math.max(0, root.watchers + (on ? 1 : -1)) }

    property bool asked: false
    // The first read builds the singleton, and that is when the questions go
    // out -- the same shape as every other service here.
    function probe() {
        if (root.asked) return
        root.asked = true
        basicProc.running = true
        hwProc.running = true
        cpuProc.running = true
        gpuProc.running = true
        memProc.running = true
        diskProc.running = true
        pkgProc.running = true
        monProc.running = true
    }
    Component.onCompleted: root.probe()

    // Uptime and memory are the two that move; the rest are settled by the
    // time the first answer lands.
    Timer {
        running: root.watchers > 0
        interval: 60000
        repeat: true
        onTriggered: { basicProc.running = true; memProc.running = true }
    }

    Process {
        id: basicProc
        command: ["sh", "-c", ". /etc/os-release; echo \"$PRETTY_NAME|$(uname -r)|$(hostnamectl hostname 2>/dev/null || hostname)|$(uptime -p)\""]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let p = text.trim().split("|")
                root.osName = p[0] || ""
                root.kernel = p[1] || ""
                root.hostname = p[2] || ""
                root.uptime = p[3] || ""
            }
        }
    }
    Process {
        id: hwProc
        command: ["sh", "-c", "echo \"$(cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null)|$(cat /sys/devices/virtual/dmi/id/board_name 2>/dev/null)\""]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let p = text.trim().split("|")
                root.product = p[0] || ""
                root.board = p[1] || ""
            }
        }
    }
    Process {
        id: cpuProc
        command: ["sh", "-c", "echo \"$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | sed 's/^ *//') ($(nproc) threads)\""]
        running: false
        stdout: StdioCollector { onStreamFinished: root.cpuInfo = text.trim() }
    }
    Process {
        id: gpuProc
        command: ["sh", "-c", "lspci | grep -E 'VGA|3D controller' | sed 's/^[^:]*: //' | paste -sd '/'"]
        running: false
        stdout: StdioCollector { onStreamFinished: root.gpuInfo = text.trim() }
    }
    Process {
        id: memProc
        command: ["sh", "-c", "free -h | awk '/^Mem:/{print $3\"/\"$2}'"]
        running: false
        stdout: StdioCollector { onStreamFinished: root.memInfo = text.trim() }
    }
    Process {
        id: diskProc
        command: ["sh", "-c", "df -h --output=used,size / | tail -1 | awk '{print $1\"/\"$2}'"]
        running: false
        stdout: StdioCollector { onStreamFinished: root.diskInfo = text.trim() }
    }
    Process {
        id: pkgProc
        command: ["sh", "-c", "echo \"$(pacman -Qq 2>/dev/null | wc -l) packages\""]
        running: false
        stdout: StdioCollector { onStreamFinished: root.pkgInfo = text.trim() }
    }
    Process {
        id: monProc
        command: ["sh", "-c", "hyprctl monitors | grep -E 'Monitor|resolution' | tr '\\n' ' ' | sed 's/  */ /g'"]
        running: false
        stdout: StdioCollector { onStreamFinished: root.monitorInfo = text.trim() }
    }

    // Short forms for a widget, which has a plate to fit rather than a table.
    readonly property string shortOs: root.osName.replace(/ Linux$/, "")
    readonly property string shortUptime: root.uptime.replace(/^up /, "")
    // "12th Gen Intel(R) Core(TM) i5-12450H (12 threads)" is mostly marketing;
    // what identifies the chip is the model number and how many threads it has.
    readonly property string shortCpu: root.cpuInfo
        .replace(/\(R\)|\(TM\)|CPU |Processor /g, "")
        .replace(/^\d+th Gen /, "")
        .replace(/ @.*?(?= \(|$)/, "")
        .trim()
}
