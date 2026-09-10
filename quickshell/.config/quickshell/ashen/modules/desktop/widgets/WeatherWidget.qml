import QtQuick

import "root:/modules/desktop"
import "root:/modules/widgets" as Widgets
import "root:/services" as Services

// Today, in three sizes: the whole thing, the reading alone, or only the shape
// of the day.
DesktopWidget {
    id: root
    wid: "weather"

    // Shifted so the coldest hour sits on the floor -- a chart of absolute
    // temperature is a flat line all day. Same arithmetic the clock panel uses.
    readonly property int lo: {
        let m = 999
        for (const h of Services.Weather.hourly) if (h.tempC < m) m = h.tempC
        return m === 999 ? 0 : m
    }
    readonly property int hi: {
        let m = -999
        for (const h of Services.Weather.hourly) if (h.tempC > m) m = h.tempC
        return m === -999 ? 1 : m
    }
    // Which hour holds the day's high and its low: the only two the curve is
    // worth writing a number on. First one wins, so a temperature that repeats
    // is labelled where it was first reached.
    readonly property int hiAt: {
        const hs = Services.Weather.hourly
        for (let i = 0; i < hs.length; i++) if (hs[i].tempC === root.hi) return i
        return -1
    }
    readonly property int loAt: {
        const hs = Services.Weather.hourly
        for (let i = 0; i < hs.length; i++) if (hs[i].tempC === root.lo) return i
        return -1
    }

    component Reading: Row {
        id: rd
        property real glyphSize: 48
        property real tempSize: 34
        // Off where a cap already names the place: printing the city twice in
        // one plate reads as two different readings.
        property bool showCity: true
        spacing: 14

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Services.Weather.icon
            font.family: "Material Symbols Rounded"
            font.pixelSize: rd.glyphSize
            color: Services.Colors.neutral
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
                text: Services.Weather.temp
                color: Services.Colors.snow
                font.pixelSize: rd.tempSize
                font.bold: true
                font.family: "JetBrainsMono NF"
            }
            Text {
                text: Services.Weather.condition
                color: Services.Colors.mist
                font.pixelSize: Services.Sizes.fsBody
                font.family: "JetBrainsMono NF"
            }
            Text {
                text: (rd.showCity ? Services.Weather.city + " · " : "")
                    + Services.I18n.t("weather.feels", { t: Services.Weather.feels })
                color: Services.Colors.ash
                font.pixelSize: Services.Sizes.fsMeta
                font.family: "JetBrainsMono NF"
            }
        }
    }

    // The next twenty-four hours as plateaus: a reading taken hourly did not
    // slide between them. The numbers ride ON the line -- the high, the low and
    // where you are standing -- because a curve with nothing written on it is a
    // shape, and the pair at the foot never said WHEN either happened.
    component Curve: Item {
        id: cv
        property real chartH: 68
        // Room above the line for the labels sitting on it, and below for the
        // hours.
        implicitHeight: cv.chartH + 34

        readonly property var hours: Services.Weather.hourly

        Widgets.Trend {
            id: line
            width: parent.width
            height: cv.chartH
            y: 14
            visible: cv.hours.length > 1
            values: cv.hours.map(h => h.tempC - root.lo)
            // Never zero: a day that holds one temperature would divide the
            // chart by nothing.
            maxValue: Math.max(1, root.hi - root.lo)
            stepped: true
            cornerR: 10
            color_: Services.Colors.ghost
        }

        // The three readings worth writing on the line: the day's high, its
        // low, and the hour you are standing in. A label is kept inside the box
        // at both ends -- one centred on the first hour would hang off the left.
        Repeater {
            // "Now" wins its hour: when the day peaks -- or bottoms -- on the
            // hour you are standing in, the other label would print on top of
            // it and both become unreadable.
            model: [
                { at: root.hiAt === 0 ? -1 : root.hiAt, t: root.hi, mark: false },
                { at: root.loAt === 0 ? -1 : root.loAt, t: root.lo, mark: false },
                { at: 0, t: cv.hours.length > 0 ? cv.hours[0].tempC : 0, mark: true }
            ]

            Item {
                id: pin
                required property var modelData
                visible: pin.modelData.at >= 0 && cv.hours.length > 1

                readonly property real cx: line.xOf(pin.modelData.at)
                readonly property real cy: line.y + line.yOf(pin.modelData.t - root.lo)

                Text {
                    x: Math.max(0, Math.min(cv.width - width, pin.cx - width / 2))
                    y: pin.cy - height - (pin.modelData.mark ? 10 : 6)
                    text: Services.Weather.degrees(pin.modelData.t)
                    color: pin.modelData.mark ? Services.Colors.snow : Services.Colors.mist
                    font.pixelSize: Services.Sizes.fsMeta
                    font.bold: pin.modelData.mark
                    font.family: "JetBrainsMono NF"
                }
                // Only "now" gets a dot: the high and the low are already the
                // two corners of the shape, and three dots on one line reads as
                // a constellation.
                Rectangle {
                    visible: pin.modelData.mark
                    x: pin.cx - width / 2
                    y: pin.cy - height / 2
                    width: 6
                    height: 6
                    radius: 3
                    color: Services.Colors.ghost
                }
            }
        }

        // Where you are on it. Four marks rather than twenty-four: the point is
        // reading the shape against the clock, not the timetable.
        Row {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: line.bottom
            anchors.topMargin: 6
            Repeater {
                model: [0, 6, 12, 18]
                Text {
                    required property int modelData
                    width: cv.width / 4
                    visible: modelData < cv.hours.length
                    // Guarded in the text too, not only in `visible`: a binding
                    // is evaluated whether or not the item is shown.
                    text: modelData === 0 ? Services.I18n.t("weather.now")
                        : modelData < cv.hours.length ? cv.hours[modelData].label : ""
                    color: Services.Colors.ash
                    font.pixelSize: Services.Sizes.fsMeta
                    font.letterSpacing: 1.2
                    font.family: "JetBrainsMono NF"
                    horizontalAlignment: modelData === 0 ? Text.AlignLeft : Text.AlignHCenter
                }
            }
        }
    }

    // The day's four figures, the same four the clock panel shows and in the
    // same clothes.
    component Extras: Row {
        id: ex
        property real cellW: 96

        Widgets.WxCell {
            width: ex.cellW
            glyph: "\uf176"
            value: Services.Weather.rainProb + "%"
            caption: Services.I18n.t("weather.rain")
        }
        Widgets.WxCell {
            width: ex.cellW
            glyph: "\uf157"
            value: Services.I18n.t("weather.uv", { n: Services.Weather.uvMax })
            caption: Services.I18n.t("weather.uvIndex")
        }
        Widgets.WxCell {
            width: ex.cellW
            glyph: "\ue798"
            value: Services.Weather.humidity + "%"
            caption: Services.I18n.t("weather.humidity")
        }
        // The bearing as an arrow instead of two letters to decode: the glyph
        // points where the wind comes FROM, which is what the reading means.
        Widgets.WxCell {
            width: ex.cellW
            glyph: Services.Weather.windGlyph(Services.Weather.windDir)
            value: Services.Weather.windKph + " km/h"
            caption: Services.I18n.t("weather.wind")
        }
    }

    Component {
        id: fullShape
        Column {
            id: full
            width: 384
            spacing: 12

            // Several readings under one roof, so it wears the cap -- the city
            // it is talking about, and today's two ends.
            WidgetHead {
                width: full.width
                // The place, not the sky: the sky is drawn life-size below it.
                glyph: "\ue55f"
                name: Services.Weather.city.toUpperCase()
                note: Services.Weather.forecast.length > 0
                    ? Services.Weather.degrees(Services.Weather.forecast[0].maxC)
                      + " / " + Services.Weather.degrees(Services.Weather.forecast[0].minC)
                    : ""
            }
            Reading { showCity: false }
            Extras { cellW: full.width / 4 }
            Curve { width: full.width; chartH: 72 }
        }
    }
    Component { id: compactShape; Reading { glyphSize: 40; tempSize: 28 } }
    Component {
        id: hourlyShape
        Curve { width: 360; chartH: 92 }
    }

    Loader {
        sourceComponent: root.style === "compact" ? compactShape
                       : root.style === "hourly" ? hourlyShape
                       : fullShape
    }
}
