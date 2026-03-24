import SwiftUI
import WidgetKit

struct SmallWeatherWidgetView: View {
    let entry: WeatherTimelineEntry

    private var snapshot: WidgetWeatherSnapshot {
        entry.snapshot ?? .placeholder
    }

    private var temp: Int {
        convertTemperature(snapshot.currentTemp, to: entry.temperatureUnit)
    }

    private var highTemp: Int {
        convertTemperature(snapshot.tempMax, to: entry.temperatureUnit)
    }

    private var lowTemp: Int {
        convertTemperature(snapshot.tempMin, to: entry.temperatureUnit)
    }

    private var unitSymbol: String {
        entry.temperatureUnit == "Celsius" ? "°C" : "°F"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(snapshot.cityName)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .lineLimit(1)

            Spacer()

            Image(systemName: WeatherIconMapper.sfSymbol(for: snapshot.conditionId, icon: snapshot.conditionIcon))
                .symbolRenderingMode(.multicolor)
                .font(.system(size: 36))

            Spacer()

            Text("\(temp)\(unitSymbol)")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("H: \(highTemp)\u{00B0}  L: \(lowTemp)\u{00B0}")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(for: .widget) {
            weatherGradient(for: snapshot.conditionId, icon: snapshot.conditionIcon)
        }
    }
}
