import Quickshell
import QtQuick
import "root:/services" as Services
import "root:/modules/widgets" as Widgets

Rectangle {
    id: root
    // The bar this pill stands on (Bar.qml hands it in).
    property var spec: Services.Sizes.first

    // How this pill draws itself, chosen in Settings > Bar > Layout.
    readonly property string content: Services.Pills.contentOf("usb")
    readonly property bool outlined: root.spec.outlined("usb")
    // The bar's one hover language, from Sizes: grow under the pointer,
    // give a little under the click.
    scale: Services.Sizes.hoverScale(hover.containsMouse, hover.pressed)
    Behavior on scale { Widgets.Anim { speed: Services.Sizes.pillHoverMs } }
    // Something on it is mounted: said by the glyph alone, the way the other
    // pills say a state. Filling the whole pill read as it lighting up.
    readonly property bool anyMounted: Services.USB.anyMounted

    // While its panel is up the pill IS the panel: it steps aside so the drop
    // that grew out of its rect reads as the pill falling open. Same relay the
    // system chips use; without it the panel just appeared next to a pill that
    // was still sitting there.
    property bool takenOver: false
    readonly property bool panelOpen: Services.AppState.usbVisible
    onPanelOpenChanged: {
        if (panelOpen) { handBack.stop(); handOver.restart() }
        else { handOver.stop(); handBack.restart() }
    }
    // Both waits come from Sizes, the same ones the drop itself uses: standing
    // down before the panel's window is on screen left the bar blank with
    // nothing moving anywhere yet.
    Timer {
        id: handOver
        interval: Services.Sizes.panelArmMs
        onTriggered: root.takenOver = true
    }
    Timer {
        id: handBack
        interval: Services.Sizes.panelHandBackMs
        onTriggered: root.takenOver = false
    }

    readonly property bool vertical: Services.Sizes.barVertical
    readonly property bool present: Services.USB.drives.length > 0

    // Collapses along the bar's own axis: width on a horizontal bar, height on
    // a vertical one, where the pill is icon-only anyway.
    height: root.vertical ? (root.present ? Services.Sizes.pillH : 0) : Services.Sizes.pillH
    radius: Services.Sizes.pillR
    border.width: root.outlined ? Services.Sizes.outlineW : 0
    border.color: Services.Colors.fillOutline
    // The fill is the open panel's, and only in the window style: in the
    // morph one the pill BECOMES the panel instead of staying behind lit.
    readonly property bool lit: root.panelOpen && root.spec.fills && !Services.Pills.wearsFace
    color: root.outlined ? Services.Colors.surfaceGlass
         : root.lit ? Services.Colors.ghost : root.spec.pillPlate
    gradient: Services.Prefs.useGradients && root.lit ? Services.Colors.accentGradient : null
    width: root.vertical ? Services.Sizes.pillH : (root.present ? icon.implicitWidth + 24 : 0)
    opacity: (root.takenOver && Services.Pills.wearsFace) ? 0.0 : (root.present ? 1.0 : 0.0)
    // Keyed on the device, not opacity: handed over to its panel the pill is
    // transparent but must keep its slot.
    readonly property bool wanted: root.present || root.takenOver || root.opacity > 0
    visible: root.wanted
    clip: true
    Behavior on color { Widgets.ColorAnim { speed: Services.Sizes.msEmphasis } }
    Behavior on width { enabled: !Services.Sizes.hidden; Widgets.Anim {} }
    Behavior on height { enabled: !Services.Sizes.hidden; Widgets.Anim {} }
    Behavior on opacity { Widgets.Anim { speed: Services.Sizes.msMicro } }

    Text {
        textFormat: Text.PlainText
        id: icon
        anchors.centerIn: parent
        text: "\ue1e0"
        // Dark only on the accent fill; lit when something is mounted; lifted
        // to snow under the pointer, like every other pill.
        color: root.lit ? Services.Colors.accentText
             : hover.containsMouse ? Services.Colors.snow
             : root.anyMounted ? Services.Colors.ghost
                               : Services.Colors.mist
        font.pixelSize: 22
        font.family: "Material Symbols Rounded"
        Behavior on color { Widgets.ColorAnim { speed: Services.Sizes.msEmphasis } }
    }

    PillCenter { key: "usb" }

    // The panel falls out of this pill wearing its glyph, so the pill has to
    // say what it is showing. Icon only: the pill has no words to hand over.
    Component.onCompleted: Services.AppState.setPillFace("usb", icon.text, "")

    MouseArea {
        id: hover
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: Services.AppState.togglePanel("usbVisible")
    }
}
