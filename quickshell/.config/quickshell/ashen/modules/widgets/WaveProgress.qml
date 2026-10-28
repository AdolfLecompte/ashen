import QtQuick
import QtQuick.Shapes

import "root:/services" as Services

// Material You's wavy progress: what has played is a wave that travels while
// it plays and flattens when paused; what is to come is a straight dim track;
// a vertical pill marks where you are. The wave is drawn once and slid
// sideways to move, so playing costs no repaint.
Item {
    id: root

    property real progress: 0
    property bool playing: false
    property color color: Services.Colors.ghost
    property color trackColor: Services.Colors.fillLine
    property real wavelength: 40
    property real amplitude: 3
    property real stroke: 4

    readonly property real headX: root.width * Math.max(0, Math.min(1, root.progress))
    readonly property real gap: 6

    // 1 playing, 0 paused: the wave settles flat rather than stopping mid-crest.
    property real amp: root.playing ? 1 : 0
    Behavior on amp { NumberAnimation { duration: 450; easing.type: Services.Sizes.easeInOut } }

    // What is still to come.
    Rectangle {
        x: Math.min(root.width, root.headX + root.gap)
        width: Math.max(0, root.width - x)
        height: root.stroke
        radius: root.stroke / 2
        anchors.verticalCenter: parent.verticalCenter
        color: root.trackColor
    }

    // What has played: a window onto a longer wave that slides one wavelength
    // and starts over, which reads as one endless travelling wave.
    Item {
        width: Math.max(0, root.headX - root.gap)
        height: root.height
        clip: true

        Shape {
            id: wave
            width: root.width + root.wavelength * 2
            height: root.height
            preferredRendererType: Shape.CurveRenderer
            property real shift: 0
            x: -wave.shift

            ShapePath {
                strokeColor: root.color
                strokeWidth: root.stroke
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                joinStyle: ShapePath.RoundJoin
                // Half a wavelength per quadratic; its control at twice the
                // amplitude puts the crest at the amplitude itself.
                PathSvg {
                    path: {
                        const mid = root.height / 2
                        const half = root.wavelength / 2
                        const a = 2 * root.amplitude * root.amp
                        let d = "M 0 " + mid
                        for (let x = 0, up = true; x < wave.width; x += half, up = !up)
                            d += " Q " + (x + half / 2) + " " + (mid + (up ? -a : a)) + " " + (x + half) + " " + mid
                        return d
                    }
                }
            }

            NumberAnimation on shift {
                running: root.playing && root.visible && root.headX > root.gap
                from: 0; to: root.wavelength
                duration: 1400
                loops: Animation.Infinite
            }
        }
    }

    // Where you are.
    Rectangle {
        x: root.headX - width / 2
        width: root.stroke
        height: root.stroke * 4
        radius: width / 2
        anchors.verticalCenter: parent.verticalCenter
        color: root.color
        visible: root.progress > 0
    }
}
