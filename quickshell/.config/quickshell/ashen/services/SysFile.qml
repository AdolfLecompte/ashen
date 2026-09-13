import Quickshell.Io
import QtQuick

// One kernel file, read in-process. Every poll that used to be `sh -c cat` was
// a fork, an exec and a pipe for a line of digits; at the rate the bar asks,
// that was the shell's whole idle cost once nothing was being painted.
//
// blockLoading makes reload() fill text() before it returns, which is what a
// poll wants. Measured on sysfs, not assumed: the files report a size of 4096
// and never raise inotify, but a reload() does see the new value every time.
FileView {
    blockLoading: true
    // A missing file is an answer ("this machine has no such thing"), not an
    // error worth a line per poll.
    printErrors: false

    // The current contents, trimmed. Empty when the file is not there.
    function read() {
        reload()
        return text().trim()
    }
    // One reader, one path. Re-pointing a reader at another file and reading
    // it at once returns what the previous path held: use a reader per file.
}
