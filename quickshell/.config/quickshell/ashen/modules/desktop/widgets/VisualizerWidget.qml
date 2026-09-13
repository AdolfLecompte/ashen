import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import QtQuick

import "root:/modules/desktop"
import "root:/modules/widgets" as Widgets
import "root:/services" as Services

// The sound as a circle: the cover in the middle, a ring of bars growing out of
// it. The shape music videos have worn since NCS put it on every release in
// 2013 -- a pulsating circle spectrum with the art in the centre.
//
// Rectangles in a Repeater rather than a Canvas: sixty bars redrawn on a canvas
// at sixty frames a second is the cost that got liquid thrown off the bar
// (29.5% against 12.68%). These are scene-graph nodes moving a height.
DesktopWidget {
    id: root
    wid: "visualizer"

    // The picture IS the widget here; a rim of plate around it reads as a mount.

    readonly property var livePlayer: {
        const live = Mpris.players.values.filter(p => p.playbackState !== MprisPlaybackState.Stopped)
        if (live.length === 0) return null
        const playing = live.find(p => p.isPlaying)
        return playing !== undefined ? playing : live[0]
    }
    readonly property string art: root.livePlayer ? (root.livePlayer.trackArtUrl || "") : ""

    // How big the circle is. Its own axis: the shape is the ring, the size is
    // how much wall you are giving it.
    readonly property real dia: root.skin === "small" ? 240
                              : root.skin === "large" ? 440 : 320

    // What the bars are standing on, and how far out they may reach.
    readonly property real ringR: root.dia * 0.29
    readonly property real reach: root.dia / 2 - root.ringR - 6

    // Cava hands back however many bars its config asks for; the ring wants an
    // even number it can mirror, so the readings are folded in half and drawn
    // out both ways -- a circle that is not symmetrical reads as a mistake.
    readonly property int spokes: 72
    // Thick enough to read as bars rather than hairs, and derived from the ring
    // instead of typed: the same number on the small circle would close the
    // gaps and on the large one would look like wire.
    readonly property real barW: Math.max(4, 2 * Math.PI * root.ringR / root.spokes * 0.72)
    property var levels: []

    Connections {
        target: Services.Cava
        enabled: root.live
        function onBarValuesChanged() {
            const src = Services.Cava.barValues
            if (!src || src.length === 0) { root.levels = []; return }
            const half = Math.floor(root.spokes / 2)
            const per = src.length / half
            let folded = []
            for (let i = 0; i < half; i++) {
                // The loudest reading the slot covers, never the average:
                // averaging flattens the peaks the eye is watching for. Same
                // call Spectrum makes.
                let v = 0
                const from = Math.floor(i * per)
                const to = Math.max(from + 1, Math.floor((i + 1) * per))
                for (let k = from; k < to; k++) v = Math.max(v, src[k] || 0)
                folded.push(Math.max(0, Math.min(1, v / 100)))
            }
            // Up one side and back down the other, so the two halves meet.
            root.levels = folded.concat(folded.slice().reverse())
        }
    }

    // The bass end drives the pulse: it is the part of the sound a body feels.
    readonly property real punch: {
        const l = root.levels
        if (!l || l.length < 4) return 0
        return Math.max(0, Math.min(1, (l[0] + l[1] + l[2] + l[3]) / 4))
    }

    component Ring: Item {
        id: ring
        implicitWidth: root.dia
        implicitHeight: root.dia

        opacity: Services.Cava.isActive ? 1 : 0.55
        Behavior on opacity { Widgets.Anim { speed: Services.Sizes.msPanel } }

        // The line the bars stand on. Quiet on purpose -- it is the ground,
        // not a reading.
        Rectangle {
            anchors.centerIn: parent
            width: root.ringR * 2 + 10
            height: width
            radius: width / 2
            color: "transparent"
            border.width: 1
            border.color: Services.Colors.ghostAlpha(0.35)
        }

        Repeater {
            model: root.spokes

            Item {
                id: spoke
                required property int index
                readonly property real level: root.levels.length > spoke.index
                    ? root.levels[spoke.index] : 0
                // Starts at twelve o'clock and goes round.
                x: ring.width / 2
                y: ring.height / 2
                width: 0
                height: 0
                rotation: spoke.index * 360 / root.spokes

                Rectangle {
                    width: root.barW
                    radius: width / 2
                    // Never nothing: a ring with silent spokes missing looks
                    // broken rather than quiet.
                    height: root.barW + spoke.level * root.reach
                    x: -width / 2
                    y: -(root.ringR + 5 + height)
                    color: Services.Colors.ghost
                    gradient: Services.Prefs.useGradients ? Services.Colors.accentGradient : null
                }
            }
        }

        // The cover, breathing with the bass.
        ClippingRectangle {
            id: coverBox
            anchors.centerIn: parent
            width: root.ringR * 2 - 6
            height: width
            radius: width / 2
            color: Services.Colors.fillInset
            scale: 1 + 0.05 * root.punch
            Behavior on scale { NumberAnimation { duration: 90; easing.type: Services.Sizes.easeOut } }

            Image {
                anchors.fill: parent
                source: root.art
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
                visible: status === Image.Ready
            }
            Text {
                textFormat: Text.PlainText
                anchors.centerIn: parent
                visible: root.art === ""
                text: "\ue019"
                color: Services.Colors.ghost
                font.pixelSize: coverBox.width * 0.34
                font.family: "Material Symbols Rounded"
            }
        }
    }

    // The flat one: the same wall of mirrored bars the media widget wears, at
    // whatever width the size axis asks for.
    component Band: Item {
        implicitWidth: root.dia * 1.6
        implicitHeight: root.dia * 0.5

        Spectrum {
            anchors.fill: parent
            live: root.live
            color_: Services.Colors.ghost
        }
    }

    Component { id: ringShape; Ring {} }
    Component { id: bandShape; Band {} }

    Loader {
        sourceComponent: root.style === "bars" ? bandShape : ringShape
    }
}
