import Foundation
import SwiftUI
import Combine
import CoreLocation
import WidgetKit

// MARK: - User Settings Enums

enum TemperatureUnit: String, CaseIterable {
    case fahrenheit = "Fahrenheit"
    case celsius = "Celsius"

    var symbol: String {
        switch self {
        case .fahrenheit: return "°F"
        case .celsius: return "°C"
        }
    }
}

enum WindSpeedUnit: String, CaseIterable {
    case mph = "mph"
    case kmh = "km/h"
    case ms = "m/s"
}

enum AppAppearance: String, CaseIterable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

enum AutoRefresh: String, CaseIterable {
    case onLaunch = "On Launch"
    case manual = "Manual"
}

@MainActor
final class WeatherViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentWeather: WeatherResponse?
    @Published var forecast: ForecastResponse?
    @Published var airQuality: AirQualityResponse?
    @Published var alerts: [NWSAlertFeature] = []
    @Published var isLoading = false
    @Published var isLoadingAlerts = false
    @Published var errorMessage: String?
    @Published var cityName: String = ""
    @Published var stateName: String = ""
    @Published var countyName: String = ""
    /// Cached past forecast items from today (accumulated across refreshes)
    @Published var cachedPastItems: [ForecastItem] = []
    private var cachedDateKey: String = ""
    @Published var searchText: String = ""
    @Published var recentSearches: [String] = []
    @Published var citySuggestions: [GeocodingResult] = []
    @Published var isLoadingSuggestions = false

    // MARK: - User Settings
    @Published var temperatureUnit: TemperatureUnit {
        didSet { UserDefaults.standard.set(temperatureUnit.rawValue, forKey: "temperatureUnit") }
    }
    @Published var windSpeedUnit: WindSpeedUnit {
        didSet { UserDefaults.standard.set(windSpeedUnit.rawValue, forKey: "windSpeedUnit") }
    }
    @Published var appearance: AppAppearance {
        didSet { UserDefaults.standard.set(appearance.rawValue, forKey: "appearance") }
    }
    @Published var autoRefresh: AutoRefresh {
        didSet { UserDefaults.standard.set(autoRefresh.rawValue, forKey: "autoRefresh") }
    }
    @Published var defaultLocationName: String {
        didSet { UserDefaults.standard.set(defaultLocationName, forKey: "defaultLocationName") }
    }
    @Published var defaultLocationLat: Double {
        didSet { UserDefaults.standard.set(defaultLocationLat, forKey: "defaultLocationLat") }
    }
    @Published var defaultLocationLon: Double {
        didSet { UserDefaults.standard.set(defaultLocationLon, forKey: "defaultLocationLon") }
    }
    @Published var savedLocations: [SavedLocation] = [] {
        didSet { persistSavedLocations() }
    }

    // MARK: - Constants
    // Wise County, Texas (Decatur area)
    static let wiseCountyLat = 33.2343
    static let wiseCountyLon = -97.5892

    // MARK: - Dependencies
    let locationManager = LocationManager()
    private let weatherService = WeatherService.shared
    private let alertService = AlertService.shared
    private var cancellables = Set<AnyCancellable>()
    private var suggestionTask: Task<Void, Never>?

    // MARK: - Computed Properties

    // MARK: - Unit Conversion Helpers

    func convertTemp(_ fahrenheit: Double) -> Double {
        switch temperatureUnit {
        case .fahrenheit: return fahrenheit
        case .celsius: return (fahrenheit - 32) * 5.0 / 9.0
        }
    }

    private func convertWindSpeed(_ mph: Double) -> Double {
        switch windSpeedUnit {
        case .mph: return mph
        case .kmh: return mph * 1.60934
        case .ms: return mph * 0.44704
        }
    }

    var temperatureString: String {
        guard let temp = currentWeather?.main.temp else { return "--" }
        return "\(Int(convertTemp(temp).rounded()))\(temperatureUnit.symbol)"
    }

    var feelsLikeString: String {
        guard let temp = currentWeather?.main.feelsLike else { return "--°" }
        return "\(Int(convertTemp(temp).rounded()))\(temperatureUnit.symbol)"
    }

    var highTempString: String {
        guard let temp = currentWeather?.main.tempMax else { return "--°" }
        return "H:\(Int(convertTemp(temp).rounded()))°"
    }

    var lowTempString: String {
        guard let temp = currentWeather?.main.tempMin else { return "--°" }
        return "L:\(Int(convertTemp(temp).rounded()))°"
    }

    var conditionDescription: String {
        currentWeather?.weather.first?.description.capitalized ?? "Unknown"
    }

    var conditionIcon: String {
        guard let weather = currentWeather?.weather.first else { return "sun.max.fill" }
        return WeatherIconMapper.sfSymbol(for: weather.id, icon: weather.icon)
    }

    /// Short natural-language outlook built from the next forecast period.
    var hourlyOutlook: String? {
        guard let current = currentWeather,
              let list = forecast?.list else { return nil }

        let now = Date().timeIntervalSince1970
        guard let next = list.first(where: { Double($0.dt) > now }),
              let nextCondition = next.weather.first,
              let currentCondition = current.weather.first else { return nil }

        let nextTemp = Int(convertTemp(next.main.temp).rounded())
        let currentTemp = Int(convertTemp(current.main.temp).rounded())
        let unit = temperatureUnit.symbol

        let conditionChanging = nextCondition.main.lowercased() != currentCondition.main.lowercased()
        let tempDiff = nextTemp - currentTemp
        let pop = next.pop ?? 0

        var parts: [String] = []

        // Temperature trend
        if abs(tempDiff) >= 2 {
            let direction = tempDiff > 0 ? "rising" : "dropping"
            parts.append("Temps \(direction) to \(nextTemp)\(unit)")
        } else {
            parts.append("Holding steady around \(currentTemp)\(unit)")
        }

        // Condition change
        if conditionChanging {
            parts.append("with \(nextCondition.description) expected")
        }

        // Precipitation chance
        if pop >= 0.3 {
            parts.append("\(Int(pop * 100))% chance of rain")
        }

        return parts.joined(separator: ", ") + "."
    }

    var isDaytime: Bool {
        guard let weather = currentWeather,
              let sunrise = weather.sys.sunrise,
              let sunset = weather.sys.sunset else { return true }
        let currentTimestamp = Int(Date().timeIntervalSince1970)
        return Date.isDaytime(currentDt: currentTimestamp, sunrise: sunrise, sunset: sunset)
    }

    var backgroundGradient: LinearGradient {
        guard let conditionId = currentWeather?.weather.first?.id else {
            return WeatherGradients.defaultBackground
        }
        let isDark: Bool
        switch appearance {
        case .dark:
            isDark = true
        case .light:
            isDark = false
        case .system:
            isDark = UITraitCollection.current.userInterfaceStyle == .dark
        }
        return WeatherGradients.background(for: conditionId, isDaytime: isDaytime, darkMode: isDark)
    }

    var humidityString: String {
        guard let humidity = currentWeather?.main.humidity else { return "--%" }
        return "\(humidity)%"
    }

    var windSpeedString: String {
        guard let speed = currentWeather?.wind.speed else { return "-- \(windSpeedUnit.rawValue)" }
        return String(format: "%.1f %@", convertWindSpeed(speed), windSpeedUnit.rawValue)
    }

    var pressureString: String {
        guard let pressure = currentWeather?.main.pressure else { return "-- hPa" }
        return "\(pressure) hPa"
    }

    var visibilityString: String {
        guard let visibility = currentWeather?.visibility else { return "-- mi" }
        let miles = Double(visibility) / 1609.34
        return String(format: "%.1f mi", miles)
    }

    var sunriseString: String {
        guard let sunrise = currentWeather?.sys.sunrise else { return "--:--" }
        return sunrise.asDate.formattedTime(timezoneOffset: currentWeather?.timezone ?? 0)
    }

    var sunsetString: String {
        guard let sunset = currentWeather?.sys.sunset else { return "--:--" }
        return sunset.asDate.formattedTime(timezoneOffset: currentWeather?.timezone ?? 0)
    }

    var daylightDurationString: String {
        guard let sunrise = currentWeather?.sys.sunrise,
              let sunset = currentWeather?.sys.sunset else { return "" }
        let seconds = sunset - sunrise
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        return "\(hours)h \(minutes)m of daylight"
    }

    var countryCode: String {
        currentWeather?.sys.country ?? ""
    }

    var hourlyForecast: [ForecastItem] {
        let now = Date().timeIntervalSince1970
        return Array(
            forecast?.list
                .filter { Double($0.dt) > now }
                .prefix(8) ?? []
        )
    }

    /// Full hourly timeline: cached past items + "Now" + future items
    var fullHourlyTimeline: [HourlyDisplayItem] {
        guard let list = forecast?.list else { return [] }
        let now = Date().timeIntervalSince1970

        var items: [HourlyDisplayItem] = []

        // Past items from cache (accumulated across refreshes throughout the day)
        for item in cachedPastItems {
            let icon = item.weather.first.map {
                WeatherIconMapper.sfSymbol(for: $0.id, icon: $0.icon)
            } ?? "sun.max.fill"
            items.append(HourlyDisplayItem(
                id: item.dt,
                timestamp: item.dt,
                forecastTemp: item.main.temp,
                actualTemp: item.main.temp,
                icon: icon,
                pop: item.pop,
                isPast: true,
                isNow: false
            ))
        }

        // "Now" item from current weather
        if let weather = currentWeather {
            let icon = weather.weather.first.map {
                WeatherIconMapper.sfSymbol(for: $0.id, icon: $0.icon)
            } ?? "sun.max.fill"
            // Find nearest forecast item for predicted temp
            let nearestForecast = list.min(by: {
                abs(Double($0.dt) - now) < abs(Double($1.dt) - now)
            })
            items.append(HourlyDisplayItem(
                id: Int(now),
                timestamp: Int(now),
                forecastTemp: nearestForecast?.main.temp ?? weather.main.temp,
                actualTemp: weather.main.temp,
                icon: icon,
                pop: nil,
                isPast: false,
                isNow: true
            ))
        }

        // Future items (next 8)
        let futureItems = Array(list.filter { Double($0.dt) > now }.prefix(8))
        for item in futureItems {
            let icon = item.weather.first.map {
                WeatherIconMapper.sfSymbol(for: $0.id, icon: $0.icon)
            } ?? "sun.max.fill"
            items.append(HourlyDisplayItem(
                id: item.dt,
                timestamp: item.dt,
                forecastTemp: item.main.temp,
                actualTemp: nil,
                icon: icon,
                pop: item.pop,
                isPast: false,
                isNow: false
            ))
        }

        return items
    }

    var dailyForecast: [DailyForecast] {
        guard let list = forecast?.list else { return [] }
        let timezone = forecast?.city.timezone ?? 0

        var dailyDict: [String: [ForecastItem]] = [:]
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: timezone)

        for item in list {
            let dateKey = formatter.string(from: item.dt.asDate)
            dailyDict[dateKey, default: []].append(item)
        }

        let todayKey = formatter.string(from: Date())

        return dailyDict
            .filter { $0.key != todayKey }
            .sorted { $0.key < $1.key }
            .prefix(5)
            .map { (key, items) in
                let highTemp = items.map(\.main.tempMax).max() ?? 0
                let lowTemp = items.map(\.main.tempMin).min() ?? 0
                let midday = items.min { item1, item2 in
                    abs(item1.dt - (items.first!.dt + 43200)) < abs(item2.dt - (items.first!.dt + 43200))
                }
                let weather = midday?.weather.first ?? items.first!.weather.first!
                let date = items.first!.dt.asDate
                let pop = items.map { $0.pop ?? 0 }.max() ?? 0

                let avgHumidity = items.map(\.main.humidity).reduce(0, +) / max(items.count, 1)
                let maxWind = items.map(\.wind.speed).max() ?? 0
                let avgPressure = items.map(\.main.pressure).reduce(0, +) / max(items.count, 1)
                let avgVis = items.compactMap(\.visibility).map(Double.init).reduce(0, +) / max(Double(items.compactMap(\.visibility).count), 1)

                let outlook = Self.buildDailyOutlook(
                    description: weather.description,
                    highTemp: highTemp,
                    lowTemp: lowTemp,
                    pop: pop,
                    humidity: avgHumidity,
                    windSpeed: maxWind
                )

                return DailyForecast(
                    date: date,
                    highTemp: highTemp,
                    lowTemp: lowTemp,
                    conditionId: weather.id,
                    conditionIcon: weather.icon,
                    conditionDescription: weather.description,
                    pop: pop,
                    avgHumidity: avgHumidity,
                    maxWindSpeed: maxWind,
                    avgPressure: avgPressure,
                    avgVisibility: avgVis,
                    outlook: outlook
                )
            }
    }

    private static func buildDailyOutlook(
        description: String,
        highTemp: Double,
        lowTemp: Double,
        pop: Double,
        humidity: Int,
        windSpeed: Double
    ) -> String {
        var parts: [String] = []

        parts.append("Expect \(description)")

        if pop >= 0.3 {
            parts.append("with a \(Int(pop * 100))% chance of precipitation")
        }

        if windSpeed > 15 {
            parts.append("Winds could gust up to \(Int(windSpeed.rounded())) mph")
        } else if windSpeed > 8 {
            parts.append("Breezy conditions with winds around \(Int(windSpeed.rounded())) mph")
        } else {
            parts.append("Light winds around \(Int(windSpeed.rounded())) mph")
        }

        if humidity > 75 {
            parts.append("High humidity at \(humidity)%")
        }

        return parts.joined(separator: ". ") + "."
    }

    var airQualityIndex: Int? {
        airQuality?.list.first?.main.aqi
    }

    var airQualityLabel: String {
        guard let aqi = airQualityIndex else { return "N/A" }
        switch aqi {
        case 1: return "Good"
        case 2: return "Fair"
        case 3: return "Moderate"
        case 4: return "Poor"
        case 5: return "Very Poor"
        default: return "Unknown"
        }
    }

    /// Whether any active alerts are tornado or hail related
    var hasTornadoOrHailAlert: Bool {
        alerts.contains { alert in
            let event = alert.properties.event.lowercased()
            return event.contains("tornado") || event.contains("hail")
        }
    }

    /// Active severe thunderstorm or tornado warnings specifically
    var severeAlerts: [NWSAlertFeature] {
        alerts.filter { alert in
            let event = alert.properties.event.lowercased()
            return event.contains("tornado") ||
                   event.contains("severe thunderstorm") ||
                   event.contains("hail") ||
                   alert.properties.severity == .extreme ||
                   alert.properties.severity == .severe
        }
    }

    // MARK: - Init

    init() {
        // Load saved settings
        let tempRaw = UserDefaults.standard.string(forKey: "temperatureUnit") ?? TemperatureUnit.fahrenheit.rawValue
        self.temperatureUnit = TemperatureUnit(rawValue: tempRaw) ?? .fahrenheit

        let windRaw = UserDefaults.standard.string(forKey: "windSpeedUnit") ?? WindSpeedUnit.mph.rawValue
        self.windSpeedUnit = WindSpeedUnit(rawValue: windRaw) ?? .mph

        let appearanceRaw = UserDefaults.standard.string(forKey: "appearance") ?? AppAppearance.dark.rawValue
        self.appearance = AppAppearance(rawValue: appearanceRaw) ?? .dark

        let refreshRaw = UserDefaults.standard.string(forKey: "autoRefresh") ?? AutoRefresh.onLaunch.rawValue
        self.autoRefresh = AutoRefresh(rawValue: refreshRaw) ?? .onLaunch

        self.defaultLocationName = UserDefaults.standard.string(forKey: "defaultLocationName") ?? "Wise County, TX"
        self.defaultLocationLat = UserDefaults.standard.object(forKey: "defaultLocationLat") as? Double ?? Self.wiseCountyLat
        self.defaultLocationLon = UserDefaults.standard.object(forKey: "defaultLocationLon") as? Double ?? Self.wiseCountyLon
        self.savedLocations = Self.loadSavedLocations()

        loadRecentSearches()
        observeLocation()
    }

    // MARK: - Methods

    func fetchWeather() {
        if let location = locationManager.location {
            Task {
                await fetchWeather(lat: location.coordinate.latitude, lon: location.coordinate.longitude)
            }
        } else if locationManager.authorizationStatus == .denied ||
                  locationManager.authorizationStatus == .restricted {
            // Fall back to saved default location
            Task {
                await fetchWeather(lat: defaultLocationLat, lon: defaultLocationLon)
            }
        } else {
            locationManager.requestAuthorization()
            // Load default location while waiting for location
            Task {
                await fetchWeather(lat: defaultLocationLat, lon: defaultLocationLon)
            }
        }
    }

    func fetchWeather(lat: Double, lon: Double) async {
        isLoading = true
        errorMessage = nil

        do {
            async let weatherTask = weatherService.fetchCurrentWeather(lat: lat, lon: lon)
            async let forecastTask = weatherService.fetchForecast(lat: lat, lon: lon)
            async let airQualityTask = weatherService.fetchAirQuality(lat: lat, lon: lon)

            let (weather, forecastResult) = try await (weatherTask, forecastTask)
            let aq = try? await airQualityTask

            self.currentWeather = weather
            self.forecast = forecastResult
            self.airQuality = aq
            self.cityName = weather.name
            cachePastForecastItems(from: forecastResult)

            // Reverse geocode to get state name and county
            if let geo = try? await weatherService.reverseGeocode(lat: lat, lon: lon) {
                self.stateName = geo.state ?? ""
            } else {
                self.stateName = ""
            }
            await fetchCountyName(lat: lat, lon: lon)
        } catch {
            self.errorMessage = error.localizedDescription
        }

        isLoading = false

        // Write widget data to shared container
        writeWidgetData()

        // Also fetch NWS alerts
        await fetchAlerts()
    }

    // MARK: - Widget Data Sharing

    private func writeWidgetData() {
        guard let weather = currentWeather, let forecastData = forecast else { return }

        // Write location and settings to shared UserDefaults
        let sharedDefaults = SharedConstants.sharedDefaults
        sharedDefaults?.set(weather.coord.lat, forKey: SharedConstants.defaultLocationLatKey)
        sharedDefaults?.set(weather.coord.lon, forKey: SharedConstants.defaultLocationLonKey)
        sharedDefaults?.set(weather.name, forKey: SharedConstants.defaultLocationNameKey)
        sharedDefaults?.set(temperatureUnit.rawValue, forKey: SharedConstants.temperatureUnitKey)

        // Build and save widget snapshot
        let timezone = weather.timezone
        let now = Date().timeIntervalSince1970

        let hourlyItems = Array(
            forecastData.list
                .filter { Double($0.dt) > now }
                .prefix(4)
        )
        let hourlySnapshots = hourlyItems.map { item in
            HourlySnapshot(
                dt: item.dt,
                temp: item.main.temp,
                conditionId: item.weather.first?.id ?? 800,
                conditionIcon: item.weather.first?.icon ?? "01d",
                pop: item.pop ?? 0
            )
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: timezone)

        let dayNameFormatter = DateFormatter()
        dayNameFormatter.dateFormat = "EEE"
        dayNameFormatter.timeZone = TimeZone(secondsFromGMT: timezone)

        var dailyDict: [String: [ForecastItem]] = [:]
        for item in forecastData.list {
            let dateKey = formatter.string(from: Date(timeIntervalSince1970: TimeInterval(item.dt)))
            dailyDict[dateKey, default: []].append(item)
        }

        let todayKey = formatter.string(from: Date())
        let dailySnapshots = dailyDict
            .filter { $0.key != todayKey }
            .sorted { $0.key < $1.key }
            .prefix(5)
            .enumerated()
            .map { (index, entry) in
                let items = entry.value
                let highTemp = items.map(\.main.tempMax).max() ?? 0
                let lowTemp = items.map(\.main.tempMin).min() ?? 0
                let midday = items.min { abs($0.dt - (items.first!.dt + 43200)) < abs($1.dt - (items.first!.dt + 43200)) }
                let condition = midday?.weather.first ?? items.first!.weather.first!
                let date = Date(timeIntervalSince1970: TimeInterval(items.first!.dt))
                let pop = items.map { $0.pop ?? 0 }.max() ?? 0

                return DailySnapshot(
                    id: index,
                    dayName: dayNameFormatter.string(from: date),
                    highTemp: highTemp,
                    lowTemp: lowTemp,
                    conditionId: condition.id,
                    conditionIcon: condition.icon,
                    pop: pop
                )
            }

        let condition = weather.weather.first
        let snapshot = WidgetWeatherSnapshot(
            cityName: weather.name,
            currentTemp: weather.main.temp,
            tempMin: weather.main.tempMin,
            tempMax: weather.main.tempMax,
            conditionId: condition?.id ?? 800,
            conditionIcon: condition?.icon ?? "01d",
            conditionDescription: condition?.description.capitalized ?? "Clear",
            humidity: weather.main.humidity,
            windSpeed: weather.wind.speed,
            timestamp: Date(),
            timezone: timezone,
            sunrise: weather.sys.sunrise ?? 0,
            sunset: weather.sys.sunset ?? 0,
            hourlyForecast: hourlySnapshots,
            dailyForecast: Array(dailySnapshots)
        )

        saveWidgetSnapshot(snapshot)
        WidgetCenter.shared.reloadAllTimelines()
    }

    func searchCity() {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        Task {
            isLoading = true
            errorMessage = nil

            do {
                async let weatherTask = weatherService.fetchCurrentWeather(city: trimmed)
                async let forecastTask = weatherService.fetchForecast(city: trimmed)

                let (weather, forecastResult) = try await (weatherTask, forecastTask)

                self.currentWeather = weather
                self.forecast = forecastResult
                self.cityName = weather.name

                // Fetch air quality and reverse geocode with coordinates from response
                let coord = weather.coord
                self.airQuality = try? await weatherService.fetchAirQuality(lat: coord.lat, lon: coord.lon)
                if let geo = try? await weatherService.reverseGeocode(lat: coord.lat, lon: coord.lon) {
                    self.stateName = geo.state ?? ""
                } else {
                    self.stateName = ""
                }
                await fetchCountyName(lat: coord.lat, lon: coord.lon)

                addRecentSearch(trimmed)
            } catch {
                self.errorMessage = error.localizedDescription
            }

            isLoading = false

            // Fetch alerts for new location
            await fetchAlerts()
        }
    }

    func searchCity(_ city: String) {
        searchText = city
        searchCity()
    }

    /// Fetch city autocomplete suggestions with debouncing
    func fetchCitySuggestions(for query: String) {
        suggestionTask?.cancel()

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else {
            citySuggestions = []
            isLoadingSuggestions = false
            return
        }

        isLoadingSuggestions = true
        suggestionTask = Task {
            // Debounce: wait 300ms before firing
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }

            do {
                let results = try await weatherService.fetchCitySuggestions(query: trimmed)
                guard !Task.isCancelled else { return }
                self.citySuggestions = results
            } catch {
                guard !Task.isCancelled else { return }
                self.citySuggestions = []
            }
            self.isLoadingSuggestions = false
        }
    }

    /// Select a city from autocomplete and fetch its weather by coordinates
    func selectCity(_ city: GeocodingResult) {
        citySuggestions = []
        addRecentSearch(city.name)
        Task {
            await fetchWeather(lat: city.lat, lon: city.lon)
        }
    }

    private func fetchCountyName(lat: Double, lon: Double) async {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: lat, longitude: lon)
        if let placemarks = try? await geocoder.reverseGeocodeLocation(location),
           let county = placemarks.first?.subAdministrativeArea {
            self.countyName = county
        } else {
            self.countyName = ""
        }
    }

    func loadWiseCounty() {
        Task {
            await fetchWeather(lat: defaultLocationLat, lon: defaultLocationLon)
        }
    }

    func setDefaultLocation(name: String, lat: Double, lon: Double) {
        defaultLocationName = name
        defaultLocationLat = lat
        defaultLocationLon = lon
    }

    func setCurrentLocationAsDefault() {
        if let weather = currentWeather {
            setDefaultLocation(
                name: "\(weather.name), \(weather.sys.country ?? "")",
                lat: weather.coord.lat,
                lon: weather.coord.lon
            )
        }
    }

    // MARK: - Saved Locations

    func addSavedLocation(label: String, cityName: String, lat: Double, lon: Double) {
        let location = SavedLocation(label: label, cityName: cityName, latitude: lat, longitude: lon)
        savedLocations.append(location)
    }

    func updateSavedLocation(_ location: SavedLocation) {
        if let index = savedLocations.firstIndex(where: { $0.id == location.id }) {
            savedLocations[index] = location
        }
    }

    func removeSavedLocation(_ location: SavedLocation) {
        savedLocations.removeAll { $0.id == location.id }
    }

    func loadSavedLocationWeather(_ location: SavedLocation) {
        Task {
            await fetchWeather(lat: location.latitude, lon: location.longitude)
        }
    }

    private func persistSavedLocations() {
        if let data = try? JSONEncoder().encode(savedLocations) {
            UserDefaults.standard.set(data, forKey: "savedLocations")
        }
    }

    private static func loadSavedLocations() -> [SavedLocation] {
        guard let data = UserDefaults.standard.data(forKey: "savedLocations"),
              let locations = try? JSONDecoder().decode([SavedLocation].self, from: data) else {
            return []
        }
        return locations
    }

    // MARK: - Past Forecast Caching

    private func cachePastForecastItems(from forecast: ForecastResponse) {
        let timezone = forecast.city.timezone ?? 0
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: timezone)
        let todayKey = formatter.string(from: Date())

        // Reset cache if it's a new day
        if cachedDateKey != todayKey {
            cachedPastItems = []
            cachedDateKey = todayKey
        }

        let now = Date().timeIntervalSince1970

        // Add any items from today that are in the past and not already cached
        let existingTimestamps = Set(cachedPastItems.map(\.dt))
        let newPastItems = forecast.list.filter { item in
            Double(item.dt) <= now &&
            formatter.string(from: item.dt.asDate) == todayKey &&
            !existingTimestamps.contains(item.dt)
        }
        cachedPastItems.append(contentsOf: newPastItems)
        cachedPastItems.sort { $0.dt < $1.dt }
    }

    func refresh() async {
        if let weather = currentWeather {
            await fetchWeather(lat: weather.coord.lat, lon: weather.coord.lon)
        } else {
            fetchWeather()
        }
    }

    // MARK: - Alerts

    func fetchAlerts() async {
        isLoadingAlerts = true
        do {
            // Always fetch Wise County alerts, plus location-specific if available
            let wiseCountyAlerts = try await alertService.fetchAlertsForWiseCounty()

            if let weather = currentWeather,
               abs(weather.coord.lat - Self.wiseCountyLat) > 0.5 ||
               abs(weather.coord.lon - Self.wiseCountyLon) > 0.5 {
                // User is looking at a different location, merge alerts
                let locationAlerts = (try? await alertService.fetchAlerts(
                    lat: weather.coord.lat,
                    lon: weather.coord.lon
                )) ?? []
                // Deduplicate by ID
                var seen = Set<String>()
                var merged: [NWSAlertFeature] = []
                for alert in wiseCountyAlerts + locationAlerts {
                    if seen.insert(alert.id).inserted {
                        merged.append(alert)
                    }
                }
                self.alerts = merged.sorted { $0.properties.severity < $1.properties.severity }
            } else {
                self.alerts = wiseCountyAlerts
            }
        } catch {
            // Don't fail the whole app for alert failures
            print("Failed to fetch alerts: \(error.localizedDescription)")
        }
        isLoadingAlerts = false
    }

    func refreshAlerts() async {
        await fetchAlerts()
    }

    // MARK: - Recent Searches

    private func loadRecentSearches() {
        recentSearches = UserDefaults.standard.stringArray(forKey: "recentSearches") ?? []
    }

    private func addRecentSearch(_ city: String) {
        recentSearches.removeAll { $0.lowercased() == city.lowercased() }
        recentSearches.insert(city, at: 0)
        if recentSearches.count > 10 {
            recentSearches = Array(recentSearches.prefix(10))
        }
        UserDefaults.standard.set(recentSearches, forKey: "recentSearches")
    }

    func removeRecentSearch(_ city: String) {
        recentSearches.removeAll { $0 == city }
        UserDefaults.standard.set(recentSearches, forKey: "recentSearches")
    }

    func clearRecentSearches() {
        recentSearches.removeAll()
        UserDefaults.standard.removeObject(forKey: "recentSearches")
    }

    // MARK: - Private

    private func observeLocation() {
        locationManager.$location
            .compactMap { $0 }
            .first()
            .sink { [weak self] location in
                guard let self else { return }
                Task {
                    await self.fetchWeather(lat: location.coordinate.latitude, lon: location.coordinate.longitude)
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Daily Forecast Model
struct DailyForecast: Identifiable {
    let id = UUID()
    let date: Date
    let highTemp: Double
    let lowTemp: Double
    let conditionId: Int
    let conditionIcon: String
    let conditionDescription: String
    let pop: Double
    let avgHumidity: Int
    let maxWindSpeed: Double
    let avgPressure: Int
    let avgVisibility: Double // meters
    let outlook: String
}
