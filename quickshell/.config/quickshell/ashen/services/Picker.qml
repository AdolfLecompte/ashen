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
    // The folder the lists above belong to. `dir` moves the moment you click;
    // this only moves when the new listing has landed -- which is what the
    // grid slides on, so it changes once instead of once per half.
    property string listed: ""
    // path -> a small cached copy, as a URL. A 4K PNG cannot be decoded at a
    // smaller size the way a JPEG can, so a folder of wallpapers took seconds
    // to fill in every time it was opened. Filled as the copies are found or
    // made; a picture with no entry yet is drawn from the original.
    property var thumbs: ({})

    signal picked(string purpose, string path)

    readonly property var startDirs: [
        { label: "Pictures", path: Services.Paths.home + "/Pictures" },
        { label: "Wallpapers", path: Services.Prefs.wallpaperDir !== ""
            ? Services.Prefs.wallpaperDir : Services.Paths.wallpapers },
        { label: "Downloads", path: Services.Paths.home + "/Downloads" },
        { label: "Home", path: Services.Paths.home }
    ]

    // Which way the last move went, so the grid sweeps the way you walked:
    // into a folder is forwards, the way back up is backwards. Same idea as
    // AppState.mediaDir -- a path has no order of its own, so whoever caused
    // the change is the only one who can say which way it goes.
    property int step: 1

    function open(purpose, startDir) {
        root.purpose = purpose
        // A fresh start: the last listing belongs to wherever the picker was
        // left, and showing it for the moment the new folder takes to read
        // would be a grid of the wrong pictures sliding away.
        root.listed = ""
        root.folders = []
        root.files = []
        root.go(startDir && startDir !== "" ? startDir : root.startDirs[0].path)
        root.visible = true
    }
    function close() {
        root.visible = false
        root.purpose = ""
    }
    function go(path) { root.walk(path, 1) }
    function up() {
        const cut = root.dir.lastIndexOf("/")
        if (cut > 0) root.walk(root.dir.slice(0, cut), -1)
    }
    // The direction is set BEFORE the path: what watches `dir` starts its sweep
    // on the change, and would read last move's direction if it came after.
    function walk(path, dir) {
        root.step = dir
        root.dir = path
        root.scan()
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

    readonly property string thumbDir: Services.Paths.home + "/.cache/ashen_pick_thumbs"
    property var pendingThumbs: ({})
    function makeThumbs(list) {
        thumber.running = false
        if (list.length === 0) return
        thumber.command = ["sh", "-c",
            'd="$1"; shift; mkdir -p "$d"; ' +
            // Pass 1: what is already cached, straight away.
            'for f in "$@"; do k="$d/$(printf %s "$f" | cksum | cut -d" " -f1).jpg"; ' +
            '[ -f "$k" ] && [ ! "$f" -nt "$k" ] && printf "%s\\t%s\\n" "$f" "$k"; done; ' +
            // Pass 2: the rest, one per core. jpeg:size lets a JPEG decode at a
            // fraction of its size; [0] is the first frame of a gif.
            'printf "%s\\0" "$@" | xargs -0 -P "$(nproc)" -I{} sh -c ' +
            '\'f="$1"; d="$2"; k="$d/$(printf %s "$f" | cksum | cut -d" " -f1).jpg"; ' +
            '[ -f "$k" ] && [ ! "$f" -nt "$k" ] && exit 0; ' +
            'magick -define jpeg:size=800x560 "$f[0]" -thumbnail "400x280^" -gravity center -extent 400x280 -quality 80 "$k" 2>/dev/null ' +
            '&& printf "%s\\t%s\\n" "$f" "$k"\' _ {} "$d"',
            "sh", root.thumbDir].concat(list)
        thumber.running = true
    }
    Process {
        id: thumber
        running: false
        stdout: SplitParser {
            onRead: data => {
                const tab = data.indexOf("\t")
                if (tab < 0) return
                root.pendingThumbs[data.slice(0, tab)] = "file://" + data.slice(tab + 1)
                flushThumbs.start()
            }
        }
    }
    // Handed over in batches: every assignment re-evaluates every tile that
    // reads the map, and one per picture was a few hundred re-layouts a second.
    Timer {
        id: flushThumbs
        interval: 120
        onTriggered: {
            root.thumbs = Object.assign({}, root.thumbs, root.pendingThumbs)
            root.pendingThumbs = ({})
        }
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
                root.listed = at
                root.scanning = false
                root.makeThumbs(fs)
            }
        }
    }
}
