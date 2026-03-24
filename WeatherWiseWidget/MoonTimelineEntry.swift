import WidgetKit

struct MoonTimelineEntry: TimelineEntry {
    let date: Date
    let moonPhase: WidgetMoonPhase

    static var placeholder: MoonTimelineEntry {
        MoonTimelineEntry(
            date: Date(),
            moonPhase: WidgetMoonCalculator.currentPhase()
        )
    }
}
