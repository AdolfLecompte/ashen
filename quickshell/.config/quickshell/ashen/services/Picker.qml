pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

import "root:/services" as Services

// Choosing a picture, in the shell's own clothes. It used to be zenity: a GTK
// dialog dragged over a desktop that looks nothing like it, to find a file you
// could already see on the wallpaper behind it.
//
// Who asked is a string rather than a callback -- "profile", "widget:image:2" --
// because the panel and the thing that wanted the picture are in different
// scopes and only a signal crosses between them.
Singleton {
    id: root

    property bool visible: false
    property string purpose: ""

    // Where it is looking. Not saved: it starts where the thing that asked
    // says, and follows you from there for as long as it is open.
    property string dir: ""
    property var folders: []
    property var files: []
    property bool scanning: false

    signal picked(string purpose, string path)

    readonly property var startDirs: [
        { label: "Pictures", path: Services.Paths.home + "/Pictures" },
        { label: "Wallpapers", path: Services.Prefs.wallpaperDir !== ""
            ? Services.Prefs.wallpaperDir : Services.Paths.wallpapers },
        { label: "Downloads", path: Services.Paths.home + "/Downloads" },
        { label: "Home", path: Services.Paths.home }
    ]

    function open(purpose, startDir) {
        root.purpose = purpose
        root.go(startDir && startDir !== "" ? startDir : root.startDirs[0].path)
        root.visible = true
    }
    function close() {
        root.visible = false
        root.purpose = ""
    }
    function go(path) {
        root.dir = path
        root.scan()
    }
    function up() {
        const cut = root.dir.lastIndexOf("/")
        if (cut > 0) root.go(root.dir.slice(0, cut))
    }
    function choose(path) {
        const who = root.purpose
        root.close()
        root.picked(who, path)
    }

    // The folder's name alone, for the crumb.
    function nameOf(path) {
        const p = String(path).replace(/\/$/, "")
        const cut = p.lastIndexOf("/")
        return cut < 0 ? p : p.slice(cut + 1)
    }

    function scan() {
        root.scanning = true
        scanner.running = false
        scanner.running = true
    }

    Process {
        id: scanner
        running: false
        // One trip for both halves: folders first, then pictures, each line
        // tagged. Hidden entries are skipped -- a picture you mean to use does
        // not live in a dotfolder -- and the depth is one, because this is a
        // browser, not a search.
        command: ["sh", "-c",
            'cd "$1" 2>/dev/null || exit 0; ' +
            'find . -maxdepth 1 -mindepth 1 -type d ! -name ".*" 2>/dev/null | sed "s|^\\./|D |"; ' +
            'find . -maxdepth 1 -mindepth 1 -type f ! -name ".*" ' +
            '\\( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.webp" ' +
            '-o -iname "*.gif" -o -iname "*.bmp" \\) 2>/dev/null | sed "s|^\\./|F |"',
            "sh", root.dir]
        // The folder is stamped on at scan time, so what comes out is a list of
        // whole paths. Names alone would be joined to `dir` when they are drawn,
        // and for one frame after you walk into a folder that means last
        // folder's names on this folder's path -- every picture failing to load.
        property string scanned_: ""
        onRunningChanged: if (running) scanner.scanned_ = root.dir
        stdout: StdioCollector {
            onStreamFinished: {
                const at = scanner.scanned_
                let ds = [], fs = []
                for (const line of text.split("\n")) {
                    if (line.length < 3) continue
                    const path = at + "/" + line.slice(2)
                    if (line[0] === "D") ds.push(path)
                    else fs.push(path)
                }
                ds.sort((a, b) => a.localeCompare(b))
                fs.sort((a, b) => a.localeCompare(b))
                root.folders = ds
                root.files = fs
                root.scanning = false
            }
        }
    }
}
