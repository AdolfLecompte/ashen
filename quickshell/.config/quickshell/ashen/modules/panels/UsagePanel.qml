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

        // The day leads: its total and its hours on the left, the applications
        // that filled it on the right, and the week and the month underneath to
        // walk to another day. The shell's own pieces throughout -- the clock
        // panel's hourly curve, a slider track stood on end for each day of the
        // week, the clock's calendar, the storage bar.
        readonly property int gap: 12
        readonly property int pad: 22
        readonly property int headH: 36
        readonly property int innerW: 1040
        readonly property int dayW: 600
        readonly property int topH: 300
        readonly property int bottomH: 250
        readonly property int monthW: 392
        readonly property int appRowH: 44
        readonly property int appRows: 6
        openW: innerW + pad * 2
        openH: headH + gap + topH + gap + bottomH + pad * 2
        cardRadius: 22

        body: Component {
            Item {
                id: board

                readonly property Item glyphTarget: null
                readonly property Item labelTarget: null

                function stage(i) {
                    const start = Math.min(0.5, i * 0.09)
                    return Math.max(0, Math.min(1, (card.contentAmt - start) / (1 - start)))
                }

                component Plate: Rectangle {
                    id: pl
                    property int index: 0
                    radius: Services.Sizes.cardLgR
                    color: Services.Colors.plate
                    clip: true
                    opacity: board.stage(index)
                    transform: Translate { y: (1 - board.stage(pl.index)) * 12 }
                }

                // ── The day you are looking at ───────────────────────────
                Item {
                    x: card.pad
                    y: card.pad
                    width: card.innerW
                    height: card.headH
                    opacity: board.stage(0)

                    Widgets.IconButton {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        glyph: ""
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
                        glyph: ""
                        available: !win.isToday
                        onActivated: if (!win.isToday) win.selected = win.shift(win.day, 1)
                    }
                }

                Item {
                    x: card.pad
                    y: card.pad + card.headH + card.gap
                    width: card.innerW
                    height: card.topH + card.gap + card.bottomH

                    // ── The day: its total and its hours ─────────────────
                    Plate {
                        id: dayPlate
                        index: 1
                        width: card.dayW
                        height: card.topH

                        Text {
                            textFormat: Text.PlainText
                            id: dayGlyph
                            x: 22
                            anchors.verticalCenter: dayTotal.verticalCenter
                            text: ""
                            color: Services.Colors.ghost
                            font.pixelSize: 34
                            font.family: "Material Symbols Rounded"
                        }
                        Text {
                            textFormat: Text.PlainText
                            id: dayTotal
                            anchors.left: dayGlyph.right
                            anchors.leftMargin: 10
                            y: 18
                            text: Services.Usage.span(win.dayData.total)
                            color: Services.Colors.snow
                            font.pixelSize: 44
                            font.bold: true
                            font.family: "JetBrainsMono NF"
                        }
                        // Against the week's average: the arrow says which way,
                        // the number how far.
                        Row {
                            anchors.right: parent.right
                            anchors.rightMargin: 22
                            anchors.verticalCenter: dayTotal.verticalCenter
                            spacing: 4
                            visible: win.average >= 60
                            Text {
                                textFormat: Text.PlainText
                                anchors.verticalCenter: parent.verticalCenter
                                visible: Math.abs(win.delta) >= 60
                                text: win.delta > 0 ? "" : ""
                                color: win.delta > 0 ? Services.Colors.ghost : Services.Colors.mist
                                font.pixelSize: 22
                                font.family: "Material Symbols Rounded"
                            }
                            Text {
                                textFormat: Text.PlainText
                                anchors.verticalCenter: parent.verticalCenter
                                text: Math.abs(win.delta) < 60 ? "=" : Services.Usage.span(Math.abs(win.delta))
                                color: Services.Colors.snow
                                font.pixelSize: Services.Sizes.fsSectionTitle
                                font.bold: true
                                font.family: "JetBrainsMono NF"
                            }
                        }
                        Text {
                            textFormat: Text.PlainText
                            x: 22
                            anchors.top: dayTotal.bottom
                            text: Services.I18n.t("usage.average") + "  " + Services.Usage.span(win.average)
                                + "   ·   "
                                + (win.week.length
                                   ? Services.I18n.locale.toString(win.week[0].date, "d MMM") + " – "
                                     + Services.I18n.locale.toString(win.week[6].date, "d MMM")
                                   : "")
                            color: Services.Colors.ash
                            font.pixelSize: Services.Sizes.fsBody
                            font.family: "JetBrainsMono NF"
                        }

                        // The hours of the day, stepped: each hour holds its own
                        // level, the way the clock panel draws the weather. An
                        // hour never had more than sixty minutes in it.
                        Item {
                            id: hoursBox
                            x: 22
                            width: parent.width - 44
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 16
                            height: 150
                            readonly property var hours: {
                                const h = win.dayData.hours || []
                                return h.length === 24 ? h : new Array(24).fill(0)
                            }
                            Widgets.Trend {
                                id: hoursCurve
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                height: 124
                                stepped: true
                                values: hoursBox.hours.map(s => s / 60)
                                maxValue: 60
                            }
                            Repeater {
                                model: [0, 6, 12, 18]
                                delegate: Text {
                                    textFormat: Text.PlainText
                                    required property int modelData
                                    x: Math.max(0, Math.min(hoursBox.width - width,
                                                            hoursBox.width * (modelData + 0.5) / 24 - width / 2))
                                    anchors.top: hoursCurve.bottom
                                    anchors.topMargin: 6
                                    text: Services.Prefs.clock24h
                                        ? (modelData < 10 ? "0" : "") + modelData + ":00"
                                        : (modelData % 12 === 0 ? 12 : modelData % 12) + (modelData < 12 ? " am" : " pm")
                                    color: Services.Colors.ash
                                    font.pixelSize: Services.Sizes.fsMeta
                                    font.family: "JetBrainsMono NF"
                                }
                            }
                        }
                    }

                    // ── What filled it ───────────────────────────────────
                    Plate {
                        id: appsPlate
                        index: 2
                        x: card.dayW + card.gap
                        width: card.innerW - x
                        height: card.topH
                        readonly property real most: win.dayData.apps.length ? win.dayData.apps[0].secs : 1

                        Column {
                            anchors.fill: parent
                            anchors.margins: 16
                            anchors.leftMargin: 20
                            anchors.rightMargin: 20
                            visible: win.dayData.apps.length > 0
                            Repeater {
                                model: win.dayData.apps.slice(0, card.appRows)
                                delegate: Item {
                                    required property var modelData
                                    readonly property var app: Services.Usage.appOf(modelData.key)
                                    width: parent.width
                                    height: card.appRowH

                                    Item {
                                        id: appIcon
                                        y: 4
                                        width: 18; height: 18
                                        Image {
                                            anchors.fill: parent
                                            visible: parent.parent.app !== null && parent.parent.app.icon !== ""
                                            source: {
                                                const a = parent.parent.app
                                                if (!a || !a.icon) return ""
                                                return a.icon.startsWith("/") ? ("file://" + a.icon)
                                                    : Quickshell.iconPath(a.icon, "application-x-executable")
                                            }
                                            sourceSize.width: 36
                                            sourceSize.height: 36
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
                                        font.pixelSize: Services.Sizes.fsBody
                                        font.family: "JetBrainsMono NF"
                                    }
                                    // The storage bar: a track and its share.
                                    Rectangle {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.top: appIcon.bottom
                                        anchors.topMargin: 8
                                        height: 6
                                        radius: 3
                                        color: Services.Colors.fillLine
                                        Rectangle {
                                            width: Math.max(parent.height, parent.width * modelData.secs / appsPlate.most)
                                            height: parent.height
                                            radius: parent.radius
                                            color: Services.Colors.ghost
                                            gradient: Services.Prefs.useGradients ? Services.Colors.accentGradient : null
                                            Behavior on width { Widgets.Anim {} }
                                        }
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

                    // ── The week, as bars ────────────────────────────────
                    // Each day is a track stood on end with its share filled
                    // from the foot -- the slider's own shape. The day on the
                    // board in the accent; press a bar to look at that day.
                    Plate {
                        id: weekPlate
                        index: 3
                        y: card.topH + card.gap
                        width: card.innerW - card.monthW - card.gap
                        height: card.bottomH
                        Row {
                            id: bars
                            anchors.fill: parent
                            anchors.margins: 18
                            Repeater {
                                model: win.week
                                delegate: Item {
                                    required property var modelData
                                    readonly property bool on: modelData.key === win.day
                                    width: bars.width / 7
                                    height: bars.height

                                    // A plain bar chart: each day a bar as tall as its
                                    // share of the busiest day, and nothing else.
                                    Rectangle {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        anchors.bottom: dayLabel.top
                                        anchors.bottomMargin: 10
                                        readonly property real room: parent.height - dayLabel.height - 10
                                        width: Math.min(44, parent.width - 16)
                                        height: modelData.total < 60 ? 0 : Math.max(4, room * modelData.total / win.weekMax)
                                        radius: 6
                                        color: parent.on ? Services.Colors.ghost
                                             : Services.Colors.tint(Services.Colors.fillLine, Services.Colors.ghost, 0.45)
                                        Behavior on height { Widgets.Anim {} }
                                    }
                                    Text {
                                        textFormat: Text.PlainText
                                        id: dayLabel
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        anchors.bottom: parent.bottom
                                        text: Services.I18n.locale.dayName(modelData.date.getDay(), Locale.ShortFormat)
                                        color: parent.on ? Services.Colors.snow : Services.Colors.mist
                                        font.pixelSize: Services.Sizes.fsBody
                                        font.bold: parent.on
                                        font.family: "JetBrainsMono NF"
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

                    // ── The month, as the clock's calendar ───────────────
                    Plate {
                        id: monthPlate
                        index: 4
                        x: card.innerW - card.monthW
                        y: card.topH + card.gap
                        width: card.monthW
                        height: card.bottomH
                        readonly property date shownDate: win.dateOf(win.day)
                        Text {
                            textFormat: Text.PlainText
                            id: monthTitle
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: 14
                            text: Services.I18n.locale.toString(monthPlate.shownDate, "MMMM")
                            color: Services.Colors.mist
                            font.pixelSize: Services.Sizes.fsBody
                            font.family: "JetBrainsMono NF"
                        }
                        Widgets.MonthGrid {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: monthTitle.bottom
                            anchors.topMargin: 10
                            reserveRows: true
                            cellW: Math.floor((monthPlate.width - 28) / 7) - 3
                            cellSize: 30
                            monthIndex: monthPlate.shownDate.getFullYear() * 12 + monthPlate.shownDate.getMonth()
                            shownIndex: monthIndex
                            selectedDay: monthPlate.shownDate.getDate()
                            levelOf: function(day) {
                                const d = monthPlate.shownDate
                                const k = win.keyOf(new Date(d.getFullYear(), d.getMonth(), day))
                                if (k > win.todayKey) return -1
                                const t = win.totalOf(k)
                                return t < 60 ? 0 : t / win.monthMax
                            }
                            onPicked: day => {
                                const d = monthPlate.shownDate
                                win.selected = win.keyOf(new Date(d.getFullYear(), d.getMonth(), day))
                            }
                        }
                    }
                }
            }
        }
    }
}
