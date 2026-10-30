import QtQuick

import "root:/modules/desktop"
import "root:/modules/widgets" as Widgets
import "root:/services" as Services

// Today, in three sizes: the whole thing, the reading alone, or the hours ahead.
DesktopWidget {
    id: root
    wid: "weather"

    component Reading: Row {
        id: rd
        property real glyphSize: 48
        property real tempSize: 34
        // Off where a cap already names the place: printing the city twice in
        // one plate reads as two different readings.
        property bool showCity: true
        spacing: 14

        Text {
            textFormat: Text.PlainText
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
                textFormat: Text.PlainText
                text: Services.Weather.temp
                color: Services.Colors.snow
                font.pixelSize: rd.tempSize
                font.bold: true
                font.family: "JetBrainsMono NF"
            }
            Text {
                textFormat: Text.PlainText
                text: Services.Weather.condition
                color: Services.Colors.mist
                font.pixelSize: Services.Sizes.fsBody
                font.family: "JetBrainsMono NF"
            }
            Text {
                textFormat: Text.PlainText
                text: (rd.showCity ? Services.Weather.city + " · " : "")
                    + Services.I18n.t("weather.feels", { t: Services.Weather.feels })
                color: Services.Colors.ash
                font.pixelSize: Services.Sizes.fsMeta
                font.family: "JetBrainsMono NF"
            }
        }
    }

    // The next day every three hours: when, the sky, the temperature, and the
    // chance of rain where there is one. Read at a glance, no chart to decode.
    component Hours: Row {
        id: hr
        // As many as fit with room for "12:00 AM": 8 at 50 px cut the labels.
        readonly property var slots: Services.Weather.hourly.filter((h, i) => i % 3 === 0)
                                         .slice(0, Math.max(4, Math.floor(hr.width / 66)))
        Repeater {
            model: hr.slots
            delegate: Column {
                required property var modelData
                required property int index
                width: hr.width / Math.max(1, hr.slots.length)
                spacing: 4
                Text {
                    textFormat: Text.PlainText
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: index === 0 ? Services.I18n.t("weather.now") : modelData.label
                    color: index === 0 ? Services.Colors.snow : Services.Colors.mist
                    font.pixelSize: Services.Sizes.fsCaption
                    font.bold: index === 0
                    font.family: "JetBrainsMono NF"
                }
                Text {
                    textFormat: Text.PlainText
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: modelData.icon
                    color: Services.Colors.neutral
                    font.pixelSize: 22
                    font.family: "Material Symbols Rounded"
                }
                Text {
                    textFormat: Text.PlainText
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Services.Weather.degrees(modelData.tempC)
                    color: Services.Colors.snow
                    font.pixelSize: Services.Sizes.fsBody
                    font.bold: true
                    font.family: "JetBrainsMono NF"
                }
                Text {
                    textFormat: Text.PlainText
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: modelData.rain > 0 ? modelData.rain + "%" : " "
                    color: Services.Colors.ghost
                    font.pixelSize: Services.Sizes.fsCaption
                    font.family: "JetBrainsMono NF"
                }
            }
        }
    }

    // The next three days: name, sky, and the two ends.
    component Days: Row {
        id: dy
        property real cellW: 96
        Repeater {
            model: Services.Weather.forecast.slice(1, 4)
            delegate: Column {
                required property var modelData
                width: dy.cellW
                spacing: 4
                Text {
                    textFormat: Text.PlainText
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: modelData.label.toUpperCase()
                    color: Services.Colors.mist
                    font.pixelSize: Services.Sizes.fsCaption
                    font.bold: true
                    font.letterSpacing: 1.2
                    font.family: "JetBrainsMono NF"
                }
                Text {
                    textFormat: Text.PlainText
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: modelData.icon
                    color: Services.Colors.neutral
                    font.pixelSize: 24
                    font.family: "Material Symbols Rounded"
                }
                Text {
                    textFormat: Text.PlainText
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Services.Weather.degrees(modelData.maxC) + " / " + Services.Weather.degrees(modelData.minC)
                    color: Services.Colors.snow
                    font.pixelSize: Services.Sizes.fsMeta
                    font.family: "JetBrainsMono NF"
                }
            }
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
            Hours { width: full.width }
            Days { cellW: full.width / 3 }
        }
    }
    Component { id: compactShape; Reading { glyphSize: 40; tempSize: 28 } }
    Component {
        id: hourlyShape
        Hours { width: 460 }
    }

    Loader {
        sourceComponent: root.style === "compact" ? compactShape
                       : root.style === "hourly" ? hourlyShape
                       : fullShape
    }
}
