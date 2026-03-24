import Foundation

enum SharedConstants {
    static let appGroupID = "group.com.weatherwise.app"
    static let apiKey = "39029bf0c1f9bc244377f3e8c16de220"

    // UserDefaults keys
    static let defaultLocationLatKey = "defaultLocationLat"
    static let defaultLocationLonKey = "defaultLocationLon"
    static let defaultLocationNameKey = "defaultLocationName"
    static let temperatureUnitKey = "temperatureUnit"
    static let widgetSnapshotKey = "widgetWeatherSnapshot"

    /// Shared UserDefaults suite for App Group
    static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    /// Shared container URL for App Group
    static var sharedContainerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
    }

    /// File URL for the cached weather snapshot
    static var snapshotFileURL: URL? {
        sharedContainerURL?.appendingPathComponent("widget_weather_snapshot.json")
    }
}
