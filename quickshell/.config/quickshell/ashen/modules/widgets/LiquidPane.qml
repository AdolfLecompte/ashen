import QtQuick
import "root:/services" as Services

// The liquid box, grown until it holds the whole reading: the water still
// rises bottom-up, and everything the caller puts inside -- lettering, a
// slider, a glyph -- is re-inked where the water has got to it. Nothing here
// is draggable: the controls inside keep their own behaviour and get wet.
Item {
    id: pane

    // 0..1, how full it is.
    property real value: 0
    property int easeMs: 220

    property color fillColor: Services.Colors.ghost
    property bool dimmed: false
    // Held empty until the card is really on screen, then run up to `value` --
    // the whole climb from nothing is the point of opening the panel. Callers
    // with nothing to wait for leave it armed and never set `sweepMs`.
    property bool armed: true
    property int sweepMs: 0
    // Something is going in or out right now: the surface moves more, and the
    // vessel breathes -- the same 900/900 pulse the dial's halo had.
    property bool lively: false
    property bool glow: false
    property int radius_: Services.Sizes.cardLgR
    property bool running: true

    // Everything declared inside the caller lands in `face`.
    default property alias content: face.data

    // A click anywhere the inner controls did not take.
    signal tapped()

    readonly property real target: pane.armed ? Math.max(0, Math.min(1, pane.value)) : 0
    property real frac: 0
    onTargetChanged: pane.frac = pane.target
    Component.onCompleted: pane.frac = pane.target
    Behavior on frac {
        NumberAnimation {
            // The climb from empty is the sweep; everything after is a reading
            // moving, and moves at the usual speed.
            duration: (pane.sweepMs > 0 && pane.frac < 0.001) ? pane.sweepMs : pane.easeMs
            easing.type: Services.Sizes.easeOut
        }
    }

    implicitHeight: 140

    Rectangle {
        id: vessel
        anchors.fill: parent
        radius: pane.radius_
        color: Services.Colors.fillInset
        border.width: 1
        border.color: Services.Colors.fillRest
        Behavior on border.color { ColorAnim {} }
    }

    LiquidFill {
        id: water
        anchors.fill: parent
        shape: "rect"
        radius_: vessel.radius
        level: pane.frac
        opacity: pane.dimmed ? 0.55 : 1.0
        Behavior on opacity { Anim { speed: Services.Sizes.msMicro } }
        // Fuller means livelier, the same rule the other vessels read by; and
        // livelier still while something is actually flowing.
        waveAmp: (1.5 + pane.frac * 1.9) * (pane.lively ? 1.6 : 1.0)
        periodMs: Math.round((6400 - pane.frac * 1800) * (pane.lively ? 0.62 : 1.0))
        running: pane.running && pane.visible
        color_: pane.fillColor
        layer.enabled: true
    }

    // The breath while something is flowing in. Sits outside the vessel's edge
    // so it never washes over the reading standing inside it.
    Rectangle {
        anchors.fill: parent
        anchors.margins: -4
        radius: pane.radius_ + 4
        color: "transparent"
        border.width: 5
        border.color: Qt.rgba(pane.fillColor.r, pane.fillColor.g, pane.fillColor.b, 0.30)
        visible: pane.glow && pane.armed
        SequentialAnimation on opacity {
            running: pane.glow && pane.armed
            loops: Animation.Infinite
            NumberAnimation { to: 1; duration: 900; easing.type: Services.Sizes.easeLoop }
            NumberAnimation { to: 0; duration: 900; easing.type: Services.Sizes.easeLoop }
        }
    }

    // Under the contents, so anything with its own mouse area wins.
    MouseArea {
        id: back
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: pane.tapped()
    }

    Item {
        id: face
        anchors.fill: parent
    }

    // The part of the contents the liquid has reached, re-inked so nothing
    // ever sits on a tone it shares. Takes no input of its own.
    Submerged {
        anchors.fill: parent
        source: face
        mask: water
        ink: Services.Colors.onColor(pane.fillColor)
    }
}
