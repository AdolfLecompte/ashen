import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "root:/services" as Services
import "root:/modules/widgets" as Widgets
import "root:/modules/settings/components"

// Power profile, battery estimate and the toggles that decide whether the
// machine is allowed to go to sleep.
Section {
    id: tab

    // What the profile-picture card is doing: "" (idle), "picking" while the
    // dialog is up, "done" / "failed" for a moment after. The word in the
    // button is the only confirmation a card like this can give.
    property string faceState: ""

    // Idle steps in minutes; 0 means the listener is left out of hypridle.conf.
    function stepIdle(secs, deltaMin) {
        return Math.max(0, Math.min(120 * 60, secs + deltaMin * 60))
    }
    function idleLabel(secs) {
        if (secs <= 0) return Services.I18n.t("common.never")
        return (secs % 60 === 0 ? Services.I18n.t("settings.system.minutes", { n: secs / 60 }) : Services.I18n.t("settings.system.seconds", { n: secs }))
    }

    property string timeRemaining: "--"
    property var availableProfiles: []
    property string activeProfile: ""

    function setProfile(name) {
        if (!availableProfiles.includes(name)) return
        Quickshell.execDetached(["sh", "-c", "powerprofilesctl set " + name])
        activeProfile = name
    }

    Component.onCompleted: {
        battProc.running = true
        profProc.running = true
    }

    Process {
        id: battProc
        command: ["sh", "-c", "upower -i $(upower -e | grep BAT) 2>/dev/null | grep -E 'time to (empty|full)'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let line = text.trim()
                tab.timeRemaining = line.length > 0 ? line.split(":").slice(1).join(":").trim() : "--"
            }
        }
    }
    Process {
        id: profProc
        command: ["sh", "-c", "powerprofilesctl list"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = text.split("\n")
                let profiles = []
                let active = ""
                for (let line of lines) {
                    let m = line.match(/^\s*(\*?)\s*([\w-]+):$/)
                    if (m) { profiles.push(m[2]); if (m[1] === "*") active = m[2] }
                }
                tab.availableProfiles = profiles
                tab.activeProfile = active
            }
        }
    }

    // The first card of the tab on purpose: everything below it is read in
    // whatever this one says. Its own title travels with the pick, so the card
    // is the proof that the language changed.
    Card {
        title: Services.I18n.t("settings.language.title")

        // A list, not a row of buttons: four languages fit a row, the fifth
        // does not, and every one added later would squeeze the rest.
        // Names are NOT translated: a language is written in itself, so it
        // can be recognised by someone who cannot read the current one.
        Widgets.DevicePicker {
            Layout.fillWidth: true
            overlay: true
            rowH: 34
            glyph: "\ue894"      // language
            devices: Services.I18n.languages.map(l => ({ name: l.id, desc: l.label }))
            current: Services.I18n.lang
            onPicked: name => Services.I18n.setLang(name)
        }
    }

    // What the four app keybinds open. Lived in Input until 2026-09-07: which
    // terminal opens is not something you type, it is what the machine reaches
    // for, and that has been System's business in every desktop since.
    // Named here rather than in keybinds.lua, where "brave" meant SUPER+W did
    // nothing on a machine without it.
    Card {
        title: Services.I18n.t("settings.system.apps")

        Repeater {
            model: Services.Apps.kinds

            AppRow {
                required property var modelData
                kind: modelData.id
                glyph: modelData.glyph
                title: modelData.label
                fallback: modelData.hint
            }
        }
    }

    Card {
        title: Services.I18n.t("settings.system.power")
        RowLayout {
            spacing: 14
            Text {
                textFormat: Text.PlainText
                text: Services.Battery.level + "%"
                color: Services.Colors.snow
                font.pixelSize: Services.Sizes.fsReadout
                font.bold: true
                font.family: "JetBrainsMono NF"
            }
            ColumnLayout {
                spacing: 2
                Text {
                    textFormat: Text.PlainText
                    text: Services.Battery.charging ? Services.I18n.t("settings.system.charging") : Services.I18n.t("settings.system.onBattery")
                    color: Services.Colors.mist
                    font.pixelSize: Services.Sizes.fsBody
                    font.family: "JetBrainsMono NF"
                }
                Text {
                    textFormat: Text.PlainText
                    text: tab.timeRemaining !== "--" ? tab.timeRemaining : (Services.Battery.charging ? Services.I18n.t("settings.system.full") : Services.I18n.t("settings.system.calculating"))
                    color: Services.Colors.ash
                    font.pixelSize: Services.Sizes.fsMeta
                    font.family: "JetBrainsMono NF"
                }
            }
        }

        SectionLabel { text: Services.I18n.t("settings.system.profile") }

        Segmented {
            stacked: true
            options: [
                { id: "power-saver", icon: "", label: Services.I18n.t("settings.system.saver"), available: tab.availableProfiles.includes("power-saver") },
                { id: "balanced", icon: "", label: Services.I18n.t("settings.system.balanced"), available: tab.availableProfiles.includes("balanced") },
                { id: "performance", icon: "", label: Services.I18n.t("settings.system.performance"), available: tab.availableProfiles.includes("performance") },
            ]
            current: tab.activeProfile
            onPicked: id => tab.setProfile(id)
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            Text {
                textFormat: Text.PlainText
                text: ""
                font.family: "Material Symbols Rounded"
                font.pixelSize: 20
                color: Services.AppState.keepAwake ? Services.Colors.ghost : Services.Colors.mist
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text { textFormat: Text.PlainText; text: Services.I18n.t("settings.system.keepAwake"); color: Services.Colors.snow; font.pixelSize: Services.Sizes.fsInput; font.bold: true; font.family: "JetBrainsMono NF" }
            }
        }

        // Three answers, so a Segmented rather than a switch -- the same control
        // the power profiles above use. No `available:` here: all three always
        // are.
        Segmented {
            options: [
                { id: "off",   label: Services.I18n.t("settings.system.awakeOff") },
                { id: "locks", label: Services.I18n.t("settings.system.awakeLocks") },
                { id: "full",  label: Services.I18n.t("settings.system.awakeFull") }
            ]
            current: Services.AppState.keepAwakeMode
            // AppState drives hypridle itself, so every route agrees.
            onPicked: id => Services.AppState.keepAwakeMode = id
        }

    }

    // Not folded into the power card above: this one touches the compositor,
    // not the CPU governor, and reading them as one thing would suggest game
    // mode changes your power profile. It does not.
    Card {
        title: Services.I18n.t("settings.system.game")

        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            RowGlyph { glyph: "\uf135" }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                // One line, not a label repeating the card's own title with an
                // explanation under it. What it does IS the label.
                Text {
                    textFormat: Text.PlainText
                    text: Services.I18n.t("settings.system.gameHint")
                    color: Services.Colors.snow
                    font.pixelSize: Services.Sizes.fsInput
                    font.bold: true
                    font.family: "JetBrainsMono NF"
                }
            }
            Item { Layout.fillWidth: true }
            Toggle {
                checked: Services.Game.on
                onToggled: Services.Game.toggle()
            }
        }
    }

    Card {
        title: Services.I18n.t("settings.system.lockScreen")

        // One switch per card out there. The clock and the login are the
        // screen itself, so they are not on the list.
        Repeater {
            model: [
                { key: "weather", glyph: "\uf172", label: Services.I18n.t("settings.clock.weather") },
                { key: "machine", glyph: "\ue30a", label: Services.I18n.t("settings.system.lock.machine") },
                { key: "media", glyph: "\ue405", label: Services.I18n.t("settings.system.lock.media") },
                { key: "system", glyph: "\ueaa2", label: Services.I18n.t("settings.tab.system") },
                { key: "notify", glyph: "\ue7f4", label: Services.I18n.t("settings.tab.notifications") },
            ]
            delegate: RowLayout {
                id: lockRow
                required property var modelData
                Layout.fillWidth: true
                spacing: 12

                readonly property bool on_: modelData.key === "weather" ? Services.Prefs.lockShowWeather
                    : modelData.key === "machine" ? Services.Prefs.lockShowMachine
                    : modelData.key === "media" ? Services.Prefs.lockShowMedia
                    : modelData.key === "system" ? Services.Prefs.lockShowSystem
                    : Services.Prefs.lockShowNotifications

                function flip() {
                    switch (lockRow.modelData.key) {
                    case "weather": Services.Prefs.lockShowWeather = !Services.Prefs.lockShowWeather; break
                    case "machine": Services.Prefs.lockShowMachine = !Services.Prefs.lockShowMachine; break
                    case "media": Services.Prefs.lockShowMedia = !Services.Prefs.lockShowMedia; break
                    case "system": Services.Prefs.lockShowSystem = !Services.Prefs.lockShowSystem; break
                    default: Services.Prefs.lockShowNotifications = !Services.Prefs.lockShowNotifications
                    }
                }

                RowGlyph { glyph: lockRow.modelData.glyph }
                Text {
                    textFormat: Text.PlainText
                    text: lockRow.modelData.label
                    color: Services.Colors.snow
                    font.pixelSize: Services.Sizes.fsInput
                    font.bold: true
                    font.family: "JetBrainsMono NF"
                }
                Item { Layout.fillWidth: true }
                Toggle {
                    checked: lockRow.on_
                    onToggled: lockRow.flip()
                }
            }
        }
    }

    // The face the lock screen shows. It lives HERE, next to what the lock
    // screen draws, and not in About: About is what this build and this
    // machine are, and a portrait is neither.
    PreviewCard {
        source: Services.AppState.facePath
        fallbackGlyph: "\uf0d3"
        title: Services.I18n.t("settings.about.picture")
        subtitle: Services.AppState.userLabel
        // The button IS the progress report: there is nowhere else on this card
        // to say that a dialog is open or that the copy landed.
        action: tab.faceState === "picking" ? Services.I18n.t("settings.about.choosing")
              : tab.faceState === "done" ? Services.I18n.t("settings.about.updated")
              : tab.faceState === "failed" ? Services.I18n.t("settings.about.failed") : Services.I18n.t("common.change")
        busy: tab.faceState === "picking"
        onTriggered: {
            tab.faceState = "picking"
            Services.Picker.open("profile", "")
        }
    }
    // Puts the word back to "Change" once it has been read.
    Timer {
        id: faceStateTimer
        interval: 1500
        onTriggered: tab.faceState = ""
    }

    // The shell's own picker, not zenity: same dialog as the widget pictures,
    // and it looks like the rest of the desktop.
    Connections {
        target: Services.Picker
        function onPicked(purpose, path) {
            if (purpose !== "profile") return
            if (path === "" || Services.AppState.homeDir === "") { tab.faceState = ""; return }
            faceCopyProc.command = ["cp", path, Services.AppState.homeDir + "/.face"]
            faceCopyProc.running = true
        }
        // Closed without choosing: not a failure, and not a change.
        function onVisibleChanged() {
            if (!Services.Picker.visible && tab.faceState === "picking") tab.faceState = ""
        }
    }

    Process {
        id: faceCopyProc
        running: false
        // The version bump is what every copy of the face repaints off, so it
        // is only earned when the copy actually succeeded -- it used to fire
        // even when nothing had been written.
        onExited: (code) => {
            if (code !== 0) {
                tab.faceState = "failed"
                faceStateTimer.restart()
                Services.Notifications.addSystemToast(
                    Services.I18n.t("settings.about.faceFail"), "\uf008", false, "face")
                return
            }
            Services.AppState.faceVersion = Date.now()
            tab.faceState = "done"
            faceStateTimer.restart()
            // Same shape as the screenshot toast: the picture you just chose,
            // shown back to you. One `typeKey`, so a second change replaces the
            // first instead of stacking.
            Services.Notifications.addSystemToast(
                Services.I18n.t("settings.about.faceOk"), "\uf008", false, "face",
                { image: Services.AppState.facePath })
        }
    }

    Card {
        title: Services.I18n.t("settings.system.idle")


        Repeater {
            model: [
                { key: "lock", label: Services.I18n.t("settings.system.idle.lock") },
                { key: "screenOff", label: Services.I18n.t("settings.system.idle.screenOff") },
                { key: "suspend", label: Services.I18n.t("settings.system.idle.suspend") },
            ]
            // Label, value, the two buttons -- and no elastic spacer between them:
            // with one there every row shared its leftover width differently, and
            // the buttons stood in a different place on each line.
            delegate: RowLayout {
                required property var modelData
                Layout.fillWidth: true
                spacing: 10
                readonly property int secs: modelData.key === "lock" ? Services.Prefs.idleLockSecs
                    : modelData.key === "screenOff" ? Services.Prefs.idleScreenOffSecs
                    : Services.Prefs.idleSuspendSecs
                function apply(v) {
                    if (modelData.key === "lock") Services.Prefs.idleLockSecs = v
                    else if (modelData.key === "screenOff") Services.Prefs.idleScreenOffSecs = v
                    else Services.Prefs.idleSuspendSecs = v
                }

                Text {
                    textFormat: Text.PlainText
                    Layout.fillWidth: true
                    text: modelData.label
                    color: Services.Colors.snow
                    font.pixelSize: Services.Sizes.fsBody
                    font.family: "JetBrainsMono NF"
                }
                Text {
                    textFormat: Text.PlainText
                    text: tab.idleLabel(parent.secs)
                    color: parent.secs > 0 ? Services.Colors.ghost : Services.Colors.mist
                    font.pixelSize: Services.Sizes.fsInput
                    font.bold: true
                    font.family: "JetBrainsMono NF"
                    Layout.preferredWidth: 64
                    horizontalAlignment: Text.AlignRight
                }
                StepBtn {
                    glyph: ""
                    onClicked: parent.apply(tab.stepIdle(parent.secs, -5))
                }
                StepBtn {
                    glyph: ""
                    onClicked: parent.apply(tab.stepIdle(parent.secs, 5))
                }
            }
        }

        Text {
            textFormat: Text.PlainText
            // Ordering mistakes are easy to make and impossible to see
            visible: Services.Prefs.idleSuspendSecs > 0
                && Services.Prefs.idleLockSecs > Services.Prefs.idleSuspendSecs
            text: Services.I18n.t("settings.system.idle.warn")
            color: Services.Colors.error_
            font.pixelSize: Services.Sizes.fsMeta
            font.family: "JetBrainsMono NF"
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
    }


    Item { Layout.preferredHeight: 8 }
}
