import Quickshell
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "root:/services" as Services
import "root:/modules/widgets" as Widgets
import "root:/modules/settings/components"

// The furniture on the wallpaper: which widgets are out, what shape each
// one wears, and how they land when you drop them.
Section {
    id: tab

    // ── Desktop widgets ──────────────────────────────────────
    // Turning one on, choosing its shape and putting it somewhere all happen
    // on the desktop itself now -- this card is the door, not the controls.
    Card {
        title: "Desktop"

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            RowGlyph { glyph: "\ue1bd" }

            ColumnLayout {
                spacing: 0
                Text {
                    text: "Desktop widgets"
                    color: Services.Colors.snow
                    font.pixelSize: Services.Sizes.fsInput
                    font.family: "JetBrainsMono NF"
                }
                Text {
                    // Read off the live layout, so it follows a wallpaper
                    // profile arriving as much as your own switches.
                    text: {
                        const cat = Services.Desktop.catalogue.filter(w => !w.multi)
                        let on = 0
                        for (const w of cat) if (Services.Desktop.shown(w.id)) on++
                        const pics = Services.Desktop.idsOf("image").length
                        return on + " of " + cat.length + " on"
                             + (pics > 0 ? "  \u00b7  " + pics + (pics === 1 ? " picture" : " pictures") : "")
                    }
                    color: Services.Colors.ash
                    font.pixelSize: Services.Sizes.fsMeta
                    font.family: "JetBrainsMono NF"
                }
            }
            // Without this the button sits against its own name instead of
            // the edge of the card.
            Item { Layout.fillWidth: true }
            ActionBtn {
                label: Services.Desktop.editMode ? "Done" : "Arrange"
                accent: Services.Desktop.editMode
                onGo: {
                    Services.Desktop.editMode = !Services.Desktop.editMode
                    // The drawer covers the half of the screen the widgets are
                    // on; arranging them behind it is arranging them blind.
                    if (Services.Desktop.editMode) Services.AppState.settingsVisible = false
                }
            }
        }
    }


    Item { Layout.preferredHeight: 8 }
}
