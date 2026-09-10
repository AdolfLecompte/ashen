import QtQuick
import Qt5Compat.GraphicalEffects
import QtQuick.Layouts
import "root:/services" as Services

// The wallpaper, at the size it deserves: the picture is the whole card and
// everything else rides on top of it. PreviewCard stays as it is -- the About
// tab's profile photo is a thumbnail on purpose, this one is not.
Rectangle {
    id: hero

    // The action button's word, and what it does.
    property string action: Services.I18n.t("common.open")
    signal triggered()

    Layout.fillWidth: true
    implicitHeight: 220
    radius: Services.Sizes.cardR
    color: Services.Colors.fillLine
    clip: true

    readonly property string path: Services.Wallpaper.path
    readonly property string fileName: hero.path === "" ? "" : hero.path.split("/").pop()
    readonly property string folder: Services.Prefs.wallpaperDir !== ""
        ? Services.Prefs.wallpaperDir : Services.Paths.wallpapers
    readonly property bool video: /\.(mp4|webm|mkv|mov)$/i.test(hero.path)
    readonly property bool animated: hero.video || /\.gif$/i.test(hero.path)

    // Cropped, not fitted: at this width a fit would letterbox every wallpaper
    // that is not the screen's own ratio, and the bars would be most of the card.
    Image {
        id: shot
        anchors.fill: parent
        source: Services.Wallpaper.stillUrl
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        // Decoded at the width it is DRAWN at, not the width it was shot at: a
        // 4K wallpaper is 8 megapixels held in memory to fill a strip 220 px
        // tall. Width and not height because the crop here is width-driven --
        // the box is far wider than it is tall, so the width is what has to
        // cover and the height spills over on its own.
        sourceSize.width: shot.width
        visible: status === Image.Ready
        // The path is stable while the file behind it changes.
        cache: false
        layer.enabled: true
        layer.smooth: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: hero.width
                height: hero.height
                radius: hero.radius
            }
        }
    }

    // Nothing chosen yet.
    Text {
        anchors.centerIn: parent
        text: "\ue1bc"
        color: Services.Colors.ghost
        font.pixelSize: 52
        font.family: "Material Symbols Rounded"
        visible: shot.status !== Image.Ready
    }

    // The wallpaper is somebody else's picture, so the words need ground of
    // their own: a veil over the bottom third, never a plate.
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: parent.height * 0.46
        visible: shot.status === Image.Ready
        // Hover lifts the veil rather than filling the card.
        opacity: heroHover.containsMouse ? 1 : 0.86
        Behavior on opacity { NumberAnimation { duration: Services.Sizes.msMicro } }
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0) }
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.66) }
        }
    }

    // A video shows a still frame, so it has to say that it is one.
    Rectangle {
        visible: hero.animated
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        height: 20
        width: badgeRow.implicitWidth + 12
        radius: 6
        color: Qt.rgba(0, 0, 0, 0.62)

        Row {
            id: badgeRow
            anchors.centerIn: parent
            spacing: 4

            Text {
                text: "\ue02c"
                color: Services.Colors.snow
                font.pixelSize: 11
                font.family: "Material Symbols Rounded"
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: hero.video ? "VIDEO" : "GIF"
                color: Services.Colors.snow
                font.pixelSize: 9
                font.bold: true
                font.family: "JetBrainsMono NF"
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    // The whole card opens the picker; the button is where you look for it.
    MouseArea {
        id: heroHover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: hero.triggered()
    }

    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 16
        spacing: 12

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                text: hero.fileName === "" ? "No wallpaper yet" : hero.fileName
                color: Services.Colors.snow
                font.pixelSize: Services.Sizes.fsCardTitle
                font.bold: true
                font.family: "JetBrainsMono NF"
                elide: Text.ElideMiddle
                Layout.fillWidth: true
            }
            Text {
                text: hero.folder
                color: Services.Colors.mist
                font.pixelSize: Services.Sizes.fsMeta
                font.family: "JetBrainsMono NF"
                elide: Text.ElideMiddle
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
