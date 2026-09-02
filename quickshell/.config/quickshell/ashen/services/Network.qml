// Ashen — Network service (Wi-Fi/eth/BT state via nmcli).  by Adolf — github.com/AdolfLecompte
pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import QtQuick

Singleton {
    id: root
    property string wifiSsid: ""
    // The NetworkManager profile behind it ("SSID", "SSID 1", …), which is what
    // `connection up id` wants and is NOT what the user calls the network.
    property string wifiProfile: ""
    property int wifiSignal: 0
    property bool wifiEnabled: false
    property string ethConnection: ""
    property string ethDevice: ""
    readonly property bool online: wifiSsid !== "" || ethConnection !== ""
    // Straight off BlueZ. It used to be `bluetoothctl devices Connected` on a
    // 10 s timer, so a headset took up to ten seconds to show its name -- and
    // the same fact was already sitting in the adapter, live.
    readonly property string btDevice: {
        const a = Bluetooth.defaultAdapter
        if (!a) return ""
        const d = a.devices.values.find(x => x.connected)
        // Same name the panel and the rows use, so the chip's label and the
        // hub's match exactly -- a morph only flies on an exact match.
        return d ? BtLink.displayName(d) : ""
    }
    property bool btEnabled: Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.enabled : false

    // NetworkManager said something. Anything that mirrors nmcli state hangs
    // off this rather than off a poll of its own.
    signal changed()

    // Force an immediate re-poll instead of waiting for the 10s Timer -- callers
    // that just changed radio state (the Wi-Fi toggle) use this so the pill/panel
    // reconcile in ~1s rather than lagging up to a full poll interval behind.
    function refresh() { wifiProc.running = true; radioProc.running = true }

    Process {
        id: wifiProc
        command: ["nmcli", "-t", "-e", "no", "-f", "TYPE,STATE,DEVICE,CONNECTION", "dev", "status"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let ssid = ""
                let eth = ""
                let ethDev = ""
                for (let line of text.split("\n")) {
                    const f = line.split(":")
                    if (f.length < 4)
                        continue
                    const type = f[0]
                    const state = f[1]
                    const device = f[2]
                    const conn = f.slice(3).join(":").trim()
                    if (!state.startsWith("connected") || conn === "")
                        continue
                    if (type === "wifi")
                        ssid = conn
                    else if (type === "ethernet") {
                        eth = conn
                        ethDev = device
                    }
                }
                // `dev status` hands back the PROFILE name, "SSID 1" on a duplicate, and
                // writing it to wifiSsid made the pill flick between the two every poll.
                // Only signalProc, which reads the real SSID off the AP, writes the name.
                root.wifiProfile = ssid
                root.ethConnection = eth
                root.ethDevice = ethDev
                if (ssid !== "") {
                    if (root.wifiSsid === "")
                        root.wifiSsid = ssid.replace(/ \d+$/, "")
                    signalProc.running = true
                } else {
                    root.wifiSsid = ""
                    root.wifiSignal = 0
                }
            }
        }
    }

    Process {
        id: signalProc
        // IN-USE ("*") marks the AP we are associated with, and its SIGNAL is the
        // only reliable one: where several APs share an SSID the strongest visible
        // is not necessarily ours. Its SSID is also the real network name -- the
        // CONNECTION field is the NM profile, which gets a " 1" on duplicates.
        command: ["nmcli", "-t", "-e", "no", "-f", "IN-USE,SIGNAL,SSID", "dev", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: {
                let level = 0
                for (let line of text.split("\n")) {
                    if (line.charAt(0) !== "*")
                        continue
                    const f = line.split(":")
                    if (f.length < 3)
                        continue
                    level = parseInt(f[1]) || 0
                    const ssid = f.slice(2).join(":").trim()
                    if (ssid !== "")
                        root.wifiSsid = ssid
                    break
                }
                root.wifiSignal = level
            }
        }
    }

    // Radio power state, independent of whether we're associated to a network.
    // Lets the pill tell "on but not connected" apart from "wifi off".
    Process {
        id: radioProc
        command: ["nmcli", "-t", "radio", "wifi"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.wifiEnabled = text.trim() === "enabled"
        }
    }

    // NetworkManager PUSHES. Polling was the whole reason connecting to a
    // network took up to ten seconds to show anywhere: the state was already
    // known, nobody had asked yet.
    Process {
        id: nmMonitor
        command: ["nmcli", "monitor"]
        running: true
        // One line per event, and a single change fires several of them --
        // hence the debounce rather than a poll per line.
        stdout: SplitParser { onRead: nmDebounce.restart() }
        // nmcli monitor dies with NetworkManager. Come back, but never in a
        // tight loop: a respawn storm against a dead daemon is worse than lag.
        onExited: monitorRevive.restart()
    }
    Timer { id: monitorRevive; interval: 3000; onTriggered: nmMonitor.running = true }

    Timer {
        id: nmDebounce
        interval: 250
        onTriggered: {
            wifiProc.running = true
            radioProc.running = true
            root.changed()
        }
    }

    // Fallback only, now that events do the work: something NM does not report
    // (a driver dropping the link) still gets picked up eventually.
    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: { wifiProc.running = true; radioProc.running = true }
    }
}
