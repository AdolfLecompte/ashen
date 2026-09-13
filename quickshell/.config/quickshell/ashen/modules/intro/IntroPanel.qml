import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "root:/services" as Services
import "root:/modules/widgets" as Widgets
import "root:/modules/settings/components"

// Two things on one surface: the screen the shell shows the first time it ever
// runs, and the one that says what changed after an update. They are the same
// card because they answer the same question -- "what am I looking at?" -- and
// because a rice with two different welcome screens is a rice with none.
//
// The first face is a TITLE CARD, not a form: the mark, the name, and two ways
// out. What the keys do is a page behind it -- somebody meeting the shell wants
// to look at it before being handed a manual.
//
// The notes are not written here: they are the repo's CHANGELOG, parsed by
// services/Release.qml. Nothing to say means nothing is shown.
PanelWindow {
    id: root
    anchors { top: true; left: true; right: true; bottom: true }
    screen: Services.Screens.active
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.keyboardFocus: root.shown ? WlrKeyboardFocus.OnDemand
                                            : WlrKeyboardFocus.None

    readonly property bool shown: Services.AppState.introVisible
    readonly property bool welcoming: Services.AppState.introMode === "welcome"
    visible: shown || closeDelay.running
    Timer { id: closeDelay; interval: card.holdMs }
    onShownChanged: if (!shown) closeDelay.restart()

    // "home" is the title card, "about" is what the keys do. Only the welcome
    // face has two pages: the notes are one thing to read.
    // The face lives in AppState, so an ipc call can ask for it before this
    // panel has even been built.
    readonly property string page: Services.AppState.introPage
    readonly property bool onHome: root.welcoming && root.page === "home"
    readonly property bool onAbout: root.welcoming && root.page === "about"

    // The box, as a target the card FOLLOWS rather than a value it jumps to.
    // `Behavior` only fires on a write, so the size cannot be a readonly
    // binding: it is a plain property bound to the target.
    readonly property real wantW: root.onHome ? Math.min(900, root.width - 140)
                                              : Math.min(980, root.width - 120)
    readonly property real wantH: root.onHome ? Math.min(700, root.height - 160)
                                              : Math.min(760, root.height - 120)
    property real boxW: root.wantW
    property real boxH: root.wantH
    onWantWChanged: root.boxW = root.wantW
    onWantHChanged: root.boxH = root.wantH
    Behavior on boxW {
        Widgets.Anim { speed: Services.Sizes.msPanel; curve: Services.Sizes.easeBox }
    }
    Behavior on boxH {
        Widgets.Anim { speed: Services.Sizes.msPanel; curve: Services.Sizes.easeBox }
    }

    // Turning to About is a page sliding, not two cards dissolving into each
    // other: out towards where you came from, in from where you went. Same
    // SlideSwap every other section change in the shell uses.
    property int shownFace: 0
    Widgets.SlideSwap {
        id: faceSwap
        index: root.onHome ? 0 : 1
        travel: 26
        onCommit: root.shownFace = faceSwap.index
    }

    // Leaving IS being told: whichever way it is closed, the version is marked
    // as seen. Otherwise the same card comes back at the next login and the
    // shell turns into something that nags.
    function dismiss() {
        Services.Release.markSeen()
        Services.AppState.introVisible = false
    }

    // The whole screen dims: this is the one surface that has the floor.
    Rectangle {
        anchors.fill: parent
        color: Services.Colors.scrim
        opacity: root.shown ? 1 : 0
        Behavior on opacity { Widgets.Anim { speed: Services.Sizes.msPanel } }
        MouseArea {
            anchors.fill: parent
            enabled: root.shown
            onClicked: root.dismiss()
        }
    }

    FocusScope {
        anchors.fill: parent
        focus: root.shown
        // Escape steps back a page before it closes anything: the way out of a
        // page you opened is the page you came from.
        Keys.onEscapePressed: {
            if (root.onAbout) Services.AppState.introPage = "home"
            else root.dismiss()
        }
    }

    Widgets.PanelHost {
        id: card
        shown: root.shown
        // No pill of its own, so it always unfolds -- and it unfolds in the
        // middle, because there is nowhere on the bar it came from.
        pillKey: ""
        // The title card is a plate you look at; the two pages that carry text
        // need the room. The box animates between the two, so turning to About
        // is the card growing rather than the card being swapped.
        // Held in properties of our own so the CHANGE can be animated: the card
        // itself has no Behavior on its size (a panel's box is already driven
        // by its arrival, and smoothing that twice is the drag this codebase
        // keeps re-learning). Turning a page is the box growing on a curve.
        openW: root.boxW
        openH: root.boxH
        cardRadius: Services.Sizes.panelR
        restSide: "center"

        body: Component {
            Item {
                anchors.fill: parent

                // ── Face one: the title card ────────────────────────────
                ColumnLayout {
                    anchors.centerIn: parent
                    width: parent.width - 80
                    spacing: 0
                    // One face for the whole welcome now: what changes is what
                    // sits under the name, not which card is on top. The
                    // side-to-side swap went with the second face.
                    opacity: root.welcoming ? card.contentAmt : 0
                    visible: opacity > 0.01

                    // The name IS the card, and it is the same mark the
                    // installer prints and fastfetch draws -- one artifact, not
                    // three drawings of one idea. It fades up rather than
                    // animating letter by letter: a shape that means something
                    // does not need to perform.
                    Widgets.AshenMark {
                        id: title
                        Layout.alignment: Qt.AlignHCenter
                        pixelSize: 16
                        color: Services.Colors.snow
                        opacity: card.stage(0)
                        transform: Translate { y: (1 - card.stage(0)) * 10 }
                    }

                    // What sits under the name changes; the name does not. The
                    // welcome is one card that learns something, not two cards
                    // that replace each other.
                    Item {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 10
                        // The size of what is SHOWING, not of the taller of the
                        // two: reserving the keys' height on the first screen
                        // leaves a hole where nothing will ever be.
                        implicitWidth: root.onHome ? saying.implicitWidth : keyList.implicitWidth
                        implicitHeight: root.onHome ? saying.implicitHeight : keyList.implicitHeight
                        Behavior on implicitWidth {
                            NumberAnimation { duration: Services.Sizes.msPanel
                                              easing.type: Services.Sizes.easeBox }
                        }
                        Behavior on implicitHeight {
                            NumberAnimation { duration: Services.Sizes.msPanel
                                              easing.type: Services.Sizes.easeBox }
                        }

                        // What it is.
                        ColumnLayout {
                            id: saying
                            anchors.centerIn: parent
                            spacing: 2
                            opacity: root.onHome ? 1 : 0
                            visible: opacity > 0.01
                            Behavior on opacity { Widgets.Anim {} }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: Services.I18n.t("app.tagline")
                                color: Services.Colors.mist
                                font.pixelSize: Services.Sizes.fsInput
                                font.family: "JetBrainsMono NF"
                            }
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "by Adolf"
                                color: Services.Colors.ash
                                font.pixelSize: Services.Sizes.fsMeta
                                font.family: "JetBrainsMono NF"
                            }
                        }

                        // …and then what it does. Keys only: a command you type
                        // is not a key. Read from services/Shortcuts, which
                        // parses the real keybinds.lua, so a rebind shows here.
                        // Two columns: six keys in one tall stack reads as a
                        // form to fill in, and there is nothing to fill in.
                        GridLayout {
                            id: keyList
                            anchors.centerIn: parent
                            columns: 2
                            columnSpacing: 22
                            rowSpacing: 8
                            opacity: root.onHome ? 0 : 1
                            visible: opacity > 0.01
                            Behavior on opacity { Widgets.Anim {} }

                            Repeater {
                                // The launcher is the exception: the bind is
                                // SUPER on release, written `SUPER + SUPER_L`,
                                // and nobody presses it that way -- you tap it.
                                model: [
                                    { keys: "SUPER", what: Services.I18n.t("intro.key.launcher") },
                                    { keys: Services.Shortcuts.keyOf("terminal"), what: Services.I18n.t("intro.front.terminal") },
                                    { keys: Services.Shortcuts.keyOf("browser"),  what: Services.I18n.t("intro.front.browser") },
                                    { keys: Services.Shortcuts.keyOf("files"),    what: Services.I18n.t("intro.front.files") },
                                    { keys: Services.Shortcuts.keyOf("settings"), what: Services.I18n.t("intro.front.settings") },
                                    { keys: Services.Shortcuts.keyOf("clipboard"), what: Services.I18n.t("intro.key.clipboard") }
                                ]
                                delegate: RowLayout {
                                    required property var modelData
                                    spacing: 12
                                    Rectangle {
                                        Layout.preferredWidth: 168
                                        Layout.preferredHeight: 28
                                        radius: Services.Sizes.innerR
                                        color: Services.Colors.fillLine
                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.keys
                                            color: Services.Colors.ghost
                                            font.pixelSize: Services.Sizes.fsMeta
                                            font.bold: true
                                            font.family: "JetBrainsMono NF"
                                        }
                                    }
                                    Text {
                                        Layout.preferredWidth: 150
                                        text: modelData.what
                                        color: Services.Colors.snow
                                        font.pixelSize: Services.Sizes.fsMeta
                                        font.family: "JetBrainsMono NF"
                                        wrapMode: Text.WordWrap
                                    }
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 22
                        spacing: 12
                        opacity: card.stage(3)
                        transform: Translate { y: (1 - card.stage(3)) * 10 }

                        // Start shows the keys; enjoy is only offered once there
                        // is nothing left to be shown.
                        ActionBtn {
                            label: Services.I18n.t("intro.start")
                            accent: true
                            visible: root.onHome
                            onGo: Services.AppState.introPage = "about"
                        }
                        ActionBtn {
                            label: Services.I18n.t("intro.enjoy")
                            accent: true
                            visible: !root.onHome
                            onGo: root.dismiss()
                        }
                    }
                }

                // ── Face three: what changed ────────────────────────────
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 34
                    spacing: 14
                    opacity: root.welcoming ? 0 : card.contentAmt
                    visible: opacity > 0.01
                    Behavior on opacity { Widgets.Anim {} }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            Text {
                                text: Services.I18n.t("intro.news.title")
                                color: Services.Colors.snow
                                font.pixelSize: Services.Sizes.fsSectionTitle
                                font.bold: true
                                font.letterSpacing: 1.6
                                font.family: "JetBrainsMono NF"
                            }
                            Text {
                                text: Services.I18n.t("intro.news.version", { v: Services.Release.version })
                                color: Services.Colors.mist
                                font.pixelSize: Services.Sizes.fsMeta
                                font.family: "JetBrainsMono NF"
                            }
                        }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: Services.Colors.fillLine }

                    Flickable {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentHeight: notesCol.implicitHeight
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        ColumnLayout {
                            id: notesCol
                            width: parent.width
                            spacing: 10

                            Repeater {
                                model: Services.Release.notes

                                Item {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    implicitHeight: line.implicitHeight + (modelData.group !== "" ? 10 : 4)

                                    Text {
                                        id: line
                                        width: parent.width
                                        y: modelData.group !== "" ? 8 : 0
                                        text: modelData.group !== ""
                                            ? modelData.group.toUpperCase()
                                            : "•  " + Services.Release.rich(modelData.text)
                                        textFormat: Text.StyledText
                                        color: modelData.group !== "" ? Services.Colors.ghost
                                                                      : Services.Colors.snow
                                        font.pixelSize: modelData.group !== ""
                                            ? Services.Sizes.fsCaption : Services.Sizes.fsBody
                                        font.bold: modelData.group !== ""
                                        font.letterSpacing: modelData.group !== "" ? 1.4 : 0
                                        font.family: "JetBrainsMono NF"
                                        wrapMode: Text.WordWrap
                                        lineHeight: 1.25
                                    }
                                }
                            }

                            // An update whose changelog section is empty: say
                            // so rather than opening an empty card.
                            Text {
                                Layout.fillWidth: true
                                visible: Services.Release.notes.length === 0
                                text: Services.I18n.t("intro.news.empty")
                                color: Services.Colors.mist
                                font.pixelSize: Services.Sizes.fsBody
                                font.family: "JetBrainsMono NF"
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        Text {
                            Layout.fillWidth: true
                            text: Services.I18n.t("intro.news.changelog")
                            color: Services.Colors.ash
                            font.pixelSize: Services.Sizes.fsMeta
                            font.family: "JetBrainsMono NF"
                            elide: Text.ElideRight
                        }
                        ActionBtn {
                            label: Services.I18n.t("intro.gotIt")
                            accent: true
                            onGo: root.dismiss()
                        }
                    }
                }
            }
        }
    }
}
