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
    onLevelChanged: { root.maybeWarnLow(); root.sample() }
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
    property real energyNow: 0      // Wh
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
            root.energyNow = f.energy_now / 1e6
            root.energyFull = (f.energy_full || 0) / 1e6
            root.energyDesign = (f.energy_full_design || 0) / 1e6
            root.watts = Math.abs((f.power_now || 0) / 1e6)
            root.hasRate = f.power_now !== undefined
        } else if (f.charge_now !== undefined) {
            root.energyNow = f.charge_now / 1e6 * volt
            root.energyFull = (f.charge_full || 0) / 1e6 * volt
            root.energyDesign = (f.charge_full_design || 0) / 1e6 * volt
            root.watts = Math.abs((f.current_now || 0) / 1e6 * volt)
            root.hasRate = f.current_now !== undefined
        }
        if (root.energyDesign > 0)
            root.health = Math.round(root.energyFull / root.energyDesign * 100)
        if (f.cycle_count !== undefined) root.cycles = Math.round(f.cycle_count)
    }

    // ── The last day of charge ───────────────────────────────────────────
    // UPower already keeps this, one line per whole percent, going back days.
    // Reading its file gives a curve the moment the panel opens instead of one
    // that only exists after the shell has been up long enough to draw it.
    // The file belongs to root; on this machine the battery's is world
    // readable, but some devices' are 0640 -- so anything unreadable simply
    // leaves `series` empty and `sample()` fills it as the shell runs.
    property var series: []         // [{t: unix seconds, v: percent}], oldest first
    readonly property int seriesHours: 24

    function trimSeries(list) {
        const cut = Date.now() / 1000 - root.seriesHours * 3600
        return list.filter(p => p.t >= cut)
    }

    // Our own reading, folded in on top of whatever history was on disk. One
    // point per whole percent, the same resolution the file has.
    function sample() {
        const now = Math.round(Date.now() / 1000)
        const last = root.series.length > 0 ? root.series[root.series.length - 1] : null
        if (last && last.v === root.level && now - last.t < 300) return
        root.series = root.trimSeries(root.series.concat([{ t: now, v: root.level }]))
    }
    // Evenly spaced buckets across the window, because the samples are not:
    // upower writes when the percent changes, so an hour asleep is one point
    // and a fast drain is thirty. Drawing them evenly would stretch the quiet
    // hours and squash the busy ones. Each bucket holds the last reading at or
    // before it, so a flat stretch stays flat.
    function plot(n) {
        if (root.series.length === 0) return []
        const end = Date.now() / 1000
        const start = end - root.seriesHours * 3600
        const out = []
        let i = 0
        let held = root.series[0].v
        for (let k = 0; k < n; k++) {
            const t = start + (end - start) * (k / (n - 1))
            while (i < root.series.length && root.series[i].t <= t) {
                held = root.series[i].v
                i++
            }
            out.push(held)
        }
        return out
    }

    Process {
        id: historyProc
        command: ["sh", "-c",
            "cat /var/lib/upower/history-charge-*.dat 2>/dev/null | sort -n | tail -400"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const out = []
                for (const line of text.trim().split("\n")) {
                    const p = line.split(/\s+/)
                    if (p.length < 2) continue
                    const t = parseInt(p[0])
                    // The comma is not a typo: upower writes the number in the
                    // machine's locale, so some of these lines say "0,000".
                    const v = parseFloat(String(p[1]).replace(",", "."))
                    // `unknown` rows are written as 0 on suspend and resume;
                    // taken at face value they draw a cliff to the floor and
                    // back that never happened.
                    if (isNaN(t) || isNaN(v) || v <= 0) continue
                    out.push({ t: t, v: v })
                }
                root.series = root.trimSeries(out.concat(root.series))
            }
        }
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
