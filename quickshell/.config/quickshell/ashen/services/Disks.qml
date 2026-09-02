pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// How full the real filesystems are. SysMon already watches the root disk for
// its own gauge; this is the whole set, including whatever is plugged in.
Singleton {
    id: root

    // { path, used, size, percent, label } per mount, root first.
    property var mounts: []

    property int watchers: 0
    function watch(on) {
        root.watchers = Math.max(0, root.watchers + (on ? 1 : -1))
        if (root.watchers > 0) root.sample()
    }

    function sample() { if (!proc.running) proc.running = true }

    // A disk moves by a gigabyte a week. Once a minute is already generous.
    Timer {
        running: root.watchers > 0
        interval: 60000
        repeat: true
        onTriggered: root.sample()
    }

    function human(bytes) {
        const units = ["B", "K", "M", "G", "T"]
        let v = bytes
        let i = 0
        while (v >= 1024 && i < units.length - 1) { v /= 1024; i++ }
        // One decimal only while it buys something: 1.4T says more than 1T,
        // 431G says everything 431.0G does.
        return (v >= 100 || i <= 1 ? Math.round(v) : (Math.round(v * 10) / 10)) + units[i]
    }

    Process {
        id: proc
        running: false
        // Real filesystems only: the pseudo ones are memory wearing a mount
        // point, and a bar for them says nothing about space.
        command: ["sh", "-c",
            "df -B1 --output=source,target,used,size -x tmpfs -x devtmpfs -x squashfs -x efivarfs -x overlay 2>/dev/null | tail -n +2"]
        stdout: StdioCollector {
            onStreamFinished: {
                let out = []
                // One entry per DEVICE, not per mount point: a btrfs layout
                // mounts half a dozen subvolumes off the same disk, and drawing
                // six identical bars says the machine has six disks.
                let seen = ({})
                for (const line of text.split("\n")) {
                    const p = line.trim().split(/\s+/)
                    if (p.length < 4) continue
                    const source = p[0]
                    const target = p[1]
                    const used = Number(p[2])
                    const size = Number(p[3])
                    if (!(size > 0)) continue
                    // The boot partition is a few hundred megabytes nobody
                    // manages by eye.
                    if (size < 2 * 1024 * 1024 * 1024 && target !== "/") continue
                    const known = seen[source]
                    // Root wins its device outright; otherwise the shallowest
                    // mount point is the one worth naming.
                    if (known !== undefined) {
                        const cur = out[known]
                        if (cur.path === "/") continue
                        if (target !== "/" && target.length >= cur.path.length) continue
                    }
                    const entry = {
                        path: target,
                        label: target === "/" ? "root" : target.split("/").pop(),
                        used: used,
                        size: size,
                        percent: Math.round(used / size * 100)
                    }
                    if (known !== undefined) out[known] = entry
                    else { seen[source] = out.length; out.push(entry) }
                }
                root.mounts = out
            }
        }
    }
}
