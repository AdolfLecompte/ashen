import QtQuick

import "root:/services" as Services

// The services that must be AWAKE at login, whether or not anything on screen
// has asked for one yet.
//
// A QML singleton is built the first time something reads it, and several of
// these are read only by a Settings tab that lives behind a LazyPanel. Left to
// themselves they wait for you to go and look at them: the saved monitor
// arrangement stays unapplied, the desktop widgets never arm, the blue-light
// filter you switched on last night does not come back.
//
// One list, with a name, so the next service that has to act at boot has an
// obvious place to be added instead of a second Component.onCompleted in
// whatever file happened to be open.
QtObject {
    Component.onCompleted: {
        // Each of these does its own waiting on Prefs, and each is idempotent.
        Services.Displays.refresh()   // the monitor layout that was saved
        Services.Desktop.arm()        // the widgets standing on the wallpaper
        Services.Theme.arm()          // the palette and what it writes out
        Services.Looks.arm()          // this wallpaper's own widget profile
        Services.Idle.seed()          // hypridle.conf, from the idle timeouts

        Services.NightLight.arm()      // wlsunset, if the filter was left on
    }
}
