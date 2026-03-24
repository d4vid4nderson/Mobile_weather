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
        VStack(alignment: .leading, spacing: 0) {
            // Top row: condition icon + city name, right-aligned
            HStack(spacing: 4) {
                Spacer()
                Image(systemName: WeatherIconMapper.sfSymbol(for: snapshot.conditionId, icon: snapshot.conditionIcon))
                    .symbolRenderingMode(.multicolor)
                    .font(.system(size: 16))
                Text(snapshot.cityName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.trailing)
            }

            Spacer()

            // Large temperature, left-aligned
            Text("\(temp)")
                .font(.system(size: 64, weight: .heavy))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.6)

            // Hi/Lo at the bottom
            Text("H: \(highTemp)\u{00B0}  L: \(lowTemp)\u{00B0}")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(for: .widget) {
            weatherGradient(for: snapshot.conditionId, icon: snapshot.conditionIcon)
        }
    }
}
