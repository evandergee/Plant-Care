import SwiftUI
import MapKit
import CoreLocation

// St. Louis, used for both the weather request and the map pin.
let stLouis = CLLocationCoordinate2D(latitude: 38.61, longitude: -90.21)

// 1. The shape of the JSON. Property names match Open-Meteo's keys exactly,
//    so JSONDecoder can fill them in automatically.
struct Forecast: Decodable {
    let current: Current
    let daily: Daily

    struct Current: Decodable {
        let temperature_2m: Double        // right now, °F
        let relative_humidity_2m: Double  // right now, %
    }

    struct Daily: Decodable {
        let time: [String]                // "2026-09-29"
        let temperature_2m_max: [Double]  // highs, °F
        let temperature_2m_min: [Double]  // lows, °F
        let precipitation_sum: [Double]   // rain, inches
        let precipitation_probability_max: [Int?]  // chance of rain, %
        let weather_code: [Int]           // sunny, cloudy, rain... (a number code)
    }
}

// 2. Ask Open-Meteo for the forecast at any location. No API key needed.
func fetchForecast(at place: CLLocationCoordinate2D) async throws -> Forecast {
    let url = URL(string: "https://api.open-meteo.com/v1/forecast?latitude=\(place.latitude)&longitude=\(place.longitude)&current=temperature_2m,relative_humidity_2m&daily=temperature_2m_max,temperature_2m_min,precipitation_sum,precipitation_probability_max,weather_code&temperature_unit=fahrenheit&precipitation_unit=inch&timezone=auto")!
    let (data, _) = try await URLSession.shared.data(from: url)
    return try JSONDecoder().decode(Forecast.self, from: data)
}

// A map area about 20 miles across, centered on a location.
func mapArea(around place: CLLocationCoordinate2D) -> MapCameraPosition {
    .region(MKCoordinateRegion(center: place,
                               span: MKCoordinateSpan(latitudeDelta: 0.3, longitudeDelta: 0.3)))
}

// 3. A small "72° · 58% RH" badge you can drop on any screen.
struct CurrentConditionsBar: View {
    @State private var current: Forecast.Current?

    var body: some View {
        HStack(spacing: 10) {
            if let current {
                Label("\(Int(current.temperature_2m))°", systemImage: "thermometer.medium")
                Label("\(Int(current.relative_humidity_2m))% RH", systemImage: "humidity")
            } else {
                ProgressView()
            }
        }
        .font(.subheadline)
        .task {
            current = try? await fetchForecast(at: stLouis).current
        }
    }
}

// 4. The weather screen: search box, map, current conditions, 7-day forecast.
struct WeatherView: View {
    @State private var forecast: Forecast?
    @State private var errorText: String?

