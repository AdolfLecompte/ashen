import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "root:/services" as Services
import "root:/modules/settings/components"

// Power profile, battery estimate and the toggles that decide whether the
// machine is allowed to go to sleep.
Section {
    id: tab

    // Idle steps in minutes; 0 means the listener is left out of hypridle.conf.
    function stepIdle(secs, deltaMin) {
        return Math.max(0, Math.min(120 * 60, secs + deltaMin * 60))
    }
    function idleLabel(secs) {
        if (secs <= 0) return "Never"
        return (secs % 60 === 0 ? (secs / 60) + " min" : secs + " s")
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

        SectionLabel { text: Services.I18n.t("settings.language.pick") }

        Segmented {
            // Names are NOT translated: a language is written in itself, so it
            // can be recognised by someone who cannot read the current one.
            options: Services.I18n.languages.map(l => ({ id: l.id, label: l.label }))
            current: Services.I18n.lang
            onPicked: id => Services.I18n.setLang(id)
        }

        Text {
            Layout.fillWidth: true
            text: Services.I18n.t("settings.language.hint") + " "
                + Services.I18n.t("settings.language.live")
            wrapMode: Text.WordWrap
            color: Services.Colors.ash
            font.pixelSize: Services.Sizes.fsMeta
            font.family: "JetBrainsMono NF"
        }
    }

    Card {
        title: "Power & Session"
        RowLayout {
            spacing: 14
            Text {
                text: Services.Battery.level + "%"
                color: Services.Colors.snow
                font.pixelSize: Services.Sizes.fsReadout
                font.bold: true
                font.family: "JetBrainsMono NF"
            }
            ColumnLayout {
                spacing: 2
                Text {
                    text: Services.Battery.charging ? "Charging" : "On battery"
                    color: Services.Colors.mist
                    font.pixelSize: Services.Sizes.fsBody
                    font.family: "JetBrainsMono NF"
                }
                Text {
                    text: tab.timeRemaining !== "--" ? tab.timeRemaining : (Services.Battery.charging ? "Fully charged" : "Calculating...")
                    color: Services.Colors.ash
                    font.pixelSize: Services.Sizes.fsMeta
                    font.family: "JetBrainsMono NF"
                }
            }
        }

        SectionLabel { text: "Power Profile" }

        Segmented {
            stacked: true
            options: [
                { id: "power-saver", icon: "", label: "Saver", available: tab.availableProfiles.includes("power-saver") },
                { id: "balanced", icon: "", label: "Balanced", available: tab.availableProfiles.includes("balanced") },
                { id: "performance", icon: "", label: "Performance", available: tab.availableProfiles.includes("performance") },
            ]
            current: tab.activeProfile
            onPicked: id => tab.setProfile(id)
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            Text {
                text: ""
                font.family: "Material Symbols Rounded"
                font.pixelSize: 20
                color: Services.AppState.keepAwake ? Services.Colors.ghost : Services.Colors.mist
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text { text: "Keep Awake"; color: Services.Colors.snow; font.pixelSize: Services.Sizes.fsInput; font.bold: true; font.family: "JetBrainsMono NF" }
            }
            Item { Layout.fillWidth: true }
            Toggle {
                checked: Services.AppState.keepAwake
                // AppState drives hypridle itself, so every flip agrees
                onToggled: Services.AppState.keepAwake = !Services.AppState.keepAwake
            }
        }

    }

    Card {
        title: "Lock Screen"

        // One switch per card out there. The clock and the login are the
        // screen itself, so they are not on the list.
        Repeater {
            model: [
                { key: "weather", glyph: "\uf172", label: "Weather" },
                { key: "machine", glyph: "\ue30a", label: "Session and battery" },
                { key: "media", glyph: "\ue405", label: "What is playing" },
                { key: "system", glyph: "\ueaa2", label: "System" },
                { key: "notify", glyph: "\ue7f4", label: "Notifications" },
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

    Card {
        title: "Idle & Suspend"


        Repeater {
            model: [
                { key: "lock", label: "Lock the screen" },
                { key: "screenOff", label: "Turn the screen off" },
                { key: "suspend", label: "Suspend" },
            ]
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
                    Layout.fillWidth: true
                    text: modelData.label
                    color: Services.Colors.snow
                    font.pixelSize: Services.Sizes.fsBody
                    font.family: "JetBrainsMono NF"
                }
                Text {
                    text: tab.idleLabel(parent.secs)
                    color: parent.secs > 0 ? Services.Colors.ghost : Services.Colors.mist
                    font.pixelSize: Services.Sizes.fsInput
                    font.bold: true
                    font.family: "JetBrainsMono NF"
                    Layout.preferredWidth: 64
                    horizontalAlignment: Text.AlignRight
                }
                Item { Layout.fillWidth: true }
                StepBtn {
                    glyph: ""
                    onClicked: parent.apply(tab.stepIdle(parent.secs, -5))
                }
                Item { Layout.fillWidth: true }
                StepBtn {
                    glyph: ""
                    onClicked: parent.apply(tab.stepIdle(parent.secs, 5))
                }
            }
        }

        Text {
            // Ordering mistakes are easy to make and impossible to see
            visible: Services.Prefs.idleSuspendSecs > 0
                && Services.Prefs.idleLockSecs > Services.Prefs.idleSuspendSecs
            text: "Suspend fires before the lock does — the machine will sleep unlocked."
            color: Services.Colors.error_
            font.pixelSize: Services.Sizes.fsMeta
            font.family: "JetBrainsMono NF"
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
    }


    Item { Layout.preferredHeight: 8 }
}
