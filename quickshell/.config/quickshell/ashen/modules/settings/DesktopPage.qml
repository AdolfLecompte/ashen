import QtQuick
import QtQuick.Layouts
import "root:/modules/settings/components"

// The two surfaces that are always there, in one scroll: where the bar sits,
// what it carries, and what stands on the wallpaper. They used to be three
// tabs inside a tab, which hid two of them behind a guess.
TabPage {
    BarShapePage {}
    BarLayoutPage {}
    BarDesktopPage {}
}
