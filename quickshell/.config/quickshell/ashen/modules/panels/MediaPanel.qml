import Quickshell
import Quickshell.Widgets
import QtQuick
import "root:/services" as Services
import "root:/modules/widgets" as Widgets

// The media pill's panel: the pill does not open a card beside itself, it
// BECOMES the card. The blob and its drivers live in Widgets.MorphCard.
// The card shows Widgets.MediaCard and takes its size from it.
PanelWindow {
    id: root
    anchors { top: true; left: true; right: true; bottom: true }
    screen: Services.Screens.active
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    // Everything but the bar's strip: a click on a pill has to reach it,
    // or changing panels costs two. See widgets/ShellMask.qml.
    mask: Widgets.ShellMask { winW: root.width; winH: root.height }
    // stays mapped through the close animation, so the exit plays in reverse
    readonly property bool shown: Services.AppState.mediaVisible
    visible: shown || card.closing

    // The pill stands aside while its panel is wearing its face.
    Binding {
        target: Services.AppState
        property: "mediaMorphing"
        // Not `morphing`: in "window" style the card never wears the pill's
        // face, and the pill must stay where it is.
        value: card.wearingFace
    }

    // Measured off the card itself, never off a constant -- though neither
    // number moves any more: the words are one line inside the room the
    // details column already had, so the box is the same whatever the track is
    // doing.
    readonly property real openW: panelRef.implicitWidth + panelRef.pad * 2
    readonly property real openH: panelRef.implicitHeight + panelRef.pad * 2

    // `hasPlayer` is derived from the copy we hold, not fetched separately:
    // two bindings onto the same ref update in whatever order QML likes, so
    // for a frame `hasPlayer` was true while `activePlayer` was already null.
    readonly property var activePlayer: panelRef.activePlayer
    readonly property bool hasPlayer: root.activePlayer !== null

    // The music stopping closes the card. The pill it wears the face of is gone
    // the moment there is no player, so a panel left open is a card standing on
    // a rect that no longer exists. `activePlayer` already survives the few ms
    // MPRIS goes null between tracks, so this only fires when it is really over.
    onHasPlayerChanged: if (!root.hasPlayer && Services.AppState.mediaVisible)
        Services.AppState.mediaVisible = false

    // Chip sizes at each end of the trip
    // What the pill is drawing: the copy below has to be the same shape, or
    // the pieces fly out of places the pill does not have. The title only on a
    // full top/bottom pill, the transport unless icon.
    readonly property string pillContent: Services.Pills.contentOf("media")
    readonly property bool pillVertical: Services.Sizes.barVertical
    readonly property bool titleInPill: !root.pillVertical && root.pillContent === "full"
    readonly property bool ctlInPill: root.pillContent !== "icon"
    readonly property real chipSm: Services.Sizes.innerH
    readonly property real playSm: Services.Sizes.innerH
    // Origin of the pill reference layout, in card coordinates
    readonly property real prColX: pillRef.x + refCol.x
    readonly property real prColY: pillRef.y + refCol.y

    MouseArea {
        anchors.fill: parent
        z: -1
        // Off while the panel is closing: the window stays mapped for the
        // animation, and a live dismiss layer ate the next click.
        enabled: Services.AppState.mediaVisible
        onClicked: Services.AppState.mediaVisible = false
    }

    FocusScope {
        anchors.fill: parent
        focus: root.shown
        Keys.onEscapePressed: Services.AppState.mediaVisible = false
    }

    Widgets.MorphCard {
        id: card
        anchors.fill: parent

        shown: root.shown
        pillW: Math.max(1, Services.AppState.mediaPillW)
        pillH: Math.max(1, Services.AppState.mediaPillH)
        pillCX: Services.AppState.mediaPillCenterX
        pillCY: Services.AppState.mediaPillCenterY
        hasPill: Services.Pills.onScreen("media")
        openW: root.openW
        openH: root.openH

        // ── Reference layout A: the pill ────────────────────────────────
        // A structural copy of MediaPill's grid -- same cells, same axis, same
        // gaps -- laid out but never drawn, so the shared items know where the
        // pill puts them. Centred, not left-anchored: the box then grows around
        // its contents instead of dragging them along.
        Grid {
            id: pillRef
            opacity: 0
            anchors.centerIn: parent
            spacing: 8
            columns: root.pillVertical ? 1
                : 1 + (root.titleInPill ? 1 : 0) + (root.ctlInPill ? 1 : 0)
            horizontalItemAlignment: Grid.AlignHCenter
            verticalItemAlignment: Grid.AlignVCenter

            Item {
                id: refArt
                width: Services.Sizes.pillH - 10
                height: Services.Sizes.pillH - 10
            }

            Column {
                id: refCol
                visible: root.titleInPill
                width: 120
                spacing: 3

                Text {
                    textFormat: Text.PlainText
                    id: refTitle
                    width: parent.width
                    text: panelRef.titleText
                    font.pixelSize: 11
                    font.bold: true
                    font.family: "JetBrainsMono NF"
                    elide: Text.ElideRight
                }
                // The pill's single "0:12/3:45" as three pieces at zero
                // spacing: in a monospaced face that lays out identically to
                // the joined string, and it lets the two numbers walk apart.
                Row {
                    id: refTimes
                    spacing: 0
                    Text {
                        textFormat: Text.PlainText
                        id: refPos
                        text: panelRef.posText
                        font.pixelSize: 10; font.bold: true
                        font.family: "JetBrainsMono NF"
                    }
                    Text {
                        textFormat: Text.PlainText
                        id: refSep
                        text: "/"
                        font.pixelSize: 10; font.bold: true
                        font.family: "JetBrainsMono NF"
                    }
                    Text {
                        textFormat: Text.PlainText
                        id: refLen
                        text: panelRef.lenText
                        font.pixelSize: 10; font.bold: true
                        font.family: "JetBrainsMono NF"
                    }
                }
            }

            Grid {
                id: refCtl
                visible: root.ctlInPill
                columns: root.pillVertical ? 1 : 3
                spacing: Services.Sizes.btnGap
                horizontalItemAlignment: Grid.AlignHCenter
                verticalItemAlignment: Grid.AlignVCenter

                Item { id: refPrev; width: root.chipSm; height: root.chipSm }
                Item { id: refPlay; width: root.playSm; height: root.playSm }
                Item { id: refNext; width: root.chipSm; height: root.chipSm }
            }
        }

        // ── Reference layout B: the card ────────────────────────────────
        // `ghostShared` leaves the flown pieces laid out but undrawn, so they are
        // targets rather than duplicates; `extrasOpacity` holds back what the pill
        // has no counterpart for until the blob has finished opening.
        Widgets.MediaCard {
            id: panelRef
            // Top, WITH the padding the box is sized for: anchoring to the
            // bare top edge put the cover and the title against the plate,
            // which clips.
            anchors.top: parent.top
            anchors.topMargin: panelRef.pad
            anchors.horizontalCenter: parent.horizontalCenter
            ghostShared: true
            extrasOpacity: card.contentAmt
            // The blob is the box; this is what happens inside it once the box
            // has landed. Morph gets both animations, not one instead of the other.
            stageFn: card.stage
            offerLyrics: true
        }

        // ── The shared items ────────────────────────────────────────────
        // One of each, drawn on top of both refs, walking from slot A to slot
        // B. These are the only transport controls the user can click.

        // Album art: 34 px pill chip to the card's cover, growing about its own
        // centre so it reads as the same square swelling.
        ClippingRectangle {
            id: flyArt
            readonly property real size: card.lerp(refArt.width, panelRef.artSize, card.morph)
            width: size
            height: size
            radius: card.lerp(Services.Sizes.innerR, 28, card.morph)
            color: Services.Colors.abyss
            x: card.lerp(pillRef.x + refArt.x + refArt.width / 2,
                         panelRef.x + panelRef.artCX, card.morph) - width / 2
            y: card.lerp(pillRef.y + refArt.y + refArt.height / 2,
                         panelRef.y + panelRef.artCY, card.morph) - height / 2
            // Changing track sweeps the flown pieces, the same numbers the card
            // publishes -- they are the ones actually drawn.
            opacity: panelRef.swapFade
            transform: Translate { x: panelRef.swapOffX }

            Image {
                id: flyImg
                anchors.fill: parent
                source: panelRef.shownArtUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                // The player reuses its temp file name: never serve a cached picture.
                cache: false
                visible: status === Image.Ready
            }
            Text {
                textFormat: Text.PlainText
                anchors.centerIn: parent
                // No cover, or one that did not load: never an empty square.
                visible: flyImg.status !== Image.Ready
                text: "\ue405"
                color: Services.Colors.ash
                font.family: "Material Symbols Rounded"
                font.pixelSize: card.lerp(18, 40, card.morph)
            }
        }

        // Title. Scaled rather than re-sized: stepping font.pixelSize from 11
        // to 18 reflows the glyphs in integer jumps and reads as a stutter.
        // Laid out at the big size and shrunk, so the elide width has to be
        // divided back out to keep the visible width honest.
        Text {
            textFormat: Text.PlainText
            id: flyTitle
            readonly property real m: root.titleInPill ? card.morph : 1
            readonly property real alone: root.titleInPill ? 1 : card.contentAmt
            readonly property real s: card.lerp(11 / 18, 1, flyTitle.m)
            readonly property real visW: card.lerp(refCol.width, panelRef.titleW, flyTitle.m)
            text: panelRef.shownTitle
            color: Services.Colors.snow
            opacity: panelRef.swapFade * flyTitle.alone
            font.pixelSize: 18
            font.bold: true
            font.family: "JetBrainsMono NF"
            elide: Text.ElideRight
            width: visW / s
            x: card.lerp(root.prColX + refTitle.x, panelRef.x + panelRef.titleX, flyTitle.m)
            y: card.lerp(root.prColY + refTitle.y + refTitle.height / 2,
                         panelRef.y + panelRef.titleCY, flyTitle.m) - height / 2
            transform: [
                Scale {
                    origin.x: 0
                    origin.y: flyTitle.height / 2
                    xScale: flyTitle.s
                    yScale: flyTitle.s
                },
                Translate { x: panelRef.swapOffX }
            ]
        }

        // Elapsed and total. Same size at both ends, so they only travel: in
        // the pill they are welded either side of a slash, in the card they
        // stand at opposite ends of the wave.
        Text {
            textFormat: Text.PlainText
            id: flyPos
            readonly property real m: root.titleInPill ? card.morph : 1
            readonly property real alone: root.titleInPill ? 1 : card.contentAmt
            opacity: flyPos.alone
            text: panelRef.posText
            color: Services.Colors.mist
            font.pixelSize: 10; font.bold: true
            font.family: "JetBrainsMono NF"
            x: card.lerp(root.prColX + refTimes.x + refPos.x,
                         panelRef.x + panelRef.posX, flyPos.m)
            y: card.lerp(root.prColY + refTimes.y + refPos.y + refPos.height / 2,
                         panelRef.y + panelRef.posCY, flyPos.m) - height / 2
        }
        // The slash has nowhere to go once the numbers separate, so it is the
        // one shared piece that does fade — quickly, before the gap opens.
        Text {
            textFormat: Text.PlainText
            id: flySep
            text: "/"
            color: Services.Colors.mist
            font.pixelSize: 10; font.bold: true
            font.family: "JetBrainsMono NF"
            opacity: 1 - Math.min(1, card.morph * 4)
            visible: root.titleInPill && opacity > 0.01
            x: card.lerp(root.prColX + refTimes.x + refSep.x, flyPos.x + flyPos.width, card.morph)
            y: flyPos.y
        }
        Text {
            textFormat: Text.PlainText
            id: flyLen
            readonly property real m: root.titleInPill ? card.morph : 1
            readonly property real alone: root.titleInPill ? 1 : card.contentAmt
            opacity: flyLen.alone
            text: panelRef.lenText
            color: Services.Colors.mist
            font.pixelSize: 10; font.bold: true
            font.family: "JetBrainsMono NF"
            x: card.lerp(root.prColX + refTimes.x + refLen.x,
                         panelRef.x + panelRef.lenX, flyLen.m)
            y: card.lerp(root.prColY + refTimes.y + refLen.y + refLen.height / 2,
                         panelRef.y + panelRef.lenCY, flyLen.m) - height / 2
        }

        // Transport chips: the same three plates the bar shows, grown and
        // respaced. Everything about their look lives in CtlChip, so hover
        // behaves identically at either size.
        Widgets.CtlChip {
            id: flyPrev
            readonly property real m: root.ctlInPill ? card.morph : 1
            opacity: root.ctlInPill ? 1 : card.contentAmt
            glyph: "\ue045"
            size: card.lerp(root.chipSm, panelRef.chipLg, flyPrev.m)
            glyphSize: card.lerp(18, 20, flyPrev.m)
            available: root.activePlayer !== null && root.activePlayer.canGoPrevious
            onTriggered: if (root.activePlayer) { Services.AppState.mediaStep(-1); root.activePlayer.previous() }
            x: card.lerp(pillRef.x + refCtl.x + refPrev.x + refPrev.width / 2,
                         panelRef.x + panelRef.prevCX, flyPrev.m) - width / 2
            y: card.lerp(pillRef.y + refCtl.y + refPrev.y + refPrev.height / 2,
                         panelRef.y + panelRef.prevCY, flyPrev.m) - height / 2
        }
        Widgets.CtlChip {
            id: flyPlay
            readonly property real m: root.ctlInPill ? card.morph : 1
            opacity: root.ctlInPill ? 1 : card.contentAmt
            glyph: panelRef.playGlyph
            size: card.lerp(root.playSm, panelRef.playLg, flyPlay.m)
            glyphSize: card.lerp(20, 24, flyPlay.m)
            available: root.hasPlayer
            active: root.activePlayer !== null && root.activePlayer.isPlaying
            onTriggered: if (root.activePlayer) root.activePlayer.togglePlaying()
            x: card.lerp(pillRef.x + refCtl.x + refPlay.x + refPlay.width / 2,
                         panelRef.x + panelRef.playCX, flyPlay.m) - width / 2
            y: card.lerp(pillRef.y + refCtl.y + refPlay.y + refPlay.height / 2,
                         panelRef.y + panelRef.playCY, flyPlay.m) - height / 2
        }
        Widgets.CtlChip {
            id: flyNext
            readonly property real m: root.ctlInPill ? card.morph : 1
            opacity: root.ctlInPill ? 1 : card.contentAmt
            glyph: "\ue044"
            size: card.lerp(root.chipSm, panelRef.chipLg, flyNext.m)
            glyphSize: card.lerp(18, 20, flyNext.m)
            available: root.activePlayer !== null && root.activePlayer.canGoNext
            onTriggered: if (root.activePlayer) { Services.AppState.mediaStep(1); root.activePlayer.next() }
            x: card.lerp(pillRef.x + refCtl.x + refNext.x + refNext.width / 2,
                         panelRef.x + panelRef.nextCX, flyNext.m) - width / 2
            y: card.lerp(pillRef.y + refCtl.y + refNext.y + refNext.height / 2,
                         panelRef.y + panelRef.nextCY, flyNext.m) - height / 2
        }
    }
}
