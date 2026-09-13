import QtQuick

import "root:/modules/desktop"
import "root:/modules/widgets" as Widgets
import "root:/services" as Services

// What is waiting to be installed. It never installs anything: a button on the
// wallpaper that starts a pacman transaction is a trap, not a feature.
DesktopWidget {
    id: root
    wid: "updates"


    // Nothing asks pacman on behalf of a widget nobody is looking at.
    Component.onCompleted: Services.Updates.watch(root.live)
    Component.onDestruction: Services.Updates.watch(false)
    onLiveChanged: Services.Updates.watch(root.live)

    readonly property int n: Services.Updates.count

    // Said when it turns out there is nothing to install, and only then: a
    // line that re-rolled every check would be a widget fidgeting.
    property string cleanLine: Services.Voice.pick("updates.none")
    // Asked for on the edge, so the line is not re-rolled every repaint while
    // the check runs.
    property string checkLine: Services.Voice.pick("updates.checking")
    Connections {
        target: Services.Updates
        function onCheckingChanged() {
            if (Services.Updates.checking) root.checkLine = Services.Voice.pick("updates.checking")
        }
    }
    readonly property bool clean: root.n === 0 && Services.Updates.checkedAt > 0
    onCleanChanged: if (root.clean) root.cleanLine = Services.Voice.pick("updates.none")


    component Row_: Item {
        id: rw
        property var pkg: null
        implicitWidth: 300
        implicitHeight: 20

        Text {
            textFormat: Text.PlainText
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width * 0.52
            text: rw.pkg ? rw.pkg.name : ""
            color: Services.Colors.snow
            font.pixelSize: Services.Sizes.fsBody
            font.family: "JetBrainsMono NF"
            elide: Text.ElideRight
        }
        // Only where it is going. Where it came from is the version you have,
        // and nobody upgrades because of that number.
        Text {
            textFormat: Text.PlainText
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: rw.pkg ? rw.pkg.to : ""
            color: Services.Colors.ghost
            font.pixelSize: Services.Sizes.fsMeta
            font.family: "JetBrainsMono NF"
            elide: Text.ElideLeft
        }
    }

    component List_: Column {
        spacing: 6
        WidgetHead {
            implicitWidth: 300
            glyph: "\ue8d7"
            name: Services.I18n.t("widget.updates")
            // Checking is a state worth showing: an empty list and an unasked
            // question look identical otherwise.
            note: Services.Updates.checking ? "checking"
                : Services.Updates.checkedAt === 0 ? "--" : root.n
        }
        Repeater {
            model: Math.min(6, root.n)
            Row_ { required property int index; pkg: Services.Updates.list[index] }
        }
        Text {
            textFormat: Text.PlainText
            visible: root.n > 6
            text: "+" + (root.n - 6) + " more"
            color: Services.Colors.ash
            font.pixelSize: Services.Sizes.fsMeta
            font.family: "JetBrainsMono NF"
        }
        // Waiting is typed, being done is printed: the same line, two speeds.
        Widgets.SaidLine {
            visible: text !== ""
            line: Services.Updates.checking ? root.checkLine
                : (root.n === 0 && Services.Updates.checkedAt > 0 ? root.cleanLine : "")
            msPerChar: Services.Updates.checking ? 26 : 0
            font.pixelSize: Services.Sizes.fsBody
        }
    }

    component Count: Column {
        spacing: -6
        Text {
            textFormat: Text.PlainText
            text: Services.Updates.checkedAt === 0 ? "--" : root.n
            color: Services.Colors.snow
            font.pixelSize: 72
            font.bold: true
            font.family: "JetBrainsMono NF"
        }
        Text {
            textFormat: Text.PlainText
            text: Services.I18n.t(root.n === 1 ? "widget.update" : "widget.updates")
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
