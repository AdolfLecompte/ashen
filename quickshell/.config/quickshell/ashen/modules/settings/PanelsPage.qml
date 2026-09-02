import QtQuick
import QtQuick.Layouts
import "root:/modules/settings/components"

// The three surfaces that talk to you: the clock chip and its weather, the
// music card, and the notifications.
TabPage {
    PanelsClockPage {}
    PanelsMediaPage {}
    PanelsNotifyPage {}
}
