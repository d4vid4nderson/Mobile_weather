import SwiftUI

struct WeatherDetailCard: View {
    let icon: String
    let title: String
    let value: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label {
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.onGradientSecondary)
            } icon: {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(Color.onGradientSecondary)
            }

            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(Color.onGradientPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Color.onGradientSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.onGradientCard, in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [.blue, .indigo],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            WeatherDetailCard(
                icon: "humidity.fill",
                title: "HUMIDITY",
                value: "72%"
            )
            WeatherDetailCard(
                icon: "wind",
                title: "WIND",
                value: "5.2 m/s",
                subtitle: "Northwest"
            )
            WeatherDetailCard(
                icon: "gauge.medium",
                title: "PRESSURE",
                value: "1013 hPa"
            )
            WeatherDetailCard(
                icon: "eye.fill",
                title: "VISIBILITY",
                value: "10.0 km"
            )
        }
        .padding()
    }
}
