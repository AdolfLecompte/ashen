import QtQuick

import "root:/modules/desktop"
import "root:/modules/widgets" as Widgets
import "root:/services" as Services

// The day's light: where the sun is on its way between the two ends of it.
DesktopWidget {
    id: root
    wid: "sun"

    // Weather formats these to be READ ("6:12 PM" in 12-hour), so they cannot
    // be parsed by counting characters -- same trap the clock panel pays.
    function hhmmFrac(s) {
        if (!s || s.length < 4) return -1
        const t = String(s).trim()
        const p = t.split(":")
        let h = parseInt(p[0])
        const m = parseInt(p[1])
        if (isNaN(h) || isNaN(m)) return -1
        if (t.indexOf("PM") >= 0 && h < 12) h += 12
        if (t.indexOf("AM") >= 0 && h === 12) h = 0
        return (h * 3600 + m * 60) / 86400
    }

    readonly property real dayFrac: (Services.Time.now.getHours() * 3600
        + Services.Time.now.getMinutes() * 60 + Services.Time.now.getSeconds()) / 86400
    readonly property real upFrac: root.hhmmFrac(Services.Weather.sunrise)
    readonly property real downFrac: root.hhmmFrac(Services.Weather.sunset)
    readonly property bool daytime: root.dayFrac >= root.upFrac && root.dayFrac < root.downFrac

    readonly property string lightLeft: {
        if (root.upFrac < 0 || root.downFrac < 0) return ""
        const mins = Math.round((root.daytime ? root.downFrac - root.dayFrac
                                              : (root.upFrac - root.dayFrac + 1) % 1) * 1440)
        const h = Math.floor(mins / 60)
        return (h > 0 ? h + "h " : "") + (mins % 60) + "m"
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
            anchors.verticalCenter: parent.verticalCenter
            text: st.glyph
            color: Services.Colors.ghost
            font.pixelSize: 13
            font.family: "Material Symbols Rounded"
        }
        Text {
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
