pragma Singleton
import Quickshell
import QtQuick

// Shell-wide readline editing for text fields: Ctrl+W drops the word before
// the cursor, Ctrl+U everything before it.
Singleton {
    function handle(event, field) {
        if (!(event.modifiers & Qt.ControlModifier) || field.readOnly) return false
        const c = field.cursorPosition
        if (event.key === Qt.Key_U) {
            field.remove(0, c)
            return true
        }
        if (event.key === Qt.Key_W) {
            const t = field.text
            let i = c
            while (i > 0 && /\s/.test(t[i - 1])) i--
            while (i > 0 && !/\s/.test(t[i - 1])) i--
            field.remove(i, c)
            return true
        }
        return false
    }
}
