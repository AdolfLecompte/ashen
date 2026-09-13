import QtQuick

import "root:/modules/desktop"
import "root:/services" as Services

// The machine's own name card: what it runs, on what, and how long it has been
// up. The questions are asked once by services/Machine.qml -- the same answers
// the About tab shows, so the two can never disagree.
DesktopWidget {
    id: root
    wid: "machine"


    // Only uptime moves, and only while something is watching it.
    Component.onCompleted: {
        Services.Machine.watch(root.live)
        if (root.style === "session") Services.Battery.refreshTime()
    }
    Component.onDestruction: Services.Machine.watch(false)
    onLiveChanged: {
        Services.Machine.watch(root.live)
        if (root.live && root.style === "session") Services.Battery.refreshTime()
    }

    // Only the session card says how long is left, and only it has to ask:
    // the figure is slow and the answer changes meaning when the charger does.
    Connections {
        target: Services.Battery
        enabled: root.style === "session"
        function onChargingChanged() { Services.Battery.refreshTime() }
    }

    component Line: Item {
        id: ln
        property string caption: ""
        property string value: ""
        property real lineWidth: 400
        implicitWidth: ln.lineWidth
        implicitHeight: 18

        Text {
            textFormat: Text.PlainText
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: ln.caption
            color: Services.Colors.mist
            font.pixelSize: Services.Sizes.fsCaption
            font.letterSpacing: 1.2
            font.family: "JetBrainsMono NF"
        }
        Text {
            textFormat: Text.PlainText
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width * 0.74
            horizontalAlignment: Text.AlignRight
            text: ln.value
            color: Services.Colors.snow
            font.pixelSize: Services.Sizes.fsBody
            font.family: "JetBrainsMono NF"
            elide: Text.ElideRight
        }
    }

    component Card_: Column {
        spacing: 6

        // The hostname is the machine's name, so it is the headline and not
        // another row in the table.
        Text {
            textFormat: Text.PlainText
            text: Services.Machine.hostname
            color: Services.Colors.snow
            font.pixelSize: 34
            font.bold: true
            font.family: "JetBrainsMono NF"
        }
        Text {
            textFormat: Text.PlainText
            text: Services.Machine.shortOs
            color: Services.Colors.ghost
            font.pixelSize: Services.Sizes.fsInput
            font.family: "JetBrainsMono NF"
            bottomPadding: 8
        }

        Line { caption: Services.I18n.t("widget.kernel"); value: Services.Machine.kernel }
        Line { caption: Services.I18n.t("widget.cpu");    value: Services.Machine.shortCpu }
        Line { caption: Services.I18n.t("widget.memory"); value: Services.Machine.memInfo }
        Line { caption: Services.I18n.t("widget.uptime"); value: Services.Machine.shortUptime }
        Line { caption: Services.I18n.t("widget.packages"); value: Services.Machine.pkgInfo }
    }

    component Compact: Column {
        spacing: 2
        Text {
            textFormat: Text.PlainText
            text: Services.Machine.hostname
            color: Services.Colors.snow
            font.pixelSize: 26
            font.bold: true
            font.family: "JetBrainsMono NF"
        }
        Text {
            textFormat: Text.PlainText
            text: Services.Machine.shortOs + "  ·  up " + Services.Machine.shortUptime
            color: Services.Colors.mist
            font.pixelSize: Services.Sizes.fsBody
            font.family: "JetBrainsMono NF"
        }
    }

    // Who is logged in and on what, with the charge underneath: the reading a
    // locked screen is actually asked for. The battery is a line of this card
    // and not a card of its own -- one plate per thought.
    component Session: Column {
        spacing: 6

        Text {
            textFormat: Text.PlainText
            text: Services.AppState.userName + "@" + Services.Machine.hostname
            color: Services.Colors.snow
            font.pixelSize: 26
            font.bold: true
            font.family: "JetBrainsMono NF"
        }
        Text {
            textFormat: Text.PlainText
            text: Services.Machine.shortOs
            color: Services.Colors.ghost
            font.pixelSize: Services.Sizes.fsInput
            font.family: "JetBrainsMono NF"
            bottomPadding: 8
        }

        Line { caption: Services.I18n.t("widget.wm");     value: "Hyprland"; lineWidth: 300 }
        Line { caption: Services.I18n.t("widget.kernel"); value: Services.Machine.kernel; lineWidth: 300 }
        Line { caption: Services.I18n.t("widget.uptime"); value: Services.Machine.shortUptime; lineWidth: 300 }

        Row {
            spacing: 10
            topPadding: 8

            Text {
                textFormat: Text.PlainText
                anchors.verticalCenter: parent.verticalCenter
                text: Services.Battery.icon(Services.Battery.level, Services.Battery.charging)
                // Charging is something happening; a level is not, at any level.
                color: Services.Battery.charging ? Services.Colors.ghost : Services.Colors.mist
                font.pixelSize: 22
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
            Text {
                textFormat: Text.PlainText
                anchors.verticalCenter: parent.verticalCenter
                text: Services.Battery.timeRemaining !== "--"
                    ? Services.I18n.t(Services.Battery.charging ? "battery.fullIn" : "battery.left",
                                      { t: Services.Battery.timeRemaining })
                    : ""
                color: Services.Colors.mist
                font.pixelSize: Services.Sizes.fsMeta
                font.letterSpacing: 1.2
                font.family: "JetBrainsMono NF"
            }
        }
    }

    Component { id: cardShape; Card_ {} }
    Component { id: compactShape; Compact {} }
    Component { id: sessionShape; Session {} }

    Loader {
        sourceComponent: root.style === "compact" ? compactShape
                       : root.style === "session" ? sessionShape
                       : cardShape
    }
}
