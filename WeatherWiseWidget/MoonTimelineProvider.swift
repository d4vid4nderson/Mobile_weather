import WidgetKit

struct MoonTimelineProvider: TimelineProvider {
    typealias Entry = MoonTimelineEntry

    func placeholder(in context: Context) -> MoonTimelineEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (MoonTimelineEntry) -> Void) {
        let entry = MoonTimelineEntry(
            date: Date(),
            moonPhase: WidgetMoonCalculator.currentPhase()
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MoonTimelineEntry>) -> Void) {
        let now = Date()
        let moonPhase = WidgetMoonCalculator.currentPhase(date: now)

        let entry = MoonTimelineEntry(
            date: now,
            moonPhase: moonPhase
        )

        // Moon phase changes slowly — refresh every 6 hours
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 6, to: now) ?? now
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}
