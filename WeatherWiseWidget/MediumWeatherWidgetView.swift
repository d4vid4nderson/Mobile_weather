import SwiftUI
import WidgetKit

struct MediumWeatherWidgetView: View {
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
        HStack(spacing: 0) {
            // Left: current conditions (matching small widget layout)
            VStack(alignment: .leading, spacing: 0) {
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

                Text("\(temp)")
                    .font(.system(size: 64, weight: .heavy))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.6)

                Text("H: \(highTemp)\u{00B0}  L: \(lowTemp)\u{00B0}")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Divider
            Rectangle()
                .fill(.white.opacity(0.3))
                .frame(width: 1)
                .padding(.vertical, 8)

            // Right: next 4 hours
            VStack(spacing: 6) {
                ForEach(snapshot.hourlyForecast.prefix(4)) { hour in
                    HStack(spacing: 8) {
                        Text(Date(timeIntervalSince1970: TimeInterval(hour.dt))
                            .formattedHour(timezoneOffset: snapshot.timezone))
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.8))
                            .frame(width: 40, alignment: .leading)

                        Image(systemName: WeatherIconMapper.sfSymbol(for: hour.conditionId, icon: hour.conditionIcon))
                            .symbolRenderingMode(.multicolor)
                            .font(.caption)

                        Text("\(convertTemperature(hour.temp, to: entry.temperatureUnit))\u{00B0}")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .containerBackground(for: .widget) {
            weatherGradient(for: snapshot.conditionId, icon: snapshot.conditionIcon)
        }
    }
}
