import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import Qt5Compat.GraphicalEffects
import QtQuick
import "root:/services" as Services
import "root:/modules/widgets" as Widgets
import "root:/modules/desktop/widgets" as DeskWidgets

Scope {
    id: root

    IpcHandler {
        target: "lockscreen"
        function lock() {
            sessionLock.locked = true
        }

    }

    // The in-process route, for callers that are already inside this shell.
    Connections {
        target: Services.AppState
        function onLockRequested() { sessionLock.locked = true }
    }

    WlSessionLock {
        id: sessionLock


        WlSessionLockSurface {
            id: surface

            // Material Symbols codepoints
            readonly property string glyphLock: "\uE899"
            readonly property string glyphLockOpen: "\uE898"

            // Off the shell's single SystemClock, not a Timer of this
            // surface's own -- with one surface per output that was a clock
            // per screen, none of them in step.
            readonly property string currentTime: Services.Time.fmt(Services.Prefs.timeFormat)
            readonly property string currentSecs: Services.Time.fmt("ss")
            readonly property string currentDate: Services.Time.fmt("MMMM d, yyyy")
            readonly property string currentDay: Services.Time.dayName(Services.Time.now.getDay())
            property string password: ""
            property string errorMsg: ""
            // The label split in two, so the name can be read louder than the
            // machine it is on. AppState keeps them joined for everywhere else.
            readonly property string userOnly: Services.AppState.userName
            readonly property string hostOnly: Services.AppState.hostName !== ""
                ? "@" + Services.AppState.hostName : ""
            property bool checking: false
            property bool showPower: false
            property string wallpaper: ""
            property bool revealed: false
            property bool unlocking: false

            // The Wayland protocol builds one of these PER OUTPUT, so with two
            // screens there are two of everything below -- two password fields
            // with a caret blinking in each, two PamContexts, and only one of
            // them receiving keys. The login belongs to the screen you are
            // looking at; the rest stay at rest, showing the time.
            //
            // Screens.active always resolves to exactly one screen (it falls
            // back to the first), so this can never be true twice or false
            // everywhere -- which is what would lock you out.
            readonly property bool loginFace: {
                const a = Services.Screens.active
                if (!a || !surface.screen) return true
                return surface.screen.name === a.name
            }

            // Two states, one driver. At rest the screen only tells you
            // things: the time, the weather, the machine, what is playing.
            // Touch it and it becomes something to answer -- the clock steps
            // aside, the columns dim, and the face and the field take the
            // middle.
            property bool authing: false
            property real auth: 0
            Behavior on auth {
                Widgets.Anim { speed: Services.Sizes.msPanel }
            }
            onAuthingChanged: surface.auth = authing ? 1 : 0
            // Typing is asking to log in, so the field never has to be found
            // first. It already holds focus, which is what makes this work.
            function beginAuth() {
                // A key or a click on a screen that is not the login one must
                // not turn it into a second question.
                if (!surface.authing && surface.loginFace) surface.authing = true
            }

            // What the screen is saying under the field. One line for all of
            // it -- the password being checked, the greeting once it is right,
            // the remark when it is not -- so two of them can never overlap.
            // The typing itself lives in widgets/SaidLine.
            property string saying: ""
            property bool sayingIsError: false
            function say(line, isError) {
                surface.saying = line
                surface.sayingIsError = isError === true
            }
            function hush() {
                surface.saying = ""
                surface.sayingIsError = false
            }

            // The password was right. Unlocking on the instant read as the
            // screen being yanked away, so it takes a breath first: it says it
            // is checking, then it says something back, and only then goes.
            property bool greeting: false
            // Two wrong in a row is worth noticing out loud; the first is a typo.
            property int misses: 0
            SequentialAnimation {
                id: greetAnim
                // No line of its own to start: the one tryUnlock already put
                // up is still being read. Saying "checking" twice, in two
                // different words, reads as two different questions.
                PauseAnimation { duration: 1200 }
                ScriptAction { script: surface.say(Services.Voice.pick("lock.welcome")) }
                PauseAnimation { duration: 1400 }
                ScriptAction {
                    script: {
                        surface.unlocking = true
                        unlockTimer.start()
                    }
                }
            }

            // Intro: the padlock snaps shut before the lock screen itself fades in
            property bool introDone: false
            property bool lockShut: false

            color: Services.Colors.abyss

            Component.onCompleted: introAnim.start()

            // The focus re-grab used to ride on this surface's clock Timer. It
            // still wants a once-a-second beat, so it rides the shared clock
            // instead: after resume the field can lose keyboard focus (mouse
            // still works), and it has to be typeable without a click.
            // Only from the login screen: with a surface per output, every one
            // of them grabbing once a second is a tug of war.
            Connections {
                target: Services.Time
                function onSecondsChanged() {
                    if (surface.loginFace && !surface.unlocking && !passInput.activeFocus)
                        passInput.forceActiveFocus()
                }
            }

            Process {
                id: wallpaperProc
                // The live wallpaper may be a video (mpvpaper), which QML can't
                // draw as a still. So resolve to a paintable image: a still
                // wallpaper is used as-is; for video/gif we fall back to the
                // frame ashen-wallpaper.sh extracts (same one matugen samples).
                command: ["sh", "-c",
                    "w=$(cat \"$HOME/.cache/ashen_wallpaper.txt\" 2>/dev/null); " +
                    "case \"$(printf '%s' \"$w\" | tr '[:upper:]' '[:lower:]')\" in " +
                    "*.png|*.jpg|*.jpeg|*.webp) printf '%s' \"$w\" ;; " +
                    "*) printf '%s' \"$HOME/.cache/ashen_wall_frame.png\" ;; " +
                    "esac"]
                running: true
                stdout: StdioCollector { onStreamFinished: surface.wallpaper = text.trim() }
            }
            PamContext {
                id: pam

                config: "login"

                onPamMessage: {
                    if (responseRequired)
                        respond(surface.password)
                }

                onCompleted: result => {
                    surface.checking = false

                    if (result === PamResult.Success) {
                        surface.misses = 0
                        surface.greeting = true
                        greetAnim.start()
                    } else {
                        surface.misses++
                        // A real PAM fault is not a remark: it is the one thing
                        // here that has to be read literally.
                        const line = result === PamResult.Error ? Services.I18n.t("lock.authError")
                            : Services.Voice.pick(surface.misses > 1 ? "lock.wrongAgain" : "lock.wrong")
                        surface.errorMsg = line
                        surface.say(line, true)
                        surface.password = ""
                        passInput.text = ""
                        errorTimer.restart()
                        shakeAnim.restart()
                    }
                }
            }

            Timer {
                id: unlockTimer
                interval: 340
                onTriggered: sessionLock.locked = false
            }

            Timer {
                id: errorTimer
                interval: 2500
                onTriggered: {
                    surface.errorMsg = ""
                    if (surface.sayingIsError) surface.hush()
                }
            }

            function tryUnlock() {
                if (surface.greeting) return
                if (surface.password.length === 0) {
                    surface.errorMsg = Services.I18n.t("lock.needPassword")
                    surface.say(Services.I18n.t("lock.nothingToCheck"), true)
                    errorTimer.restart()
                    shakeAnim.restart()
                    return
                }
                if (pam.active)
                    return

                surface.checking = true
                surface.errorMsg = ""
                surface.say(Services.Voice.pick("lock.checking"))
                pam.start()
            }

            // Persistent blurred-wallpaper backdrop, shared by the intro overlay
            // and the lock content so both sit on the same background (no black
            // flash during the intro). surface.wallpaper is already resolved to a
            // still — or the extracted video frame — by wallpaperProc.
            Item {
                id: bgLayer
                anchors.fill: parent

                // The veil is the background tone, so on a light palette it is
                // pale: laid on as thick as the dark one it turns the wallpaper
                // into a white film. Light schemes need only enough of it to
                // keep the near-black text legible.
                readonly property bool pale: Services.Colors.lightTheme
                readonly property real wallOpacity: pale ? 0.85 : 0.45
                readonly property real veilTop: pale ? 0.12 : 0.45
                readonly property real veilMid: pale ? 0.20 : 0.62
                readonly property real veilBottom: pale ? 0.38 : 0.80

                Image {
                    id: wallImg
                    anchors.fill: parent
                    source: surface.wallpaper !== "" ? ("file://" + surface.wallpaper) : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    // At the screen's width, not the file's: a wallpaper larger
                    // than the display was being decoded in full to be scaled
                    // back down for it.
                    sourceSize.width: wallImg.width
                    // frame path is fixed but its contents change per video;
                    // no cache or the lock shows the previous wallpaper's frame
                    cache: false
                    visible: false
                }
                FastBlur {
                    anchors.fill: parent
                    source: wallImg
                    radius: 64
                    visible: wallImg.status === Image.Ready
                    opacity: bgLayer.wallOpacity
                }
                // Vignette: the background tone deepens towards the edges so the
                // corner pills stay readable over any wallpaper.
                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(Services.Colors.abyss.r, Services.Colors.abyss.g, Services.Colors.abyss.b, bgLayer.veilTop) }
                        GradientStop { position: 0.5; color: Qt.rgba(Services.Colors.abyss.r, Services.Colors.abyss.g, Services.Colors.abyss.b, bgLayer.veilMid) }
                        GradientStop { position: 1.0; color: Qt.rgba(Services.Colors.abyss.r, Services.Colors.abyss.g, Services.Colors.abyss.b, bgLayer.veilBottom) }
                    }
                }
            }

            // ── Main content (with enter/exit animation) ──
            Item {
                id: content
                anchors.fill: parent
                opacity: surface.unlocking ? 0.0 : (surface.revealed ? 1.0 : 0.0)
                scale: surface.unlocking ? 1.04 : (surface.revealed ? 1.0 : 1.05)
                Behavior on opacity { Widgets.Anim { speed: Services.Sizes.msEmphasis } }
                Behavior on scale { Widgets.Anim { speed: Services.Sizes.msPanel } }

                Item {
                    anchors.fill: parent

                    // Anything at all asks to log in: at rest this screen is a
                    // readout, and the first touch turns it into a question.
                    MouseArea {
                        anchors.fill: parent
                        z: -1
                        onClicked: surface.beginAuth()
                    }

                    // ── At rest: the time, the weather, the battery, the music ──
                    Item {
                        id: idleGroup
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width
                        // Measured by the clock alone. The music fades in place
                        // and must not drag the login around as it goes.
                        height: clockCol.height
                        // Steps up out of the way rather than vanishing: it is
                        // the same clock, just no longer the whole screen.
                        y: (parent.height - height) / 2 - surface.auth * 200

                                Column {
                                    id: clockCol
                                    anchors.top: parent.top
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    spacing: 0
                                    // Smaller once it is no longer the only thing here.
                                    scale: 1 - surface.auth * 0.32
                                    transformOrigin: Item.Center
                                    Row {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        spacing: 0
                                        Text {
                                            textFormat: Text.PlainText
                                            text: surface.currentTime.split(" ")[0].split(":").slice(0, 2).join(":")
                                            color: Services.Colors.snow
                                            font.pixelSize: 104
                                            font.family: "JetBrainsMono NF"
                                            font.weight: Font.Bold
                                            font.letterSpacing: -2
                                        }
                                        Column {
                                            anchors.bottom: parent.bottom
                                            anchors.bottomMargin: 18
                                            spacing: 2
                                            leftPadding: 8
                                            Text {
                                                textFormat: Text.PlainText
                                                text: surface.currentSecs
                                                color: Services.Colors.snowAlpha(0.4)
                                                font.pixelSize: 28
                                                font.family: "JetBrainsMono NF"
                                                font.weight: Font.Bold
                                            }
                                            Text {
                                                textFormat: Text.PlainText
                                                text: surface.currentTime.split(" ")[1]
                                                color: Services.Colors.snowAlpha(0.4)
                                                font.pixelSize: 14
                                                font.family: "JetBrainsMono NF"
                                                font.weight: Font.Bold
                                            }
                                        }
                                    }
                                    // Only the date: the weather, the charge and
                                    // the music are cards in the columns now.
                                    Text {
                                        textFormat: Text.PlainText
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        topPadding: 6
                                        text: surface.currentDay + "  ·  " + surface.currentDate
                                        color: Services.Colors.snowAlpha(0.5)
                                        font.pixelSize: 15
                                        font.family: "JetBrainsMono NF"
                                        font.weight: Font.Bold
                                        font.letterSpacing: 1
                                    }
                                }

                    }

                    // ── Either side of the login: what the machine has to
                    //    say, once you have asked it something ──
                    // These are the very widgets the wallpaper wears, wearing
                    // shapes the lock picks: one plate each, no card inside a
                    // card, and a reading that can never drift from the one on
                    // the desktop because there is only one of it.
                    //
                    // At rest the screen is the clock and nothing else. The
                    // columns arrive with the face and the field, on the second
                    // half of the move, and close in around them -- held off
                    // the middle by a fixed distance rather than off the edges
                    // of the screen, so they read as one block and not as three
                    // things sharing a wall.
                    Column {
                        id: leftCol
                        readonly property real colW: 360
                        readonly property real enter: surface.loginFace
                            ? Math.max(0, surface.auth * 2 - 1) : 0
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.horizontalCenterOffset: -(leftCol.gapFromMiddle + colW / 2)
                        readonly property real gapFromMiddle: 250
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 16
                        opacity: leftCol.enter
                        visible: leftCol.enter > 0.001
                        transform: Translate { x: -(1 - leftCol.enter) * 24 }

                        // Compact, not the full shape: the full one is built
                        // around a 384 wide body, and this column is 360 -- the
                        // plate was cut off at both ends. Here the reading is
                        // what the lock is for.
                        DeskWidgets.WeatherWidget {
                            managed: false
                            live: true
                            styleOverride: "compact"
                            width: leftCol.colW
                            visible: Services.Prefs.lockShowWeather
                        }
                        DeskWidgets.MachineWidget {
                            managed: false
                            live: true
                            styleOverride: "session"
                            width: leftCol.colW
                            visible: Services.Prefs.lockShowMachine
                        }
                        // Compact, not the wall shape: cava is not running
                        // behind a locked screen, so its bars would draw as a
                        // dotted rule and read as something broken.
                        DeskWidgets.MediaWidget {
                            managed: false
                            live: true
                            styleOverride: "compact"
                            width: leftCol.colW
                            // Kept even with nothing playing: a column that
                            // loses a card between one unlock and the next
                            // reads as something missing, and the shape already
                            // has a voice for silence.
                            visible: Services.Prefs.lockShowMedia
                        }
                    }

                    Column {
                        id: rightCol
                        // The widest content out here is the notification line
                        // (340) plus its plate's padding: a column narrower
                        // than that cuts the card off at both ends.
                        readonly property real colW: 380
                        readonly property real enter: leftCol.enter
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.horizontalCenterOffset: leftCol.gapFromMiddle + colW / 2
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 16
                        opacity: rightCol.enter
                        visible: rightCol.enter > 0.001
                        transform: Translate { x: (1 - rightCol.enter) * 24 }

                        // The board.s own vocabulary -- a past and a level,
                        // both as ticks. No rings: the shell stopped saying a
                        // level with a dial everywhere but brightness.
                        DeskWidgets.SysWidget {
                            managed: false
                            live: true
                            styleOverride: "medium"
                            width: rightCol.colW
                            visible: Services.Prefs.lockShowSystem
                        }
                        // What asked for you while you were away. Read only:
                        // same list, same ages, same shapes as the one on the
                        // wallpaper, and dismissing a notice anywhere takes it
                        // off all three.
                        DeskWidgets.NotifyWidget {
                            managed: false
                            live: true
                            styleOverride: "list"
                            width: rightCol.colW
                            // Same rule as the media card: an empty history is
                            // news too, and the list shape says so itself.
                            visible: Services.Prefs.lockShowNotifications
                        }
                    }

                    // ── Once asked: the face and the field ──
                    Item {
                        id: authGroup
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: idleGroup.y + idleGroup.height + 56
                        width: authRow.width
                        height: authRow.height
                        // The second half of the move, once the music has gone.
                        readonly property real enter: Math.max(0, surface.auth * 2 - 1)
                        opacity: surface.loginFace ? 1 : 0
                        visible: authGroup.enter > 0.001 && surface.loginFace

                        // The three pieces arrive one after the other instead of
                        // as one slab: face, name, field. Same staggering the
                        // music already uses on its way out, so the two halves
                        // of the move are the one movement.
                        function stage(i) {
                            const start = i * 0.22
                            return Math.max(0, Math.min(1, (authGroup.enter - start) / (1 - start)))
                        }

                    // The face and the field, once you have asked to log in.
                    // A stack, not a row: side by side, the name sat at the top
                    // of the face and the field at its foot with nothing in
                    // between -- an L with a hole in it. Down the middle there
                    // is one column and one centre.
                    Column {
                        id: authRow
                        spacing: 16

                        Rectangle {
                            id: faceRing
                            anchors.horizontalCenter: parent.horizontalCenter
                            opacity: authGroup.stage(0)
                            transform: Translate { y: (1 - authGroup.stage(0)) * 16 }
                            width: 128; height: 128
                            // A face is round here: the one picture of a person
                            // in the shell, and the only circle among the
                            // rounded rectangles.
                            radius: width / 2
                            clip: true
                            color: Services.Colors.fillLine
                            // The ring is what says how it is going: at rest a
                            // plain edge, accent while it checks, error when it
                            // said no. The field's own border used to carry that
                            // alone, 130 px below where you are looking.
                            border.color: surface.errorMsg !== "" ? Services.Colors.error_
                                : (surface.checking || surface.greeting) ? Services.Colors.ghost
                                : Services.Colors.fillRest
                            border.width: 2
                            Behavior on border.color { Widgets.ColorAnim {} }
                            Image {
                                id: faceImg
                                anchors.fill: parent
                                anchors.margins: 2
                                source: Services.AppState.facePath
                                fillMode: Image.PreserveAspectCrop
                                cache: false
                                visible: false
                            }
                            Rectangle {
                                id: faceMask
                                anchors.fill: faceImg
                                radius: width / 2
                                visible: false
                            }
                            OpacityMask {
                                anchors.fill: faceImg
                                source: faceImg
                                maskSource: faceMask
                                visible: faceImg.status === Image.Ready
                            }
                            Text {
                                textFormat: Text.PlainText
                                anchors.centerIn: parent
                                text: "\uF0D3"
                                color: Services.Colors.ghost
                                font.pixelSize: 62
                                font.family: "Material Symbols Rounded"
                                visible: faceImg.status !== Image.Ready
                            }
                        }

                        // Name, field and whatever the screen has to say, one
                        // under the other.
                        Column {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 10

                            // Two facts, not one string: who you are, and the
                            // machine you are on. The shell splits value from
                            // note everywhere else; there is no reason the login
                            // should shout the hostname as loudly as the name.
                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 0
                                opacity: authGroup.stage(1)
                                transform: Translate { y: (1 - authGroup.stage(1)) * 16 }
                                Text {
                                    textFormat: Text.PlainText
                                    text: surface.userOnly
                                    color: Services.Colors.snow
                                    font.pixelSize: 24
                                    font.family: "JetBrainsMono NF"
                                    font.weight: Font.Bold
                                    font.letterSpacing: 1
                                }
                                Text {
                                    textFormat: Text.PlainText
                                    text: surface.hostOnly
                                    visible: text !== ""
                                    color: Services.Colors.mist
                                    font.pixelSize: 24
                                    font.family: "JetBrainsMono NF"
                                    font.letterSpacing: 1
                                }
                            }

                            SequentialAnimation {
                                id: shakeAnim
                                NumberAnimation { target: shakeT; property: "x"; to:  9; duration: 55 }
                                NumberAnimation { target: shakeT; property: "x"; to: -8; duration: 55 }
                                NumberAnimation { target: shakeT; property: "x"; to:  6; duration: 55 }
                                NumberAnimation { target: shakeT; property: "x"; to: -4; duration: 55 }
                                NumberAnimation { target: shakeT; property: "x"; to:  0; duration: 55 }
                            }

                            // Password field pinned to the avatar's bottom edge; it shakes
                            // on a wrong password (the transform lives on the field now).
                            Rectangle {
                                id: passField
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 320; height: 52
                                opacity: authGroup.stage(2)
                                transform: Translate { id: shakeT; x: 0; y: (1 - authGroup.stage(2)) * 16 }
                                radius: Services.Sizes.cardR
                                // Sunk, the way every other control in the shell
                                // that you type into or drag is sunk.
                                color: Services.Colors.fillInset
                                border.color: surface.errorMsg !== "" ? Services.Colors.error_
                                    : passInput.activeFocus ? Services.Colors.ghost
                                    : Services.Colors.fillRest
                                border.width: 1
                                Behavior on border.color { Widgets.ColorAnim { speed: Services.Sizes.msMicro } }

                                // Click to (re)grab keyboard focus. Helps when the
                                // field loses activeFocus (e.g. after resume) so the
                                // user can recover it with the mouse instead of typing.
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.IBeamCursor
                                    onClicked: passInput.forceActiveFocus()
                                }

                                // The glyph keeps to the edge and the typing owns the
                                // middle: content centred inside what is left over
                                // after a left-hand icon is not centred in the field.
                                Text {
                                    textFormat: Text.PlainText
                                    id: lockGlyph
                                    anchors.left: parent.left
                                    anchors.leftMargin: 18
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: surface.glyphLock
                                    color: surface.errorMsg !== "" ? Services.Colors.error_ : Services.Colors.ghost
                                    font.pixelSize: 18
                                    font.family: "Material Symbols Rounded"
                                    Behavior on color { Widgets.ColorAnim { speed: Services.Sizes.msMicro } }
                                }

                                Item {
                                    anchors.fill: parent

                                    // Prompt, dots and cursor are ONE centred row, so
                                    // the whole thing drifts outwards as it fills
                                    // instead of the cursor walking to the right.
                                    Row {
                                        id: dotRow
                                        anchors.centerIn: parent
                                        spacing: 0

                                        // Capped, and the cap is what fits: 16 slots of
                                        // 17 px is the 304 px this field has inside its
                                        // margins. The old 24 ran off both ends.
                                        readonly property int maxDots: 16
                                        readonly property int filled: Math.min(surface.password.length, maxDots)

                                        Text {
                                            textFormat: Text.PlainText
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: Services.I18n.t("lock.enterPassword")
                                            color: Services.Colors.ash
                                            font.pixelSize: 14
                                            font.family: "JetBrainsMono NF"
                                            visible: surface.password.length === 0
                                        }

                                        // The model is a CONSTANT. Handing a Repeater a
                                        // number that changes rebuilds every delegate,
                                        // so each keystroke replayed the entry
                                        // animation on every dot already standing
                                        // there. Fixed slots, each one told whether it
                                        // is filled, and only the one that changed
                                        // animates.
                                        //
                                        // An empty slot is nothing at all -- a row of
                                        // dashes waiting to be filled read as a form,
                                        // not as a password. The dash survives only as
                                        // the first frame of the dot being typed: the
                                        // slot opens, a line appears in it and closes
                                        // into a circle.
                                        Repeater {
                                            model: 16
                                            delegate: Item {
                                                required property int index
                                                readonly property bool on: index < dotRow.filled

                                                width: on ? 17 : 0
                                                height: 11
                                                anchors.verticalCenter: parent.verticalCenter
                                                Behavior on width {
                                                    NumberAnimation { duration: 180; easing.type: Services.Sizes.easeOut }
                                                }

                                                Rectangle {
                                                    anchors.centerIn: parent
                                                    // Dash to dot: one shape, two numbers.
                                                    // No scale-in -- the closing IS the
                                                    // keystroke.
                                                    width: parent.on ? 11 : 9
                                                    height: parent.on ? 11 : 2
                                                    radius: height / 2
                                                    color: Services.Colors.ghost
                                                    gradient: Services.Prefs.useGradients
                                                        ? Services.Colors.accentGradient : null
                                                    // Gone when the slot is: the dash is a
                                                    // stage of writing, never a placeholder
                                                    // sitting there waiting.
                                                    opacity: parent.on ? 1 : 0
                                                    Behavior on width {
                                                        NumberAnimation { duration: 220; easing.type: Services.Sizes.easeOut }
                                                    }
                                                    Behavior on height {
                                                        NumberAnimation { duration: 220; easing.type: Services.Sizes.easeOut }
                                                    }
                                                    Behavior on opacity {
                                                        Widgets.Anim { speed: Services.Sizes.msMicro }
                                                    }
                                                }
                                            }
                                        }

                                        Rectangle {
                                            id: blinkCursor
                                            width: 2; height: 16
                                            anchors.verticalCenter: parent.verticalCenter
                                            visible: passInput.activeFocus
                                            color: Services.Colors.snow
                                            SequentialAnimation on opacity {
                                                running: passInput.activeFocus
                                                loops: Animation.Infinite
                                                NumberAnimation { to: 0.0; duration: 500 }
                                                NumberAnimation { to: 1.0; duration: 500 }
                                            }
                                        }
                                    }

                                        TextInput {
                                            id: passInput
                                            width: 1; height: 1
                                            x: -9999; y: -9999
                                            echoMode: TextInput.Password
                                            color: "transparent"
                                            cursorVisible: true
                                            focus: true
                                            onTextChanged: {
                                                surface.password = text
                                                if (text.length > 0) surface.beginAuth()
                                            }
                                            Keys.onReturnPressed: surface.tryUnlock()
                                            // Escape clears what you typed; a
                                            // second one hands the screen back
                                            // to the clock.
                                            Keys.onEscapePressed: {
                                                if (text.length === 0) {
                                                    surface.authing = false
                                                    surface.showPower = false
                                                    surface.showProfiles = false
                                                } else {
                                                    text = ""
                                                    surface.errorMsg = ""
                                                }
                                            }
                                        }
                                }

                                // Was the last cell of a row; now that the field
                                // centres its contents it holds the right edge itself.
                                Text {
                                    textFormat: Text.PlainText
                                    anchors.right: parent.right
                                    anchors.rightMargin: 18
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "\uE627"
                                    color: surface.checking ? Services.Colors.ghost : Services.Colors.ash
                                    font.pixelSize: 18
                                    font.family: "Material Symbols Rounded"
                                    Behavior on color { Widgets.ColorAnim { speed: Services.Sizes.msMicro } }
                                    MouseArea {
                                        anchors.fill: parent
                                        anchors.margins: -6
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: surface.tryUnlock()
                                    }
                                    SequentialAnimation on opacity {
                                        running: surface.checking
                                        loops: Animation.Infinite
                                        NumberAnimation { to: 0.2; duration: 500 }
                                        NumberAnimation { to: 1.0; duration: 500 }
                                    }
                                }
                            }
                            // One line for everything the screen has to tell
                            // you here. Caps Lock is the one that earns its
                            // place: the shell already knows, and this is
                            // exactly where a password fails without saying why.
                            Item {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 320
                                height: 16
                                Widgets.SaidLine {
                                    anchors.centerIn: parent
                                    // Only ever one line: what the screen is
                                    // saying wins, and Caps Lock speaks into a
                                    // silence or not at all.
                                    line: surface.saying !== "" ? surface.saying
                                        : (Services.Keyboard.capsLock ? Services.I18n.t("lock.capsOn") : "")
                                    isError: surface.sayingIsError
                                    font.pixelSize: 12
                                    opacity: text !== "" ? 1.0 : 0.0
                                    Behavior on opacity { Widgets.Anim {} }
                                }
                            }
                        }
                    }
                    }

                    // ── Bottom right corner: power, and nothing else ──
                    // On screen the whole time, like the capsules at the foot:
                    // the way out of the machine should not be something you
                    // only find by starting to log in.
                    Item {
                        id: cornerArea
                        anchors.bottom: parent.bottom
                        anchors.right: parent.right
                        anchors.margins: 24
                        width: powerPill.width
                        height: powerPill.height
                        opacity: surface.loginFace ? 1 : 0
                        visible: opacity > 0.01

                        // -- Power: pill fixed on the right, options expand UPWARDS --
                        Rectangle {
                            id: powerPill
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            width: 44; height: 44
                            radius: Services.Sizes.innerR
                            color: Services.Colors.surfacePill
                            Text {
                                textFormat: Text.PlainText
                                anchors.centerIn: parent
                                text: "\uF8C7"
                                color: surface.showPower || powerPillHover.containsMouse
                                     ? Services.Colors.snow : Services.Colors.mist
                                font.pixelSize: 24
                                font.family: "Material Symbols Rounded"
                                Behavior on color { Widgets.ColorAnim { speed: Services.Sizes.msMicro } }
                                // The shell's one hover language: it grows and
                                // brightens, the plate never lights up.
                                scale: Services.Sizes.hoverScale(powerPillHover.containsMouse, powerPillHover.pressed)
                                Behavior on scale { NumberAnimation { duration: Services.Sizes.pillHoverMs; easing.type: Services.Sizes.easeOut } }
                            }
                            MouseArea {
                                id: powerPillHover
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onClicked: surface.showPower = !surface.showPower
                            }
                        }

                        Column {
                            anchors.right: powerPill.right
                            anchors.bottom: powerPill.top
                            anchors.bottomMargin: 8
                            spacing: 6
                            opacity: surface.showPower ? 1.0 : 0.0
                            visible: opacity > 0
                            // Same deploy as the system (bar) panels: fade + slide in
                            // from the direction it opens — upwards, so it rises from below.
                            Behavior on opacity { Widgets.Anim {} }
                            transform: Translate {
                                y: surface.showPower ? 0 : 12
                                Behavior on y { Widgets.Anim {} }
                            }
                            Repeater {
                                // Nothing here is red: error_ is for something
                                // that went wrong, and shutting the machine down
                                // on purpose is not that.
                                model: [
                                    { icon: "\uF8C7", label: Services.I18n.t("power.shutdown"), cmd: "systemctl poweroff" },
                                    { icon: "\uF053", label: Services.I18n.t("power.restart"),   cmd: "systemctl reboot"   },
                                    { icon: "\uF159", label: Services.I18n.t("power.suspend"),   cmd: "systemctl suspend"  },
                                ]
                                delegate: Rectangle {
                                    id: powerItem
                                    required property var modelData
                                    anchors.right: parent.right
                                    width: 44; height: 44
                                    radius: Services.Sizes.innerR
                                    color: Services.Colors.surfacePill

                                    Text {
                                        textFormat: Text.PlainText
                                        anchors.centerIn: parent
                                        text: powerItem.modelData.icon
                                        color: powerHover.containsMouse ? Services.Colors.snow
                                                                        : Services.Colors.mist
                                        font.pixelSize: 24
                                        font.family: "Material Symbols Rounded"
                                        Behavior on color { Widgets.ColorAnim { speed: Services.Sizes.msMicro } }
                                        scale: Services.Sizes.hoverScale(powerHover.containsMouse, powerHover.pressed)
                                        Behavior on scale { NumberAnimation { duration: Services.Sizes.pillHoverMs; easing.type: Services.Sizes.easeOut } }
                                    }

                                    // The word only while you are on it: the
                                    // tiles are icons, and the name is what says
                                    // which one you are about to press.
                                    Rectangle {
                                        anchors.right: parent.left
                                        anchors.rightMargin: 8
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: tipText.width + 16
                                        height: 26
                                        radius: Services.Sizes.pillR
                                        color: Services.Colors.surfacePill
                                        opacity: powerHover.containsMouse ? 1 : 0
                                        visible: opacity > 0.01
                                        Behavior on opacity { Widgets.Anim { speed: Services.Sizes.msMicro } }
                                        Text {
                                            textFormat: Text.PlainText
                                            id: tipText
                                            anchors.centerIn: parent
                                            text: powerItem.modelData.label
                                            color: Services.Colors.snow
                                            font.pixelSize: Services.Sizes.fsMeta
                                            font.bold: true
                                            font.family: "JetBrainsMono NF"
                                        }
                                    }

                                    MouseArea {
                                        id: powerHover
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        hoverEnabled: true
                                        onClicked: Quickshell.execDetached(["sh", "-c", powerItem.modelData.cmd])
                                    }
                                }
                            }
                        }

                    }
                }
            }

            // ── Intro: padlock snaps shut, then the lock screen fades in behind it ──
            Rectangle {
                id: introOverlay
                anchors.fill: parent
                // transparent: the shared bgLayer blur shows through behind the
                // padlock, instead of a black cover, during the intro
                color: "transparent"
                z: 100
                opacity: 1.0
                visible: !surface.introDone

                Item {
                    id: introLock
                    anchors.centerIn: parent
                    width: 128; height: 128
                    scale: 0.55
                    opacity: 0.0

                    // Pulse that fires the moment the shackle snaps: a rounded
                    // square, not a circle — the rest of Ashen has no circles
                    Rectangle {
                        id: introRing
                        anchors.centerIn: parent
                        width: 128; height: 128
                        radius: width * 0.23
                        color: "transparent"
                        border.color: Services.Colors.ghost
                        border.width: 2
                        opacity: 0.0
                    }

                    Rectangle {
                        id: introTile
                        anchors.fill: parent
                        radius: 30
                        color: Services.Colors.surfacePill
                        border.color: Services.Colors.ghostAlpha(0.35)
                        border.width: 2

                        Text {
                            textFormat: Text.PlainText
                            id: introGlyph
                            anchors.centerIn: parent
                            text: surface.lockShut ? surface.glyphLock : surface.glyphLockOpen
                            color: surface.lockShut ? Services.Colors.snow : Services.Colors.ghost
                            font.pixelSize: 64
                            font.family: "Material Symbols Rounded"
                            Behavior on color { Widgets.ColorAnim {} }
                        }
                    }
                }

                SequentialAnimation {
                    id: introAnim

                    // 1. padlock drops in, still open
                    ParallelAnimation {
                        NumberAnimation { target: introLock; property: "opacity"; to: 1.0; duration: 340; easing.type: Services.Sizes.easeOut }
                        NumberAnimation { target: introLock; property: "scale"; to: 1.0; duration: 540; easing.type: Easing.OutBack; easing.overshoot: Services.Sizes.overshoot }
                    }
                    // beat: the padlock sits there, open, long enough to read
                    PauseAnimation { duration: 340 }

                    // 2. shackle snaps shut: glyph swap + recoil + pulse
                    ScriptAction { script: surface.lockShut = true }
                    ParallelAnimation {
                        SequentialAnimation {
                            NumberAnimation { target: introLock; property: "scale"; to: 1.18; duration: 130; easing.type: Easing.OutQuad }
                            NumberAnimation { target: introLock; property: "scale"; to: 1.0; duration: 340; easing.type: Easing.OutBack; easing.overshoot: Services.Sizes.overshoot }
                        }
                        ParallelAnimation {
                            NumberAnimation { target: introRing; property: "opacity"; from: 0.7; to: 0.0; duration: 700; easing.type: Services.Sizes.easeOut }
                            NumberAnimation { target: introRing; property: "width"; from: 128; to: 300; duration: 700; easing.type: Services.Sizes.easeOut }
                            NumberAnimation { target: introRing; property: "height"; from: 128; to: 300; duration: 700; easing.type: Services.Sizes.easeOut }
                        }
                    }
                    PauseAnimation { duration: 380 }

                    // 3. hand off to the lock screen
                    ScriptAction { script: surface.revealed = true }
                    ParallelAnimation {
                        NumberAnimation { target: introOverlay; property: "opacity"; to: 0.0; duration: 520; easing.type: Easing.InOutQuad }
                        NumberAnimation { target: introLock; property: "opacity"; to: 0.0; duration: 380; easing.type: Easing.InQuad }
                        NumberAnimation { target: introLock; property: "scale"; to: 1.6; duration: 520; easing.type: Services.Sizes.easeIn }
                    }
                    ScriptAction { script: surface.introDone = true }
                }
            }
        }
    }
}
