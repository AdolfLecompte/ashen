pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Little pixel drawings for the moments with nothing to show -- the empty
// notification list, and whatever else wants one. Keyed like the phrase bank
// (Voice) and picked the same way: at random, never the same one twice running.
Singleton {
    id: root

    // data/sprites.json: { key: [ { name, rows: ["..##..", ...] } ] }, '#' = lit.
    property var bank: ({})

    FileView {
        path: Quickshell.shellPath("data/sprites.json")
        onLoaded: {
            try { root.bank = JSON.parse(text()) }
            catch (e) { console.warn("[Sprites] could not parse sprites.json:", e) }
        }
        onLoadFailed: console.warn("[Sprites] no sprites.json")
    }

    // Written in place, like Voice.lastPick: reassigning it from inside pick()
    // would re-run every binding that picked.
    property var lastPick: ({})

    // The rows of one sprite, or [] while the bank has not landed: callers that
    // pick in a handler re-pick on bankChanged.
    function pick(key) {
        const pool = root.bank[key]
        if (!pool || pool.length === 0) return []
        let i = Math.floor(Math.random() * pool.length)
        if (pool.length > 1 && i === root.lastPick[key]) i = (i + 1) % pool.length
        root.lastPick[key] = i
        return pool[i].rows
    }
}
