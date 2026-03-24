import SwiftUI
import WidgetKit

struct SmallMoonWidgetView: View {
    let entry: MoonTimelineEntry

    private var moon: WidgetMoonPhase {
        entry.moonPhase
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Header
            HStack(spacing: 4) {
                Image(systemName: "moon.stars.fill")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
                Text("MOON")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()

            // Moon icon
            Image(systemName: moon.icon)
                .font(.system(size: 40))
                .foregroundStyle(.white)
                .shadow(color: .white.opacity(0.3), radius: 8)

            Spacer()

            // Phase name
            Text(moon.name)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            // Illumination
            Text("\(Int(moon.illumination * 100))% illuminated")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(for: .widget) {
            moonGradient
        }
    }
}

private var moonGradient: LinearGradient {
    LinearGradient(
        colors: [
            Color(red: 0.08, green: 0.08, blue: 0.22),
            Color(red: 0.04, green: 0.04, blue: 0.12)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
