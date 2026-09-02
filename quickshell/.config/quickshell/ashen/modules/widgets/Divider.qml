import QtQuick
import QtQuick.Layouts
import "root:/services" as Services

// Hairline between two groups of rows. In a Layout it fills the width by
// itself; in a plain Column the caller sets `width`.
Rectangle {
    Layout.fillWidth: true
    height: 1
    color: Services.Colors.fillLine
}
