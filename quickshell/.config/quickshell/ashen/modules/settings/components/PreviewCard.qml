import QtQuick
import Qt5Compat.GraphicalEffects
import QtQuick.Layouts
import "root:/services" as Services
import "root:/modules/widgets" as Widgets

// Profile picture and Wallpaper are the same card: a rounded preview of an
// image, a glyph while there is none, a label pinned beside it and one
// action button.
Rectangle {
    id: card
    property string source: ""
    property string fallbackGlyph: ""
    property string title: ""
    property string subtitle: ""
    property string action: ""
    // While the card is waiting on something of its own -- a file dialog that
    // is still open -- it stops taking clicks and says so by standing down a
    // little. Two dialogs from two clicks is the thing being prevented.
    property bool busy: false
    // Square + crop suits a face; a wallpaper needs a wide tile and a fit,
    // since they run from near-square to 2.76 ultrawide and cropping would
    // hide most of the picture.
    property int previewWidth: 80
    property int previewFill: Image.PreserveAspectCrop
    signal triggered()

    Layout.fillWidth: true
    height: 110
    radius: Services.Sizes.cardR
    color: Services.Colors.fillLine
    // Capped in PIXELS, not in percent: 6% of a card this wide is thirty px of
    // growth, which pushed the picture and both corners past the tab's clip.
    scale: Services.Sizes.hoverScaleFor(card.width, cardHover.containsMouse, cardHover.pressed)
    Behavior on scale { NumberAnimation { duration: Services.Sizes.pillHoverMs; easing.type: Services.Sizes.easeOut } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        // Small gap only: the label belongs to the picture, so it sits next
        // to it rather than drifting into the middle of the card.
        spacing: 12

        Rectangle {
            id: preview
            width: card.previewWidth; height: 80
            radius: Services.Sizes.cardR
            color: Services.Colors.fillRest
            clip: true

            // Masked through the image's own layer: a separate OpacityMask
            // item left the picture poking out of one rounded corner.
            Image {
                id: previewImg
                anchors.fill: parent
                source: card.source
                fillMode: card.previewFill
                asynchronous: true
                // See WallpaperHero: a thumbnail 80 px tall has no use for the
                // other seven and a half megapixels.
                sourceSize.width: previewImg.width
                visible: status === Image.Ready
                // paths are stable while the file behind them changes
                cache: false
                layer.enabled: true
                layer.smooth: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: preview.width
                        height: preview.height
                        radius: preview.radius
                    }
                }
            }
            Text {
                anchors.centerIn: parent
                text: card.fallbackGlyph
                color: Services.Colors.ghost
                font.pixelSize: 40
                font.family: "Material Symbols Rounded"
                visible: previewImg.status !== Image.Ready
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3
            Text {
                text: card.title
                color: Services.Colors.snow
                font.pixelSize: Services.Sizes.fsCardTitle
                font.bold: true
                font.family: "JetBrainsMono NF"
                Layout.alignment: Qt.AlignLeft
            }
            Text {
                text: card.subtitle
                color: Services.Colors.mist
                font.pixelSize: Services.Sizes.fsMeta
                font.family: "JetBrainsMono NF"
                elide: Text.ElideMiddle
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignLeft
            }
        }

        Rectangle {
            width: 90; height: 36
            radius: Services.Sizes.innerR
            color: Services.Colors.ghost
            gradient: Services.Prefs.useGradients ? Services.Colors.accentGradient : null
            opacity: card.busy ? 0.55 : 1
            Behavior on opacity { Widgets.Anim { speed: Services.Sizes.msMicro } }
            Text {
                anchors.centerIn: parent
                text: card.action
                color: Services.Colors.accentText
                font.pixelSize: Services.Sizes.fsBody
                font.bold: true
                font.family: "JetBrainsMono NF"
            }
        }
    }
    MouseArea {
        id: cardHover
        anchors.fill: parent
        cursorShape: card.busy ? Qt.BusyCursor : Qt.PointingHandCursor
        hoverEnabled: true
        enabled: !card.busy
        onClicked: card.triggered()
    }
}
