import QtQuick

import "root:/services" as Services

// One live clock inside the shared box: what it reads, and the two buttons that
// work it. It knows no service -- the layer above hands it the numbers and takes
// the presses back, so the stopwatch and the countdown are this twice.
//
// Off, it collapses to nothing rather than hiding: the box measures itself by
// what is in it, so a size that animates to zero IS the box closing up.
Item {
    id: rd

    property bool on: false
    // The hairline in front of it, drawn only when something precedes it.
    property bool showRule: false
    // Set when the BOX stacks its readouts (a side bar). It turns only this
    // corner: the reading itself stays a row whichever way the bar runs --
    // stacking the glyph, the digits and the two buttons drew a tall ribbon
    // down the side of the screen.
    property bool stacked: false

    property string glyph: ""
    property string value: ""
    // Running reads in snow, paused steps back to mist. Same rule as the panel.
    property bool live: false
    property bool playing: false
    property bool canReset: false
    // Which tab of the clock panel the digits open.
    property int tab: 0

    signal toggled()
    signal cleared()

    // Measured by what it draws, never by anything that fills it back.
    implicitWidth: rd.on ? lay.implicitWidth : 0
    implicitHeight: rd.on ? lay.implicitHeight : 0
    clip: true

    opacity: rd.on ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: Services.Sizes.msPanel; easing.type: Services.Sizes.easeOut } }
    Behavior on implicitWidth { NumberAnimation { duration: Services.Sizes.msPanel; easing.type: Services.Sizes.easeOut } }
    Behavior on implicitHeight { NumberAnimation { duration: Services.Sizes.msPanel; easing.type: Services.Sizes.easeOut } }

    Grid {
        id: lay
        columns: rd.stacked ? 1 : 2
        spacing: rd.stacked ? 6 : 10
        horizontalItemAlignment: Grid.AlignHCenter
        verticalItemAlignment: Grid.AlignVCenter

        // A rule, never a fill: a filled section inside the box's plate is the
        // double plate the bar got rid of (see docs/DESIGN.md).
        Rectangle {
            visible: rd.showRule
            width: rd.stacked ? line.implicitWidth : 1
            height: rd.stacked ? 1 : 18
            color: Services.Colors.fillRest
        }

        Row {
            id: line
            spacing: 6

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: rd.glyph
                color: Services.Colors.ghost
                font.pixelSize: 16
                font.family: "Material Symbols Rounded"
            }

            // The reading is its own click target: it opens the panel already
            // on this tool's tab, the shortcut the bar chip used to give.
            Item {
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: digits.implicitWidth
                implicitHeight: digits.implicitHeight

                Text {
                    id: digits
                    text: rd.value
                    color: (rd.live || reach.containsMouse) ? Services.Colors.snow
                                                            : Services.Colors.mist
                    font.pixelSize: 14
                    font.bold: true
                    font.family: "JetBrainsMono NF"
                    Behavior on color { ColorAnimation { duration: Services.Sizes.msMicro } }
                }

                MouseArea {
                    id: reach
                    anchors.fill: parent
                    // Digits are a thin target; the margin gives the pointer
                    // the whole height of the box to land in.
                    anchors.margins: -6
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Services.AppState.openClockAt(rd.tab)
                }
            }

            CtlChip {
                anchors.verticalCenter: parent.verticalCenter
                size: 22
                glyphSize: 13
                glyph: rd.playing ? "" : ""
                active: rd.playing
                onTriggered: rd.toggled()
            }
            CtlChip {
                anchors.verticalCenter: parent.verticalCenter
                size: 22
                glyphSize: 13
                glyph: ""
                available: rd.canReset
                onTriggered: rd.cleared()
            }
        }
    }
}
