import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell.Widgets
import "root:/services" as Services
import "root:/modules/widgets" as Widgets

// You, at the top of System: the face large over your own wallpaper, blurred
// and darkened -- the wallpaper hero's family, a size smaller.
Rectangle {
    id: hero

    // The button's word, which doubles as the progress report.
    property string action: Services.I18n.t("common.change")
    signal triggered()

    Layout.fillWidth: true
    implicitHeight: 152
    radius: Services.Sizes.cardR
    color: Services.Colors.fillLine
    clip: true

    // The wallpaper, blurred: decoded small (the blur throws the detail away
    // anyway), blurred, then cut to the card's corners.
    Item {
        id: back
        anchors.fill: parent
        visible: wall.status === Image.Ready
        layer.enabled: true
        layer.smooth: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: hero.width
                height: hero.height
                radius: hero.radius
            }
        }
        Image {
            id: wall
            anchors.fill: parent
            anchors.margins: -40
            source: Services.Wallpaper.stillUrl
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: 360
            asynchronous: true
            cache: false
            layer.enabled: true
            layer.effect: FastBlur { radius: 64 }
        }
    }
    // Ground for the words. Hover lifts it rather than filling the card.
    Rectangle {
        anchors.fill: parent
        radius: hero.radius
        color: "black"
        visible: back.visible
        opacity: area.containsMouse ? 0.34 : 0.46
        Behavior on opacity { Widgets.Anim { speed: Services.Sizes.msMicro } }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: hero.triggered()
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 20

        ClippingRectangle {
            id: face
            Layout.preferredWidth: 104
            Layout.preferredHeight: 104
            radius: width / 2
            color: Services.Colors.fillInset
            scale: Services.Sizes.hoverScale(area.containsMouse, area.pressed)
            Behavior on scale { Widgets.Anim { speed: Services.Sizes.msMicro } }

            Image {
                id: faceImg
                anchors.fill: parent
                source: Services.AppState.facePath
                fillMode: Image.PreserveAspectCrop
                sourceSize.width: 208
                asynchronous: true
                cache: false
                visible: status === Image.Ready
            }
            Text {
                textFormat: Text.PlainText
                anchors.centerIn: parent
                visible: faceImg.status !== Image.Ready
                text: "\uf0d3"
                color: Services.Colors.ghost
                font.pixelSize: 48
                font.family: "Material Symbols Rounded"
            }
            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: "transparent"
                border.width: 2
                border.color: Services.Colors.ghost
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            Text {
                textFormat: Text.PlainText
                text: Services.AppState.userName
                color: Services.Colors.snow
                font.pixelSize: 26
                font.bold: true
                font.family: "JetBrainsMono NF"
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            Text {
                textFormat: Text.PlainText
                visible: Services.AppState.hostName !== ""
                text: "@" + Services.AppState.hostName
                color: Services.Colors.mist
                font.pixelSize: Services.Sizes.fsBody
                font.family: "JetBrainsMono NF"
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        ActionBtn {
            label: hero.action
            accent: true
            onGo: hero.triggered()
        }
    }
}
