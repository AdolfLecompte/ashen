import QtQuick
import QtQuick.Layouts

import "root:/services" as Services
import "root:/modules/widgets" as Widgets

// Collapsible slot: same slide-open feel as the volume/mic DevicePicker.
// Wraps its children in a clipped Item whose height eases 0 <-> content, so
// sections grow/shrink smoothly instead of snapping in.
Item {
    id: cl
    property bool open: false
    property int gap: 10
    default property alias content: inner.data
    Layout.fillWidth: true
    clip: true
    implicitHeight: open ? inner.implicitHeight : 0
    Behavior on implicitHeight { Widgets.Anim {} }
    opacity: open ? 1.0 : 0.0
    Behavior on opacity { Widgets.Anim { speed: Services.Sizes.msMicro } }
    ColumnLayout {
        id: inner
        width: cl.width
        spacing: cl.gap
    }
}
