import Quickshell
import QtQuick
import "root:/services" as Services
import "root:/modules/widgets" as Widgets

// Where the time went, as a board like the process monitor's: a day you can
// walk back through, its total against the week's average, the week as columns,
// the month as a grid, and the applications that had you that day. Its own
// panel -- the process monitor is the hardware, this is how the machine is used.
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

    // ── The day on the board ─────────────────────────────────────────────
    function keyOf(d) { return Services.Usage.dayKey(d) }
    function dateOf(k) { const p = k.split("-"); return new Date(+p[0], +p[1] - 1, +p[2]) }
    function shift(k, n) { const d = win.dateOf(k); return win.keyOf(new Date(d.getFullYear(), d.getMonth(), d.getDate() + n)) }
    readonly property string todayKey: { win.beat; return win.keyOf(new Date()) }
    property string selected: ""
    readonly property string day: win.selected !== "" ? win.selected : win.todayKey
    readonly property bool isToday: win.day === win.todayKey

    // The running span is booked once a minute; while the board is up the
    // numbers are re-asked often enough to move under your eyes.
    property int beat: 0
    Timer { interval: 15000; running: win.shown; repeat: true; onTriggered: win.beat++ }
    onShownChanged: {
        if (shown) { win.selected = ""; win.beat++; win.emptyLine = Services.Voice.pick("usage.empty") }
        else closeDelay.restart()
    }
    property string emptyLine: Services.Voice.pick("usage.empty")

    function totalOf(k) {
        win.beat; Services.Usage.revision
        const rec = Services.Usage.days[k]
        return (rec ? rec.total : 0) + Services.Usage.liveExtra(k)
    }
    readonly property var dayData: { win.beat; Services.Usage.revision; return Services.Usage.day(win.day) }

    // The week the day belongs to, in the locale's own order (Monday first
    // here, Sunday first where that is the custom).
    readonly property var week: {
        win.beat; Services.Usage.revision
        const d = win.dateOf(win.day)
        const first = Services.I18n.locale.firstDayOfWeek % 7
        const back = (d.getDay() - first + 7) % 7
        const out = []
        for (let i = 0; i < 7; i++) {
            const dd = new Date(d.getFullYear(), d.getMonth(), d.getDate() - back + i)
            const k = win.keyOf(dd)
            out.push({ key: k, date: dd, total: win.totalOf(k), future: k > win.todayKey })
        }
        return out
    }
    readonly property real weekMax: Math.max(3600, ...win.week.map(x => x.total))
    // The average over the days of that week that have happened.
    readonly property real average: {
        const past = win.week.filter(x => !x.future)
        return past.length ? past.reduce((a, x) => a + x.total, 0) / past.length : 0
    }
    readonly property real delta: win.dayData.total - win.average

    // The month the day belongs to, as a calendar: leading blanks, then days.
    readonly property var month: {
        win.beat; Services.Usage.revision
        const d = win.dateOf(win.day)
        const firstOfMonth = new Date(d.getFullYear(), d.getMonth(), 1)
        const first = Services.I18n.locale.firstDayOfWeek % 7
        const lead = (firstOfMonth.getDay() - first + 7) % 7
        const days = new Date(d.getFullYear(), d.getMonth() + 1, 0).getDate()
        const out = []
        for (let i = 0; i < lead; i++) out.push(null)
        for (let n = 1; n <= days; n++) {
            const k = win.keyOf(new Date(d.getFullYear(), d.getMonth(), n))
            out.push({ key: k, n: n, total: win.totalOf(k), future: k > win.todayKey })
        }
        return out
    }
    readonly property real monthMax: Math.max(3600, ...win.month.filter(x => x).map(x => x.total))

    function dayTitle(k) {
        if (k === win.todayKey) return Services.I18n.t("usage.today")
        if (k === win.shift(win.todayKey, -1)) return Services.I18n.t("usage.yesterday")
        return Services.I18n.locale.toString(win.dateOf(k), "dddd d MMMM")
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

        // The process monitor's grid: 126 px cells, 12 px apart.
        readonly property int cell: 126
        readonly property int gap: 12
        readonly property int pad: 22
        readonly property int headH: 36
        function span(n) { return n * cell + (n - 1) * gap }
        openW: span(6) + pad * 2
        openH: headH + gap + span(5) + pad * 2
        cardRadius: 22

        body: Component {
            Item {
                id: board

                readonly property Item glyphTarget: win.isToday ? heroGlyph : null
                readonly property Item labelTarget: win.isToday ? heroNum : null

                function stage(i) {
                    const start = Math.min(0.5, i * 0.09)
                    return Math.max(0, Math.min(1, (card.contentAmt - start) / (1 - start)))
                }

                // Every card on the board: its place on the grid, its name in
                // the corner, and its own beat in the arrival.
                component Card: Rectangle {
                    id: cd
                    property string glyph: ""
                    property string name: ""
                    property string note: ""
                    property int index: 0
                    property int col: 0
                    property int row: 0
                    property int cw: 1
                    property int ch: 1
                    readonly property int headH: 40
                    readonly property int inset: 14

                    x: col * (card.cell + card.gap)
                    y: row * (card.cell + card.gap)
                    width: card.span(cw)
                    height: card.span(ch)
                    radius: Services.Sizes.cardLgR
                    color: Services.Colors.tint(Services.Colors.surface, Services.Colors.ghost, 0.07)
                    clip: true
                    opacity: board.stage(index)
                    transform: Translate { y: (1 - board.stage(cd.index)) * 12 }

                    Row {
                        id: cdHead
                        x: cd.inset
                        y: cd.inset
                        spacing: 8
                        Text {
                            textFormat: Text.PlainText
                            anchors.verticalCenter: parent.verticalCenter
                            text: cd.glyph
                            color: Services.Colors.mist
                            font.pixelSize: 16
                            font.family: "Material Symbols Rounded"
                        }
                        Text {
                            textFormat: Text.PlainText
                            anchors.verticalCenter: parent.verticalCenter
                            text: cd.name
                            color: Services.Colors.mist
                            font.pixelSize: Services.Sizes.fsCaption
                            font.bold: true
                            font.letterSpacing: 1.4
                            font.family: "JetBrainsMono NF"
                        }
                    }
                    Text {
                        textFormat: Text.PlainText
                        anchors.right: parent.right
                        anchors.rightMargin: cd.inset
                        anchors.verticalCenter: cdHead.verticalCenter
                        text: cd.note
                        visible: cd.note !== ""
                        color: Services.Colors.ash
                        font.pixelSize: Services.Sizes.fsMeta
                        font.family: "JetBrainsMono NF"
                    }
                }

                // ── The day you are looking at ───────────────────────────
                Item {
                    x: card.pad
                    y: card.pad
                    width: card.span(6)
                    height: card.headH
                    opacity: board.stage(0)

                    Widgets.IconButton {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        glyph: ""
                        onActivated: win.selected = win.shift(win.day, -1)
                    }
                    Text {
                        textFormat: Text.PlainText
                        anchors.centerIn: parent
                        text: win.dayTitle(win.day)
                        color: Services.Colors.snow
                        font.pixelSize: Services.Sizes.fsCardTitle
                        font.bold: true
                        font.family: "JetBrainsMono NF"
                    }
                    Widgets.IconButton {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        glyph: ""
                        available: !win.isToday
                        onActivated: if (!win.isToday) win.selected = win.shift(win.day, 1)
                    }
                }

                Item {
                    x: card.pad
                    y: card.pad + card.headH + card.gap
                    width: card.span(6)
                    height: card.span(5)

                    // ── Average of the week ──────────────────────────────
                    Card {
                        index: 1
                        col: 0; row: 0; cw: 2; ch: 1
                        glyph: ""
                        name: Services.I18n.t("usage.average")
                        Text {
                            textFormat: Text.PlainText
                            x: parent.inset
                            y: parent.headH - 2
                            text: Services.Usage.span(win.average)
                            color: Services.Colors.snow
                            font.pixelSize: Services.Sizes.fsReadout
                            font.bold: true
                            font.family: "JetBrainsMono NF"
                        }
                        Text {
                            textFormat: Text.PlainText
                            x: parent.inset
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: parent.inset
                            text: win.week.length
                                ? Services.I18n.locale.toString(win.week[0].date, "d MMM") + " – "
                                  + Services.I18n.locale.toString(win.week[6].date, "d MMM")
                                : ""
                            color: Services.Colors.ash
                            font.pixelSize: Services.Sizes.fsMeta
                            font.family: "JetBrainsMono NF"
                        }
                    }

                    // ── The day itself ───────────────────────────────────
                    Card {
                        index: 2
                        col: 2; row: 0; cw: 2; ch: 1
                        Text {
                            textFormat: Text.PlainText
                            id: heroGlyph
                            x: parent.inset
                            anchors.verticalCenter: parent.verticalCenter
                            text: ""
                            visible: !card.morphingGlyph
                            color: Services.Colors.ghost
                            font.pixelSize: 30
                            font.family: "Material Symbols Rounded"
                        }
                        Text {
                            textFormat: Text.PlainText
                            id: heroNum
                            anchors.left: heroGlyph.right
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: Services.Usage.span(win.dayData.total)
                            visible: !card.morphingLabel
                            color: Services.Colors.snow
                            font.pixelSize: 34
                            font.bold: true
                            font.family: "JetBrainsMono NF"
                        }
                    }

                    // ── Against the average ──────────────────────────────
                    Card {
                        index: 3
                        col: 4; row: 0; cw: 2; ch: 1
                        glyph: ""
                        name: Services.I18n.t("usage.vsAverage")
                        Row {
                            x: parent.inset
                            y: parent.headH - 2
                            spacing: 6
                            Text {
                                textFormat: Text.PlainText
                                anchors.verticalCenter: parent.verticalCenter
                                visible: Math.abs(win.delta) >= 60
                                text: win.delta > 0 ? "" : ""
                                color: win.delta > 0 ? Services.Colors.ghost : Services.Colors.mist
                                font.pixelSize: 24
                                font.family: "Material Symbols Rounded"
                            }
                            Text {
                                textFormat: Text.PlainText
                                anchors.verticalCenter: parent.verticalCenter
                                text: Math.abs(win.delta) < 60 ? "=" : Services.Usage.span(Math.abs(win.delta))
                                color: Services.Colors.snow
                                font.pixelSize: Services.Sizes.fsReadout
                                font.bold: true
                                font.family: "JetBrainsMono NF"
                            }
                        }
                    }

                    // ── The week ─────────────────────────────────────────
                    // Seven columns of ticks lit up to each day's share of the
                    // busiest (never less than an hour). The day on the board is
                    // the accent; press a column to look at that day.
                    Card {
                        id: weekCard
                        index: 4
                        col: 0; row: 1; cw: 3; ch: 2
                        glyph: ""
                        name: Services.I18n.t("usage.week")
                        Row {
                            id: weekCols
                            x: weekCard.inset
                            y: weekCard.headH + 4
                            width: weekCard.width - weekCard.inset * 2
                            height: weekCard.height - y - weekCard.inset
                            Repeater {
                                model: win.week
                                delegate: Item {
                                    required property var modelData
                                    readonly property bool on: modelData.key === win.day
                                    width: weekCols.width / 7
                                    height: weekCols.height

                                    Widgets.TickMeter {
                                        width: parent.height - 34
                                        height: 18
                                        rotation: -90
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        anchors.top: parent.top
                                        anchors.topMargin: (parent.height - 34 - 18) / 2
                                        mode: "level"
                                        tickW: 4
                                        gap: 3
                                        value: modelData.total / win.weekMax
                                        color_: parent.on ? Services.Colors.ghost : Services.Colors.mist
                                        opacity: modelData.future ? 0.35 : 1
                                    }
                                    Column {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        anchors.bottom: parent.bottom
                                        spacing: 1
                                        Text {
                                            textFormat: Text.PlainText
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: Services.I18n.locale.dayName(modelData.date.getDay(), Locale.ShortFormat)
                                            color: parent.parent.on ? Services.Colors.snow : Services.Colors.ash
                                            font.pixelSize: Services.Sizes.fsMeta
                                            font.bold: parent.parent.on
                                            font.family: "JetBrainsMono NF"
                                        }
                                        Text {
                                            textFormat: Text.PlainText
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: modelData.future || modelData.total < 60 ? "·"
                                                : Math.floor(modelData.total / 3600) > 0
                                                    ? Math.floor(modelData.total / 3600) + "h"
                                                    : Math.floor(modelData.total / 60) + "m"
                                            color: Services.Colors.ash
                                            font.pixelSize: Services.Sizes.fsCaption
                                            font.family: "JetBrainsMono NF"
                                        }
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        enabled: !modelData.future
                                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                        onClicked: win.selected = modelData.key
                                    }
                                }
                            }
                        }
                    }

                    // ── The month ────────────────────────────────────────
                    // A square a day, filled by how much of it was screen time
                    // against the month's busiest. Press one to look at it.
                    Card {
                        id: monthCard
                        index: 5
                        col: 3; row: 1; cw: 3; ch: 2
                        glyph: ""
                        name: Services.I18n.locale.toString(win.dateOf(win.day), "MMMM").toUpperCase()
                        Grid {
                            id: monthGrid
                            readonly property int cellSize: Math.floor((monthCard.width - monthCard.inset * 2 - 6 * spacing) / 7)
                            readonly property int rowsNeeded: Math.ceil(win.month.length / 7)
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: monthCard.headH + 4
                            columns: 7
                            spacing: 6
                            Repeater {
                                model: win.month
                                delegate: Rectangle {
                                    required property var modelData
                                    readonly property bool on: modelData !== null && modelData.key === win.day
                                    readonly property real share: modelData ? modelData.total / win.monthMax : 0
                                    width: monthGrid.cellSize
                                    height: Math.min(monthGrid.cellSize,
                                        Math.floor((monthCard.height - monthCard.headH - 4 - monthCard.inset
                                                    - (monthGrid.rowsNeeded - 1) * monthGrid.spacing) / monthGrid.rowsNeeded))
                                    radius: 6
                                    // A blank before the 1st keeps its cell: a Grid
                                    // skips invisible children, which moved every
                                    // day to the first column.
                                    opacity: modelData !== null ? 1 : 0
                                    color: !modelData ? "transparent"
                                        : modelData.future ? Services.Colors.fillInset
                                        : Services.Colors.tint(Services.Colors.fillInset, Services.Colors.ghost,
                                                               modelData.total < 60 ? 0 : 0.2 + 0.8 * share)
                                    border.width: on ? 2 : (modelData && modelData.key === win.todayKey ? 1 : 0)
                                    border.color: on ? Services.Colors.snow : Services.Colors.mist
                                    Text {
                                        textFormat: Text.PlainText
                                        anchors.centerIn: parent
                                        text: modelData ? modelData.n : ""
                                        color: parent.share > 0.55 ? Services.Colors.onColor(Services.Colors.ghost)
                                                                   : Services.Colors.ash
                                        font.pixelSize: Services.Sizes.fsCaption
                                        font.family: "JetBrainsMono NF"
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        enabled: modelData !== null && !modelData.future
                                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                        onClicked: win.selected = modelData.key
                                    }
                                }
                            }
                        }
                    }

                    // ── The applications that had you ────────────────────
                    Card {
                        id: appsCard
                        index: 6
                        col: 0; row: 3; cw: 6; ch: 2
                        glyph: ""
                        name: Services.I18n.t("usage.apps")
                        note: win.dayData.apps.length > 8 ? "+" + (win.dayData.apps.length - 8) : ""

                        Grid {
                            id: appGrid
                            x: appsCard.inset
                            y: appsCard.headH
                            width: appsCard.width - appsCard.inset * 2
                            columns: 2
                            columnSpacing: 28
                            rowSpacing: 8
                            visible: win.dayData.apps.length > 0
                            readonly property real most: win.dayData.apps.length ? win.dayData.apps[0].secs : 1
                            Repeater {
                                model: win.dayData.apps.slice(0, 8)
                                delegate: Item {
                                    required property var modelData
                                    readonly property var app: Services.Usage.appOf(modelData.key)
                                    width: (appGrid.width - appGrid.columnSpacing) / 2
                                    height: 44

                                    Item {
                                        id: appIcon
                                        width: 20; height: 20
                                        Image {
                                            anchors.fill: parent
                                            visible: parent.parent.app !== null && parent.parent.app.icon !== ""
                                            source: {
                                                const a = parent.parent.app
                                                if (!a || !a.icon) return ""
                                                return a.icon.startsWith("/") ? ("file://" + a.icon)
                                                    : Quickshell.iconPath(a.icon, "application-x-executable")
                                            }
                                            sourceSize.width: 40
                                            sourceSize.height: 40
                                            fillMode: Image.PreserveAspectFit
                                        }
                                        Text {
                                            textFormat: Text.PlainText
                                            anchors.centerIn: parent
                                            visible: parent.parent.app === null || parent.parent.app.icon === ""
                                            text: Services.Windows.iconForClass(modelData.key)
                                            color: Services.Colors.mist
                                            font.pixelSize: 16
                                            font.family: "Material Symbols Rounded"
                                        }
                                    }
                                    Text {
                                        textFormat: Text.PlainText
                                        anchors.left: appIcon.right
                                        anchors.leftMargin: 10
                                        anchors.right: appTime.left
                                        anchors.rightMargin: 10
                                        anchors.verticalCenter: appIcon.verticalCenter
                                        text: Services.Usage.nameOf(modelData.key)
                                        color: Services.Colors.snow
                                        font.pixelSize: Services.Sizes.fsInput
                                        font.family: "JetBrainsMono NF"
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        textFormat: Text.PlainText
                                        id: appTime
                                        anchors.right: parent.right
                                        anchors.verticalCenter: appIcon.verticalCenter
                                        text: Services.Usage.span(modelData.secs)
                                        color: Services.Colors.mist
                                        font.pixelSize: Services.Sizes.fsInput
                                        font.bold: true
                                        font.family: "JetBrainsMono NF"
                                    }
                                    Widgets.TickMeter {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.bottom: parent.bottom
                                        height: 14
                                        mode: "level"
                                        tickW: 3
                                        gap: 2
                                        value: modelData.secs / appGrid.most
                                        color_: Services.Colors.ghost
                                    }
                                }
                            }
                        }
                        Text {
                            textFormat: Text.PlainText
                            anchors.centerIn: parent
                            visible: win.dayData.apps.length === 0
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
}
