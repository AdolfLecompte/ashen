import QtQuick

import "root:/modules/desktop"
import "root:/modules/widgets" as Widgets
import "root:/services" as Services

// How full the disks are. Flat bars, never curves: a filesystem moves by a
// gigabyte a week, and a line drawn through that is a straight one that lies
// about what matters -- how much is left. Same call the system widget made.
DesktopWidget {
    id: root
    wid: "disks"


    Component.onCompleted: Services.Disks.watch(root.live)
    Component.onDestruction: Services.Disks.watch(false)
    onLiveChanged: Services.Disks.watch(root.live)

    readonly property var mounts: Services.Disks.mounts || []

    component Bar_: Item {
        id: br
        property var mount: null
        property real barWidth: 300
        implicitWidth: br.barWidth
        implicitHeight: 34

        Text {
            textFormat: Text.PlainText
            id: name
            anchors.left: parent.left
            anchors.top: parent.top
            text: br.mount ? br.mount.label : ""
            color: Services.Colors.mist
            font.pixelSize: Services.Sizes.fsCaption
            font.letterSpacing: 1.2
            font.family: "JetBrainsMono NF"
        }
        Text {
            textFormat: Text.PlainText
            anchors.right: parent.right
            anchors.top: parent.top
            text: br.mount
                ? Services.Disks.human(br.mount.size - br.mount.used) + " free"
                : ""
            color: Services.Colors.snow
            font.pixelSize: Services.Sizes.fsCaption
            font.bold: true
            font.family: "JetBrainsMono NF"
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 10
            radius: 5
            color: Services.Colors.fillLine

            Rectangle {
                width: parent.width * (br.mount ? br.mount.percent / 100 : 0)
                height: parent.height
                radius: parent.radius
                color: Services.Colors.ghost
                gradient: Services.Prefs.useGradients ? Services.Colors.accentGradient : null
                Behavior on width {
                    Widgets.Anim {}
                }
            }
        }
    }


    component Full: Column {
        spacing: 10
        WidgetHead {
            implicitWidth: 300
            glyph: "\ue1db"
            name: Services.I18n.t("widget.disks")
        }
        // Root as the headline: what is left, large, and of how much.
        Row {
            visible: root.mounts.length > 0
            spacing: 8
            Text {
                textFormat: Text.PlainText
                text: root.mounts.length > 0 ? Services.Disks.human(root.mounts[0].size - root.mounts[0].used) : ""
                color: Services.Colors.snow
                font.pixelSize: Services.Sizes.fsReadout
                font.bold: true
                font.family: "JetBrainsMono NF"
            }
            Text {
                textFormat: Text.PlainText
                anchors.baseline: parent.children[0].baseline
                text: root.mounts.length > 0
                    ? Services.I18n.t("widget.diskFreeOf", { t: Services.Disks.human(root.mounts[0].size) }) : ""
                color: Services.Colors.mist
                font.pixelSize: Services.Sizes.fsMeta
                font.family: "JetBrainsMono NF"
            }
        }
        Repeater {
            model: root.mounts.length
            Bar_ { required property int index; mount: root.mounts[index] }
        }
    }

    // Root only, for a corner that has room for one line.
    component Compact: Bar_ {
        mount: root.mounts.length > 0 ? root.mounts[0] : null
        barWidth: 200
    }

    Component { id: fullShape; Full {} }
    Component { id: compactShape; Compact {} }

    Loader {
        sourceComponent: root.style === "compact" ? compactShape : fullShape
    }
}
