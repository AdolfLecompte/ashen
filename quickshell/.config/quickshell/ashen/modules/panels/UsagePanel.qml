import Quickshell
import QtQuick
import QtQuick.Layouts
import "root:/services" as Services
import "root:/modules/widgets" as Widgets

// Where the time went: today's total, the week as seven columns, and the
// applications that had you today. A panel of its own rather than a tab of the
// process monitor -- that one is the machine's hardware, this is how you use it.
PanelWindow {
    id: win
    anchors { top: true; left: true; right: true; bottom: true }
    screen: Services.Screens.active
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    mask: Widgets.ShellMask { winW: win.width; winH: win.height }
    readonly property bool shown: Services.AppState.usageVisible
    visible: shown || closeDelay.running
    Timer { id: closeDelay; interval: card.closeMs }

    // The running span is booked once a minute; while the panel is up the
    // numbers are re-asked often enough to move under your eyes.
    property int beat: 0
    Timer { interval: 15000; running: win.shown; repeat: true; onTriggered: win.beat++ }
    readonly property var today: { win.beat; Services.Usage.revision; return Services.Usage.today() }
    readonly property var week: { win.beat; Services.Usage.revision; return Services.Usage.week() }
    readonly property real weekMax: Math.max(3600, ...win.week.map(d => d.total))
    readonly property var topApps: win.today.apps.slice(0, 6)
    readonly property bool empty: win.today.total < 60 && win.topApps.length === 0

    property string emptyLine: Services.Voice.pick("usage.empty")
    onShownChanged: {
        if (shown) { win.beat++; win.emptyLine = Services.Voice.pick("usage.empty") }
        else closeDelay.restart()
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        enabled: Services.AppState.usageVisible
        onClicked: Services.AppState.usageVisible = false
    }

    Widgets.PanelHost {
        id: card
        shown: Services.AppState.usageVisible
        pillKey: "usage"
        restSide: "center"
        pillCX: Services.AppState.usagePillCenterX
        pillCY: Services.AppState.usagePillCenterY
        pillW: Services.AppState.usagePillW
        pillH: Services.AppState.usagePillH
        pillActive: false
        pillGlyph: Services.AppState.pillGlyph("usage")
        pillLabel: Services.AppState.pillLabel("usage")
        openW: 440
        openH: (card.bodyItem ? card.bodyItem.contentH : 0) + 40
        cardRadius: 18

        body: Component {
            Item {
                readonly property Item glyphTarget: usageGlyph
                readonly property Item labelTarget: usageTotal
                readonly property real contentH: col.implicitHeight

                ColumnLayout {
                    id: col
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 16

                    // ── Today ────────────────────────────────────────────
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        Text {
                            textFormat: Text.PlainText
                            id: usageGlyph
                            Layout.alignment: Qt.AlignVCenter
                            text: ""
                            visible: !card.morphingGlyph
                            color: Services.Colors.ghost
                            font.pixelSize: 34
                            font.family: "Material Symbols Rounded"
                        }
                        Text {
                            textFormat: Text.PlainText
                            id: usageTotal
                            Layout.alignment: Qt.AlignVCenter
                            Layout.fillWidth: true
                            text: Services.Usage.span(win.today.total)
                            visible: !card.morphingLabel
                            color: Services.Colors.snow
                            font.pixelSize: 40
                            font.bold: true
                            font.family: "JetBrainsMono NF"
                            elide: Text.ElideRight
                        }
                    }

                    // ── The week ─────────────────────────────────────────
                    // Seven columns of ticks, lit up to each day's share of the
                    // busiest one (never less than an hour, so a quiet week is
                    // not drawn as seven full bars). Today in the accent.
                    Row {
                        id: weekRow
                        Layout.fillWidth: true
                        Layout.preferredHeight: 84 + 6 + 14
                        Repeater {
                            model: win.week
                            delegate: Item {
                                required property var modelData
                                required property int index
                                readonly property bool isToday: index === win.week.length - 1
                                width: weekRow.width / 7
                                height: weekRow.height

                                // A column of ticks lit from the bottom: the same
                                // meter as everywhere, stood on its end.
                                Widgets.TickMeter {
                                    width: 84
                                    height: 14
                                    transformOrigin: Item.Center
                                    rotation: -90
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.top: parent.top
                                    anchors.topMargin: (84 - 14) / 2
                                    mode: "level"
                                    tickW: 4
                                    gap: 3
                                    value: modelData.total / win.weekMax
                                    color_: parent.isToday ? Services.Colors.ghost : Services.Colors.mist
                                }
                                Text {
                                    textFormat: Text.PlainText
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottom: parent.bottom
                                    text: Services.I18n.locale.dayName(modelData.date.getDay(), Locale.NarrowFormat).toUpperCase()
                                    color: parent.isToday ? Services.Colors.snow : Services.Colors.ash
                                    font.pixelSize: Services.Sizes.fsMeta
                                    font.bold: parent.isToday
                                    font.family: "JetBrainsMono NF"
                                }
                            }
                        }
                    }

                    // ── Today's applications ─────────────────────────────
                    Column {
                        Layout.fillWidth: true
                        spacing: 10
                        visible: !win.empty

                        Repeater {
                            model: win.topApps
                            delegate: RowLayout {
                                required property var modelData
                                readonly property var app: Services.Usage.appOf(modelData.key)
                                width: parent.width
                                spacing: 10

                                Item {
                                    implicitWidth: 22
                                    implicitHeight: 22
                                    Layout.alignment: Qt.AlignVCenter
                                    Image {
                                        anchors.fill: parent
                                        visible: parent.parent.app !== null && parent.parent.app.icon !== ""
                                        source: {
                                            const a = parent.parent.app
                                            if (!a || !a.icon) return ""
                                            return a.icon.startsWith("/") ? ("file://" + a.icon)
                                                : Quickshell.iconPath(a.icon, "application-x-executable")
                                        }
                                        sourceSize.width: 44
                                        sourceSize.height: 44
                                        fillMode: Image.PreserveAspectFit
                                    }
                                    Text {
                                        textFormat: Text.PlainText
                                        anchors.centerIn: parent
                                        visible: parent.parent.app === null || parent.parent.app.icon === ""
                                        text: Services.Windows.iconForClass(modelData.key)
                                        color: Services.Colors.mist
                                        font.pixelSize: 18
                                        font.family: "Material Symbols Rounded"
                                    }
                                }
                                Text {
                                    textFormat: Text.PlainText
                                    Layout.preferredWidth: 120
                                    Layout.alignment: Qt.AlignVCenter
                                    text: Services.Usage.nameOf(modelData.key)
                                    color: Services.Colors.snow
                                    font.pixelSize: Services.Sizes.fsInput
                                    font.family: "JetBrainsMono NF"
                                    elide: Text.ElideRight
                                }
                                Widgets.TickMeter {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 14
                                    Layout.alignment: Qt.AlignVCenter
                                    mode: "level"
                                    tickW: 3
                                    gap: 2
                                    value: win.topApps.length > 0 ? modelData.secs / win.topApps[0].secs : 0
                                    color_: Services.Colors.ghost
                                }
                                Text {
                                    textFormat: Text.PlainText
                                    Layout.preferredWidth: 64
                                    Layout.alignment: Qt.AlignVCenter
                                    horizontalAlignment: Text.AlignRight
                                    text: Services.Usage.span(modelData.secs)
                                    color: Services.Colors.mist
                                    font.pixelSize: Services.Sizes.fsInput
                                    font.bold: true
                                    font.family: "JetBrainsMono NF"
                                }
                            }
                        }
                    }

                    // Nothing counted yet today: said, not an empty box.
                    Text {
                        textFormat: Text.PlainText
                        Layout.fillWidth: true
                        visible: win.empty
                        horizontalAlignment: Text.AlignHCenter
                        text: win.emptyLine
                        color: Services.Colors.mist
                        font.pixelSize: Services.Sizes.fsInput
                        font.family: "JetBrainsMono NF"
                    }
                }
            }
        }
    }
}
