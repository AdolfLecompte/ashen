import QtQuick

import "root:/modules/desktop"
import "root:/modules/widgets" as Widgets
import "root:/services" as Services

// The charge, in the three ways the rest of the shell already draws a level.
// Never red at the bottom: the accent says it at any level, here as everywhere.
DesktopWidget {
    id: root
    wid: "battery"

    readonly property real frac: Services.Battery.level / 100
    readonly property string glyph: Services.Battery.icon(Services.Battery.level,
                                                          Services.Battery.charging)
    // Not `left`: every Item already has left/right/top/bottom as anchor
    // lines, and they are FINAL. Same family as `layer` and `focus`.
    readonly property string untilFull: Services.Battery.timeRemaining !== "--"
        ? (Services.Battery.charging ? "Full in " + Services.Battery.timeRemaining
                                     : Services.Battery.timeRemaining + " left")
        : ""

    // Slow number, asked for rather than polled -- and again whenever the
    // charger comes and goes, which is when it changes meaning.
    Component.onCompleted: Services.Battery.refreshTime()
    onLiveChanged: if (root.live) Services.Battery.refreshTime()
    Connections {
        target: Services.Battery
        function onChargingChanged() { Services.Battery.refreshTime() }
    }
    Timer {
        interval: 120000
        repeat: true
        running: root.live
        onTriggered: Services.Battery.refreshTime()
    }

    Component {
        id: vesselShape
        Widgets.LiquidPane {
            width: 200
            height: 96
            value: root.frac
            // Charging is something happening, not something that is.
            glow: Services.Battery.charging
            lively: Services.Battery.charging
            running: root.live

            Row {
                anchors.centerIn: parent
                spacing: 10

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.glyph
                    color: Services.Colors.snow
                    font.pixelSize: 26
                    font.family: "Material Symbols Rounded"
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Services.Battery.level + "%"
                    color: Services.Colors.snow
                    font.pixelSize: Services.Sizes.fsReadout
                    font.bold: true
                    font.family: "JetBrainsMono NF"
                }
            }
        }
    }

    Component {
        id: ringShape
        Widgets.DialGauge {
            size: 132
            value: root.frac
            glyph: root.glyph
            label: Services.Battery.level + "%"
            caption: root.untilFull
            glow: Services.Battery.charging
        }
    }

    Component {
        id: plainShape
        Column {
            spacing: 2

            Row {
                spacing: 10
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.glyph
                    color: Services.Colors.ghost
                    font.pixelSize: 30
                    font.family: "Material Symbols Rounded"
                }
                Text {
                    text: Services.Battery.level + "%"
                    color: Services.Colors.snow
                    font.pixelSize: 44
                    font.bold: true
                    font.family: "JetBrainsMono NF"
                }
            }
            Text {
                text: root.untilFull
                visible: root.untilFull !== ""
                color: Services.Colors.mist
                font.pixelSize: Services.Sizes.fsMeta
                font.family: "JetBrainsMono NF"
                font.letterSpacing: 1.2
            }
        }
    }

    Loader {
        sourceComponent: root.style === "ring" ? ringShape
                       : root.style === "plain" ? plainShape
                       : vesselShape
    }
}
