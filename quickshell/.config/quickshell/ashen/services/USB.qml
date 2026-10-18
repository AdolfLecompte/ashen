pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

import "root:/services" as Services

// What is plugged in over USB: one entry per drive, its partitions inside.
// A stick with two partitions is ONE thing you pull out, and listing each
// partition as its own device gave it two eject buttons that did the same.
Singleton {
    id: root

    // [{ name, path, title, size, parts: [{ name, path, label, fstype, size,
    //    mountpoint, used, avail }] }]
    property var drives: []
    readonly property bool anyMounted: root.drives.some(d => d.parts.some(p => p.mountpoint !== ""))

    // The partition or drive a command is running on, so its row can say so.
    property string busyPath: ""

    function refresh() { scanProc.running = true }

    // USB, not "removable": an external SSD or hard drive reports rm=0 and was
    // never listed at all. A removable card reader on another bus still is.
    function wanted(dev) {
        return dev.type === "disk" && (dev.tran === "usb" || dev.rm === true || dev.rm === "1")
    }
    function partOf(n) {
        const size = Number(n.size) || 0
        return {
            name: n.name,
            path: n.path || ("/dev/" + n.name),
            label: n.label || "",
            fstype: n.fstype || "",
            size: size,
            mountpoint: n.mountpoint || "",
            used: Number(n.fsused) || 0,
            avail: Number(n.fsavail) || 0
        }
    }

    Process {
        id: scanProc
        command: ["lsblk", "-J", "-b", "-o",
                  "NAME,PATH,SIZE,FSTYPE,LABEL,MOUNTPOINT,RM,TYPE,TRAN,MODEL,VENDOR,FSUSED,FSAVAIL"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text)
                    let list = []
                    for (const dev of (data.blockdevices || [])) {
                        if (!root.wanted(dev)) continue
                        let parts = (dev.children || [])
                            .filter(c => c.type === "part" && c.fstype && c.fstype !== "swap")
                            .map(root.partOf)
                        // A stick formatted whole, with no partition table.
                        if (parts.length === 0 && dev.fstype) parts = [root.partOf(dev)]
                        const model = [dev.vendor, dev.model].map(s => String(s || "").trim())
                            .filter(s => s !== "").join(" ")
                        // Named by what you wrote on it before what the
                        // factory did: the biggest partition's label first.
                        const named = parts.slice().sort((a, b) => b.size - a.size)
                            .find(p => p.label !== "")
                        list.push({
                            name: dev.name,
                            path: dev.path || ("/dev/" + dev.name),
                            title: named ? named.label : (model !== "" ? model : dev.name),
                            model: model,
                            size: Number(dev.size) || 0,
                            parts: parts
                        })
                    }
                    root.drives = list
                } catch (e) {
                    console.warn("[USB] parse error:", e)
                }
            }
        }
    }

    // lsblk every three seconds was a process a third of the time for a list
    // that changes when somebody plugs something in. The kernel's own lists are
    // read in-process instead, and lsblk only runs when one of them moved: a
    // new partition table, or a mount appearing or going -- which also catches
    // the automounter, not only the mounts made from the panel.
    SysFile { id: partsFile;  path: "/proc/partitions" }
    SysFile { id: mountsFile; path: "/proc/self/mounts" }
    property string seen: ""
    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: {
            const now = partsFile.read() + "\u0000" + mountsFile.read()
            if (now === root.seen) return
            root.seen = now
            root.refresh()
        }
    }
    Component.onCompleted: root.refresh()

    // ── Actions ─────────────────────────────────────────────────────────
    // One at a time, and each one waits for its answer: a mount that fails
    // because the stick is in use, or an eject refused for the same reason,
    // used to fail in silence.
    property string pending: ""     // "mount" | "unmount" | "eject"
    property string pendingName: ""
    property string pendingOpen: "" // open the folder once mounted

    function say(key, name, glyph) {
        Services.Notifications.addSystemToast(Services.I18n.t(key, { name: name }),
                                              glyph || "\ue1e0", false, "usb",
                                              { title: Services.I18n.t("usb.toast") })
    }
    function run(kind, path, name, cmd) {
        if (actProc.running) return
        root.pending = kind
        root.pendingName = name
        root.busyPath = path
        actProc.command = cmd
        actProc.running = true
    }

    function mount(part, openAfter) {
        root.pendingOpen = openAfter ? part.path : ""
        root.run("mount", part.path, part.label || part.name, ["udisksctl", "mount", "-b", part.path])
    }
    function unmount(part) {
        root.run("unmount", part.path, part.label || part.name, ["udisksctl", "unmount", "-b", part.path])
    }
    // Every mounted partition first, then the drive is powered down. Stops at
    // the first partition that will not let go, and says which.
    function eject(drive) {
        const mounted = drive.parts.filter(p => p.mountpoint !== "").map(p => p.path)
        root.run("eject", drive.path, drive.title, ["sh", "-c",
            'for p in "$@"; do udisksctl unmount -b "$p" || exit 1; done; udisksctl power-off -b "$0"',
            drive.path].concat(mounted))
    }
    function open(part) {
        if (part.mountpoint === "") { root.mount(part, true); return }
        Quickshell.execDetached(["sh", "-c",
            'S="$HOME/ashen/scripts/ashen-app"; [ -x "$S" ] || S=ashen-app; exec "$S" files "$1"',
            "sh", part.mountpoint])
    }

    Process {
        id: actProc
        stdout: StdioCollector { id: actOut }
        stderr: StdioCollector { id: actErr }
        onExited: (code) => {
            const name = root.pendingName
            const kind = root.pending
            if (code === 0) {
                if (kind === "eject") root.say("usb.ejected", name, "\ue8fb")
                // "Mounted /dev/sda1 at /run/media/you/Stick"
                const m = actOut.text.match(/ at (.+?)\.?\s*$/)
                if (kind === "mount" && root.pendingOpen !== "" && m)
                    root.open({ mountpoint: m[1].trim() })
            } else {
                const err = actErr.text
                root.say(/busy/i.test(err) ? "usb.busy" : ("usb.failed." + kind), name, "\ue1e0")
            }
            root.pending = ""
            root.pendingOpen = ""
            root.busyPath = ""
            root.refresh()
        }
    }
}
