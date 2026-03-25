import SwiftUI

/// A compact bar/line graph showing forecast data for the selected radar layer.
/// Displays the next 24 hours of data (up to 8 three-hour forecast points).
struct RadarDataGraphView: View {
    let forecastItems: [ForecastItem]
    let selectedLayer: WeatherLayer
    let timezoneOffset: Int
    let convertTemp: (Double) -> Double

    private var dataPoints: [(label: String, value: Double, rawValue: String)] {
        let now = Date().timeIntervalSince1970
        let items = Array(forecastItems.filter { Double($0.dt) > now }.prefix(8))

        return items.map { item in
            let hour = item.dt.asDate.formattedHour(timezoneOffset: timezoneOffset)
            let (value, raw) = extractValue(from: item)
            return (label: hour, value: value, rawValue: raw)
        }
    }

    /// Extract the relevant metric for the selected layer
    private func extractValue(from item: ForecastItem) -> (Double, String) {
        switch selectedLayer {
        case .wind:
            let speed = item.wind.speed
            return (speed, String(format: "%.0f", speed))
        case .precipitation:
            let pop = (item.pop ?? 0) * 100
            return (pop, String(format: "%.0f%%", pop))
        case .temperature:
            let temp = convertTemp(item.main.temp)
            return (temp, String(format: "%.0f°", temp))
        case .humidity:
            let hum = Double(item.main.humidity)
            return (hum, "\(item.main.humidity)%")
        case .pressure:
            let pressure = Double(item.main.pressure)
            return (pressure, "\(item.main.pressure)")
        case .clouds:
            let clouds = Double(item.clouds?.all ?? 0)
            return (clouds, "\(item.clouds?.all ?? 0)%")
        }
    }

    /// Unit label for the selected layer
    private var unitLabel: String {
        switch selectedLayer {
        case .wind: return "mph"
        case .precipitation: return "%"
        case .temperature: return "°"
        case .humidity: return "%"
        case .pressure: return "hPa"
        case .clouds: return "%"
        }
    }

    /// Color for bars based on layer
    private var barColor: Color {
        switch selectedLayer {
        case .wind: return .green
        case .precipitation: return .blue
        case .temperature: return .orange
        case .humidity: return .cyan
        case .pressure: return .purple
        case .clouds: return .gray
        }
    }

    var body: some View {
        let points = dataPoints
        guard !points.isEmpty else {
            return AnyView(EmptyView())
        }

        let values = points.map(\.value)
        let maxVal = values.max() ?? 1
        let minVal = values.min() ?? 0
        let range = max(maxVal - minVal, 1)
        // Add padding so bars don't fill to zero when all values are similar
        let graphMin = selectedLayer == .precipitation || selectedLayer == .clouds || selectedLayer == .humidity
            ? 0.0
            : minVal - range * 0.1
        let graphMax = maxVal + range * 0.15

        return AnyView(
            VStack(alignment: .leading, spacing: 6) {
                // Title
                HStack(spacing: 6) {
                    Image(systemName: selectedLayer.icon)
                        .font(.system(size: 11, weight: .semibold))
                    Text("24h \(selectedLayer.displayName) Forecast")
                        .font(.system(size: 12, weight: .semibold))
                    Spacer()
                    // Current value indicator
                    if let first = points.first {
                        Text(first.rawValue)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(barColor)
                    }
                }
                .foregroundColor(.white)

                // Bar chart
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(Array(points.enumerated()), id: \.offset) { index, point in
                        VStack(spacing: 2) {
                            // Value label on top of bar
                            Text(point.rawValue)
                                .font(.system(size: 8, weight: .medium, design: .monospaced))
                                .foregroundColor(.white.opacity(0.7))
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)

                            // Bar
                            let normalized = graphMax > graphMin
                                ? CGFloat((point.value - graphMin) / (graphMax - graphMin))
                                : 0.5
                            let barHeight = max(normalized * 60, 4)

                            RoundedRectangle(cornerRadius: 3)
                                .fill(
                                    LinearGradient(
                                        colors: [barColor.opacity(0.8), barColor.opacity(0.4)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(height: barHeight)

                            // Time label
                            Text(point.label)
                                .font(.system(size: 8, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(.ultraThinMaterial)
            )
        )
    }
}
