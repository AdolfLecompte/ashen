import QtQuick
import QtQuick.Layouts
import "root:/services" as Services

// The box every settings section sits in: a titled, rounded panel that grows
// with its content. Children go straight inside it, no wrapper needed.
Rectangle {
    id: cardRoot
    default property alias content: cardInner.data
    property string title: ""
    // The card's own glyph, in its tile beside the title (the panels' header).
    property string glyph: ""
    Layout.fillWidth: true
    radius: Services.Sizes.cardR
    color: Services.Colors.fillInset
    implicitHeight: cardInner.implicitHeight + 32
    ColumnLayout {
        id: cardInner
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 16
        spacing: 12
        RowLayout {
            visible: cardRoot.title !== ""
            spacing: 10
            Layout.bottomMargin: 4
            Rectangle {
                visible: cardRoot.glyph !== ""
                Layout.preferredWidth: 30
                Layout.preferredHeight: 30
                radius: Services.Sizes.innerR
                color: Services.Colors.fillLine
                Text {
                    textFormat: Text.PlainText
                    anchors.centerIn: parent
                    text: cardRoot.glyph
                    color: Services.Colors.ghost
                    font.pixelSize: 18
                    font.family: "Material Symbols Rounded"
                }
            }
            Text {
                textFormat: Text.PlainText
                Layout.fillWidth: true
                text: cardRoot.title
                // The card's name leads: larger than any row inside it.
                color: Services.Colors.snow
                font.pixelSize: Services.Sizes.fsCardTitle
                font.bold: true
                font.family: "JetBrainsMono NF"
                elide: Text.ElideRight
            }
        }
    }
}
