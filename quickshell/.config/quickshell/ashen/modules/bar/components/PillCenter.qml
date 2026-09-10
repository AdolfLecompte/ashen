import QtQuick
import Quickshell

import "root:/services" as Services

// Publishes where a bar pill sits on screen, so the panel that hangs off it can
// line up with it. mapToGlobal has no change signal, so this listens to every
// event that can move the pill instead of polling it several times a second.
Item {
    id: root

    // Key in AppState: "volume", "network", "clock"…
    property string key: ""
    // The pill itself; defaults to whoever holds this reporter
    property Item pill: parent

    visible: false

    // The screen THIS bar is on, asked of its own window rather than taken from
    // Screens.active. With a bar per monitor the two are different things, and
    // reading the focused one would offset a pill against a screen it is not on.
    readonly property var barScreen: QsWindow.window ? QsWindow.window.screen : null

    // mapToGlobal on a layer surface returns coordinates in the LAYOUT, not in
    // the window: on a second monitor at x=1920 a pill 1681 px along its own bar
    // comes back as 3601. The panel that reads this number lives in a window
    // 1920 wide, so it clamped every panel on that screen against its right
    // edge -- which is why panels opened displaced on a second monitor, and why
    // it looked fine on the primary one, where the two happen to be equal.
    //
    // Measured, not assumed: [PILL] volume screen HEADLESS-1 g.x 3601 => cx 3669.
    readonly property real screenX: root.barScreen ? root.barScreen.x : 0
    readonly property real screenY: root.barScreen ? root.barScreen.y : 0

    // Sizes owns the bar-edge correction, since the workspace preview reports
    // its geometry the same way and needs the same sum.
    readonly property real originX: Services.Sizes.barOriginX(root.barScreen)
    readonly property real originY: Services.Sizes.barOriginY(root.barScreen)

    // AppState holds ONE set of numbers per pill, and every panel opens on the
    // focused monitor -- so only the bar on that monitor has anything true to
    // say. Without this the bars overwrite each other every couple of seconds
    // and a panel lands wherever the last one to speak happened to put it.
    // A reporter that does not yet know its screen says NOTHING. It used to be
    // allowed to speak (`!barScreen ||`), and on a second monitor the first
    // report fires before the window is attached: with no screen there is no
    // origin to subtract, so a layout coordinate -- 2134 on a 1920-wide screen
    // -- was written into AppState and never corrected, because the pill had
    // no reason to move again. That is the panel that opens off to one side.
    readonly property bool speaks: !!root.barScreen
        && root.barScreen.name === Services.Screens.activeName

    function report() {
        if (!pill || !key || !root.speaks) return
        const g = pill.mapToGlobal(0, 0)
        Services.AppState.setPillCenter(key,
            root.originX + g.x - root.screenX + pill.width / 2,
            root.originY + g.y - root.screenY + pill.height / 2)
        // Size as well: the drop that falls out of a pill has to start the
        // size of that pill, and the neck has to be as wide as it is.
        Services.AppState.setPillSize(key, pill.width, pill.height)
    }

    Component.onCompleted: report()
    // …and the moment it DOES know, it says it again: the first attempt was
    // skipped precisely because the answer would have been wrong.
    onBarScreenChanged: report()

    // A monitor that MOVES moves every pill on it without any of them changing
    // size or position on their own bar, so nothing here would fire: the last
    // report keeps the coordinates the screen had at its old place. Measured
    // moving a monitor from +1920 to -1920: g.x stayed 1932 until something
    // else forced a report, and every panel on that screen opened 3840 px away.
    Connections {
        target: root.barScreen
        ignoreUnknownSignals: true
        function onXChanged() { root.report() }
        function onYChanged() { root.report() }
    }

    // The pill moves when its own geometry changes…
    Connections {
        target: root.pill
        function onXChanged() { root.report() }
        function onYChanged() { root.report() }
        function onWidthChanged() { root.report() }
        function onHeightChanged() { root.report() }
    }

    // …and when the bar itself moves to another edge or slides out and back
    Connections {
        target: Services.Sizes
        function onBarPositionChanged() { root.report() }
        function onHiddenChanged() { root.report() }
    }

    // Focus moved to this monitor: this bar has just become the one that speaks,
    // and its numbers are whatever the other bar left behind until it says so.
    onSpeaksChanged: if (root.speaks) root.report()

    // Safety net for anything the signals above cannot see (an ancestor moving
    // without resizing). Slow on purpose: this is a backstop, not the source.
    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: root.report()
    }
}
