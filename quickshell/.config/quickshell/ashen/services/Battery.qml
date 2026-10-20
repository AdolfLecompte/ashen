pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import "root:/services" as Services

Singleton {
    id: root
    property int level: 0
    property bool charging: false

    // The face the shell wears for a given charge. One ladder here rather than
    // a chain of ternaries at every site: the bar, the lock screen and anything
    // else showing a battery must not disagree about what 40 % looks like.
    // Charging has a ladder of its own -- a bolt that never moves says the
    // machine is plugged in but not how far along it is.
    function icon(lvl, isCharging) {
        if (isCharging)
            return lvl >= 95 ? "\ue1a3"   // battery_charging_full
                 : lvl >= 85 ? "\uf0a7"   // battery_charging_90
                 : lvl >= 70 ? "\uf0a6"   // battery_charging_80
                 : lvl >= 55 ? "\uf0a5"   // battery_charging_60
                 : lvl >= 40 ? "\uf0a4"   // battery_charging_50
                 : lvl >= 25 ? "\uf0a3"   // battery_charging_30
                             : "\uf0a2"   // battery_charging_20
        return lvl >= 90 ? "\ue1a5"       // battery_full
             : lvl >= 70 ? "\uf0a1"       // battery_6_bar
             : lvl >= 50 ? "\uf09f"       // battery_4_bar
             : lvl >= 30 ? "\uf09d"       // battery_2_bar
             : lvl >= 15 ? "\uf09c"       // battery_1_bar
                         : "\ue19c"       // battery_alert
    }

    // Low-battery warning. Fires once when crossing the threshold on battery;
    // re-arms when charging or once the level climbs back up, so it never spams.
    // Routed through addSystemToast so it wears the system look (icon box + two
    // lines) and its own battery_alert glyph, not a third-party app style.
    // "1.4 hours" as upower words it, or "--". Read on demand: it is a slow
    // number and nothing needs it until a surface shows it.
    property string timeRemaining: "--"
    // The same time, short enough to sit beside the percentage: upower says
    // "35.0 minutes" and "2.1 hours", which is a sentence where a number goes.
    readonly property string timeShort: {
        const m = root.timeRemaining.match(/^([\d.]+)\s*(\w+)/)
        if (!m) return ""
        const n = parseFloat(m[1])
        if (isNaN(n)) return ""
        const mins = /^h/i.test(m[2]) ? Math.round(n * 60) : /^s/i.test(m[2]) ? 1 : Math.round(n)
        if (mins < 60) return mins + " min"
        const h = Math.floor(mins / 60), r = mins % 60
        return h + "h " + (r < 10 ? "0" : "") + r
    }
    function refreshTime() { timeProc.running = true }
    Process {
        id: timeProc
        command: ["sh", "-c", "upower -i $(upower -e | grep BAT) 2>/dev/null | grep -E 'time to (empty|full)'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const line = text.trim()
                const parts = line.split(":")
                root.timeRemaining = (line.length > 0 && parts.length > 1)
                    ? parts.slice(1).join(":").trim() : "--"
            }
        }
    }

    property bool lowWarned: false
    readonly property int lowThreshold: 15
    onLevelChanged: root.maybeWarnLow()
    onChargingChanged: { if (root.charging) root.lowWarned = false; root.maybeWarnLow() }
    function maybeWarnLow() {
        if (root.charging || root.level <= 0) return
        if (root.level > root.lowThreshold) { root.lowWarned = false; return }
        if (root.lowWarned) return
        root.lowWarned = true
        Services.Notifications.addSystemToast(
            "Battery low - " + root.level + "% left", "", false, "battery")
    }

    // ── What the battery IS, not just how full it is ─────────────────────
    // sysfs has the lot and costs one read; upower would be a process per
    // field. `capacity` here is HEALTH -- what the pack still holds against
    // what it shipped with -- which is the one number that says whether a
    // laptop is dying or merely empty.
    property int health: 0          // % of design capacity still there
    property int cycles: 0          // charge cycles the pack has done
    property real watts: 0          // in or out right now, always positive
    // Whether the kernel reports a rate at all. Zero watts on a full battery is
    // a reading; zero watts because the file is missing is not, and the panel
    // has to be able to tell them apart.
    property bool hasRate: false
    property real energyFull: 0     // Wh
    property real energyDesign: 0   // Wh

    // One reader walked across the files: ten reads, no shell. Missing files
    // come back empty and the parser below simply leaves that field alone.
    // One reader per file. A single reader walked across them by changing its
    // path handed back ANOTHER file's contents -- the panel showed the voltage
    // as the cycle count and a worn pack at 100% health.
    readonly property var factNames: ["energy_now", "energy_full", "energy_full_design",
        "power_now", "cycle_count", "charge_now", "charge_full", "charge_full_design",
        "current_now", "voltage_now"]
    Instantiator {
        id: factFiles
        model: root.factNames
        delegate: SysFile { required property string modelData; path: "/sys/class/power_supply/BAT0/" + modelData }
    }

    function readFacts() {
        const f = {}
        for (let i = 0; i < factFiles.count; i++) {
            const v = factFiles.objectAt(i).read()
            if (v !== "") f[root.factNames[i]] = parseFloat(v)
        }
        // Two families of kernel driver: some report energy (µWh, µW),
        // some charge (µAh, µA) and leave the watts to be worked out
        // from the voltage. Both end up as Wh and W here.
        const volt = (f.voltage_now || 0) / 1e6
        if (f.energy_now !== undefined) {
            root.energyFull = (f.energy_full || 0) / 1e6
            root.energyDesign = (f.energy_full_design || 0) / 1e6
            root.watts = Math.abs((f.power_now || 0) / 1e6)
            root.hasRate = f.power_now !== undefined
        } else if (f.charge_now !== undefined) {
            root.energyFull = (f.charge_full || 0) / 1e6 * volt
            root.energyDesign = (f.charge_full_design || 0) / 1e6 * volt
            root.watts = Math.abs((f.current_now || 0) / 1e6 * volt)
            root.hasRate = f.current_now !== undefined
        }
        if (root.energyDesign > 0)
            root.health = Math.round(root.energyFull / root.energyDesign * 100)
        if (f.cycle_count !== undefined) root.cycles = Math.round(f.cycle_count)
    }

    SysFile { id: capFile;    path: "/sys/class/power_supply/BAT0/capacity" }
    SysFile { id: statusFile; path: "/sys/class/power_supply/BAT0/status" }

    function poll() {
        root.level = parseInt(capFile.read()) || 0
        const status = statusFile.read()
        root.charging = status === "Charging" || status === "Full" || status === "Not charging"
        root.readFacts()
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.poll()
    }
}
