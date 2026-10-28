.pragma library
// The arithmetic of screen time, kept pure so docs/probes/usage-probe.qml can
// run the same code Usage does.

function dayKey(d) {
    const p = n => (n < 10 ? "0" : "") + n
    return d.getFullYear() + "-" + p(d.getMonth() + 1) + "-" + p(d.getDate())
}

// A copy of `days` with [from, to) booked to app `key`, split at midnight and
// shared among the hours it covers.
function book(days, key, from, to) {
    const next = Object.assign({}, days)
    while (from < to) {
        const d = new Date(from)
        const midnight = new Date(d.getFullYear(), d.getMonth(), d.getDate() + 1).getTime()
        const end = Math.min(to, midnight)
        const dk = dayKey(d)
        const day = next[dk] ? Object.assign({}, next[dk]) : { total: 0, apps: {}, hours: [] }
        day.apps = Object.assign({}, day.apps)
        day.hours = day.hours && day.hours.length === 24 ? day.hours.slice() : new Array(24).fill(0)
        let t = from
        while (t < end) {
            const h = new Date(t)
            const hourEnd = new Date(h.getFullYear(), h.getMonth(), h.getDate(), h.getHours() + 1).getTime()
            const chunk = Math.min(end, hourEnd) - t
            day.hours[h.getHours()] += chunk / 1000
            t += chunk
        }
        const secs = (end - from) / 1000
        day.total += secs
        day.apps[key] = (day.apps[key] || 0) + secs
        next[dk] = day
        from = end
    }
    return next
}