    // STEP 8: The place is SAVED on the phone (@AppStorage), so it's remembered after
    // the app closes AND shared with the Plants tab, which reads the same keys.
    // Starts in St. Louis; search or "Use my location" changes it.
    @AppStorage("placeName") private var placeName = "St. Louis"
    @AppStorage("placeLat") private var placeLat = stLouis.latitude
    @AppStorage("placeLon") private var placeLon = stLouis.longitude
    private var place: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: placeLat, longitude: placeLon)
    }
    @State private var mapPosition = mapArea(around: stLouis)

    @State private var searchText = ""
    @State private var searchMessage: String?

    var body: some View {
        List {
            // The map follows whatever place is selected.
            Section {
                Map(position: $mapPosition) {
                    Marker(placeName, systemImage: "leaf.fill", coordinate: place)
                        .tint(Color.leaf)
                    UserAnnotation()   // the blue "you are here" dot, once location is allowed
                }
                .frame(height: 200)
                .listRowInsets(EdgeInsets())   // let the map fill the whole card
            }

            if let searchMessage {
                Text(searchMessage).foregroundStyle(.secondary)
            }

            if let forecast {
                Section("Right now") {
                    HStack {
                        Label("\(Int(forecast.current.temperature_2m))°F", systemImage: "thermometer.medium")
                        Spacer()
                        Label("\(Int(forecast.current.relative_humidity_2m))% RH", systemImage: "humidity")
                    }
                }
                Section("Next 7 days") {
                    let daily = forecast.daily
                    // The coldest and hottest temps of the week, so every bar uses the same scale.
                    let weekLow = daily.temperature_2m_min.min() ?? 0
                    let weekHigh = daily.temperature_2m_max.max() ?? 100

                    ForEach(daily.time.indices, id: \.self) { i in
                        HStack(spacing: 12) {
                            Text(dayName(daily.time[i], isToday: i == 0))
                                .font(.headline)
                                .frame(width: 52, alignment: .leading)

                            // Weather icon, with rain chance underneath when it's likely.
                            VStack(spacing: 2) {
                                Image(systemName: weatherIcon(daily.weather_code[i]))
                                    .symbolRenderingMode(.multicolor)
                                    .font(.title3)
                                if let chance = daily.precipitation_probability_max[i], chance >= 20 {
                                    Text("\(chance)%")
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(.blue)
                                }
                            }
                            .frame(width: 34)

                            Text("\(Int(daily.temperature_2m_min[i]))°")
                                .foregroundStyle(.secondary)
                                .frame(width: 36, alignment: .trailing)

                            TempRangeBar(low: daily.temperature_2m_min[i],
                                         high: daily.temperature_2m_max[i],
                                         weekLow: weekLow, weekHigh: weekHigh)

                            Text("\(Int(daily.temperature_2m_max[i]))°")
                                .frame(width: 36, alignment: .leading)
                        }
                        .padding(.vertical, 4)
                    }
                }
            } else if let errorText {
                Text("Couldn't load weather: \(errorText)")
            } else {
                ProgressView()
            }
        }
        .scrollContentBackground(.hidden)   // same green garden look as the plant list
        .background(GardenBackground())
        .navigationTitle(placeName)
        // Adds a search box under the title.
        .searchable(text: $searchText, prompt: "Search a city or zip code")
        .onSubmit(of: .search) {
            Task { await search() }
        }
        // Location button in the top corner.
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { await useMyLocation() }
                } label: {
                    Label("Use my location", systemImage: "location.fill")
                }
            }
        }
        // Point the map at the saved place when the screen opens.
        .onAppear { mapPosition = mapArea(around: place) }
        // Runs on open, and again every time the place moves.
        .task(id: "\(place.latitude),\(place.longitude)") {
            await loadWeather()
        }
    }

    private func loadWeather() async {
        forecast = nil
        errorText = nil
        do {
            forecast = try await fetchForecast(at: place)
        } catch {
            errorText = error.localizedDescription
        }
    }

    // Save a new place (latitude and longitude are stored separately).
    private func setPlace(_ coordinate: CLLocationCoordinate2D) {
        placeLat = coordinate.latitude
        placeLon = coordinate.longitude
    }

    // Ask the phone where we are. The first time, iOS shows the "Allow location?" popup.
    private func useMyLocation() async {
        do {
            for try await update in CLLocationUpdate.liveUpdates() {
                if let location = update.location {
                    setPlace(location.coordinate)
                    placeName = "My Location"
                    mapPosition = mapArea(around: place)
                    searchMessage = nil
                    return   // one reading is enough; stop listening
                }
                if update.authorizationDenied {
                    searchMessage = "Location is off for PlantCare. You can turn it on in Settings."
                    return
                }
            }
        } catch {
            searchMessage = "Couldn't get your location."
        }
    }

    // Ask Apple Maps to turn the typed text into a location.
    private func search() async {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.resultTypes = .address           // cities, zips, addresses (not businesses)
        do {
            let response = try await MKLocalSearch(request: request).start()
            guard let match = response.mapItems.first else { return }
            setPlace(match.location.coordinate)
            placeName = match.name ?? searchText
            mapPosition = mapArea(around: place)
            searchMessage = nil
        } catch {
            searchMessage = "No place found for \"\(searchText)\"."
        }
    }
}

// 6. Helpers for the 7-day list.

// "2026-09-29" -> "Today", "Wed", "Thu"...
func dayName(_ isoDate: String, isToday: Bool) -> String {
    if isToday { return "Today" }
    let parser = DateFormatter()
    parser.dateFormat = "yyyy-MM-dd"
    guard let date = parser.date(from: isoDate) else { return isoDate }
    return date.formatted(.dateTime.weekday(.abbreviated))
}

// Open-Meteo sends a number for the weather type (WMO codes). Turn it into an SF Symbol.
func weatherIcon(_ code: Int) -> String {
    switch code {
    case 0: "sun.max.fill"                       // clear
    case 1, 2: "cloud.sun.fill"                  // partly cloudy
    case 3: "cloud.fill"                         // overcast
    case 45, 48: "cloud.fog.fill"                // fog
    case 51...57: "cloud.drizzle.fill"           // drizzle
    case 61...67, 80...82: "cloud.rain.fill"     // rain / showers
    case 71...77, 85, 86: "cloud.snow.fill"      // snow
    case 95...99: "cloud.bolt.rain.fill"         // thunderstorm
    default: "cloud.fill"
    }
}

// A little bar showing one day's low-to-high range, placed on the week's overall scale.
struct TempRangeBar: View {
    let low: Double, high: Double
    let weekLow: Double, weekHigh: Double

    var body: some View {
        GeometryReader { geo in
            let span = max(weekHigh - weekLow, 1)
            let start = (low - weekLow) / span * geo.size.width
            let width = max((high - low) / span * geo.size.width, 6)
            ZStack(alignment: .leading) {
                Capsule().fill(.secondary.opacity(0.2))           // the full week track
                Capsule()
                    .fill(LinearGradient(colors: [.blue, .green, .orange],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(width: width)
                    .offset(x: start)
            }
        }
        .frame(height: 6)
    }
}

#Preview("7-day screen") {
    NavigationStack { WeatherView() }
}

#Preview("Badge") {
    CurrentConditionsBar()
}
