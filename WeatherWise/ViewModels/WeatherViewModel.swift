import Foundation
import SwiftUI
import Combine
import CoreLocation

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
        let isDark = appearance == .dark || (appearance == .system && UIScreen.main.traitCollection.userInterfaceStyle == .dark)
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

                return DailyForecast(
                    date: date,
                    highTemp: highTemp,
                    lowTemp: lowTemp,
                    conditionId: weather.id,
                    conditionIcon: weather.icon,
                    conditionDescription: weather.description,
                    pop: pop
                )
            }
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
        } catch {
            self.errorMessage = error.localizedDescription
        }

        isLoading = false

        // Also fetch NWS alerts
        await fetchAlerts()
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

                // Fetch air quality with coordinates from response
                let coord = weather.coord
                self.airQuality = try? await weatherService.fetchAirQuality(lat: coord.lat, lon: coord.lon)

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
}
