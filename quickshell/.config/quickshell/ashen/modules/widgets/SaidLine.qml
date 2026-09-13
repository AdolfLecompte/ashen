import QtQuick

import "root:/services" as Services

// A line the shell is saying, written out a character at a time. Hand it a
// string; hand it a different one and it retypes. This is the shell's own way
// of speaking -- every surface that says something uses this one, so the rhythm
// is the same everywhere and nobody re-invents a typewriter in a panel.
//
// It is for MOMENTS and WAITS. An empty panel picks a line and prints it whole:
// watching a sentence be typed every time a drawer opens gets old by the third
// time.
Text {
    textFormat: Text.PlainText
    id: root

    // What to say. Empty means silence, and silence is a valid thing to say.
    property string line: ""
    // Something went wrong, as opposed to something merely being so.
    property bool isError: false
    // Milliseconds per character. The default is fast enough not to be a wait
    // and slow enough to be seen being written. ZERO prints the line whole,
    // which is what an empty panel wants: see docs/DESIGN.md §6b.
    property int msPerChar: 26
    // Off while the surface is not on screen: a line typing itself behind a
    // closed panel arrives already finished, which is the one way it can't be
    // read.
    property bool armed: true

    property int typed: 0

    text: root.line.substring(0, root.typed)
    color: root.isError ? Services.Colors.error_ : Services.Colors.mist
    font.pixelSize: Services.Sizes.fsMeta
    font.family: "JetBrainsMono NF"
    elide: Text.ElideRight
    Behavior on color { ColorAnim { speed: Services.Sizes.msMicro } }

    onLineChanged: root.retype()
    onArmedChanged: if (root.armed) root.retype()

    function retype() {
        typeAnim.stop()
        root.typed = 0
        if (!root.armed || root.line === "") return
        if (root.msPerChar <= 0) { root.typed = root.line.length; return }
        typeAnim.to = root.line.length
        typeAnim.duration = Math.max(180, root.line.length * root.msPerChar)
        typeAnim.start()
    }
    Component.onCompleted: root.retype()

    NumberAnimation {
        id: typeAnim
        target: root
        property: "typed"
        from: 0
        easing.type: Easing.Linear
    }
}
