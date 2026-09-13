import QtQuick
import "root:/modules/settings/components"

// The bar itself: where it sits, what shape it wears, and what it carries.
// Split out of Desktop, which was holding the bar, the dock and the wallpaper
// widgets under one word that named none of the three.
TabPage {
    BarShapePage {}
    BarLayoutPage {}
}
