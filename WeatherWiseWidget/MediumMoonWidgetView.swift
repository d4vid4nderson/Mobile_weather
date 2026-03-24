import SwiftUI
import WidgetKit

struct MediumMoonWidgetView: View {
    let entry: MoonTimelineEntry

    private var moon: WidgetMoonPhase {
        entry.moonPhase
    }

    var body: some View {
        HStack(spacing: 0) {
            // Left: current moon phase
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "moon.stars.fill")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.7))
                    Text("MOON PHASE")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer()

                Image(systemName: moon.icon)
                    .font(.system(size: 36))
                    .foregroundStyle(.white)
                    .shadow(color: .white.opacity(0.3), radius: 8)

                Text(moon.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                HStack(spacing: 8) {
                    Text("\(Int(moon.illumination * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.white.opacity(0.8))
                    Text(moon.isWaxing ? "Waxing" : "Waning")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Divider
            Rectangle()
                .fill(.white.opacity(0.2))
                .frame(width: 1)
                .padding(.vertical, 8)

            // Right: upcoming phases
            VStack(alignment: .leading, spacing: 8) {
                upcomingPhaseRow(.newMoon)
                upcomingPhaseRow(.firstQuarter)
                upcomingPhaseRow(.fullMoon)
                upcomingPhaseRow(.lastQuarter)
            }
            .frame(maxWidth: .infinity)
        }
        .containerBackground(for: .widget) {
            moonGradient
        }
    }

    private func upcomingPhaseRow(_ target: WidgetMoonCalculator.TargetPhase) -> some View {
        HStack(spacing: 6) {
            Image(systemName: target.icon)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 16)
            VStack(alignment: .leading, spacing: 0) {
                Text(target.name)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))
                Text(WidgetMoonCalculator.nextPhaseDateString(target: target, from: entry.date))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
            }
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
