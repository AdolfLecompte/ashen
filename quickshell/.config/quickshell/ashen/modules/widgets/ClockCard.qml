import QtQuick
import QtQuick.Layouts
import "root:/services" as Services

// Clock, calendar and weather as one card. Content only, no background: `pad`
// is what the caller's plate is expected to leave. The pieces the bar pill also
// shows can be left laid out but undrawn, as targets for the panel's morph.
Item {
    id: root

    // ── Metrics ─────────────────────────────────────────────────────────
    readonly property real clockW: 350
    readonly property real weatherW: 330
    readonly property real gap: 24
    readonly property real pad: 20
    readonly property real contentW: 1100
    // Hugs the tallest column, which is the timer: header 184 + the wheels and
    // their two rows. Any slack past that piles up as dead space at the bottom --
    // the columns are anchored to the top, not spread down the card.
    readonly property real contentH: 400

    implicitWidth: contentW
    implicitHeight: contentH
    width: implicitWidth
    height: implicitHeight

    // ── Morph support ───────────────────────────────────────────────────
    property bool ghostShared: false
    readonly property real sharedOpacity: ghostShared ? 0 : 1
    property real extrasOpacity: 1
    // Where each part of the card is in the arrival, when whoever opened it
    // hands one in. Without it every part shares a single fade, which is what a
    // card looks like when it is a picture of a card.
    property var stageFn: null
    function beat(i) {
        return root.stageFn ? root.stageFn(i) * root.extrasOpacity : root.extrasOpacity
    }

    // ── Clock ───────────────────────────────────────────────────────────
    // One formatted string, exactly the pill's, so the two can be the same
    // object growing rather than two different clocks crossfading.
    readonly property string timeText: Services.Time.fmt(Services.Prefs.timeFormat)
    readonly property string dateText: Services.Time.fmt("dddd, MMMM d")
    readonly property date now: Services.Time.now

    // The column always reserves room for the longest clock there is: twelve
    // hour, with seconds and a meridiem. Sizing the type to *that* and centring
    // it means the digits are as large as they can ever be, and changing the
    // format moves nothing — a shorter string just sits in the same box.
    Text {
        id: probe
        visible: false
        text: "00:00:00 AM"
        font.pixelSize: 100
        font.bold: true
        font.family: "JetBrainsMono NF"
    }
    readonly property real clockPx: Math.max(20,
        Math.floor(100 * (clockW - 30) / Math.max(1, probe.width)))

    // ── Where the shared pieces sit, in this item's coordinates ─────────
    readonly property real timeCX: row.x + clockCol.x + timeT.x + timeT.width / 2
    readonly property real timeCY: row.y + clockCol.y + timeT.y + timeT.height / 2
    readonly property real dateCX: row.x + clockCol.x + head.x + dateT.x + dateT.width / 2
    readonly property real dateCY: row.y + clockCol.y + head.y + dateT.y + dateT.height / 2
    readonly property real wIconCX: row.x + wxCol.x + wxNow.x + wIcon.x + wIcon.width / 2
    readonly property real wIconCY: row.y + wxCol.y + wxNow.y + wIcon.y + wIcon.height / 2
    readonly property real wTempCX: row.x + wxCol.x + wxNow.x + wTemp.x + wTemp.width / 2
    readonly property real wTempCY: row.y + wxCol.y + wxNow.y + wTemp.y + wTemp.height / 2

    // Which tool is showing under the clock. Held in AppState so the bar's
    // readout can open the panel straight on its tool, and so a tool you left
    // running is where you left it next time.
    property int tab: Services.AppState.clockTab

    // How far through the day it is -- what is left of the light is measured
    // against it. Off `now`, so it ticks with everything else on this card
    // rather than keeping a clock of its own.
    readonly property real dayFrac:
        (now.getHours() * 3600 + now.getMinutes() * 60 + now.getSeconds()) / 86400

    // Which day of the strip the weather column is showing. 0 is today, and
    // today is the live reading -- every other day is a forecast summary.
    property int selDay: 0
    // What the column is DRAWN from: follows `selDay` on the slide's commit, so
    // the figures change halfway through, off screen. Assigned, never bound --
    // a binding would swap them on the click and the sweep would carry the new
    // day out and back in.
    property int shownDay: 0
    // The sweep itself: the same one the calendar's months ride on.
    SlideSwap {
        id: daySlide
        axis: "horizontal"
        travel: 30
        index: root.selDay
        onCommit: root.shownDay = root.selDay
    }
    readonly property real wxSlideX: daySlide.offX
    readonly property real wxSlideFade: daySlide.fade

    readonly property bool live: shownDay === 0
    readonly property var day: Services.Weather.forecast[shownDay] || null
    // A future day has no "now", so its curve is its own 24 hours; today's
    // starts at this hour, which is what the card has always drawn.
    readonly property var hours: live || !day
        ? (Services.Weather.hourly || [])
        : Services.Weather.hoursFor(day.date)

    // What the column says, from whichever day is picked. Today reads live;
    // a forecast day has no reading of "now", so its headline is the high.
    readonly property string wxIcon: live || !day ? Services.Weather.icon : day.icon
    readonly property string wxTemp: live || !day
        ? Services.Weather.temp : Services.Weather.tempString(day.maxC)
    // Just the condition: which day it is now has a title of its own above the
    // reading, so repeating it here said the same word twice.
    readonly property string wxCondition: live || !day
        ? Services.Weather.condition : day.condition
    // Same shape every day. The city moved up to the title, so this line is
    // only what the air feels like. A forecast day has no apparent temperature
    // of "now", so it uses its high, which is the number the headline pairs with.
    readonly property string wxSub: Services.I18n.t("weather.feels",
        { t: live || !day ? Services.Weather.feels
                          : Services.Weather.tempString(day.feelsC) })
    readonly property int wxHumidity: live || !day ? Services.Weather.humidity : day.humidity
    readonly property int wxWindKph: live || !day ? Services.Weather.windKph : day.windKph
    readonly property int wxWindDir: live || !day ? Services.Weather.windDir : day.windDir
    readonly property int wxUv: live || !day ? Services.Weather.uvMax : day.uv
    readonly property int wxRain: live || !day ? Services.Weather.rainProb : day.rain
    readonly property string wxRange: day
        ? Services.Weather.degrees(day.minC) + " / " + Services.Weather.degrees(day.maxC) : ""

    // The title over the reading: TODAY, or the day and its date. Built from
    // the date's FIELDS -- new Date("2026-08-15") is midnight UTC, which west
    // of Greenwich reads back as the day before.
    readonly property string wxDayTitle: {
        if (!day) return ""
        if (shownDay === 0) return Services.I18n.t("time.today").toUpperCase()
        const p = String(day.date).split("-")
        if (p.length < 3) return day.label.toUpperCase()
        const d = new Date(parseInt(p[0]), parseInt(p[1]) - 1, parseInt(p[2]))
        return day.label.toUpperCase() + " " + parseInt(p[2]) + " "
             + Services.Time.fmtOf(d, "MMM").toUpperCase()
    }

    // Pick a day back to today whenever the reading underneath it changes:
    // a new city (or a re-fetch that shortens the strip) would otherwise leave
    // the column showing a day that is no longer the one it named.
    onDayChanged: if (!day) { selDay = 0; shownDay = 0 }
    Connections {
        target: Services.Weather
        function onCityChanged() { root.selDay = 0 }
    }

    // The 24 hours folded into eight plateaus of three. Drawn hour by hour the
    // joints are 14 px apart and any rounding swallows the step, which put the
    // realistic curve back; three hours to a plateau is what makes it read as
    // levels the day sits at.
    readonly property var hourSteps: {
        const out = []
        for (let i = 0; i < hours.length; i += 3) {
            let sum = 0, n = 0
            for (let k = i; k < Math.min(i + 3, hours.length); k++) { sum += hours[k].tempC; n++ }
            if (n === 0) continue
            out.push({ i: out.length, t: Math.round(sum / n),
                       label: root.shortHour(hours[i].label) })
        }
        return out
    }
    readonly property int stepMin: {
        let m = 999
        for (const s of hourSteps) if (s.t < m) m = s.t
        return m === 999 ? 0 : m
    }
    readonly property int stepMax: {
        let m = -999
        for (const s of hourSteps) if (s.t > m) m = s.t
        return m === -999 ? 0 : m
    }

    // Three numbers on the curve and no more: now, the warmest hour and the
    // coldest. Eight of them across a day that moves seven degrees was a line
    // buried under its own labels -- the shape says the rest.
    readonly property var curveMarks: {
        const st = root.hourSteps
        if (st.length === 0) return []
        let hi = 0, lo = 0
        for (let i = 1; i < st.length; i++) {
            if (st[i].t > st[hi].t) hi = i
            if (st[i].t < st[lo].t) lo = i
        }
        const out = [{ i: 0, t: st[0].t }]
        if (hi !== 0) out.push({ i: hi, t: st[hi].t })
        if (lo !== 0 && lo !== hi) out.push({ i: lo, t: st[lo].t })
        return out
    }
    // The clock under the chart goes every SIX hours: eight stamps of
    // "12:00 AM" ran into each other across 330 px.
    readonly property var marks6h: {
        const out = []
        for (let i = 0; i < root.hourSteps.length; i += 2)
            out.push({ i: i, label: root.hourSteps[i].label })
        return out
    }
    // "3:00 PM" -> "3PM", "15:00" -> "15". On an axis the minutes are always
    // :00 and saying so eight times is just wider.
    function shortHour(s) {
        if (!s) return ""
        const t = String(s)
        const ap = t.indexOf("PM") >= 0 ? "PM" : (t.indexOf("AM") >= 0 ? "AM" : "")
        return t.split(":")[0] + ap
    }

    // Aim the countdown without starting it. A second is the floor: the wheels
    // can be spun to 00:00:00, and a timer of no length is not a thing to hand
    // to a service that would just refuse it and leave the wheels lying.
    function aimAt(ms) { Services.Countdown.setPreset(Math.max(1000, ms)) }

    // The quickest lap taken so far, so the strip can point at it.
    readonly property real bestSplit: {
        let b = -1
        for (const l of Services.Stopwatch.laps)
            if (b < 0 || l.split < b) b = l.split
        return b
    }

    // What the middle of the day ring says: how much light is left, or how long
    // until it comes back. A number nobody else on the card is already giving.
    readonly property real sunUpFrac: Services.Weather.sunriseMin < 0
        ? -1 : Services.Weather.sunriseMin / 1440
    readonly property real sunDownFrac: Services.Weather.sunsetMin < 0
        ? -1 : Services.Weather.sunsetMin / 1440
    function spanText(frac) {
        const mins = Math.max(0, Math.round(frac * 1440))
        const h = Math.floor(mins / 60), m = mins % 60
        return h > 0 ? Services.I18n.t("time.hours", { n: h }) + " "
                     + Services.I18n.t("time.mins", { n: m })
                     : Services.I18n.t("time.mins", { n: m })
    }
    readonly property string daylightLeft: {
        if (sunUpFrac < 0 || sunDownFrac < 0) return "—"
        if (dayFrac < sunUpFrac) return spanText(sunUpFrac - dayFrac)
        if (dayFrac < sunDownFrac) return spanText(sunDownFrac - dayFrac)
        return spanText(1 - dayFrac + sunUpFrac)
    }
    readonly property string daylightCaption: {
        if (sunUpFrac < 0 || sunDownFrac < 0) return ""
        if (dayFrac < sunUpFrac) return Services.I18n.t("clock.untilSunrise")
        if (dayFrac < sunDownFrac) return Services.I18n.t("clock.lightLeft")
        return Services.I18n.t("clock.untilSunrise")
    }

    // The whole strip, today included: today's card is the way back from a day
    // that was picked, and with it in the row a card's index IS `selDay`.
    readonly property var fcDays: Services.Weather.forecast

    // ── Inline components ───────────────────────────────────────────────
    // These must be declared on the document's root object; nested inside a
    // Column they simply do not parse.

    // The hairline between sections. Thin, dim, and the only thing doing the
    // separating — no boxes, no fills.
    component VRule: Rectangle {
        Layout.preferredWidth: 1
        Layout.fillHeight: true
        color: Services.Colors.fillInset
    }

    // One cell of the weather grid: glyph and number on a line, its name under
    // them. No plate and no rule -- the grid is held together by its columns.
    // One column of a hh:mm:ss picker. A ListView with its highlight range
    // nailed to the middle row IS a wheel -- no Controls dependency and no
    // hand-rolled flicking. Nothing here reads `preset` as a binding: the wheel
    // both follows it and writes it, so the follow has to be an assignment that
    // can be switched off while it is the one doing the writing.
    component Wheel: Item {
        id: wheel
        property int count: 60
        property int unitMs: 1000
        readonly property int rowH: 38
        // What this column's digits are worth in the current preset.
        readonly property int value: Math.floor(Services.Countdown.preset / unitMs) % count
        property bool syncing: false
        // Nothing this wheel does counts as an instruction until a hand has
        // moved it. A ListView settles its own currentIndex once it has a
        // geometry, well after Component.onCompleted -- three wheels each
        // reporting that settle as a choice is what turned a fresh 5-minute
        // preset into 01:01:01.
        property bool touched: false

        width: 66
        height: rowH * 3

        // Setting currentIndex is enough: StrictlyEnforceRange already drags the
        // view onto it. Calling positionViewAtIndex as well made the two fight
        // and land a row off -- three wheels each one step out is where a fresh
        // 5-minute preset came up as 01:01:01.
        function sync() {
            if (view.moving || view.dragging) return
            wheel.syncing = true
            view.currentIndex = wheel.value
            wheel.syncing = false
        }
        Component.onCompleted: wheel.sync()
        Connections {
            target: Services.Countdown
            function onPresetChanged() { wheel.sync() }
        }

        ListView {
            id: view
            anchors.fill: parent
            clip: true
            model: wheel.count
            orientation: ListView.Vertical
            snapMode: ListView.SnapToItem
            // The selected row is the middle one, always.
            highlightRangeMode: ListView.StrictlyEnforceRange
            preferredHighlightBegin: wheel.rowH
            preferredHighlightEnd: wheel.rowH * 2
            boundsBehavior: Flickable.StopAtBounds

            onMovementStarted: wheel.touched = true
            onCurrentIndexChanged: {
                if (wheel.syncing || !wheel.touched) return
                const cur = Services.Countdown.preset
                const mine = Math.floor(cur / wheel.unitMs) % wheel.count
                if (view.currentIndex === mine) return
                root.aimAt(cur + (view.currentIndex - mine) * wheel.unitMs)
            }

            delegate: Item {
                required property int index
                width: wheel.width
                height: wheel.rowH
                readonly property bool sel: index === view.currentIndex
                Text {
                    anchors.centerIn: parent
                    text: (parent.index < 10 ? "0" : "") + parent.index
                    color: parent.sel ? Services.Colors.snow : Services.Colors.ash
                    opacity: parent.sel ? 1 : 0.55
                    font.pixelSize: parent.sel ? 34 : 24
                    font.bold: parent.sel
                    font.family: "JetBrainsMono NF"
                    Behavior on font.pixelSize { NumberAnimation { duration: Services.Sizes.msMicro } }
                    Behavior on opacity { NumberAnimation { duration: Services.Sizes.msMicro } }
                }
            }
        }
    }

    component WheelColon: Text {
        width: 14
        height: 114
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: ":"
        color: Services.Colors.mist
        font.pixelSize: 30
        font.bold: true
        font.family: "JetBrainsMono NF"
    }

    // One fact, in a small card: icon and value on a line, its name under it.
    component Stat: Rectangle {
        id: stat
        property string glyph: ""
        property string value: ""
        property string caption: ""
        radius: Services.Sizes.cardR
        color: Services.Colors.fillInset

        Column {
            anchors.centerIn: parent
            spacing: 2

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 5
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: stat.glyph
                    color: Services.Colors.ghost
                    font.pixelSize: 15
                    font.family: "Material Symbols Rounded"
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: stat.value
                    color: Services.Colors.snow
                    font.pixelSize: 15
                    font.bold: true
                    font.family: "JetBrainsMono NF"
                }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: stat.caption
                color: Services.Colors.mist
                font.pixelSize: 8
                font.family: "JetBrainsMono NF"
            }
        }
    }

    // Tools slide aside in the direction you moved along the tabs.
    SlideSwap {
        id: toolSlide
        axis: "horizontal"
        index: root.tab
        onCommit: root.shownTool = root.tab
    }
    property int shownTool: 0

    component Tool: Item {
        property int index: 0
        anchors.fill: parent
        opacity: root.shownTool === index ? root.beat(1) * toolSlide.fade : 0
        visible: opacity > 0.01
        transform: Translate { x: toolSlide.offX }
    }

    RowLayout {
        id: row
        anchors.fill: parent
        spacing: root.gap

        // ── Left: the clock, and the tools that belong to a clock ───────
        Item {
            id: clockCol
            Layout.preferredWidth: root.clockW
            Layout.fillHeight: true

            // The clock leads and the day reads under it: the hour is what
            // this column is for, and a date on top made the reading feel like
            // a footnote to its own label.
            ClockText {
                id: timeT
                opacity: root.sharedOpacity
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                time: root.timeText
                px: root.clockPx
            }

            Column {
                id: head
                anchors.top: timeT.bottom
                anchors.topMargin: 2
                width: parent.width
                spacing: 2

                Text {
                    id: dateT
                    opacity: root.sharedOpacity
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: root.dateText.toUpperCase()
                    color: Services.Colors.snow
                    font.pixelSize: 13
                    font.bold: true
                    font.letterSpacing: 2
                    font.family: "JetBrainsMono NF"
                }
            }

            // Category strip: one container pill holding the mode pills, the
            // whole thing centred under the clock it belongs to.
            Item {
                id: tabsWrap
                anchors.top: head.bottom
                anchors.topMargin: 16
                width: parent.width
                height: 34
                opacity: root.beat(0)
                property Item activeTab: null

                Rectangle {
                    id: tabsPill
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: tabs.width + 8
                    height: 34
                    radius: 12
                    color: Services.Colors.surfacePill

                    // Sliding highlight behind whichever pill is picked
                    Rectangle {
                        visible: tabsWrap.activeTab !== null
                        x: 4 + (tabsWrap.activeTab ? tabsWrap.activeTab.x : 0)
                        width: tabsWrap.activeTab ? tabsWrap.activeTab.width : 0
                        height: 26
                        anchors.verticalCenter: parent.verticalCenter
                        radius: 9
                        color: Services.Colors.ghost
                        gradient: Services.Prefs.useGradients ? Services.Colors.accentGradient : null
                        Behavior on x { SmoothedAnimation { duration: Services.Sizes.msPronounced } }
                        Behavior on width { SmoothedAnimation { duration: Services.Sizes.msStandard } }
                    }

                    Row {
                        id: tabs
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 4
                        spacing: 4

                        Repeater {
                            model: [
                                { id: 0, label: Services.I18n.t("clock.tab.clock"),     icon: "" },
                                { id: 1, label: Services.I18n.t("clock.tab.stopwatch"), icon: "" },
                                { id: 2, label: Services.I18n.t("clock.tab.timer"),     icon: "" }
                            ]

                            delegate: Rectangle {
                                required property var modelData
                                readonly property bool active: root.tab === modelData.id
                                onActiveChanged: if (active) tabsWrap.activeTab = this
                                Component.onCompleted: if (active) tabsWrap.activeTab = this

                                height: 26
                                width: tabRow.implicitWidth + 18
                                radius: 9
                                // Only the sliding indicator carries the active fill;
                                // idle pills are bare -- hover only brightens them,
                                // it never paints a plate.
                                color: "transparent"
                                Behavior on color { ColorAnimation { duration: Services.Sizes.msMicro } }

                                Row {
                                    id: tabRow
                                    anchors.centerIn: parent
                                    spacing: 5

                                    Text {
                                        text: parent.parent.modelData.icon
                                        color: parent.parent.active ? Services.Colors.accentText
                                             : tabHover.containsMouse ? Services.Colors.snow
                                             : Services.Colors.mist
                                        font.pixelSize: 13
                                        font.family: "Material Symbols Rounded"
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Text {
                                        text: parent.parent.modelData.label
                                        color: parent.parent.active ? Services.Colors.accentText
                                             : tabHover.containsMouse ? Services.Colors.snow
                                             : Services.Colors.mist
                                        font.pixelSize: 11
                                        font.bold: parent.parent.active
                                        font.family: "JetBrainsMono NF"
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }

                                MouseArea {
                                    id: tabHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    // Through AppState: assigning root.tab here
                                    // would break its binding on the first click.
                                    onClicked: Services.AppState.clockTab = parent.modelData.id
                                }
                            }
                        }
                    }
                }
            }

            // ── Tool area: all three stacked, one showing ───────────────
            Item {
                id: tools
                anchors.top: tabsWrap.bottom
                anchors.topMargin: 14
                anchors.bottom: parent.bottom
                width: parent.width

                // -- Clock: what today is, in plain rows --
                // No ring, no plates, no rules: a short centred list.
                Tool {
                    index: 0
                    Item {
                        anchors.fill: parent

                        // The sun's own path. The headline sits ABOVE the
                        // curve, not inside its bowl: the box has to reserve
                        // room for a noon peak, and the band left over at the
                        // top is exactly where a line of text belongs (the
                        // shape iOS's solar module settled on).
                        Row {
                            id: sunLine
                            anchors.bottom: clockHead.top
                            anchors.bottomMargin: 10
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 8
                            Text {
                                anchors.baseline: sunCap.baseline
                                text: root.daylightLeft
                                color: Services.Colors.snow
                                font.pixelSize: 16
                                font.bold: true
                                font.family: "JetBrainsMono NF"
                            }
                            Text {
                                id: sunCap
                                text: root.daylightCaption
                                color: Services.Colors.mist
                                font.pixelSize: 9
                                font.bold: true
                                font.family: "JetBrainsMono NF"
                            }
                        }

                        Item {
                            id: clockHead
                            // Hung off the figures rather than centred with
                            // them: the arc can change height without dragging
                            // the row of numbers down the column with it.
                            anchors.bottom: clockRow.top
                            anchors.bottomMargin: 22
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 132

                            SunArc {
                                id: sunArc
                                anchors.fill: parent
                                sunUp: root.sunUpFrac
                                sunDown: root.sunDownFrac
                                // To the minute, not to the second: the dot
                                // moves a pixel an hour, and the canvas has no
                                // reason to repaint sixty times a minute.
                                nowFrac: Math.floor(root.dayFrac * 1440) / 1440
                            }
                        }

                        // The day's four figures, on one line and in the same
                        // shape the weather column uses: glyph and number on
                        // top, what they are underneath. Stacked rows put two
                        // gaps inside every line of a narrow column.
                        Grid {
                            id: clockRow
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 24
                            anchors.left: parent.left
                            anchors.right: parent.right
                            columns: 4

                            WxCell {
                                width: parent.width / 4
                                glyph: "\ue1c6"
                                value: Services.Weather.sunrise || "\u2014"
                                caption: Services.I18n.t("weather.sunrise")
                            }
                            WxCell {
                                width: parent.width / 4
                                glyph: "\ue916"
                                value: {
                                    // ISO week: the Thursday of this week owns the year
                                    let d = new Date(root.now.getFullYear(), root.now.getMonth(), root.now.getDate())
                                    d.setDate(d.getDate() + 3 - ((d.getDay() + 6) % 7))
                                    let jan4 = new Date(d.getFullYear(), 0, 4)
                                    let n = 1 + Math.round(((d - jan4) / 86400000
                                            - 3 + ((jan4.getDay() + 6) % 7)) / 7)
                                    return String(n)
                                }
                                caption: Services.I18n.t("clock.week")
                            }
                            WxCell {
                                width: parent.width / 4
                                glyph: "\ue88b"
                                value: {
                                    let start = new Date(root.now.getFullYear(), 0, 0)
                                    return String(Math.floor((root.now - start) / 86400000))
                                }
                                caption: Services.I18n.t("clock.dayOf", { n: root.isLeap ? 366 : 365 })
                            }
                            WxCell {
                                width: parent.width / 4
                                glyph: "\ue1f9"
                                value: Services.Weather.sunset || "\u2014"
                                caption: Services.I18n.t("weather.sunset")
                            }
                        }
                    }
                }

                // -- Stopwatch: the number, and nothing around it --
                // It had a ring for a while. A stopwatch has no end to be a
                // fraction of, so the ring was drawing a minute nobody asked
                // about while the digits -- the whole point -- had to shrink to
                // fit inside it.
                Tool {
                    index: 1
                    Column {
                        anchors.centerIn: parent
                        spacing: 20

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Services.Stopwatch.display
                            color: Services.Colors.snow
                            font.pixelSize: 46
                            font.bold: true
                            font.family: "JetBrainsMono NF"
                        }

                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 8
                            CtlChip {
                                glyph: Services.Stopwatch.running ? "" : ""
                                active: Services.Stopwatch.running
                                onTriggered: Services.Stopwatch.toggle()
                            }
                            CtlChip {
                                glyph: ""
                                available: Services.Stopwatch.running
                                onTriggered: Services.Stopwatch.lap()
                            }
                            CtlChip {
                                glyph: ""
                                available: !Services.Stopwatch.idle
                                onTriggered: Services.Stopwatch.reset()
                            }
                        }

                        // Newest on the left, the fastest one wearing the accent:
                        // which lap was the good one is a comparison, and a
                        // column of bare numbers never makes it for you.
                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 6
                            Repeater {
                                model: Services.Stopwatch.laps.slice(-4).reverse()
                                delegate: Rectangle {
                                    required property var modelData
                                    // Nothing is "fastest" until there is
                                    // something to be faster than.
                                    readonly property bool best: Services.Stopwatch.laps.length > 1
                                        && modelData.split === root.bestSplit
                                    width: 60
                                    height: 34
                                    radius: Services.Sizes.innerR
                                    color: best ? Services.Colors.ghost : Services.Colors.fillInset
                                    gradient: Services.Prefs.useGradients && best
                                        ? Services.Colors.accentGradient : null
                                    Behavior on color { ColorAnimation { duration: Services.Sizes.msMicro } }

                                    Column {
                                        anchors.centerIn: parent
                                        spacing: 0
                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: "#" + modelData.index
                                            color: parent.parent.best ? Services.Colors.accentBody : Services.Colors.ash
                                            font.pixelSize: 9
                                            font.family: "JetBrainsMono NF"
                                        }
                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: Services.Stopwatch.format(modelData.split)
                                            color: parent.parent.best ? Services.Colors.accentText : Services.Colors.snow
                                            font.pixelSize: 11
                                            font.bold: true
                                            font.family: "JetBrainsMono NF"
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // -- Countdown: pick the time on the wheels, or take a preset --
                Tool {
                    index: 2
                    Column {
                        anchors.centerIn: parent
                        spacing: 18

                        // Two faces, one slot: the wheels are for setting, and
                        // once it is counting the only thing worth the space is
                        // what is left.
                        Item {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: wheels.width
                            height: 114

                            Row {
                                id: wheels
                                anchors.centerIn: parent
                                spacing: 2
                                opacity: Services.Countdown.active ? 0 : 1
                                visible: opacity > 0.01
                                Behavior on opacity { NumberAnimation { duration: Services.Sizes.msStandard } }

                                Wheel { id: wHours;   count: 24; unitMs: 3600000 }
                                WheelColon { }
                                Wheel { id: wMins;    count: 60; unitMs: 60000 }
                                WheelColon { }
                                Wheel { id: wSecs;    count: 60; unitMs: 1000 }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: Services.Countdown.display
                                color: Services.Countdown.running ? Services.Colors.snow : Services.Colors.mist
                                font.pixelSize: 46
                                font.bold: true
                                font.family: "JetBrainsMono NF"
                                opacity: Services.Countdown.active ? 1 : 0
                                visible: opacity > 0.01
                                Behavior on opacity { NumberAnimation { duration: Services.Sizes.msStandard } }
                                Behavior on color { ColorAnimation { duration: Services.Sizes.msStandard } }
                            }
                        }

                        // The lengths worth a button; the wheels cover everything
                        // between them.
                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 6
                            Repeater {
                                model: [1, 5, 10, 25]
                                delegate: Rectangle {
                                    required property var modelData
                                    readonly property bool picked: Services.Countdown.preset === modelData * 60000
                                    width: 42; height: 24; radius: 8
                                    color: picked ? Services.Colors.ghost : Services.Colors.fillInset
                                    gradient: Services.Prefs.useGradients && picked
                                        ? Services.Colors.accentGradient : null
                                    Behavior on color { ColorAnimation { duration: Services.Sizes.msMicro } }
                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData + "m"
                                        color: parent.picked ? Services.Colors.accentText : Services.Colors.snow
                                        font.pixelSize: 10
                                        font.bold: true
                                        font.family: "JetBrainsMono NF"
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        // A length aims the timer; starting is
                                        // the one button that starts things.
                                        onClicked: root.aimAt(modelData * 60000)
                                    }
                                }
                            }
                        }

                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 8
                            CtlChip {
                                glyph: Services.Countdown.running ? "" : ""
                                active: Services.Countdown.running
                                available: Services.Countdown.remaining > 0
                                onTriggered: Services.Countdown.toggle()
                            }
                            CtlChip {
                                glyph: ""
                                available: Services.Countdown.active
                                onTriggered: Services.Countdown.reset()
                            }
                        }
                    }
                }
            }
        }

        VRule { opacity: root.beat(2) }

        // ── Middle: calendar ────────────────────────────────────────────
        Item {
            id: calCol
            Layout.fillWidth: true
            Layout.fillHeight: true
            opacity: root.beat(3)

            Column {
                id: calStack
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                spacing: 12

                // Month on the left, controls gathered on the right, so the
                // label and the buttons stop competing for the middle.
                Item {
                    width: parent.width
                    height: 26

                    // The name rides the SAME slide as the days. It already
                    // reads off `shownIndex`, so it changed at the commit --
                    // correct, but as a cut, next to a grid that travels.
                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        // Caps, like every other title on this card -- the
                        // city, TODAY, the four figures under the arc.
                        text: (Services.Time.monthName(grid.curMonth) + " " + grid.curYear).toUpperCase()
                        color: Services.Colors.snow
                        font.pixelSize: 14
                        font.family: "JetBrainsMono NF"
                        font.bold: true
                        font.letterSpacing: 1.4
                        opacity: monthSlide.fade
                        transform: Translate { x: monthSlide.offX }
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Services.Sizes.btnGap

                        // Same chip as the media transport, so every small
                        // button in the shell behaves identically. Today sits
                        // between the arrows because that is where it belongs:
                        // it is the middle of what they move you away from.
                        CtlChip {
                            glyph: "\ue5cb"
                            size: 28
                            glyphSize: 17
                            onTriggered: grid.monthIndex--
                        }
                        CtlChip {
                            glyph: "\ue8df"
                            size: 28
                            glyphSize: 15
                            // Lit while you are already looking at this month.
                            // Off `monthIndex`, not the month on show: a button
                            // answers when you press it, not a slide later.
                            active: grid.monthIndex === grid.todayYear * 12 + grid.todayMonth
                            onTriggered: grid.monthIndex = grid.todayYear * 12 + grid.todayMonth
                        }
                        CtlChip {
                            glyph: "\ue5cc"
                            size: 28
                            glyphSize: 17
                            onTriggered: grid.monthIndex++
                        }
                    }
                }

                SlideSwap {
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
                            required property int index
                            width: calStack.width / 7
                            horizontalAlignment: Text.AlignHCenter
                            // Sunday first, the order the grid below counts in.
                            text: Services.Time.dayShort(index).replace(".", "").toUpperCase()
                            color: Services.Colors.ash
                            font.pixelSize: 11
                            font.family: "JetBrainsMono NF"
                        }
                    }
                }

                MonthGrid {
                    id: grid
                    width: parent.width
                    cellW: calStack.width / 7 - 3
                    cellSize: Math.min(calStack.width / 7 - 3, 34)
                    // The days slide the way the arrow points; `shownIndex` is
                    // moved by that slide's commit, above.
                    opacity: monthSlide.fade
                    transform: Translate { x: monthSlide.offX }
                }
            }
        }

        VRule { opacity: root.beat(4) }

        // ── Right: weather ──────────────────────────────────────────────
        // The city as the title, one day under it with an arrow to each side,
        // the reading, its 24 hours and six figures. No plates anywhere: the
        // strip of day cards was the last box left on this card.
        Item {
            id: wxCol
            Layout.preferredWidth: root.weatherW
            Layout.fillHeight: true

            // The title. It does NOT ride the day sweep -- the city is the same
            // city on every day of the strip.
            Text {
                id: wxCity
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                opacity: root.beat(5)
                text: Services.Weather.city.toUpperCase()
                color: Services.Colors.snow
                font.pixelSize: 13
                font.bold: true
                font.letterSpacing: 2
                font.family: "JetBrainsMono NF"
            }

            // Which day, and the way to the next one. The arrows answer the
            // click, so they hang off the live `selDay`; the name between them
            // belongs to the body and changes mid-sweep with the figures.
            Row {
                id: wxDayNav
                anchors.top: wxCity.bottom
                anchors.topMargin: 6
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 6
                opacity: root.beat(5)

                CtlChip {
                    anchors.verticalCenter: parent.verticalCenter
                    glyph: ""
                    size: 26
                    glyphSize: 16
                    available: root.selDay > 0
                    onTriggered: if (root.selDay > 0) root.selDay--
                }
                // A fixed width, or the arrows would shuffle sideways every
                // time a day's name changed length.
                Item {
                    width: 158
                    height: 26
                    anchors.verticalCenter: parent.verticalCenter
                    Text {
                        anchors.centerIn: parent
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        opacity: root.wxSlideFade
                        transform: Translate { x: root.wxSlideX }
                        text: root.wxDayTitle
                        color: Services.Colors.mist
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 1
                        font.family: "JetBrainsMono NF"
                    }
                }
                CtlChip {
                    anchors.verticalCenter: parent.verticalCenter
                    glyph: ""
                    size: 26
                    glyphSize: 16
                    available: root.selDay < root.fcDays.length - 1
                    onTriggered: if (root.selDay < root.fcDays.length - 1) root.selDay++
                }
            }

            // Conditions now: the glyph and the number are shared with the bar
            // pill, so they are slots here and fly in from it.
            Item {
                id: wxNow
                anchors.top: wxDayNav.bottom
                anchors.topMargin: 14
                width: parent.width
                height: 76
                // Rides the day sweep. The glyph and the number are drawn by
                // the panel's flying copies, which carry the same two numbers.
                opacity: root.wxSlideFade
                transform: Translate { x: root.wxSlideX }

                // The headline is centred as one block: glyph, number, range.
                // wIcon is placed by hand instead of anchored to the middle so
                // the coordinates the panel's flying copies aim at stay a plain
                // sum of parents (see wIconCX).
                readonly property real heroW:
                    wIcon.width + 12 + wTemp.width + 10 + wRange.width

                Text {
                    id: wIcon
                    opacity: root.sharedOpacity
                    x: Math.max(0, (wxNow.width - wxNow.heroW) / 2)
                    anchors.top: parent.top
                    text: root.wxIcon
                    color: Services.Colors.neutral
                    font.pixelSize: 48
                    font.family: "Material Symbols Rounded"
                }
                Text {
                    id: wTemp
                    opacity: root.sharedOpacity
                    anchors.left: wIcon.right
                    anchors.leftMargin: 12
                    anchors.top: parent.top
                    anchors.topMargin: 2
                    text: root.wxTemp
                    color: Services.Colors.snow
                    font.pixelSize: 30
                    font.bold: true
                    font.family: "JetBrainsMono NF"
                }
                // The day's range, next to the number it belongs to. Never a
                // flying piece -- the bar pill has no room for it -- so it
                // arrives with the rest of the extras.
                Text {
                    id: wRange
                    anchors.left: wTemp.right
                    anchors.leftMargin: 10
                    anchors.baseline: wTemp.baseline
                    opacity: root.beat(5)
                    text: root.wxRange
                    color: Services.Colors.ash
                    font.pixelSize: 11
                    font.family: "JetBrainsMono NF"
                }
                Column {
                    anchors.top: wTemp.bottom
                    anchors.topMargin: 4
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 1
                    opacity: root.beat(5)
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.wxCondition
                        color: Services.Colors.mist
                        font.pixelSize: 11
                        font.family: "JetBrainsMono NF"
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.wxSub
                        color: Services.Colors.ash
                        font.pixelSize: 10
                        font.family: "JetBrainsMono NF"
                    }
                }
            }

            // The next 24 hours: the one thing this column can say that no
            // other part of the card already says. The curve is the same Trend
            // the process panel draws, shifted so the coldest hour sits on the
            // floor -- a chart of absolute temperature is a flat line all day.
            Item {
                id: hourly
                anchors.top: wxNow.bottom
                anchors.topMargin: 14
                anchors.left: parent.left
                anchors.right: parent.right
                height: 160
                opacity: root.beat(5) * root.wxSlideFade
                transform: Translate { x: root.wxSlideX }
                visible: root.hours.length > 1

                // The curve, with the temperature written ON it every three
                // hours and the clock under it. A line with no numbers was the
                // complaint and it was the right one: a shape alone says the
                // afternoon is warmer, which anyone already knew.
                Trend {
                    id: curve
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.topMargin: 14
                    height: 116
                    stepped: true
                    values: {
                        const out = []
                        for (const st of root.hourSteps) out.push(st.t - root.stepMin)
                        return out
                    }
                    // Never zero: a day that holds one temperature would divide
                    // the chart by nothing.
                    maxValue: Math.max(1, root.stepMax - root.stepMin)
                }

                // Each of the three sits just above where the line actually
                // is -- the same arithmetic Trend uses to place the point, or
                // the number would float off its own curve.
                Repeater {
                    model: root.curveMarks
                    delegate: Text {
                        required property var modelData
                        // Slots, not points: the plateau's own middle.
                        readonly property int slots: Math.max(1, root.hourSteps.length)
                        readonly property real fx: hourly.width * (modelData.i + 0.5) / slots
                        readonly property real fy: {
                            const cap = Math.max(1, root.stepMax - root.stepMin)
                            const f = (modelData.t - root.stepMin) / cap
                            return curve.y + 3 + (curve.height - 6) * (1 - f)
                        }
                        x: Math.max(0, Math.min(hourly.width - width, fx - width / 2))
                        y: fy - height - 2
                        text: Services.Weather.degrees(modelData.t)
                        color: Services.Colors.snow
                        font.pixelSize: 10
                        font.bold: true
                        font.family: "JetBrainsMono NF"
                    }
                }

                // The clock under the curve, every six hours.
                Repeater {
                    model: root.marks6h
                    delegate: Text {
                        required property var modelData
                        readonly property int slots: Math.max(1, root.hourSteps.length)
                        x: Math.max(0, Math.min(hourly.width - width,
                                                hourly.width * (modelData.i + 0.5) / slots - width / 2))
                        anchors.top: curve.bottom
                        anchors.topMargin: 5
                        text: modelData.label
                        color: Services.Colors.ash
                        font.pixelSize: 9
                        font.family: "JetBrainsMono NF"
                    }
                }
            }

            // The day's four figures, on one line. No plate under any of
            // them: the strip of day cards used to live here, and the arrows
            // over the reading replaced it. Sunrise and sunset are not here --
            // the clock column already says both, and the light it has left.
            Grid {
                id: wxGrid
                anchors.top: hourly.bottom
                anchors.topMargin: 24
                anchors.left: parent.left
                anchors.right: parent.right
                columns: 4
                opacity: root.beat(5) * root.wxSlideFade
                transform: Translate { x: root.wxSlideX }

                WxCell {
                    width: wxGrid.width / 4
                    glyph: "\ue798"
                    value: root.wxHumidity + "%"
                    caption: Services.I18n.t("weather.humidity")
                }
                // The bearing as an arrow instead of two letters to decode: the
                // glyph points where the wind comes FROM, which is what the
                // reading means.
                WxCell {
                    width: wxGrid.width / 4
                    glyph: Services.Weather.windGlyph(root.wxWindDir)
                    value: root.wxWindKph + " km/h"
                    caption: Services.I18n.t("weather.wind")
                }
                WxCell {
                    width: wxGrid.width / 4
                    glyph: "\uf157"
                    value: Services.I18n.t("weather.uv", { n: root.wxUv })
                    caption: Services.I18n.t("weather.uvIndex")
                }
                WxCell {
                    width: wxGrid.width / 4
                    glyph: "\uf176"
                    value: root.wxRain + "%"
                    caption: Services.I18n.t("weather.rain")
                }
            }
        }
    }

    readonly property bool isLeap: {
        let y = now.getFullYear()
        return (y % 4 === 0 && y % 100 !== 0) || y % 400 === 0
    }
}
