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

    // Location lives in Prefs as a single "lat|lon|City" string: JsonAdapter
    // drops intermediate values when several props are written in one tick, so
    // the three pieces are packed into one field and written once.
    readonly property var loc: {
        let parts = (Services.Prefs.weatherLoc || "").split("|")
        if (parts.length < 2) return null
        let lat = parseFloat(parts[0]), lon = parseFloat(parts[1])
        if (isNaN(lat) || isNaN(lon)) return null
        return { lat: lat, lon: lon, city: parts.slice(2).join("|") }
    }
    readonly property string city: loc ? loc.city : ""

    function setLoc(lat, lon, city) {
        Services.Prefs.weatherLoc = lat + "|" + lon + "|" + (city || "")
    }

    // Open-Meteo speaks WMO weather codes (ints), not text, so both the glyph
    // and the human label are derived from the code here.
    function codeToIcon(code, hour) {
        let night = hour < 6 || hour >= 19
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
        if (index === 0) return "Today"
        let d = new Date(dateStr)
        return Qt.locale().dayName(d.getDay(), Locale.ShortFormat)
    }

    // Entry point: use the saved location, or geolocate by IP once if none yet.
    function refresh() {
        if (root.loc) fetchForecast(root.loc.lat, root.loc.lon)
        else geoProc.running = true
    }

    function fetchForecast(lat, lon) {
        let url = "https://api.open-meteo.com/v1/forecast?latitude=" + lat
            + "&longitude=" + lon
            + "&current=temperature_2m,weather_code"
            + "&daily=weather_code,temperature_2m_max,temperature_2m_min"
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
    // Commit one chosen candidate (exact coords, no re-geocode) and refresh.
    function chooseResult(lat, lon, label) {
        root.searchResults = []
        root.cityError = false
        root.setLoc(lat, lon, label)
        root.fetchForecast(lat, lon)
    }

    // IP geolocation fallback (no coords saved yet). Non-commercial, no key.
    Process {
        id: geoProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let d = JSON.parse(text)
                    if (d.status === "success") {
                        root.setLoc(d.lat, d.lon, d.city || "")
                        root.fetchForecast(d.lat, d.lon)
                    }
                } catch (e) { console.log("[Weather] geo error:", e) }
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
                } catch (e) { console.log("[Weather] search error:", e); root.searchResults = [] }
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
                    root.condition = root.codeToText(cur.weather_code)
                    root.icon = root.codeToIcon(cur.weather_code, new Date().getHours())

                    let days = []
                    let dy = d.daily
                    for (let i = 0; i < dy.time.length; i++) {
                        days.push({
                            label: root.dayLabel(dy.time[i], i),
                            maxC: Math.round(dy.temperature_2m_max[i]),
                            minC: Math.round(dy.temperature_2m_min[i]),
                            icon: root.codeToIcon(dy.weather_code[i], 12)
                        })
                    }
                    root.forecast = days
                } catch (e) { console.log("[Weather] forecast error:", e) }
            }
        }
    }

    Component.onCompleted: root.refresh()

    Timer {
        interval: 900000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
}
