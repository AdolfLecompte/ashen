import QtQuick

import "root:/services" as Services

// The one place a duration and a curve get chosen.
//
// Ashen's tokens are two independent ladders -- how LONG a thing takes and what
// SHAPE it takes -- so this carries them as two properties rather than as one
// combined token the way Caelestia does. `msStandard` with `easeBox` is a real
// pair here, and an enum of every combination would be a second vocabulary to
// keep in step with the first one.
//
// It is also the motion kill-switch: with `Sizes.motion` false every animation
// that comes through here takes zero time. The values still arrive, they just
// stop travelling. That is a thing 402 hand-written Behaviors could never be
// asked to do at once.
NumberAnimation {
    property int speed: Services.Sizes.msStandard
    property int curve: Services.Sizes.easeOut

    duration: Services.Sizes.motion ? speed : 0
    easing.type: curve
}
