import SwiftUI
import WidgetKit

struct WeatherWidget: Widget {
    let kind: String = "WeatherWiseWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WeatherTimelineProvider()) { entry in
            WeatherWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Weather Wise")
        .description("View current weather conditions at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct WeatherWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: WeatherTimelineEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWeatherWidgetView(entry: entry)
        case .systemMedium:
            MediumWeatherWidgetView(entry: entry)
        case .systemLarge:
            LargeWeatherWidgetView(entry: entry)
        default:
            SmallWeatherWidgetView(entry: entry)
        }
    }
}
