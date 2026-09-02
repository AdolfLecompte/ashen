import QtQuick

import "root:/services" as Services

// The hour, with its seconds written small. Same face the lockscreen wears:
// hh:mm carries the reading, the seconds hang off its foot as a footnote --
// they are the only part that moves, and at full size that is all the eye gets.
//
// Fed the ALREADY formatted string and split by hand, so one component covers
// all four shapes of Prefs.timeFormat without asking which one it is: with and
// without seconds, 24-hour and 12-hour.
Row {
    id: root

    property string time: ""
    property real px: 15
    // How small the seconds go against the hour. The bar runs tighter than the
    // panel: a pill has no room to spend on a number nobody reads.
    property real secRatio: 0.30
    property color color_: Services.Colors.snow
    property real dimAlpha: 0.4

    readonly property var parts: String(time).split(" ")
    readonly property var clockParts: String(parts[0] || "").split(":")
    readonly property string hhmm: clockParts.slice(0, 2).join(":")
    readonly property string ss: clockParts.length > 2 ? clockParts[2] : ""
    // Empty in 24-hour: the Text collapses on its own, no guard needed.
    readonly property string ap: parts.length > 1 ? parts[1] : ""

    spacing: 0

    Text {
        text: root.hhmm
        color: root.color_
        font.pixelSize: root.px
        font.bold: true
        font.family: "JetBrainsMono NF"
    }
    // Hung from the bottom of the row and lifted, the way the lockscreen does
    // it: a real baseline anchor would put the small digits on the line of the
    // big ones and leave them looking dropped.
    Text {
        visible: root.ss !== ""
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.px * 0.17
        leftPadding: root.px * 0.10
        text: root.ss
        color: Qt.rgba(root.color_.r, root.color_.g, root.color_.b, root.dimAlpha)
        font.pixelSize: Math.max(7, Math.round(root.px * root.secRatio))
        font.bold: true
        font.family: "JetBrainsMono NF"
    }
    // The meridiem stays the size of the hour: it is part of the reading, not
    // a tick going by.
    Text {
        visible: root.ap !== ""
        leftPadding: root.px * 0.26
        text: root.ap
        color: root.color_
        font.pixelSize: root.px
        font.bold: true
        font.family: "JetBrainsMono NF"
    }
}
