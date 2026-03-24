import SwiftUI
import WidgetKit

struct MoonWidget: Widget {
    let kind: String = "MoonPhaseWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MoonTimelineProvider()) { entry in
            MoonWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Moon Phase")
        .description("Track the current lunar phase and upcoming moon events.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct MoonWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: MoonTimelineEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallMoonWidgetView(entry: entry)
        case .systemMedium:
            MediumMoonWidgetView(entry: entry)
        default:
            SmallMoonWidgetView(entry: entry)
        }
    }
}
