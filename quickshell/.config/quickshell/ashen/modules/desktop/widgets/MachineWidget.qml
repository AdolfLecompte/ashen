import QtQuick

import "root:/modules/desktop"
import "root:/modules/widgets" as Widgets
import "root:/services" as Services

// The machine's own name card: what it runs, on what, and how long it has been
// up. The questions are asked once by services/Machine.qml -- the same answers
// the About tab shows, so the two can never disagree.
DesktopWidget {
    id: root
    wid: "machine"
    // The battery line unfolds: the plate eases there in one motion.
    easeSize: true


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
    }

    Component { id: cardShape; Card_ {} }
    Component { id: compactShape; Compact {} }
    Component { id: sessionShape; Session {} }

    // Come close and the battery says where it stands: charged, how long it
    // has left, or how long to full. Lingers a moment after the pointer goes,
    // so brushing past does not blink it.
    readonly property bool near: nearArea.containsMouse || linger.running
    Timer { id: linger; interval: 600 }
    readonly property bool hasBattery: Services.Battery.level > 0
    readonly property string batteryNote: Services.Battery.charging
        ? (Services.Battery.timeShort !== ""
           ? Services.I18n.t("battery.fullIn", { t: Services.Battery.timeShort }) : "")
        : Services.Battery.level >= 99 ? Services.I18n.t("battery.charged")
        : Services.Battery.timeShort !== ""
          ? Services.I18n.t("battery.left", { t: Services.Battery.timeShort }) : ""

    Column {
        Loader {
            id: shape
            sourceComponent: root.style === "compact" ? compactShape
                           : root.style === "session" ? sessionShape
                           : cardShape
        }

        Item {
            id: fold
            property real amt: root.near && root.hasBattery ? 1 : 0
            Behavior on amt { Widgets.Anim { speed: Services.Sizes.msPanel } }
            width: shape.item ? shape.item.width : 0
            height: 40 * fold.amt
            visible: fold.amt > 0.01
            clip: true
            Binding { target: root; property: "foldH"; value: fold.height }
            Binding { target: root; property: "foldTo"; value: root.near && root.hasBattery ? 40 : 0 }

            Row {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                spacing: 10
                opacity: fold.amt
                Text {
                    textFormat: Text.PlainText
                    anchors.verticalCenter: parent.verticalCenter
                    text: Services.Battery.icon(Services.Battery.level, Services.Battery.charging)
                    // Charging is something happening; a level is not.
                    color: Services.Battery.charging ? Services.Colors.ghost : Services.Colors.mist
                    font.pixelSize: 20
                    font.family: "Material Symbols Rounded"
                }
                Text {
                    textFormat: Text.PlainText
                    anchors.verticalCenter: parent.verticalCenter
                    text: Services.Battery.level + "%"
                    color: Services.Colors.snow
                    font.pixelSize: Services.Sizes.fsCardTitle
                    font.bold: true
                    font.family: "JetBrainsMono NF"
                }
                Text {
                    textFormat: Text.PlainText
                    anchors.verticalCenter: parent.verticalCenter
                    visible: text !== ""
                    text: root.batteryNote
                    color: Services.Colors.mist
                    font.pixelSize: Services.Sizes.fsMeta
                    font.family: "JetBrainsMono NF"
                }
            }
        }
    }

    // Over the whole widget, hover only: clicks fall through.
    MouseArea {
        id: nearArea
        anchors.fill: parent
        z: 3
        enabled: !root.editing
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onContainsMouseChanged: {
            if (containsMouse) Services.Battery.refreshTime()
            else linger.restart()
        }
    }
}
