import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import "root:/modules/widgets" as Widgets
import "root:/services" as Services

PanelWindow {
    id: win
    anchors { top: true; left: true; right: true; bottom: true }
    screen: Services.Screens.active
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: Services.Notifications.activePopups.length > 0

    // The surface spans the whole screen but only the toast column should grab
    // the pointer — otherwise the invisible rest of the window eats clicks meant
    // for the bar pills underneath. Mask input to the cards' region.
    mask: Region { item: col }

    // Where the rail will open (it follows its pill), so the stack can take the
    // other side and both can be open at once.
    readonly property real railX: Services.Sizes.panelX(win.width, Services.Sizes.notifRailW,
                                                        Services.AppState.notificationPillCenterX)
    readonly property bool railLeft: win.railX + Services.Sizes.notifRailW / 2 < win.width / 2
    readonly property bool stackRight: win.railLeft

    // Cards enter from, and leave towards, the edge the stack hugs, so the
    // motion always points at where the stack lives.
    readonly property int offEdge: win.stackRight ? 40 : -40

    Column {
        id: col
        // Opposite side from the notification rail, so both can be open
        x: win.stackRight
           ? parent.width - width - Services.Sizes.marginRight
           : Services.Sizes.marginLeft
        y: Services.Sizes.pinBottom
           ? parent.height - height - Services.Sizes.marginBottom
           : Services.Sizes.marginTop
        spacing: 8
        width: 360

        move: Transition {
            NumberAnimation { properties: "x,y"; duration: 260; easing.type: Services.Sizes.easeBox }
        }

        Repeater {
            model: Services.Notifications.shownPopups

            delegate: Item {
                id: card
                required property var modelData
                readonly property bool isSystem: modelData.source === "system"
                // The service owns the countdown and decides when a card goes;
                // the card only plays it.
                readonly property bool leaving: Services.Notifications.leavingIds.indexOf(modelData.id) !== -1

                // Buttons the sender offered. "default" is not one of them: it
                // is what clicking the card itself does. They only work while
                // the live notification is around to invoke them.
                readonly property var acts: (modelData.actions || []).filter(a => a.id !== "default")
                // A system toast carries its own actions (a shell line each),
                // so it is not held to the live-notification test.
                readonly property bool hasActs: acts.length > 0
                                                && (isSystem
                                                    || Services.Notifications.liveIds.indexOf(modelData.id) !== -1)

                // A system toast with a picture (the screenshot) gets a taller
                // row: a 16:9 frame squeezed into the glyph's box is a smudge.
                readonly property bool hasShot: isSystem && (modelData.image || "") !== ""
                readonly property int contentH: isSystem ? (hasShot ? 78 : 62)
                                                        : (bodyTxt.visible ? 94 : 70)
                readonly property int fullH: contentH + (hasActs ? 42 : 0)

                // Collapsing to nothing is the second beat of the exit, so the
                // cards below close the gap instead of jumping up when this one
                // is dropped from the model.
                property real collapse: 1
                width: 360
                height: fullH * collapse
                // Only for the height JUMP when a card gains or loses its
                // action row. On the way out it has to be off: `collapse` is
                // already an animation, and a Behavior chasing each of its
                // intermediate values stretched the collapse past the budget
                // the service gives the card to be gone in.
                Behavior on height {
                    enabled: !card.leaving
                    Widgets.Anim { speed: Services.Sizes.msMicro }
                }


                function dismiss() { Services.Notifications.dismissPopup(modelData.id) }

                // Reading the stack holds every countdown. The hold is released
                // on destruction too: a delegate can be torn down mid-hover
                // when the model is reassigned, and a hold left behind would
                // freeze the stack for good.
                property bool holding: false
                function hold(on) {
                    if (on === card.holding) return
                    card.holding = on
                    Services.Notifications.hoverHolds += on ? 1 : -1
                }
                Component.onDestruction: card.hold(false)

                onLeavingChanged: if (leaving) { enterAnim.stop(); exitAnim.start() }

                Rectangle {
                    id: shell
                    anchors.fill: parent
                    radius: 16
                    color: Services.Colors.surfacePanel
                    border.width: Services.Colors.panelEdgeW
                    border.color: Services.Colors.fillOutline
                    clip: true
                    transform: Translate { id: slideT }

                    // Hover lifts the card a touch. Flat colour, no shadow.
                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: Services.Colors.ghostAlpha(cardHover.containsMouse ? 0.07 : 0.0)
                        Behavior on color { Widgets.ColorAnim { speed: Services.Sizes.msMicro } }
                    }

                    // ── Entry and exit, spelled out ───────────────────────
                    // Not Behaviors: the two are asymmetric, and a Behavior
                    // with a conditional duration reads the OLD value of the
                    // flag that picks it.
                    ParallelAnimation {
                        id: enterAnim
                        NumberAnimation { target: shell; property: "opacity"; from: 0; to: 1; duration: 240; easing.type: Services.Sizes.easeOut }
                        NumberAnimation { target: slideT; property: "x"; from: win.offEdge; to: 0; duration: 460; easing.type: Services.Sizes.easeBox }
                        NumberAnimation { target: shell; property: "scale"; from: 0.94; to: 1; duration: 460; easing.type: Services.Sizes.easeBox }
                    }

                    SequentialAnimation {
                        id: exitAnim
                        ParallelAnimation {
                            NumberAnimation { target: shell; property: "opacity"; to: 0; duration: 190; easing.type: Services.Sizes.easeIn }
                            NumberAnimation { target: slideT; property: "x"; to: win.offEdge; duration: 220; easing.type: Services.Sizes.easeIn }
                            NumberAnimation { target: shell; property: "scale"; to: 0.92; duration: 220; easing.type: Services.Sizes.easeIn }
                        }
                        NumberAnimation { target: card; property: "collapse"; to: 0; duration: 170; easing.type: Services.Sizes.easeOut }
                    }

                    // A rebuilt delegate must not replay its entrance. The
                    // Repeater recreates every card whenever the model array is
                    // reassigned, which is on every single new notification.
                    Component.onCompleted: {
                        if (card.leaving) {
                            // Already on its way out: land on the end state
                            // rather than starting the exit over.
                            shell.opacity = 0
                            shell.scale = 0.92
                            slideT.x = win.offEdge
                            card.collapse = 0
                        } else if (Services.Notifications.hasEntered(card.modelData.id)) {
                            shell.opacity = 1
                            shell.scale = 1
                            slideT.x = 0
                        } else {
                            Services.Notifications.markEntered(card.modelData.id)
                            enterAnim.start()
                        }
                    }

                    MouseArea {
                        id: cardHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onContainsMouseChanged: card.hold(containsMouse)
                        // Clicking the body runs the sender's default action
                        // when there is one — that is what opens the chat the
                        // message came from — and closes the toast otherwise.
                        onClicked: Services.Notifications.activateDefault(card.modelData.id)
                    }

                    // ── System: illustrative glyph, label, message ──
                    Item {
                        visible: card.isSystem
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 12
                        height: card.contentH - 24

                        ClippingRectangle {
                            id: sysBox
                            // The shot keeps the screen's shape; everything
                            // else stays the square glyph box it always was.
                            width: card.hasShot ? 92 : 38
                            height: card.hasShot ? 52 : 38
                            radius: 11
                            anchors.verticalCenter: parent.verticalCenter
                            color: Services.Colors.fillLine
                            Image {
                                id: sysShot
                                anchors.fill: parent
                                visible: card.hasShot && status === Image.Ready
                                source: card.modelData.image || ""
                                sourceSize.width: 256
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }
                            Text {
                                anchors.centerIn: parent
                                visible: !sysShot.visible
                                text: card.modelData.glyph || ""
                                color: Services.Colors.ghost
                                font.pixelSize: card.modelData.glyphIsLetter ? 17 : 18
                                font.bold: card.modelData.glyphIsLetter === true
                                font.family: card.modelData.glyphIsLetter ? "JetBrainsMono NF" : "Material Symbols Rounded"
                            }
                        }

                        Column {
                            anchors.left: sysBox.right
                            anchors.leftMargin: 12
                            anchors.right: parent.right
                            anchors.rightMargin: 24
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 3
                            Text {
                                text: card.modelData.summary || Services.I18n.t("notify.systemAlert")
                                color: Services.Colors.ash
                                font.pixelSize: 8
                                font.family: "JetBrainsMono NF"
                                font.letterSpacing: 1.2
                            }
                            Text {
                                width: parent.width
                                text: card.modelData.body || ""
                                color: Services.Colors.snow
                                font.pixelSize: 13
                                font.bold: true
                                font.family: "JetBrainsMono NF"
                                elide: Text.ElideRight
                            }
                        }
                    }

                    // ── Apps: art, who it is from, what it says ──
                    // The sender is the headline, not the app: "Ana Ruiz"
                    // matters more than "Signal", which is a caption above it.
                    Item {
                        visible: !card.isSystem
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 12
                        height: card.contentH - 24

                        ClippingRectangle {
                            id: artBox
                            width: 40; height: 40
                            radius: 13
                            anchors.top: parent.top
                            color: Services.Colors.fillLine
                            Image {
                                id: toastIconImg
                                // The notice's own art (a sender's avatar) fills
                                // the frame; a bare app icon is padded, because
                                // app icons are drawn to sit on a background.
                                readonly property bool isArt: (card.modelData.image || "") !== ""
                                anchors.fill: parent
                                anchors.margins: isArt ? 0 : 7
                                source: card.modelData.image || card.modelData.icon || ""
                                sourceSize.width: 64
                                sourceSize.height: 64
                                fillMode: isArt ? Image.PreserveAspectCrop : Image.PreserveAspectFit
                                visible: status === Image.Ready
                            }
                            Text {
                                anchors.centerIn: parent
                                visible: toastIconImg.status !== Image.Ready
                                text: "\uf727"
                                color: Services.Colors.ghost
                                font.pixelSize: 18
                                font.family: "Material Symbols Rounded"
                            }
                        }

                        Column {
                            anchors.left: artBox.right
                            anchors.leftMargin: 12
                            anchors.right: parent.right
                            anchors.top: parent.top
                            spacing: 2

                            Row {
                                width: parent.width
                                spacing: 6
                                Text {
                                    width: Math.min(implicitWidth, parent.width - 74)
                                    text: (card.modelData.appName || Services.I18n.t("notify.unknownApp")).toUpperCase()
                                    color: Services.Colors.ash
                                    font.pixelSize: 8
                                    font.family: "JetBrainsMono NF"
                                    font.letterSpacing: 1.2
                                    elide: Text.ElideRight
                                }
                                Rectangle {
                                    width: 2; height: 2; radius: 1
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: Services.Colors.ash
                                }
                                Text {
                                    text: Services.Notifications.relTime(card.modelData.timestamp, Services.Notifications.clockTick)
                                    color: Services.Colors.ash
                                    font.pixelSize: 8
                                    font.family: "JetBrainsMono NF"
                                }
                            }

                            Text {
                                width: parent.width - 20
                                text: card.modelData.summary || card.modelData.appName || ""
                                color: Services.Colors.snow
                                font.pixelSize: 13
                                font.bold: true
                                font.family: "JetBrainsMono NF"
                                elide: Text.ElideRight
                                topPadding: 2
                            }
                            Text {
                                id: bodyTxt
                                width: parent.width
                                visible: (card.modelData.body || "") !== ""
                                text: card.modelData.body || ""
                                color: Services.Colors.mist
                                font.pixelSize: 11
                                font.family: "JetBrainsMono NF"
                                elide: Text.ElideRight
                                maximumLineCount: 2
                                wrapMode: Text.WordWrap
                            }
                        }
                    }

                    // Tucked into the corner: present, but never the loudest
                    // thing on the card.
                    Widgets.IconButton {
                        size: 24
                        glyph: "\ue5cd"
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 8
                        onActivated: card.dismiss()
                    }

                    // ── What the sender asked us to offer ──
                    // The server advertises actionsSupported, so apps send
                    // these; until now nothing drew them and they were
                    // unreachable. Aligned under the text, not the art.
                    Row {
                        visible: card.hasActs
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        // Under the text, whatever the box to its left is.
                        anchors.leftMargin: card.hasShot ? 116 : 64
                        anchors.rightMargin: 12
                        anchors.bottomMargin: 10
                        spacing: 6

                        Repeater {
                            model: card.acts.slice(0, 3)
                            delegate: Rectangle {
                                required property var modelData
                                height: 28
                                width: Math.min(140, actLabel.implicitWidth + 22)
                                radius: 9
                                color: Services.Colors.fillRest
                                Behavior on color { Widgets.ColorAnim { speed: Services.Sizes.msMicro } }
                                scale: Services.Sizes.hoverScale(actHover.containsMouse, actHover.pressed)
                                Behavior on scale { NumberAnimation { duration: Services.Sizes.pillHoverMs; easing.type: Services.Sizes.easeOut } }

                                Text {
                                    id: actLabel
                                    anchors.centerIn: parent
                                    text: modelData.text || modelData.id
                                    color: actHover.containsMouse ? Services.Colors.snow : Services.Colors.mist
                                    font.pixelSize: 11
                                    font.family: "JetBrainsMono NF"
                                    elide: Text.ElideRight
                                    Behavior on color { Widgets.ColorAnim { speed: Services.Sizes.msMicro } }
                                }

                                MouseArea {
                                    id: actHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Services.Notifications.invokeAction(card.modelData.id, modelData.id)
                                }
                            }
                        }
                    }

                }
            }
        }

        // Tail of a burst: how many toasts are queued, and a way to sweep them.
        // Two compact buttons tucked against the edge the stack hugs.
        Row {
            visible: Services.Notifications.hiddenPopupCount > 0
            spacing: 6
            x: Services.Sizes.barPosition === "right" ? 0 : parent.width - width

            Rectangle {
                width: 46
                height: 30
                radius: 9
                color: Services.Colors.surfacePanel
                Behavior on color { Widgets.ColorAnim { speed: Services.Sizes.msMicro } }
                border.width: Services.Colors.panelEdgeW
                border.color: Services.Colors.fillOutline
                scale: Services.Sizes.hoverScale(countHover.containsMouse, countHover.pressed)
                Behavior on scale { NumberAnimation { duration: Services.Sizes.pillHoverMs; easing.type: Services.Sizes.easeOut } }

                Text {
                    anchors.centerIn: parent
                    text: "+" + Services.Notifications.hiddenPopupCount
                    color: countHover.containsMouse ? Services.Colors.snow : Services.Colors.mist
                    font.pixelSize: 11
                    font.bold: true
                    font.family: "JetBrainsMono NF"
                    Behavior on color { Widgets.ColorAnim { speed: Services.Sizes.msMicro } }
                }

                MouseArea {
                    id: countHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Services.AppState.notificationsVisible = true
                }
            }

            Rectangle {
                width: 34
                height: 30
                radius: 9
                color: Services.Colors.surfacePanel
                Behavior on color { Widgets.ColorAnim { speed: Services.Sizes.msMicro } }
                border.width: Services.Colors.panelEdgeW
                border.color: Services.Colors.fillOutline
                scale: Services.Sizes.hoverScale(sweepHover.containsMouse, sweepHover.pressed)
                Behavior on scale { NumberAnimation { duration: Services.Sizes.pillHoverMs; easing.type: Services.Sizes.easeOut } }

                Text {
                    anchors.centerIn: parent
                    // The same glyph the rail uses for the same idea: these
                    // have been seen. One action, one icon.
                    text: "\ue0b8"
                    color: sweepHover.containsMouse ? Services.Colors.snow : Services.Colors.mist
                    font.pixelSize: 15
                    font.family: "Material Symbols Rounded"
                    Behavior on color { Widgets.ColorAnim { speed: Services.Sizes.msMicro } }
                }

                MouseArea {
                    id: sweepHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Services.Notifications.dismissAllPopups()
                }
            }
        }

    }
}
