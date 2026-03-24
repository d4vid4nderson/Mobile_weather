import Foundation

// MARK: - Widget Weather Snapshot

struct WidgetWeatherSnapshot: Codable {
    let cityName: String
    let currentTemp: Double
    let tempMin: Double
    let tempMax: Double
    let conditionId: Int
    let conditionIcon: String
    let conditionDescription: String
    let humidity: Int
    let windSpeed: Double
    let timestamp: Date
    let timezone: Int
    let sunrise: Int
    let sunset: Int
    let hourlyForecast: [HourlySnapshot]
    let dailyForecast: [DailySnapshot]

    static var placeholder: WidgetWeatherSnapshot {
        WidgetWeatherSnapshot(
            cityName: "Decatur",
            currentTemp: 72,
            tempMin: 65,
            tempMax: 78,
            conditionId: 802,
            conditionIcon: "02d",
            conditionDescription: "Partly Cloudy",
            humidity: 55,
            windSpeed: 8.5,
            timestamp: Date(),
            timezone: -18000,
            sunrise: Int(Date().timeIntervalSince1970) - 21600,
            sunset: Int(Date().timeIntervalSince1970) + 21600,
            hourlyForecast: [
                HourlySnapshot(dt: Int(Date().timeIntervalSince1970) + 3600, temp: 73, conditionId: 802, conditionIcon: "02d", pop: 0.1),
                HourlySnapshot(dt: Int(Date().timeIntervalSince1970) + 7200, temp: 74, conditionId: 800, conditionIcon: "01d", pop: 0.0),
                HourlySnapshot(dt: Int(Date().timeIntervalSince1970) + 10800, temp: 72, conditionId: 801, conditionIcon: "02d", pop: 0.05),
                HourlySnapshot(dt: Int(Date().timeIntervalSince1970) + 14400, temp: 70, conditionId: 802, conditionIcon: "02n", pop: 0.15),
            ],
            dailyForecast: [
                DailySnapshot(id: 0, dayName: "Tue", highTemp: 80, lowTemp: 62, conditionId: 800, conditionIcon: "01d", pop: 0.0),
                DailySnapshot(id: 1, dayName: "Wed", highTemp: 76, lowTemp: 58, conditionId: 500, conditionIcon: "10d", pop: 0.6),
                DailySnapshot(id: 2, dayName: "Thu", highTemp: 72, lowTemp: 55, conditionId: 802, conditionIcon: "03d", pop: 0.1),
                DailySnapshot(id: 3, dayName: "Fri", highTemp: 78, lowTemp: 60, conditionId: 801, conditionIcon: "02d", pop: 0.05),
                DailySnapshot(id: 4, dayName: "Sat", highTemp: 82, lowTemp: 64, conditionId: 800, conditionIcon: "01d", pop: 0.0),
            ]
        )
    }
}

// MARK: - Hourly Snapshot

struct HourlySnapshot: Codable, Identifiable {
    var id: Int { dt }
    let dt: Int
    let temp: Double
    let conditionId: Int
    let conditionIcon: String
    let pop: Double
}

// MARK: - Daily Snapshot

struct DailySnapshot: Codable, Identifiable {
    let id: Int
    let dayName: String
    let highTemp: Double
    let lowTemp: Double
    let conditionId: Int
    let conditionIcon: String
    let pop: Double
}

// MARK: - Read / Write Helpers

func saveWidgetSnapshot(_ snapshot: WidgetWeatherSnapshot) {
    guard let url = SharedConstants.snapshotFileURL else { return }
    do {
        let data = try JSONEncoder().encode(snapshot)
        try data.write(to: url, options: .atomic)
    } catch {
        print("Failed to save widget snapshot: \(error)")
    }
}

func loadWidgetSnapshot() -> WidgetWeatherSnapshot? {
    guard let url = SharedConstants.snapshotFileURL,
          FileManager.default.fileExists(atPath: url.path) else { return nil }
    do {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(WidgetWeatherSnapshot.self, from: data)
    } catch {
        print("Failed to load widget snapshot: \(error)")
        return nil
    }
}

// MARK: - Temperature Conversion Helper

func convertTemperature(_ fahrenheit: Double, to unit: String) -> Int {
    if unit == "Celsius" {
        return Int(((fahrenheit - 32) * 5.0 / 9.0).rounded())
    }
    return Int(fahrenheit.rounded())
}
