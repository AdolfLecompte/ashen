// Ashen — one view of the system clock for the whole shell.  by Adolf — github.com/AdolfLecompte
pragma Singleton
import Quickshell
import QtQuick

// Every clock face used to run its own `Timer { interval: 1000 }` and build a
// `new Date()` on each tick -- four of them, four wakeups a second, none of
// them in step. A Timer also drifts: it fires a second after the LAST tick,
// not on the second, so a face could sit on the same minute for 1999 ms or
// skip one outright. SystemClock follows the system clock itself (within
// 50 ms of it changing) and hands back the date it woke up for, which is the
// one Quickshell asks you to read rather than constructing your own.
Singleton {
    id: root

    // Seconds, because the bar clock and the lockscreen both show them.
    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    // The current instant. Bind to this; do NOT call `new Date()` off it --
    // the constructed object can be up to a second away from what woke us.
    readonly property date now: clock.date
    readonly property int hours: clock.hours
    readonly property int minutes: clock.minutes
    readonly property int seconds: clock.seconds

    // Every face formats through here, and every one of these goes through
    // I18n.locale -- never the system's. The shell speaks one language.
    function fmt(spec) { return root.now.toLocaleString(I18n.locale, spec) }
    function fmtOf(date, spec) { return date.toLocaleString(I18n.locale, spec) }

    // Day and month names. Indexes are the JavaScript ones (0 = Sunday,
    // 0 = January), which is what QML's Locale takes too.
    function dayName(jsDay) { return I18n.locale.dayName(jsDay) }
    function dayShort(jsDay) { return I18n.locale.dayName(jsDay, Locale.ShortFormat) }
    function dayNarrow(jsDay) { return I18n.locale.standaloneDayName(jsDay, Locale.NarrowFormat) }
    function monthName(jsMonth) { return I18n.locale.monthName(jsMonth) }
}
