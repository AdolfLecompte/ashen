pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// The current wallpaper, resolved to something QML can actually paint.
// ashen-wallpaper.sh writes the chosen path to ashen_wallpaper.txt and always
// extracts a still to ashen_wall_frame.png (ensure_frame), so video/gif
// wallpapers -- which QML cannot draw -- fall back to that frame.
Singleton {
    id: root

    readonly property string home: Paths.home

    // Raw path as written by the wallpaper script ("" = nothing chosen yet)
    property string path: ""
    // Bumped on every change: the frame's path is fixed but its contents are
    // not, so consumers need a cache-busting token (same trick as faceVersion).
    property real version: 0

    readonly property bool isStill: /\.(png|jpe?g|webp)$/i.test(root.path)
    readonly property string stillPath: root.path === ""
        ? "" : (root.isStill ? root.path : root.home + "/.cache/ashen_wall_frame.png")
    // Ready to drop into an Image.source. Pair it with cache: false.
    readonly property string stillUrl: root.stillPath === ""
        ? "" : "file://" + root.stillPath + "?v=" + root.version

    // Two switches close together write this file twice, and the reload can
    // answer with the first write while the second never raises another
    // change -- the shell then believes in a wallpaper that is not on screen.
    // Reading once more after the dust settles costs one file read and makes
    // the last writer win.
    Timer {
        id: settle
        interval: 400
        onTriggered: { wallFile.reload(); outFile.reload() }
    }

    FileView {
        id: wallFile
        path: root.home + "/.cache/ashen_wallpaper.txt"
        watchChanges: true
        onFileChanged: { reload(); settle.restart() }
        onLoaded: {
            root.path = text().trim()
            root.version = Date.now()
        }
        onLoadFailed: root.path = ""
    }

    // What each SCREEN is wearing, one line of "<key>TAB<path>" per monitor,
    // written by the same script. The key is the monitor's description, the
    // same handle Displays.keyOf() hands out, because a port name moves
    // between reboots.
    property var perOutput: ({})

    // The screen's own wallpaper, falling back to the shared one -- which is
    // what every screen wears until somebody gives one its own.
    function forKey(key) {
        return (key !== "" && root.perOutput[key]) ? root.perOutput[key] : root.path
    }

    FileView {
        id: outFile
        path: root.home + "/.cache/ashen_wallpapers.txt"
        watchChanges: true
        onFileChanged: { reload(); settle.restart() }
        onLoaded: {
            const map = {}
            for (const line of text().split("\n")) {
                const tab = line.indexOf("\t")
                if (tab > 0) map[line.substring(0, tab)] = line.substring(tab + 1)
            }
            root.perOutput = map
        }
        onLoadFailed: root.perOutput = ({})
    }
}
