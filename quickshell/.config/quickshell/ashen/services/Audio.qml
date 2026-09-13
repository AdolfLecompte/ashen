// Ashen — Audio service, straight off the PipeWire graph.  by Adolf — github.com/AdolfLecompte
pragma Singleton
import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

// This used to be four `pactl`/`wpctl` processes a second, forever, plus five
// more every three seconds -- the heaviest thing the shell did, and still a
// second behind whatever you had just pressed. Quickshell speaks to PipeWire
// directly: the numbers below are the graph's own, and they change when it
// does. Only the two things the node graph cannot express -- WHICH device is
// the default, and moving streams onto it -- still shell out.
Singleton {
    id: root

    // Nothing on a node is populated until something tracks it. Twelve nodes on
    // a laptop, so tracking the lot is cheaper than working out a subset.
    PwObjectTracker { objects: Pipewire.nodes.values }

    readonly property var sinkNode: Pipewire.defaultAudioSink
    readonly property var sourceNode: Pipewire.defaultAudioSource

    // ── Output ─────────────────────────────────────────────────────────────
    readonly property int volume: root.sinkNode && root.sinkNode.audio
        ? Math.round(root.sinkNode.audio.volume * 100) : 0
    readonly property bool muted: root.sinkNode && root.sinkNode.audio
        ? root.sinkNode.audio.muted : false
    readonly property string defaultSink: root.sinkNode ? root.sinkNode.name : ""
    readonly property bool headphones: /headphone|headset|bluez/i.test(root.defaultSink)

    function toggleMute() {
        if (root.sinkNode && root.sinkNode.audio)
            root.sinkNode.audio.muted = !root.sinkNode.audio.muted
    }
    // Capped at 100%: the old `wpctl set-volume -l 1.0` did the same, and a
    // slider that can push past unity is a speaker-shaped trap.
    function setVolume(pct) {
        if (!root.sinkNode || !root.sinkNode.audio) return
        root.sinkNode.audio.muted = false
        root.sinkNode.audio.volume = Math.max(0, Math.min(100, pct)) / 100
    }

    // shared by the pill, the OSD and the volume panel
    function icon(vol, isMuted, isHeadphones) {
        if (isMuted || vol === 0)
            return ""
        if (isHeadphones)
            return ""
        return vol < 66 ? "" : ""
    }

    // ── Input ──────────────────────────────────────────────────────────────
    readonly property int micVolume: root.sourceNode && root.sourceNode.audio
        ? Math.round(root.sourceNode.audio.volume * 100) : 0
    readonly property bool micMuted: root.sourceNode && root.sourceNode.audio
        ? root.sourceNode.audio.muted : false
    readonly property string defaultSource: root.sourceNode ? root.sourceNode.name : ""

    function toggleMicMute() {
        if (root.sourceNode && root.sourceNode.audio)
            root.sourceNode.audio.muted = !root.sourceNode.audio.muted
    }
    function setMicVolume(pct) {
        if (!root.sourceNode || !root.sourceNode.audio) return
        root.sourceNode.audio.volume = Math.max(0, Math.min(100, pct)) / 100
    }

    // ── The devices you can pick between ───────────────────────────────────
    // A stream is an application; a device is not. Monitors never show up here
    // the way they did through `pactl list sources`: in the graph a monitor is
    // a PORT of its sink, not a source of its own, so there is nothing to
    // filter out any more.
    readonly property var sinks: Pipewire.nodes.values
        .filter(n => n.isSink && !n.isStream && n.audio)
        .map(n => ({ name: n.name, desc: root.shortName(n.description) }))
    readonly property var sources: Pipewire.nodes.values
        .filter(n => !n.isSink && !n.isStream && n.audio)
        .map(n => ({ name: n.name, desc: root.shortName(n.description) }))

    // Strip the long controller prefix so the picker shows just the port name.
    function shortName(desc) {
        return (desc || "").replace(/^.*High Definition Audio Controller /, "")
                           .replace(/^Monitor of /, "Monitor: ")
    }

    // Which device is the default is WirePlumber policy, not a property of the
    // graph, so these two stay on pactl. Moving the already-running streams is
    // what makes the switch immediate instead of only affecting apps opened
    // afterwards.
    function setSink(name) {
        Quickshell.execDetached(["sh", "-c",
            "pactl set-default-sink '" + name + "'; " +
            "for i in $(pactl list short sink-inputs | cut -f1); do pactl move-sink-input $i '" + name + "'; done"])
    }
    function setSource(name) {
        Quickshell.execDetached(["sh", "-c",
            "pactl set-default-source '" + name + "'; " +
            "for i in $(pactl list short source-outputs | cut -f1); do pactl move-source-output $i '" + name + "'; done"])
    }

    function descOf(list, name) {
        for (const d of list) if (d.name === name) return root.shortName(d.desc)
        return ""
    }
    // The one in use right now, either side.
    readonly property string activeSinkName: root.descOf(root.sinks, root.defaultSink)
    readonly property string activeSourceName: root.descOf(root.sources, root.defaultSource)

    // ── Per-app streams ────────────────────────────────────────────────────
    // A playback stream is a stream that is ALSO a sink: audio goes into it on
    // its way out. `isStream && !isSink` is a recorder (cava listening to the
    // monitor), which does not belong in a list of things making noise.
    // The nodes themselves, NOT copies of their numbers: a plain object rebuilt
    // on every volume change hands the Repeater a new model, which throws away
    // the delegate -- and with it the slider you were still dragging.
    readonly property var streams: Pipewire.nodes.values
        .filter(n => n.isStream && n.isSink && n.audio)

    function streamLabel(n) {
        if (!n) return "Audio"
        return n.properties["application.name"] || n.properties["media.name"] || "Audio"
    }

    // Take the node, not an id: the caller already holds it.
    function setStreamVolume(n, pct) {
        if (n && n.audio) n.audio.volume = Math.max(0, Math.min(100, pct)) / 100
    }
    function toggleStreamMute(n) {
        if (n && n.audio) n.audio.muted = !n.audio.muted
    }
}
