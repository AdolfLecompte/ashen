import QtQuick

import "root:/modules/desktop"
import "root:/modules/widgets" as Widgets
import "root:/services" as Services

// The last few things that asked for you. It reads the same history the panel
// does, so dismissing one there takes it off the wallpaper too.
DesktopWidget {
    id: root
    wid: "notify"


    readonly property var log: Services.Notifications.history || []

    // "just now", "12m", "3h", "2d" -- a notification's age is the only part of
    // its time anyone reads.
    function ago(ms) {
        const d = Math.max(0, Date.now() - ms)
        const m = Math.floor(d / 60000)
        if (m < 1) return "now"
        if (m < 60) return m + "m"
        const h = Math.floor(m / 60)
        if (h < 24) return h + "h"
        return Math.floor(h / 24) + "d"
    }
    // Ticks once a minute so those ages do not freeze at whatever they were
    // when the widget was built.
    property int agoTick: 0
    Timer {
        running: root.live
        interval: 60000
        repeat: true
        onTriggered: root.agoTick++
    }

    component Line: Item {
        id: ln
        property var entry: null
        implicitWidth: 340
        implicitHeight: 42

        // The sender's own icon where there is one; its first letter otherwise.
        Rectangle {
            id: badge
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 30
            height: 30
            radius: Services.Sizes.innerR
            color: Services.Colors.fillLine

            Image {
                id: shot
                anchors.fill: parent
                anchors.margins: 5
                source: ln.entry ? (ln.entry.image || ln.entry.icon || "") : ""
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                visible: status === Image.Ready
            }
            Text {
                anchors.centerIn: parent
                visible: shot.status !== Image.Ready
                text: ln.entry && ln.entry.appName ? ln.entry.appName.charAt(0).toUpperCase() : "?"
                color: Services.Colors.ghost
                font.pixelSize: Services.Sizes.fsInput
                font.bold: true
                font.family: "JetBrainsMono NF"
            }
        }

        Column {
            anchors.left: badge.right
            anchors.leftMargin: 10
            anchors.right: age.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            Text {
                width: parent.width
                text: ln.entry ? (ln.entry.summary || ln.entry.appName || "") : ""
                color: Services.Colors.snow
                font.pixelSize: Services.Sizes.fsBody
                font.bold: true
                font.family: "JetBrainsMono NF"
                elide: Text.ElideRight
            }
            Text {
                width: parent.width
                text: ln.entry ? (ln.entry.body || ln.entry.appName || "") : ""
                color: Services.Colors.mist
                font.pixelSize: Services.Sizes.fsMeta
                font.family: "JetBrainsMono NF"
                elide: Text.ElideRight
                // The body arrives with the sender's own line breaks in it,
                // and one line is all there is room for.
                maximumLineCount: 1
            }
        }

        Text {
            id: age
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: 4
            text: {
                root.agoTick
                return ln.entry ? root.ago(ln.entry.timestamp) : ""
            }
            color: Services.Colors.ash
            font.pixelSize: Services.Sizes.fsMeta
            font.family: "JetBrainsMono NF"
        }
    }

    // Picked when the history actually empties, never per frame: a line that
    // changed under your eyes would read as a list still moving.
    property string quietLine: Services.Voice.pick("notify.empty")
    onLogChanged: if (root.log.length === 0) root.quietLine = Services.Voice.pick("notify.empty")

    // Nothing waiting is worth saying plainly rather than drawing an empty box.
    component Quiet: Item {
        implicitWidth: 340
        implicitHeight: 46
        Row {
            anchors.centerIn: parent
            spacing: 8
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "\ue86c"
                color: Services.Colors.ghost
                font.pixelSize: 20
                font.family: "Material Symbols Rounded"
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.quietLine
                color: Services.Colors.mist
                font.pixelSize: Services.Sizes.fsBody
                font.family: "JetBrainsMono NF"
            }
        }
    }


    component List_: Column {
        spacing: 8
        WidgetHead {
            implicitWidth: 340
            glyph: "\ue7f4"
            name: Services.I18n.t("widget.notifications")
            note: root.log.length
        }
        Repeater {
            model: Math.min(3, root.log.length)
            Line { entry: root.log[index]; required property int index }
        }
        Quiet { visible: root.log.length === 0 }
    }

    // Just how many, for a desktop that wants the number and not the news.
    component Count: Column {
        spacing: -6
        Text {
            text: root.log.length
            color: Services.Colors.snow
            font.pixelSize: 72
            font.bold: true
            font.family: "JetBrainsMono NF"
        }
        Text {
            text: Services.I18n.t(root.log.length === 1 ? "widget.notification" : "widget.notifications")
            color: Services.Colors.mist
            font.pixelSize: Services.Sizes.fsCaption
            font.letterSpacing: 1.6
            font.family: "JetBrainsMono NF"
            topPadding: 10
        }
    }

    Component { id: listShape; List_ {} }
    Component { id: countShape; Count {} }

    Loader {
        sourceComponent: root.style === "count" ? countShape : listShape
    }
}
