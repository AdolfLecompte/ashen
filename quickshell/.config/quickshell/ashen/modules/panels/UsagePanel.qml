import Quickshell
import QtQuick
import "root:/services" as Services
import "root:/modules/widgets" as Widgets

// Where the time went: the day and its apps on top, the week and the month
// under them. No plates; hairlines split the sections, as in the clock panel.
PanelWindow {
    id: win
    anchors { top: true; left: true; right: true; bottom: true }
    screen: Services.Screens.active
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    mask: Widgets.ShellMask { winW: win.width; winH: win.height; keepRect: card.restRect }
    readonly property bool shown: Services.AppState.usageVisible
    visible: shown || closeDelay.running
    Timer { id: closeDelay; interval: card.closeMs }

    // ── The day on the board ─────────────────────────────────────────────
    function keyOf(d) { return Services.Usage.dayKey(d) }
    function dateOf(k) { const p = k.split("-"); return new Date(+p[0], +p[1] - 1, +p[2]) }
    function shift(k, n) { const d = win.dateOf(k); return win.keyOf(new Date(d.getFullYear(), d.getMonth(), d.getDate() + n)) }
    // Day count since the epoch, so a slide knows which way the day moved.
    function ordinal(k) { const p = k.split("-"); return Math.round(Date.UTC(+p[0], +p[1] - 1, +p[2]) / 86400000) }
    readonly property string todayKey: { win.beat; return win.keyOf(new Date()) }
    property string selected: ""
    // Same day of the next or previous month, clamped to its length and to today.
    function shiftMonth(key, n) {
        const d = win.dateOf(key)
        const last = new Date(d.getFullYear(), d.getMonth() + n + 1, 0).getDate()
        const t = new Date(d.getFullYear(), d.getMonth() + n, Math.min(d.getDate(), last))
        const k = win.keyOf(t)
        return k > win.todayKey ? win.todayKey : k
    }
    readonly property string day: win.selected !== "" ? win.selected : win.todayKey
    readonly property bool isToday: win.day === win.todayKey

    // The running span is booked once a minute; re-read often while open.
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

    // The week a day belongs to, in the locale's order.
    function weekOf(k) {
        win.beat; Services.Usage.revision
        const d = win.dateOf(k)
        const first = Services.I18n.locale.firstDayOfWeek % 7
        const back = (d.getDay() - first + 7) % 7
        const out = []
        for (let i = 0; i < 7; i++) {
            const dd = new Date(d.getFullYear(), d.getMonth(), d.getDate() - back + i)
            const dk = win.keyOf(dd)
            out.push({ key: dk, date: dd, total: win.totalOf(dk), future: dk > win.todayKey })
        }
        return out
    }
    // Average over the days of that week that have happened.
    function averageOf(wk) {
        const past = wk.filter(x => !x.future)
        return past.length ? past.reduce((a, x) => a + x.total, 0) / past.length : 0
    }
    readonly property var week: win.weekOf(win.day)
    readonly property real weekMax: Math.max(3600, ...win.week.map(x => x.total))

    readonly property real monthMax: {
        win.beat; Services.Usage.revision
        const d = win.dateOf(win.day)
        const n = new Date(d.getFullYear(), d.getMonth() + 1, 0).getDate()
        let m = 3600
        for (let i = 1; i <= n; i++) m = Math.max(m, win.totalOf(win.keyOf(new Date(d.getFullYear(), d.getMonth(), i))))
        return m
    }

    function dayTitle(k) {
        if (k === win.todayKey) return Services.I18n.t("usage.today")
        if (k === win.shift(win.todayKey, -1)) return Services.I18n.t("usage.yesterday")
        return Services.I18n.locale.toString(win.dateOf(k), "dddd d MMMM")
    }
    function hourLabel(h) {
        return Services.Prefs.clock24h
            ? (h < 10 ? "0" : "") + h + ":00"
            : (h % 12 === 0 ? 12 : h % 12) + (h < 12 ? " am" : " pm")
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

        readonly property int gap: 16
        readonly property int pad: 22
        readonly property int headH: 26
        readonly property int innerW: 1040
        readonly property int dayW: 600
        readonly property int topH: 280
        readonly property int bottomH: 262
        readonly property int monthW: 392
                readonly property int appRows: 6
        // Gutter each hairline sits in.
        readonly property int rule: gap * 2 + 1
        openW: innerW + pad * 2
        openH: headH + gap + topH + rule + bottomH + pad * 2
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

                // What the day and its apps are drawn from: follows `win.day`
                // on the slide's commit, never bound.
                property string shownDay: ""
                Component.onCompleted: { board.shownDay = win.day; board.lastWeek = win.week[0].key }
                readonly property string dayKey: board.shownDay !== "" ? board.shownDay : win.day
                readonly property var info: {
                    win.beat; Services.Usage.revision
                    return Services.Usage.day(board.dayKey)
                }
                readonly property var shownWeek: win.weekOf(board.dayKey)
                readonly property real average: win.averageOf(board.shownWeek)
                readonly property real delta: board.info.total - board.average

                // Bars and curve grow into the new day after the swap.
                property real grow: 1
                NumberAnimation {
                    id: growAnim
                    target: board; property: "grow"; from: 0; to: 1
                    duration: Services.Sizes.msPanel
                    easing.type: Services.Sizes.easeOut
                }
                // Week bars rise: all of them on a new week, only the picked one
                // on a new day inside the same week.
                property real weekGrow: 1
                property real dayGrow: 1
                property string lastWeek: ""
                NumberAnimation {
                    id: weekRise
                    target: board; property: "weekGrow"; from: 0; to: 1
                    duration: Services.Sizes.msPanel
                    easing.type: Services.Sizes.easeOut
                }
                NumberAnimation {
                    id: dayRise
                    target: board; property: "dayGrow"; from: 0; to: 1
                    duration: Services.Sizes.msPanel
                    easing.type: Services.Sizes.easeOut
                }
                Connections {
                    target: win
                    function onDayChanged() {
                        const wk = win.week[0].key
                        if (wk !== board.lastWeek) {
                            board.lastWeek = wk
                            dayRise.stop(); board.dayGrow = 1
                            weekRise.restart()
                        } else {
                            dayRise.restart()
                        }
                    }
                }
                Widgets.SlideSwap {
                    id: daySlide
                    axis: "horizontal"
                    travel: 30
                    index: win.ordinal(win.day)
                    onCommit: {
                        if (board.shownDay === win.day) return
                        board.shownDay = win.day
                        growAnim.restart()
                    }
                }

                // ── The day you are looking at ───────────────────────────
                Item {
                    x: card.pad
                    y: card.pad
                    width: card.innerW
                    height: card.headH
                    opacity: board.stage(0)

                    Widgets.CtlChip {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        glyph: ""
                        tip: Services.I18n.t("tip.prev")
                        size: 26
                        glyphSize: 16
                        onTriggered: win.selected = win.shift(win.day, -1)
                    }
                    Text {
                        textFormat: Text.PlainText
                        anchors.centerIn: parent
                        opacity: daySlide.fade
                        transform: Translate { x: daySlide.offX }
                        text: win.dayTitle(board.dayKey).toUpperCase()
                        color: Services.Colors.snow
                        font.pixelSize: 13
                        font.bold: true
                        font.letterSpacing: 2
                        font.family: "JetBrainsMono NF"
                    }
                    Widgets.CtlChip {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        glyph: ""
                        tip: Services.I18n.t("tip.next")
                        size: 26
                        glyphSize: 16
                        available: !win.isToday
                        onTriggered: if (!win.isToday) win.selected = win.shift(win.day, 1)
                    }
                }

                Item {
                    x: card.pad
                    y: card.pad + card.headH + card.gap
                    width: card.innerW
                    height: card.topH + card.rule + card.bottomH

                    // ── The day: its total and its hours ─────────────────
                    Item {
                        id: dayArea
                        width: card.dayW
                        height: card.topH
                        opacity: board.stage(1) * daySlide.fade
                        transform: Translate { x: daySlide.offX }

                        Text {
                            textFormat: Text.PlainText
                            id: dayGlyph
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
                            text: Services.Usage.span(board.info.total)
                            color: Services.Colors.snow
                            font.pixelSize: 40
                            font.bold: true
                            font.family: "JetBrainsMono NF"
                        }
                        // Against the week's average: which way, and how far.
                        Row {
                            anchors.right: parent.right
                            anchors.verticalCenter: dayTotal.verticalCenter
                            spacing: 4
                            visible: board.average >= 60
                            Text {
                                textFormat: Text.PlainText
                                anchors.verticalCenter: parent.verticalCenter
                                visible: Math.abs(board.delta) >= 60
                                text: board.delta > 0 ? "" : ""
                                color: board.delta > 0 ? Services.Colors.ghost : Services.Colors.mist
                                font.pixelSize: 18
                                font.family: "Material Symbols Rounded"
                            }
                            Text {
                                textFormat: Text.PlainText
                                anchors.verticalCenter: parent.verticalCenter
                                text: Math.abs(board.delta) < 60 ? "=" : Services.Usage.span(Math.abs(board.delta))
                                color: Services.Colors.snow
                                font.pixelSize: 14
                                font.bold: true
                                font.family: "JetBrainsMono NF"
                            }
                        }
                        Text {
                            textFormat: Text.PlainText
                            anchors.top: dayTotal.bottom
                            text: Services.I18n.t("usage.average") + "  " + Services.Usage.span(board.average)
                                + "   ·   "
                                + Services.I18n.locale.toString(board.shownWeek[0].date, "d MMM") + " – "
                                + Services.I18n.locale.toString(board.shownWeek[6].date, "d MMM")
                            color: Services.Colors.ash
                            font.pixelSize: 11
                            font.family: "JetBrainsMono NF"
                        }

                        // The hours, scaled to the busiest one and labelled there.
                        Item {
                            id: hoursBox
                            width: parent.width
                            anchors.bottom: parent.bottom
                            height: 160
                            readonly property var hours: {
                                const h = board.info.hours || []
                                return h.length === 24 ? h : new Array(24).fill(0)
                            }
                            readonly property int peak: {
                                let p = 0
                                for (let i = 1; i < 24; i++) if (hoursBox.hours[i] > hoursBox.hours[p]) p = i
                                return p
                            }
                            readonly property real ceiling: Math.max(10, hoursBox.hours[hoursBox.peak] / 60)

                            Widgets.Trend {
                                id: hoursCurve
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.topMargin: 16
                                height: 124
                                stepped: true
                                values: hoursBox.hours.map(s => s / 60)
                                maxValue: hoursBox.ceiling
                                reveal: board.grow
                            }
                            Text {
                                textFormat: Text.PlainText
                                visible: hoursBox.hours[hoursBox.peak] >= 60
                                opacity: board.grow
                                readonly property real fx: hoursCurve.xOf(hoursBox.peak)
                                x: Math.max(0, Math.min(hoursBox.width - width, fx - width / 2))
                                y: hoursCurve.y + hoursCurve.yOf(hoursBox.hours[hoursBox.peak] / 60) - height - 2
                                text: Services.Usage.span(hoursBox.hours[hoursBox.peak])
                                color: Services.Colors.snow
                                font.pixelSize: 10
                                font.bold: true
                                font.family: "JetBrainsMono NF"
                            }
                            Repeater {
                                model: [0, 6, 12, 18]
                                delegate: Text {
                                    textFormat: Text.PlainText
                                    required property int modelData
                                    x: Math.max(0, Math.min(hoursBox.width - width,
                                                            hoursBox.width * (modelData + 0.5) / 24 - width / 2))
                                    anchors.top: hoursCurve.bottom
                                    anchors.topMargin: 5
                                    text: win.hourLabel(modelData)
                                    color: Services.Colors.ash
                                    font.pixelSize: 9
                                    font.family: "JetBrainsMono NF"
                                }
                            }
                        }
                    }

                    Rectangle {
                        x: card.dayW + card.gap
                        width: 1
                        height: card.topH
                        color: Services.Colors.fillInset
                        opacity: board.stage(1)
                    }

                    // ── What filled it ───────────────────────────────────
                    Item {
                        id: appsCol
                        x: card.dayW + card.rule
                        width: card.innerW - x
                        height: card.topH
                        opacity: board.stage(2) * daySlide.fade
                        transform: Translate { x: daySlide.offX }
                        readonly property real most: board.info.apps.length ? board.info.apps[0].secs : 1

                        Text {
                            textFormat: Text.PlainText
                            id: appsTitle
                            height: 26
                            verticalAlignment: Text.AlignVCenter
                            text: Services.I18n.t("usage.apps").toUpperCase()
                            color: Services.Colors.snow
                            font.pixelSize: 14
                            font.bold: true
                            font.letterSpacing: 1.4
                            font.family: "JetBrainsMono NF"
                        }
                        Column {
                            anchors.top: appsTitle.bottom
                            anchors.topMargin: 10
                            width: parent.width
                            spacing: 8
                            visible: board.info.apps.length > 0
                            Repeater {
                                model: board.info.apps.slice(0, card.appRows)
                                delegate: Item {
                                    id: row
                                    required property var modelData
                                    readonly property var app: Services.Usage.appOf(modelData.key)
                                    width: parent.width
                                    height: 34

                                    Rectangle {
                                        id: badge
                                        anchors.left: parent.left
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 34
                                        height: 34
                                        radius: Services.Sizes.innerR
                                        color: Services.Colors.fillLine
                                        Image {
                                            id: icon
                                            anchors.centerIn: parent
                                            width: 22
                                            height: 22
                                            source: {
                                                const a = row.app
                                                if (!a || !a.icon) return ""
                                                return a.icon.startsWith("/") ? ("file://" + a.icon)
                                                    : Quickshell.iconPath(a.icon, "application-x-executable")
                                            }
                                            sourceSize.width: 44
                                            sourceSize.height: 44
                                            fillMode: Image.PreserveAspectFit
                                            asynchronous: true
                                            visible: status === Image.Ready
                                        }
                                        Text {
                                            textFormat: Text.PlainText
                                            anchors.centerIn: parent
                                            visible: icon.status !== Image.Ready
                                            text: Services.Windows.iconForClass(row.modelData.key)
                                            color: Services.Colors.ghost
                                            font.pixelSize: 18
                                            font.family: "Material Symbols Rounded"
                                        }
                                    }
                                    Text {
                                        textFormat: Text.PlainText
                                        anchors.left: badge.right
                                        anchors.leftMargin: 10
                                        anchors.right: appTime.left
                                        anchors.rightMargin: 8
                                        anchors.top: parent.top
                                        text: Services.Usage.nameOf(row.modelData.key)
                                        color: Services.Colors.snow
                                        font.pixelSize: Services.Sizes.fsBody
                                        font.bold: true
                                        font.family: "JetBrainsMono NF"
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        textFormat: Text.PlainText
                                        id: appTime
                                        anchors.right: parent.right
                                        anchors.top: parent.top
                                        text: Services.Usage.span(row.modelData.secs)
                                        color: Services.Colors.mist
                                        font.pixelSize: Services.Sizes.fsCaption
                                        font.bold: true
                                        font.family: "JetBrainsMono NF"
                                    }
                                    Rectangle {
                                        anchors.left: badge.right
                                        anchors.leftMargin: 10
                                        anchors.right: parent.right
                                        anchors.bottom: parent.bottom
                                        height: 10
                                        radius: 5
                                        color: Services.Colors.fillLine
                                        Rectangle {
                                            width: Math.max(parent.height, parent.width * row.modelData.secs / appsCol.most) * board.grow
                                            height: parent.height
                                            radius: parent.radius
                                            color: Services.Colors.ghost
                                            gradient: Services.Prefs.useGradients ? Services.Colors.accentGradient : null
                                        }
                                    }
                                }
                            }
                        }
                        Text {
                            textFormat: Text.PlainText
                            anchors.centerIn: parent
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            visible: board.info.apps.length === 0
                            text: win.emptyLine
                            color: Services.Colors.mist
                            font.pixelSize: 12
                            font.family: "JetBrainsMono NF"
                        }
                    }

                    Rectangle {
                        y: card.topH + card.gap
                        width: card.innerW
                        height: 1
                        color: Services.Colors.fillInset
                        opacity: board.stage(3)
                    }

                    // ── The week: a track per day, filled from the foot ───────
                    Row {
                        id: bars
                        y: card.topH + card.rule
                        width: card.innerW - card.monthW - card.rule
                        height: card.bottomH
                        opacity: board.stage(3)
                        Repeater {
                            model: win.week
                            delegate: Item {
                                id: wd
                                required property var modelData
                                readonly property bool on: modelData.key === win.day
                                width: bars.width / 7
                                height: bars.height

                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.top: parent.top
                                    anchors.topMargin: 6
                                    anchors.bottom: wdLabel.top
                                    anchors.bottomMargin: 10
                                    width: 34
                                    radius: 12
                                    color: Services.Colors.fillLine
                                    opacity: wd.modelData.future ? 0.4 : 1
                                    Rectangle {
                                        anchors.bottom: parent.bottom
                                        width: parent.width
                                        radius: parent.radius
                                        height: (wd.modelData.total < 60 ? 0
                                            : Math.max(parent.width, parent.height * wd.modelData.total / win.weekMax))
                                            * board.weekGrow * (wd.on ? board.dayGrow : 1)
                                        color: wd.on ? Services.Colors.ghost
                                             : Services.Colors.tint(Services.Colors.fillLine, Services.Colors.ghost, 0.45)
                                        gradient: Services.Prefs.useGradients && wd.on ? Services.Colors.accentGradientV : null
                                        Behavior on color { Widgets.ColorAnim { speed: Services.Sizes.msMicro } }
                                    }
                                }
                                Text {
                                    textFormat: Text.PlainText
                                    id: wdLabel
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottom: parent.bottom
                                    text: Services.I18n.locale.dayName(wd.modelData.date.getDay(), Locale.ShortFormat).replace(".", "").toUpperCase()
                                    color: wd.on ? Services.Colors.snow : Services.Colors.ash
                                    font.pixelSize: 11
                                    font.bold: wd.on
                                    font.family: "JetBrainsMono NF"
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    enabled: !wd.modelData.future
                                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    onClicked: win.selected = wd.modelData.key
                                }
                            }
                        }
                    }

                    Rectangle {
                        x: card.innerW - card.monthW - card.gap - 1
                        y: card.topH + card.rule
                        width: 1
                        height: card.bottomH
                        color: Services.Colors.fillInset
                        opacity: board.stage(4)
                    }

                    // ── The month, as the clock's calendar ───────────────
                    Item {
                        id: monthCol
                        x: card.innerW - card.monthW
                        y: card.topH + card.rule
                        width: card.monthW
                        height: card.bottomH
                        opacity: board.stage(4)
                        readonly property date shownDate: win.dateOf(win.day)
                        readonly property int nowIndex: { const t = win.dateOf(win.todayKey); return t.getFullYear() * 12 + t.getMonth() }

                        Column {
                            id: calStack
                            width: parent.width
                            spacing: 10

                            Item {
                                width: parent.width
                                height: 26
                                Text {
                                    textFormat: Text.PlainText
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: (Services.Time.monthName(grid.curMonth) + " " + grid.curYear).toUpperCase()
                                    color: Services.Colors.snow
                                    font.pixelSize: 14
                                    font.bold: true
                                    font.letterSpacing: 1.4
                                    font.family: "JetBrainsMono NF"
                                    opacity: monthSlide.fade
                                    transform: Translate { x: monthSlide.offX }
                                }
                                Row {
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: Services.Sizes.btnGap
                                    Widgets.CtlChip {
                                        glyph: ""
                                        tip: Services.I18n.t("tip.prev")
                                        size: 28
                                        glyphSize: 17
                                        onTriggered: win.selected = win.shiftMonth(win.day, -1)
                                    }
                                    Widgets.CtlChip {
                                        glyph: ""
                                        tip: Services.I18n.t("tip.today")
                                        size: 28
                                        glyphSize: 15
                                        active: win.isToday
                                        onTriggered: win.selected = ""
                                    }
                                    Widgets.CtlChip {
                                        glyph: ""
                                        tip: Services.I18n.t("tip.next")
                                        size: 28
                                        glyphSize: 17
                                        available: grid.monthIndex < monthCol.nowIndex
                                        onTriggered: if (grid.monthIndex < monthCol.nowIndex) win.selected = win.shiftMonth(win.day, 1)
                                    }
                                }
                            }

                            Widgets.SlideSwap {
                                id: monthSlide
                                axis: "horizontal"
                                travel: 34
                                index: grid.monthIndex
                                onCommit: grid.shownIndex = grid.monthIndex
                            }

                            Row {
                                width: parent.width
                                Repeater {
                                    model: 7
                                    Text {
                                        textFormat: Text.PlainText
                                        required property int index
                                        width: calStack.width / 7
                                        horizontalAlignment: Text.AlignHCenter
                                        text: Services.Time.dayShort(index).replace(".", "").toUpperCase()
                                        color: Services.Colors.ash
                                        font.pixelSize: 11
                                        font.family: "JetBrainsMono NF"
                                    }
                                }
                            }

                            Widgets.MonthGrid {
                                id: grid
                                width: parent.width
                                cellW: calStack.width / 7 - 3
                                cellSize: 30
                                monthIndex: monthCol.shownDate.getFullYear() * 12 + monthCol.shownDate.getMonth()
                                Component.onCompleted: shownIndex = monthIndex
                                selectedDay: grid.shownIndex === grid.monthIndex ? monthCol.shownDate.getDate() : 0
                                opacity: monthSlide.fade
                                transform: Translate { x: monthSlide.offX }
                                levelOf: function(day) {
                                    const k = win.keyOf(new Date(grid.curYear, grid.curMonth, day))
                                    if (k > win.todayKey) return -1
                                    const t = win.totalOf(k)
                                    return t < 60 ? 0 : t / win.monthMax
                                }
                                onPicked: day => win.selected = win.keyOf(new Date(grid.curYear, grid.curMonth, day))
                            }
                        }
                    }
                }
            }
        }
    }
}
