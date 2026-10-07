import QtQuick
import QtQuick.Layouts
import "root:/services" as Services

// A group of rows inside a panel: the tinted card every panel shares.
// `amt` is the panel's stage for this plate (0..1); it fades and rises with it.
Rectangle {
    id: plate
    property real amt: 1
    property int pad: 14
    default property alias content: inner.data

    Layout.fillWidth: true
    implicitHeight: inner.implicitHeight + plate.pad * 2
    radius: Services.Sizes.cardLgR
    color: Services.Colors.plate
    opacity: plate.amt
    transform: Translate { y: (1 - plate.amt) * 12 }

    ColumnLayout {
        id: inner
        x: plate.pad
        y: plate.pad
        width: plate.width - plate.pad * 2
        spacing: 10
    }
}
