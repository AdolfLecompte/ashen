import QtQuick

// The login screen's palette: the dark scheme, written where the sddm user can read it.
QtObject {
    property color abyss: "{{colors.surface_container_lowest.dark.hex}}"
    property color surface: "{{colors.surface_container.dark.hex}}"
    property color elevated: "{{colors.surface_container_highest.dark.hex}}"
    property color snow: "{{colors.on_surface.dark.hex}}"
    property color mist: "{{colors.on_surface_variant.dark.hex}}"
    property color ash: "{{colors.outline.dark.hex}}"
    property color ghost: "{{colors.primary.dark.hex}}"
    property color shade: "{{colors.secondary.dark.hex}}"
    property color neutral: "{{colors.tertiary.dark.hex}}"
    property color error_: "{{colors.error.dark.hex}}"
}
