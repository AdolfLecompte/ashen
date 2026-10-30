import QtQuick

import "root:/modules/desktop"
import "root:/modules/widgets" as Widgets
import "root:/services" as Services

// Tonight's moon, drawn, with the month's phases under it and the sun's two
// times beside it.
DesktopWidget {
    id: root
    wid: "sun"

    // Off Weather's minute counts, never off its printed times: those follow
    // the language.
    readonly property real dayFrac: (Services.Time.now.getHours() * 3600
        + Services.Time.now.getMinutes() * 60 + Services.Time.now.getSeconds()) / 86400
    readonly property real upFrac: Services.Weather.sunriseMin < 0
        ? -1 : Services.Weather.sunriseMin / 1440
    readonly property real downFrac: Services.Weather.sunsetMin < 0
        ? -1 : Services.Weather.sunsetMin / 1440
    readonly property bool daytime: root.dayFrac >= root.upFrac && root.dayFrac < root.downFrac

    readonly property string lightLeft: {
        if (root.upFrac < 0 || root.downFrac < 0) return ""
        const mins = Math.round((root.daytime ? root.downFrac - root.dayFrac
                                              : (root.upFrac - root.dayFrac + 1) % 1) * 1440)
        const h = Math.floor(mins / 60)
        return (h > 0 ? Services.I18n.t("time.hours", { n: h }) + " " : "")
             + Services.I18n.t("time.mins", { n: mins % 60 })
    }

    // Glyph and digits never share a Text: the symbols font has no
    // numerals and they come out as tofu. There is no sunrise glyph in the
    // installed font either -- the clock panel settled on the two modes.
    component Stamp: Row {
        id: st
        property string glyph: ""
        property string value: ""
        spacing: 5

        Text {
            textFormat: Text.PlainText
            anchors.verticalCenter: parent.verticalCenter
            text: st.glyph
            color: Services.Colors.ghost
            font.pixelSize: 13
            font.family: "Material Symbols Rounded"
        }
        Text {
            textFormat: Text.PlainText
            anchors.verticalCenter: parent.verticalCenter
            text: st.value
            color: Services.Colors.ash
            font.pixelSize: Services.Sizes.fsMeta
            font.family: "JetBrainsMono NF"
        }
    }

    Column {
        spacing: 16

        Row {
            spacing: 18

            Widgets.MoonPhase { id: moon; size: 84 }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6
                Text {
                    textFormat: Text.PlainText
                    text: Services.I18n.t("moon." + moon.phaseKey)
                    color: Services.Colors.snow
                    font.pixelSize: Services.Sizes.fsInput
                    font.bold: true
                    font.family: "JetBrainsMono NF"
                }
                Text {
                    textFormat: Text.PlainText
                    text: Math.round(moon.illum * 100) + "%  \u00b7  "
                        + (moon.frac < 0.5 ? Services.I18n.t("moon.fullIn", { n: moon.daysToFull })
                                           : Services.I18n.t("moon.newIn", { n: moon.daysToNew }))
                    color: Services.Colors.mist
                    font.pixelSize: Services.Sizes.fsMeta
                    font.family: "JetBrainsMono NF"
                }
                Row {
                    spacing: 14
                    topPadding: 6
                    Stamp { glyph: "\ue518"; value: Services.Weather.sunrise }
                    Stamp { glyph: "\ue51c"; value: Services.Weather.sunset }
                }
                Text {
                    textFormat: Text.PlainText
                    visible: root.lightLeft !== ""
                    text: root.lightLeft + " " + Services.I18n.t(root.daytime ? "clock.lightLeft" : "clock.untilSunrise").toLowerCase()
                    color: Services.Colors.ash
                    font.pixelSize: Services.Sizes.fsMeta
                    font.family: "JetBrainsMono NF"
                }
            }
        }

        // The month at a glance: eight phases, tonight's lit.
        Row {
            spacing: 8
            Repeater {
                model: 8
                delegate: Widgets.MoonPhase {
                    required property int index
                    size: 20
                    frac: index / 8
                    opacity: Math.round(moon.frac * 8) % 8 === index ? 1 : 0.35
                }
            }
        }
    }
}
