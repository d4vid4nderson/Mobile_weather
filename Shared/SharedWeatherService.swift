import Foundation

struct WidgetWeatherFetcher {
    private static let baseURL = "https://api.openweathermap.org/data/2.5"
    private static let units = "imperial"

    static func fetchCurrentWeather(lat: Double, lon: Double) async throws -> WeatherResponse {
        let urlString = "\(baseURL)/weather?lat=\(lat)&lon=\(lon)&appid=\(SharedConstants.apiKey)&units=\(units)"
        return try await performRequest(urlString: urlString)
    }

    static func fetchForecast(lat: Double, lon: Double) async throws -> ForecastResponse {
        let urlString = "\(baseURL)/forecast?lat=\(lat)&lon=\(lon)&appid=\(SharedConstants.apiKey)&units=\(units)"
        return try await performRequest(urlString: urlString)
    }

    /// Fetches weather and forecast, then builds a WidgetWeatherSnapshot
    static func fetchSnapshot(lat: Double, lon: Double, cityName: String?) async throws -> WidgetWeatherSnapshot {
        async let weatherTask = fetchCurrentWeather(lat: lat, lon: lon)
        async let forecastTask = fetchForecast(lat: lat, lon: lon)

        let (weather, forecast) = try await (weatherTask, forecastTask)

        let timezone = weather.timezone
        let now = Date().timeIntervalSince1970

        // Build hourly snapshots from forecast (next 4 hours)
        let hourlyItems = Array(
            forecast.list
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

        // Build daily snapshots from forecast
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: timezone)

        let dayNameFormatter = DateFormatter()
        dayNameFormatter.dateFormat = "EEE"
        dayNameFormatter.timeZone = TimeZone(secondsFromGMT: timezone)

        var dailyDict: [String: [ForecastItem]] = [:]
        for item in forecast.list {
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
        return WidgetWeatherSnapshot(
            cityName: cityName ?? weather.name,
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
    }

    private static func performRequest<T: Decodable>(urlString: String) async throws -> T {
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}
