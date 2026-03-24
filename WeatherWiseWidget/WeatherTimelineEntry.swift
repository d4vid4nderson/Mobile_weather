import WidgetKit

struct WeatherTimelineEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetWeatherSnapshot?
    let temperatureUnit: String // "Fahrenheit" or "Celsius"

    static var placeholder: WeatherTimelineEntry {
        WeatherTimelineEntry(
            date: Date(),
            snapshot: .placeholder,
            temperatureUnit: "Fahrenheit"
        )
    }
}
