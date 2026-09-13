import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls

import "root:/services" as Services
import "root:/modules/widgets" as Widgets

PanelWindow {
    id: root
    anchors { top: true; left: true; right: true; bottom: true }
    screen: Services.Screens.active
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    // Everything but the bar's strip: a click on a pill has to reach it,
    // or changing panels costs two. See widgets/ShellMask.qml.
    mask: Widgets.ShellMask { winW: root.width; winH: root.height }
    // stay mapped through the close animation
    visible: Services.AppState.processVisible || closeDelay.running

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    readonly property bool shown: Services.AppState.processVisible

    // sampling only runs while the panel is up
    onShownChanged: {
        Services.SysMon.claim("process", shown)
        // The chip steps aside for as long as the panel wears its face -- and
        // in "window" style it never does.
        Services.AppState.processTakenOver = shown && card.wearingFace
        if (!shown) closeDelay.restart()
    }

    Timer { id: closeDelay; interval: card.closeMs }

    Component.onDestruction: Services.AppState.processTakenOver = false

    // Clicking anywhere off the card closes it, the same as every other panel.
    MouseArea {
        anchors.fill: parent
        z: -1
        // Off while the panel is closing: the window stays mapped for the
        // animation, and a live dismiss layer ate the next click.
        enabled: Services.AppState.processVisible
        onClicked: Services.AppState.processVisible = false
    }

    // The same drop the clock and the system chips open with. Its pill is a
    // chip on the utility trigger, so the edge is read live from the pill
    // rather than written at click time: a keybind never clicks.
    readonly property string srcEdge: Services.Sizes.overlayEdge
    // Its chip: on the utility pill of that edge, or on the bar.
    // No capsule since the utility pill went: this panel arrives from the
    // screen edge. The rect is still read while that is decided, so it is a
    // zero rect and not null -- reading .cx off null throws four times a frame.
    readonly property var chipRect: ({ cx: 0, cy: 0, w: 44, h: 44 })
    readonly property real openXCalc: srcEdge === "" ? NaN
        : srcEdge === "left" ? Services.Sizes.panelTop
        : srcEdge === "right" ? root.width - card.openW - Services.Sizes.panelTop
        : (root.width - card.openW) / 2
    readonly property real openYCalc: srcEdge === "" ? NaN
        : srcEdge === "top" ? Math.max(68, Services.Sizes.marginTop + 18)
        : srcEdge === "bottom" ? root.height - card.openH - Math.max(68, Services.Sizes.marginBottom + 18)
        : (root.height - card.openH) / 2

    Widgets.PanelHost {
        id: card
        shown: root.shown
        sourceEdge: root.srcEdge
        openXOverride: root.openXCalc
        openYOverride: root.openYCalc

        pillCX: root.chipRect.cx
        pillCY: root.chipRect.cy
        pillW: root.chipRect.w
        pillH: root.chipRect.h

        // A board of cards, each saying its own kind of thing: a history worth
        // drawing, a proportion of something fixed, readings in rings, a vessel.
        // Seven identical liquid boxes made this panel read as a spreadsheet.
        readonly property int cell: 126
        readonly property int gap: 12
        readonly property int pad: 22
        function span(n) { return n * cell + (n - 1) * gap }
        openW: span(8) + pad * 2
        openH: span(3) + pad * 2
        cardRadius: 22

        pillKey: "process"
        restSide: "bottom"


        body: Component {
            Item {
                id: bodyRoot

                function stage(i) {
                    const start = Math.min(0.5, i * 0.09)
                    return Math.max(0, Math.min(1, (card.contentAmt - start) / (1 - start)))
                }

                // Six vessels, six tones, all of them the scheme's own. A hue
                // spun off the accent gave six colours the wallpaper had never
                // produced; these are the colours it DID produce -- the accent,
                // its darker partner, the scheme's second tone -- plus a lift of
                // each towards the light and dark ends of the same palette.
                // Turn the wallpaper and the whole board turns with it.
                readonly property var tones: [
                    Services.Colors.ghost,                                        // 0 cpu
                    Services.Colors.lift(Services.Colors.ghost, 0.28),            // 1 memory
                    Services.Colors.neutral,                                      // 2 thermals
                    Services.Colors.shade,                                        // 3 gpu
                    Services.Colors.tint(Services.Colors.ghost,
                                         Services.Colors.neutral, 0.5),           // 4 network
                    Services.Colors.lift(Services.Colors.neutral, -0.22),         // 5 storage
                    Services.Colors.lift(Services.Colors.neutral, 0.24)           // 6 the gpu dial
                ]
                function toneAt(i) { return bodyRoot.tones[i % bodyRoot.tones.length] }

                // Busier means livelier: the swell grows and quickens with the
                // reading instead of idling at one beat for everything.

                // Every card on the board: its place on the grid, its name in
                // the corner, and its own beat in the arrival.
                component Card: Rectangle {
                    id: cd
                    property string glyph: ""
                    property string name: ""
                    property int index: 0
                    property int col: 0
                    property int row: 0
                    property int cw: 1
                    property int ch: 1
                    // What a card puts in its top-right: a figure its glyph does
                    // not already say. No names: the glyph IS the name.
                    property string note: ""
                    // Where a card's own content can start.
                    readonly property int headH: 40
                    readonly property int inset: 14

                    x: col * (card.cell + card.gap)
                    y: row * (card.cell + card.gap)
                    width: card.span(cw)
                    height: card.span(ch)
                    radius: Services.Sizes.cardLgR
                    // Opaque: a translucent plate took its colour from whatever
                    // wallpaper happened to be behind the panel.
                    color: Services.Colors.tint(Services.Colors.surface,
                                                Services.Colors.ghost, 0.07)
                    clip: true
                    opacity: bodyRoot.stage(index)
                    transform: Translate { y: (1 - bodyRoot.stage(cd.index)) * 12 }

                    Row {
                        id: cdHead
                        x: cd.inset
                        y: cd.inset
                        spacing: 8
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: cd.glyph
                            color: Services.Colors.mist
                            font.pixelSize: 16
                            font.family: "Material Symbols Rounded"
                        }
                        // The name stays beside the glyph here. Taken off with the
                        // rest of the captions it left six cards of bare numbers,
                        // and a percentage with no word over it is a guess.
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: cd.name
                            color: Services.Colors.mist
                            font.pixelSize: Services.Sizes.fsCaption
                            font.bold: true
                            font.letterSpacing: 1.4
                            font.family: "JetBrainsMono NF"
                        }
                    }
                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: cd.inset
                        anchors.verticalCenter: cdHead.verticalCenter
                        width: Math.min(implicitWidth, cd.width - cdHead.width - cd.inset * 3)
                        horizontalAlignment: Text.AlignRight
                        text: cd.note
                        visible: cd.note !== ""
                        color: Services.Colors.ash
                        font.pixelSize: Services.Sizes.fsMeta
                        font.family: "JetBrainsMono NF"
                        elide: Text.ElideRight
                    }
                }

                // A small vessel: the same box a card is, at the size two of
                // them fit inside one. The temperatures use it, so the board has
                // one shape instead of boxes on one row and rings on the next.
                component Vessel: Rectangle {
                    id: vs
                    property real level: 0
                    property color tone: Services.Colors.ghost
                    property string label: ""
                    property string caption: ""

                    radius: Services.Sizes.cardR
                    color: Services.Colors.fillInset
                    clip: true

                    Widgets.TickMeter {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: 12
                        height: 16
                        mode: "level"
                        value: vs.level
                        color_: vs.tone
                    }

                    Item {
                        id: vsFace
                        anchors.fill: parent

                        Text {
                            x: 12
                            anchors.top: parent.top
                            anchors.topMargin: 10
                            text: vs.label
                            color: Services.Colors.snow
                            font.pixelSize: Services.Sizes.fsReadout
                            font.bold: true
                            font.family: "JetBrainsMono NF"
                        }
                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            anchors.top: parent.top
                            anchors.topMargin: 14
                            text: vs.caption
                            color: Services.Colors.ash
                            font.pixelSize: Services.Sizes.fsCaption
                            font.letterSpacing: 1.2
                            font.family: "JetBrainsMono NF"
                        }
                    }

                }

                Item {
                    x: card.pad
                    y: card.pad
                    width: card.span(8)
                    height: card.span(3)

                    // ── CPU: the one reading with a past worth drawing ──
                    Card {
                        id: cpuCard
                        index: 0
                        col: 0; row: 0; cw: 4; ch: 2
                        glyph: ""
                        name: Services.I18n.t("proc.cpu")

                        readonly property color tone: bodyRoot.toneAt(0)

                        Item {
                            id: cpuFace
                            anchors.fill: parent

                            Text {
                                id: cpuNum
                                x: cpuCard.inset
                                y: cpuCard.headH
                                text: Math.round(Services.SysMon.cpuPercent) + "%"
                                color: Services.Colors.snow
                                font.pixelSize: Services.Sizes.fsHero
                                font.bold: true
                                font.family: "JetBrainsMono NF"
                            }
                        }


                        Widgets.TickMeter {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: cpuCard.inset
                            height: cpuCard.height - cpuCard.headH - cpuNum.height - cpuCard.inset * 2
                            mode: "history"
                            samples: Services.SysMon.cpuHistory
                            tickW: 6
                            gap: 5
                            color_: cpuCard.tone
                        }
                    }

                    // ── Memory: a proportion of something fixed ──
                    Card {
                        index: 1
                        col: 4; row: 0; cw: 4; ch: 1
                        glyph: ""
                        name: Services.I18n.t("proc.memory")
                        id: ramCard

                        readonly property color tone: bodyRoot.toneAt(1)
                        readonly property real used: Services.SysMon.ramTotalMB > 0
                            ? Services.SysMon.ramUsedMB / Services.SysMon.ramTotalMB : 0

                        Item {
                            id: ramFace
                            anchors.fill: parent

                            Text {
                                id: ramNum
                                x: ramCard.inset
                                y: ramCard.headH - 4
                                text: Services.SysMon.ramTotalMB > 0
                                    ? Math.round(ramCard.used * 100) + "%"
                                    : "--"
                                color: Services.Colors.snow
                                font.pixelSize: Services.Sizes.fsReadout
                                font.bold: true
                                font.family: "JetBrainsMono NF"
                            }
                            Text {
                                anchors.left: ramNum.right
                                anchors.leftMargin: 10
                                anchors.baseline: ramNum.baseline
                                text: (Services.SysMon.ramUsedMB / 1024).toFixed(1) + " / "
                                      + (Services.SysMon.ramTotalMB / 1024).toFixed(1) + " GB"
                                color: Services.Colors.mist
                                font.pixelSize: Services.Sizes.fsMeta
                                font.family: "JetBrainsMono NF"
                            }
                        }


                        Widgets.TickMeter {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: ramCard.inset
                            height: 24
                            mode: "level"
                            value: ramCard.used
                            tickW: 4
                            gap: 3
                            color_: ramCard.tone
                        }
                    }

                    // ── Thermals: two readings, two rings ──
                    // The only card that is not a vessel itself: the dials it
                    // holds are already two of them.
                    Card {
                        index: 2
                        col: 4; row: 1; cw: 4; ch: 1
                        glyph: ""
                        name: Services.I18n.t("proc.thermals")
                        id: thermCard

                        readonly property color tone: bodyRoot.toneAt(2)

                        Row {
                            x: thermCard.inset
                            y: thermCard.headH - 4
                            width: thermCard.width - thermCard.inset * 2
                            height: thermCard.height - thermCard.headH - 6
                            spacing: 10

                            Vessel {
                                width: (parent.width - 10) / 2
                                height: parent.height
                                // Read against 100 degrees, turning at 80.
                                level: Math.max(0, Math.min(1, Services.SysMon.cpuTemp / 100))
                                tone: thermCard.tone
                                label: Services.SysMon.cpuTemp > 0
                                    ? Services.SysMon.cpuTemp.toFixed(0) + "°" : "--"
                                caption: Services.I18n.t("proc.cpuShort")
                            }
                            Vessel {
                                width: (parent.width - 10) / 2
                                height: parent.height
                                level: Math.max(0, Math.min(1, Services.SysMon.gpuTemp / 100))
                                tone: bodyRoot.toneAt(6)
                                label: Services.SysMon.gpuTemp > 0
                                    ? Services.SysMon.gpuTemp.toFixed(0) + "°" : "--"
                                caption: Services.I18n.t("proc.gpuShort")
                            }
                        }
                    }

                    // ── GPU: the card that has always been a vessel ──
                    Card {
                        index: 3
                        col: 0; row: 2; cw: 3; ch: 1
                        glyph: ""
                        name: Services.I18n.t("proc.gpuShort")
                        id: gpuCard

                        readonly property color tone: bodyRoot.toneAt(3)

                        Item {
                            id: gpuFace
                            anchors.fill: parent

                            Text {
                                id: gpuNum
                                x: gpuCard.inset
                                y: gpuCard.headH - 4
                                text: Math.round(Services.SysMon.gpuPercent) + "%"
                                color: Services.Colors.snow
                                font.pixelSize: Services.Sizes.fsReadout
                                font.bold: true
                                font.family: "JetBrainsMono NF"
                            }
                            Text {
                                anchors.left: gpuNum.right
                                anchors.leftMargin: 10
                                anchors.baseline: gpuNum.baseline
                                text: Services.SysMon.dgpuAwake ? Services.I18n.t("proc.discrete") : Services.I18n.t("proc.integrated")
                                color: Services.Colors.mist
                                font.pixelSize: Services.Sizes.fsMeta
                                font.family: "JetBrainsMono NF"
                            }
                        }


                        Widgets.TickMeter {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: gpuCard.inset
                            height: 24
                            mode: "history"
                            samples: Services.SysMon.gpuHistory
                            tickW: 4
                            gap: 3
                            color_: gpuCard.tone
                        }
                    }

                    // ── Network: what is moving right now ──
                    Card {
                        index: 4
                        col: 3; row: 2; cw: 2; ch: 1
                        glyph: ""
                        name: Services.I18n.t("proc.network")
                        id: netCard

                        readonly property color tone: bodyRoot.toneAt(4)

                        Item {
                            id: netFace
                            anchors.fill: parent

                            Text {
                                id: netNum
                                x: netCard.inset
                                y: netCard.headH - 4
                                text: {
                                    const kb = Services.SysMon.netRxKBs + Services.SysMon.netTxKBs
                                    return kb >= 1024 ? (kb / 1024).toFixed(1) + " MB/s"
                                                      : Math.round(kb) + " KB/s"
                                }
                                color: Services.Colors.snow
                                font.pixelSize: Services.Sizes.fsReadout
                                font.bold: true
                                font.family: "JetBrainsMono NF"
                            }
                            Text {
                                x: netCard.inset
                                anchors.top: netNum.bottom
                                anchors.topMargin: 1
                                text: "↓ " + Math.round(Services.SysMon.netRxKBs)
                                      + "    ↑ " + Math.round(Services.SysMon.netTxKBs) + " KB/s"
                                color: Services.Colors.ash
                                font.pixelSize: Services.Sizes.fsCaption
                                font.family: "JetBrainsMono NF"
                            }
                        }


                        Widgets.TickMeter {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: netCard.inset
                            height: 24
                            mode: "history"
                            samples: Services.SysMon.netHistory
                            tickW: 4
                            gap: 3
                            color_: netCard.tone
                        }
                    }

                    // ── Storage: the other proportion ──
                    Card {
                        index: 5
                        col: 5; row: 2; cw: 3; ch: 1
                        glyph: ""
                        name: Services.I18n.t("proc.storage")
                        note: Services.SysMon.diskPercent + "%"
                        id: diskCard

                        readonly property color tone: bodyRoot.toneAt(5)
                        readonly property real used: Services.SysMon.diskPercent / 100

                        Item {
                            id: diskFace
                            anchors.fill: parent

                            Text {
                                id: diskNum
                                x: diskCard.inset
                                y: diskCard.headH - 4
                                text: Math.round(Services.SysMon.diskUsedGB) + " GB"
                                color: Services.Colors.snow
                                font.pixelSize: Services.Sizes.fsReadout
                                font.bold: true
                                font.family: "JetBrainsMono NF"
                            }
                            Text {
                                anchors.left: diskNum.right
                                anchors.leftMargin: 10
                                anchors.baseline: diskNum.baseline
                                text: Services.I18n.t("proc.ofTotal", { n: Math.round(Services.SysMon.diskTotalGB) })
                                color: Services.Colors.mist
                                font.pixelSize: Services.Sizes.fsMeta
                                font.family: "JetBrainsMono NF"
                            }
                        }


                        Widgets.TickMeter {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: diskCard.inset
                            height: 24
                            mode: "level"
                            value: diskCard.used
                            tickW: 4
                            gap: 3
                            color_: diskCard.tone
                        }
                    }
                }
            }
        }
    }
}
