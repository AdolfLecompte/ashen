import QtQuick

import "root:/services" as Services

// A colour arriving instead of a number. Same two ladders and the same motion
// kill-switch as Anim -- see Anim.qml for why they are two properties and not
// one token.
ColorAnimation {
    property int speed: Services.Sizes.msStandard
    property int curve: Services.Sizes.easeOut

    duration: Services.Sizes.motion ? speed : 0
    easing.type: curve
}
