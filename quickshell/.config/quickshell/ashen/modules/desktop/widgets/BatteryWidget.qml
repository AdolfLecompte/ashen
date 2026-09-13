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
        ? Services.I18n.t(Services.Battery.charging ? "battery.fullIn" : "battery.left",
                          { t: Services.Battery.timeRemaining })
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
        // The level as a row of ticks under the reading. It was a vessel of
        // liquid; the ticks say the same fraction without repainting a wave.
        Rectangle {
            width: 200
            height: 96
            radius: Services.Sizes.cardLgR
            color: Services.Colors.fillInset
            border.width: 1
            border.color: Services.Colors.fillRest

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 14
                spacing: 10

                Text {
                    textFormat: Text.PlainText
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.glyph
                    color: Services.Battery.charging ? Services.Colors.ghost : Services.Colors.snow
                    font.pixelSize: 26
                    font.family: "Material Symbols Rounded"
                }
                Text {
                    textFormat: Text.PlainText
                    anchors.verticalCenter: parent.verticalCenter
                    text: Services.Battery.level + "%"
                    color: Services.Colors.snow
                    font.pixelSize: Services.Sizes.fsReadout
                    font.bold: true
                    font.family: "JetBrainsMono NF"
                }
            }

            Widgets.TickMeter {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 16
                height: 20
                mode: "level"
                value: root.frac
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
                    textFormat: Text.PlainText
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.glyph
                    color: Services.Colors.ghost
                    font.pixelSize: 30
                    font.family: "Material Symbols Rounded"
                }
                Text {
                    textFormat: Text.PlainText
                    text: Services.Battery.level + "%"
                    color: Services.Colors.snow
                    font.pixelSize: 44
                    font.bold: true
                    font.family: "JetBrainsMono NF"
                }
            }
            Text {
                textFormat: Text.PlainText
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
