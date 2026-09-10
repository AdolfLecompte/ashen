// Ashen — Weather service (Open-Meteo, no API key).  by Adolf — github.com/AdolfLecompte
pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import "root:/services" as Services

Singleton {
    id: root
    property string condition: ""
    property int tempC: 0
    property string icon: ""
    property var forecast: []

    // Conditions beyond the headline number. All from the same single request.
    property bool isDay: true
    property int feelsC: 0
    property int humidity: 0
    property int windKph: 0
    property int windDir: 0      // degrees the wind blows FROM
    property int uvMax: 0
    property int rainProb: 0     // highest chance of rain today, percent
    property string sunrise: ""
    property string sunset: ""
    // Minutes past midnight for the two above, for the arcs that do maths.
    property int sunriseMin: -1
    property int sunsetMin: -1
    // Next 24 h: { label, tempC, rain, icon, now }
    property var hourly: []
    // Every hour the request carried (five days), each tagged with its date, so
    // a day picked in the card has a curve of its own without asking again.
    property var allHours: []
    function hoursFor(dateStr) {
        return root.allHours.filter(h => h.date === dateStr)
    }

    readonly property string feels: tempString(feelsC)

    // "2026-07-28T06:12" -> "6:12 AM" or "06:12", following the clock setting.
    function clockOf(stamp) {
        let hm = String(stamp).split("T")[1]
        if (!hm) return ""
        let p = hm.split(":")
        let h = parseInt(p[0])
        if (Services.Prefs.clock24h) return p[0] + ":" + p[1]
        let ap = h >= 12 ? I18n.locale.pmText : I18n.locale.amText
        let h12 = h % 12
        if (h12 === 0) h12 = 12
        return h12 + ":" + p[1] + " " + ap
    }

    // The same stamp as minutes past midnight. Whoever needs the NUMBER reads
    // this: `clockOf` is a string for the eye and changes with the language.
    function minutesOf(stamp) {
        const hm = String(stamp).split("T")[1]
        if (!hm) return -1
        const p = hm.split(":")
        const h = parseInt(p[0]), m = parseInt(p[1])
        return (isNaN(h) || isNaN(m)) ? -1 : h * 60 + m
    }

    // Wind direction as a compass point. Only the clock card reads it; the lock
    // screen shows the speed in km/h, where the bearing said nothing.
    function windCompass(deg) {
        const pts = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        return pts[Math.round((deg % 360) / 45) % 8]
    }
    // The same eight sectors as an arrow instead of two letters: the glyph
    // named after the bearing points that way, so it reads without decoding.
    function windGlyph(deg) {
        const pts = ["\uf1e0", "\uf1e1", "\uf1df", "\uf1e4",   // N NE E SE
                     "\uf1e3", "\uf1e5", "\uf1e6", "\uf1e2"]   // S SW W NW
        return pts[Math.round((deg % 360) / 45) % 8]
    }
    // Set true by cityProc when a typed city can't be geocoded, so Settings can
    // show "not found". Cleared on the next successful lookup.
    property bool cityError: false

    // Open-Meteo only ever returns celsius, so F/K are derived here and every
    // consumer renders through tempString()/degrees() -- never tempC directly.
    function convert(c) {
        if (Services.Prefs.tempUnit === "F") return Math.round(c * 9 / 5 + 32)
        if (Services.Prefs.tempUnit === "K") return Math.round(c + 273.15)
        return Math.round(c)
    }
    // Kelvin is an absolute scale: writing "273°K" is wrong, it has no degree sign
    readonly property string unitSuffix: Services.Prefs.tempUnit === "K" ? "K" : "°" + Services.Prefs.tempUnit
    function tempString(c) { return convert(c) + unitSuffix }
    // Bare number + degree glyph, for the "24°/12°" forecast pairs
    function degrees(c) { return convert(c) + (Services.Prefs.tempUnit === "K" ? "" : "°") }

    readonly property string temp: tempString(tempC)

    // MANY saved locations now (like keyboard layouts). They live in Prefs as ONE
    // packed string (JsonAdapter drops sibling writes in the same tick, so the list
    // AND the active index share one field). Format: line 0 = active index, each
    // following line = "lat|lon|City". Everything below reads through savedLocs.
    readonly property var savedLocs: {
        let raw = Services.Prefs.weatherLocs || ""
        if (raw === "") return []
        let lines = raw.split("\n")
        let out = []
        for (let i = 1; i < lines.length; i++) {
            let p = lines[i].split("|")
            if (p.length < 2) continue
            let lat = parseFloat(p[0]), lon = parseFloat(p[1])
            if (isNaN(lat) || isNaN(lon)) continue
            out.push({ lat: lat, lon: lon, city: p.slice(2).join("|") })
        }
        return out
    }
    readonly property int activeLocIndex: {
        let raw = Services.Prefs.weatherLocs || ""
        if (raw === "") return -1
        let idx = parseInt(raw.split("\n")[0])
        if (isNaN(idx) || idx < 0 || idx >= root.savedLocs.length)
            return root.savedLocs.length > 0 ? 0 : -1
        return idx
    }
    readonly property var loc: (activeLocIndex >= 0 && activeLocIndex < savedLocs.length)
        ? savedLocs[activeLocIndex] : null
    readonly property string city: loc ? loc.city : ""

    // One write, one field -- sidesteps the JsonAdapter same-tick drop.
    function packLocs(list, index) {
        if (list.length === 0) { Services.Prefs.weatherLocs = ""; return }
        let lines = [String(index)]
        for (let l of list) lines.push(l.lat + "|" + l.lon + "|" + (l.city || ""))
        Services.Prefs.weatherLocs = lines.join("\n")
    }

    // Add (or re-select if already saved) a city and make it active.
    function addLoc(lat, lon, city) {
        let list = savedLocs.slice()
        // Dedup by ~coords so re-picking the same place just re-selects it.
        let hit = list.findIndex(l => Math.abs(l.lat - lat) < 0.01 && Math.abs(l.lon - lon) < 0.01)
        let idx
        if (hit >= 0) idx = hit
        else { list.push({ lat: lat, lon: lon, city: city || "" }); idx = list.length - 1 }
        packLocs(list, idx)
        fetchForecast(lat, lon)
    }

    // Switch the active city (the whole point of the feature).
    function selectLoc(index) {
        if (index < 0 || index >= savedLocs.length) return
        packLocs(savedLocs, index)
        fetchForecast(savedLocs[index].lat, savedLocs[index].lon)
    }

    function removeLoc(index) {
        if (index < 0 || index >= savedLocs.length) return
        let list = savedLocs.slice()
        list.splice(index, 1)
        if (list.length === 0) { packLocs([], 0); refresh(); return }  // back to auto/IP
        let idx = activeLocIndex
        if (index < activeLocIndex) idx = activeLocIndex - 1
        else if (index === activeLocIndex) idx = Math.min(activeLocIndex, list.length - 1)
        packLocs(list, idx)
        fetchForecast(list[idx].lat, list[idx].lon)
    }

    // One-time upgrade from the legacy single-location field.
    function migrateIfNeeded() {
        if ((Services.Prefs.weatherLocs || "") !== "") return
        let parts = (Services.Prefs.weatherLoc || "").split("|")
        if (parts.length < 2) return
        let lat = parseFloat(parts[0]), lon = parseFloat(parts[1])
        if (isNaN(lat) || isNaN(lon)) return
        packLocs([{ lat: lat, lon: lon, city: parts.slice(2).join("|") }], 0)
    }

    // Open-Meteo speaks WMO codes, so the glyph and the label are derived from
    // the code here. Day or night comes from the API's own `is_day`, never the
    // local clock: with several saved cities our hour says nothing about whether
    // the sun is up over Tokyo.
    function codeToIcon(code, daylight) {
        let night = !daylight
        if (code === 0) return night ? "\uf159" : "\uf157"              // clear
        if (code === 1 || code === 2) return night ? "\uf174" : "\uf172" // partly
        if (code === 3) return "\uf15c"                                 // overcast
        if (code === 45 || code === 48) return "\ue818"                 // fog
        if (code >= 71 && code <= 77) return "\ueb3b"                   // snow
        if (code === 85 || code === 86) return "\ueb3b"                 // snow showers
        if (code >= 95) return "\uebdb"                                 // thunder
        if (code >= 51 && code <= 82) return "\uf176"                   // drizzle/rain
        return "\uf60b"                                                  // unknown
    }
    function codeToText(code) {
        switch (code) {
        case 0: return "Clear"
        case 1: return "Mainly clear"
        case 2: return "Partly cloudy"
        case 3: return "Overcast"
        case 45: case 48: return "Fog"
        case 51: case 53: case 55: return "Drizzle"
        case 56: case 57: return "Freezing drizzle"
        case 61: case 63: case 65: return "Rain"
        case 66: case 67: return "Freezing rain"
        case 71: case 73: case 75: return "Snow"
        case 77: return "Snow grains"
        case 80: case 81: case 82: return "Rain showers"
        case 85: case 86: return "Snow showers"
        case 95: return "Thunderstorm"
        case 96: case 99: return "Thunderstorm, hail"
        default: return "—"
        }
    }

    function dayLabel(dateStr, index) {
        if (index === 0) return I18n.t("time.today")
        // Built field by field, never `new Date("2026-08-11")`: a date-only
        // string is parsed as UTC midnight and then read back in local time,
        // so west of Greenwich every day named itself as the day before.
        const p = String(dateStr).split("-")
        const d = new Date(Number(p[0]), Number(p[1]) - 1, Number(p[2]))
        return Time.dayShort(d.getDay())
    }

    // Entry point: re-fetch the active city, or IP-geolocate once if none saved.
    // Guarded by Prefs.loaded so a startup race can't mistake "not loaded yet" for
    // "no city" and geolocate over the saved pick (that was the reset bug).
    function refresh() {
        if (root.loc) fetchForecast(root.loc.lat, root.loc.lon)
        else if (Services.Prefs.loaded) geoProc.running = true
    }

    function start() {
        migrateIfNeeded()
        refresh()
    }

    function fetchForecast(lat, lon) {
        // One request carries the whole panel: conditions now, the next 24 h,
        // and five days. Open-Meteo charges nothing extra for the wider set,
        // so there is no reason to ask twice.
        let url = "https://api.open-meteo.com/v1/forecast?latitude=" + lat
            + "&longitude=" + lon
            + "&current=temperature_2m,weather_code,is_day,apparent_temperature"
            + ",relative_humidity_2m,wind_speed_10m,wind_direction_10m"
            + "&hourly=temperature_2m,precipitation_probability,weather_code,is_day"
            + ",relative_humidity_2m"
            + "&daily=weather_code,temperature_2m_max,temperature_2m_min"
            + ",sunrise,sunset,precipitation_probability_max,uv_index_max"
            + ",apparent_temperature_max"
            + ",wind_speed_10m_max,wind_direction_10m_dominant"
            + "&timezone=auto&forecast_days=5"
        fcProc.command = ["sh", "-c", "curl -s --max-time 10 '" + url + "'"]
        fcProc.running = true
    }

    // Live geocoding search for the Settings dropdown: up to 5 candidates so a
    // name shared by several cities (region/country shown) can be disambiguated.
    property var searchResults: []
    function search(name) {
        let q = (name || "").trim()
        if (q.length < 2) { root.searchResults = []; root.cityError = false; return }
        let url = "https://geocoding-api.open-meteo.com/v1/search?name="
            + encodeURIComponent(q) + "&count=5&language=en"
        searchProc.command = ["sh", "-c", "curl -s --max-time 10 '" + url + "'"]
        searchProc.running = true
    }
    // Commit one chosen candidate (exact coords, no re-geocode): save + activate.
    function chooseResult(lat, lon, label) {
        root.searchResults = []
        root.cityError = false
        root.addLoc(lat, lon, label)
    }

    // IP geolocation fallback (no coords saved yet). Non-commercial, no key.
    Process {
        id: geoProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let d = JSON.parse(text)
                    if (d.status === "success")
                        root.addLoc(d.lat, d.lon, d.city || "")
                } catch (e) { console.warn("[Weather] geo error:", e) }
            }
        }
        command: ["sh", "-c", "curl -s --max-time 10 'http://ip-api.com/json?fields=status,lat,lon,city'"]
    }

    // Geocode a typed name -> up to 5 candidate cities for the dropdown.
    Process {
        id: searchProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let d = JSON.parse(text)
                    if (d.results && d.results.length > 0) {
                        let arr = []
                        for (let i = 0; i < d.results.length; i++) {
                            let r = d.results[i]
                            arr.push({
                                lat: r.latitude,
                                lon: r.longitude,
                                label: r.name + (r.country_code ? ", " + r.country_code : ""),
                                detail: [r.admin1, r.country].filter(x => x).join(", ")
                            })
                        }
                        root.cityError = false
                        root.searchResults = arr
                    } else {
                        root.searchResults = []
                        root.cityError = true
                    }
                } catch (e) { console.warn("[Weather] search error:", e); root.searchResults = [] }
            }
        }
    }

    // Forecast fetch (current + daily).
    Process {
        id: fcProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let d = JSON.parse(text)
                    let cur = d.current
                    root.tempC = Math.round(cur.temperature_2m)
                    root.isDay = cur.is_day === 1
                    root.condition = root.codeToText(cur.weather_code)
                    root.icon = root.codeToIcon(cur.weather_code, root.isDay)
                    root.feelsC = Math.round(cur.apparent_temperature)
                    root.humidity = Math.round(cur.relative_humidity_2m)
                    root.windKph = Math.round(cur.wind_speed_10m)
                    root.windDir = Math.round(cur.wind_direction_10m)

                    // Every hour first: the days are summarised from it (the
                    // daily block has no humidity of its own).
                    let hr = d.hourly
                    let cursor = String(cur.time).slice(0, 13)
                    let at = hr.time.findIndex(t => String(t).slice(0, 13) === cursor)
                    if (at < 0) at = 0
                    let all = []
                    for (let i = 0; i < hr.time.length; i++) {
                        all.push({
                            date: String(hr.time[i]).slice(0, 10),
                            label: root.clockOf(hr.time[i]),
                            tempC: Math.round(hr.temperature_2m[i]),
                            rain: Math.round(hr.precipitation_probability[i] || 0),
                            humidity: Math.round(hr.relative_humidity_2m[i] || 0),
                            icon: root.codeToIcon(hr.weather_code[i], hr.is_day[i] === 1),
                            now: i === at
                        })
                    }
                    root.allHours = all
                    // The next 24 hours starting at the city's current hour.
                    // `timezone=auto` means these stamps are local to the city,
                    // so our own clock must not be used to find "now" — the
                    // API's `current.time` is the only honest cursor.
                    root.hourly = all.slice(at, at + 24)

                    let days = []
                    let dy = d.daily
                    for (let i = 0; i < dy.time.length; i++) {
                        let date = String(dy.time[i])
                        // Mean humidity over that day's own hours.
                        let hs = all.filter(h => h.date === date)
                        let hum = 0
                        for (const h of hs) hum += h.humidity
                        days.push({
                            date: date,
                            label: root.dayLabel(date, i),
                            maxC: Math.round(dy.temperature_2m_max[i]),
                            minC: Math.round(dy.temperature_2m_min[i]),
                            rain: Math.round(dy.precipitation_probability_max[i] || 0),
                            code: dy.weather_code[i],
                            condition: root.codeToText(dy.weather_code[i]),
                            uv: Math.round(dy.uv_index_max[i] || 0),
                            feelsC: Math.round(dy.apparent_temperature_max[i]),
                            windKph: Math.round(dy.wind_speed_10m_max[i] || 0),
                            windDir: Math.round(dy.wind_direction_10m_dominant[i] || 0),
                            humidity: hs.length > 0 ? Math.round(hum / hs.length) : 0,
                            sunrise: root.clockOf(dy.sunrise[i]),
                            sunset: root.clockOf(dy.sunset[i]),
                            // Daylight icon: a row of five day summaries reading
                            // as night would be nonsense
                            icon: root.codeToIcon(dy.weather_code[i], true)
                        })
                    }
                    root.forecast = days
                    root.rainProb = days[0].rain
                    root.uvMax = days[0].uv
                    root.sunrise = days[0].sunrise
                    root.sunset = days[0].sunset
                    root.sunriseMin = root.minutesOf(dy.sunrise[0])
                    root.sunsetMin = root.minutesOf(dy.sunset[0])
                } catch (e) { console.warn("[Weather] forecast error:", e) }
            }
        }
    }

    // Wait for prefs to actually be on disk before touching persisted state.
    Component.onCompleted: if (Services.Prefs.loaded) root.start()
    Connections {
        target: Services.Prefs
        function onLoadedChanged() { if (Services.Prefs.loaded) root.start() }
    }

    Timer {
        interval: 900000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
}
