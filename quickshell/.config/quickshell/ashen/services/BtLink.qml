// Ashen — Bluetooth link service: asking a device for a connection.  by Adolf — github.com/AdolfLecompte
pragma Singleton
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import QtQuick

// Everything that presses a device -- the ring on the panel, the rows in
// Settings -- comes through here. Three things kept plain `pair()`/`connect()`
// from working with half the hardware in the house:
//   1. NOBODY WAS ANSWERING THE PAIRING REQUEST. BlueZ hands the passkey
//      confirmation to whichever process registered the default agent, and
//      Quickshell's Bluetooth module never registers one -- its binary knows
//      only Adapter1/Device1/Battery1, no Agent1. bluetoothd said so plainly:
//        src/device.c:new_auth() No agent available for request type 2
//        device_confirm_passkey: Operation not permitted
//      so a mouse "paired" and dropped a second later, every time. Verified
//      2026-08-14 with an Attack Shark X11mouse2: same device, agent up,
//      "Pairing successful" first try.
//   2. the adapter was still sweeping. BlueZ turns a connect down while it is
//      discovering ("br-connection-busy") or takes forever over it: a scan and
//      a link are fighting for one radio.
//   3. pairing is not connecting. Plenty of devices bond and then just sit
//      there waiting for somebody to make the second call.
Singleton {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter

    // The device we are chasing, "" when idle. The rings read it so a link
    // that takes eight seconds does not look like a dead button.
    property string pendingAddr: ""

    function deviceAt(addr) {
        if (!root.adapter || addr === "")
            return null
        return root.adapter.devices.values.find(d => d.address === addr) || null
    }

    // What to call a device. BlueZ names one it has no name for after its own
    // address -- the alias comes back as "46-0A-8D-F3-7B-F1", which reads like
    // a broken label rather than "this thing never said what it is". Most of
    // those are somebody else's passing BLE beacon. An alias the user set by
    // hand is still honoured: only the address-shaped one is replaced.
    function displayName(d) {
        if (!d) return ""
        const addr = String(d.address || "")
        const dashed = addr.replace(/:/g, "-")
        const n = String(d.name || "")
        if (n !== "" && n !== dashed && n !== addr) return n
        const tail = addr.split(":").slice(-2).join(":")
        return tail !== "" ? "Unknown · " + tail : "Unknown device"
    }

    // What a device is in the middle of, if anything.
    function busyText(d) {
        if (!d) return ""
        if (d.pairing) return "Pairing…"
        if (d.state === BluetoothDeviceState.Connecting) return "Connecting…"
        if (d.address === root.pendingAddr && !d.connected) return "Connecting…"
        return ""
    }

    function stopScan() {
        if (root.adapter && root.adapter.discovering)
            root.adapter.discovering = false
    }

    function request(d) {
        if (!d) return
        root.stopScan()
        root.pendingAddr = d.address
        if (d.paired || d.bonded) {
            // Trust is what lets it come back on its own next time.
            d.trusted = true
            d.connect()
        } else {
            // Somebody has to be able to answer BlueZ before asking.
            agentProc.running = true
            // NOT trusted up front: a pair that then failed used to leave the
            // device trusted-but-unpaired, which belongs to neither ring -- it
            // simply vanished off the card.
            d.pair()
        }
        chase.restart()
    }

    function cancel() {
        root.pendingAddr = ""
        chase.stop()
        agentProc.running = false
    }

    // The agent, up only while a pairing the user asked for is in flight.
    // NoInputNoOutput accepts without a prompt, which is the only thing a bar
    // with no passkey dialog can honestly offer -- so it must NOT sit there
    // registered all session, or anything in range could bond unanswered.
    // `bluetoothctl` holds an agent for exactly as long as it lives, hence the
    // sleep keeping its stdin open; `default-agent` is what makes BlueZ route
    // a request from another client (us) to it. The 45 s cap is the backstop
    // for the case where killing the shell leaves the pipeline orphaned.
    Process {
        id: agentProc
        command: ["sh", "-c",
            "{ printf 'agent NoInputNoOutput\\ndefault-agent\\n'; sleep 45; } | bluetoothctl >/dev/null 2>&1"]
    }

    Timer {
        id: chase
        interval: 700
        repeat: true
        property int ticks: 0
        property int lastTry: 0
        onRunningChanged: if (running) { ticks = 0; lastTry = 0 }
        onTriggered: {
            const d = root.deviceAt(root.pendingAddr)
            if (!d || d.connected) { root.cancel(); return }
            ticks++
            // ~21 s and then let go. A pairing that wants a PIN is waiting on a
            // human, and retrying underneath that only confuses BlueZ.
            if (ticks >= 30) { root.cancel(); return }
            // Something is already in flight: leave it be.
            if (d.pairing || d.state === BluetoothDeviceState.Connecting) return
            if (!(d.paired || d.bonded)) return
            // Bonded and idle -- this is the call the device was waiting for.
            // Spaced out, or a retry every 700 ms just cancels the last one.
            if (ticks - lastTry < 6) return
            lastTry = ticks
            d.trusted = true
            d.connect()
        }
    }
}
