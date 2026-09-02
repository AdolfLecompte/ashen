import QtQuick
import QtQuick.Layouts

// A group of cards, with no page under it. What a settings page used to be
// minus the scrolling: several of these stack inside one TabPage, so things
// that belong together are read in one scroll instead of behind a second row
// of tabs.
ColumnLayout {
    Layout.fillWidth: true
    spacing: 14
}
