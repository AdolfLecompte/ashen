import QtQuick

import "root:/modules/desktop"
import "root:/modules/widgets" as Widgets
import "root:/services" as Services

// The day's light: where the sun is on its way between the two ends of it.
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
        spacing: 4

        Text {
            textFormat: Text.PlainText
            text: root.lightLeft + (root.daytime ? " OF LIGHT LEFT" : " UNTIL SUNRISE")
            visible: root.lightLeft !== ""
            color: Services.Colors.mist
            font.pixelSize: Services.Sizes.fsCaption
            font.bold: true
            font.letterSpacing: 1.4
            font.family: "JetBrainsMono NF"
        }

        Widgets.SunArc {
            width: 320
            height: 132
            sunUp: root.upFrac
            sunDown: root.downFrac
            // To the minute: a fraction that moves every second repaints the
            // whole path to shift a dot by nothing.
            nowFrac: Math.floor(root.dayFrac * 1440) / 1440
        }

        Row {
            spacing: 16
            Stamp { glyph: "\ue518"; value: Services.Weather.sunrise }
            Stamp { glyph: "\ue51c"; value: Services.Weather.sunset }
        }

    }
}
