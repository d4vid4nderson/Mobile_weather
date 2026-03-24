import WidgetKit

struct WeatherTimelineProvider: TimelineProvider {
    typealias Entry = WeatherTimelineEntry

    func placeholder(in context: Context) -> WeatherTimelineEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (WeatherTimelineEntry) -> Void) {
        let cached = loadWidgetSnapshot()
        let unit = SharedConstants.sharedDefaults?.string(forKey: SharedConstants.temperatureUnitKey) ?? "Fahrenheit"
        let entry = WeatherTimelineEntry(
            date: Date(),
            snapshot: cached ?? .placeholder,
            temperatureUnit: unit
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WeatherTimelineEntry>) -> Void) {
        let defaults = SharedConstants.sharedDefaults
        let lat = defaults?.double(forKey: SharedConstants.defaultLocationLatKey) ?? 33.2343
        let lon = defaults?.double(forKey: SharedConstants.defaultLocationLonKey) ?? -97.5892
        let locationName = defaults?.string(forKey: SharedConstants.defaultLocationNameKey)
        let unit = defaults?.string(forKey: SharedConstants.temperatureUnitKey) ?? "Fahrenheit"

        Task {
            let snapshot: WidgetWeatherSnapshot
            do {
                let fetched = try await WidgetWeatherFetcher.fetchSnapshot(
                    lat: lat,
                    lon: lon,
                    cityName: locationName
                )
                saveWidgetSnapshot(fetched)
                snapshot = fetched
            } catch {
                // Fall back to cached data
                snapshot = loadWidgetSnapshot() ?? .placeholder
            }

            let entry = WeatherTimelineEntry(
                date: Date(),
                snapshot: snapshot,
                temperatureUnit: unit
            )

            // Refresh every 30 minutes
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
}
