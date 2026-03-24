import SwiftUI
import WidgetKit

struct LargeWeatherWidgetView: View {
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

    /// Compute the overall temp range across all daily forecasts for the gradient bar
    private var overallLow: Double {
        let temps = snapshot.dailyForecast.map(\.lowTemp)
        return temps.min() ?? snapshot.tempMin
    }

    private var overallHigh: Double {
        let temps = snapshot.dailyForecast.map(\.highTemp)
        return temps.max() ?? snapshot.tempMax
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: - Header: city + condition
            HStack(spacing: 4) {
                Image(systemName: WeatherIconMapper.sfSymbol(for: snapshot.conditionId, icon: snapshot.conditionIcon))
                    .symbolRenderingMode(.multicolor)
                    .font(.system(size: 16))
                Text(snapshot.cityName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
            .padding(.bottom, 2)

            // MARK: - Temperature + description
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(temp)\u{00B0}")
                    .font(.system(size: 48, weight: .heavy))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.7)

                VStack(alignment: .leading, spacing: 2) {
                    Text(snapshot.conditionDescription)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(1)
                    Text("H: \(highTemp)\u{00B0}  L: \(lowTemp)\u{00B0}")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .padding(.bottom, 2)

            // MARK: - Stats row
            HStack(spacing: 16) {
                Label {
                    Text("\(snapshot.humidity)%")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                } icon: {
                    Image(systemName: "humidity.fill")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }

                Label {
                    Text(String(format: "%.0f mph", snapshot.windSpeed))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                } icon: {
                    Image(systemName: "wind")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }

            // MARK: - Hourly forecast
            Divider().overlay(.white.opacity(0.3))
                .padding(.vertical, 6)

            HStack(spacing: 0) {
                ForEach(snapshot.hourlyForecast.prefix(4)) { hour in
                    VStack(spacing: 4) {
                        Text(Date(timeIntervalSince1970: TimeInterval(hour.dt))
                            .formattedHour(timezoneOffset: snapshot.timezone))
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.7))

                        Image(systemName: WeatherIconMapper.sfSymbol(for: hour.conditionId, icon: hour.conditionIcon))
                            .symbolRenderingMode(.multicolor)
                            .font(.caption)

                        Text("\(convertTemperature(hour.temp, to: entry.temperatureUnit))\u{00B0}")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            // MARK: - Daily forecast
            Divider().overlay(.white.opacity(0.3))
                .padding(.vertical, 6)

            VStack(spacing: 0) {
                ForEach(snapshot.dailyForecast.prefix(5)) { day in
                    HStack(spacing: 6) {
                        Text(day.dayName)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .frame(width: 36, alignment: .leading)

                        Image(systemName: WeatherIconMapper.sfSymbol(for: day.conditionId, icon: day.conditionIcon))
                            .symbolRenderingMode(.multicolor)
                            .font(.subheadline)
                            .frame(width: 24)

                        Text("\(convertTemperature(day.lowTemp, to: entry.temperatureUnit))\u{00B0}")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                            .frame(width: 32, alignment: .trailing)

                        // Gradient temperature bar
                        GeometryReader { geometry in
                            let range = overallHigh - overallLow
                            let barWidth = geometry.size.width
                            let leftOffset = range > 0 ? CGFloat((day.lowTemp - overallLow) / range) * barWidth : 0
                            let rightOffset = range > 0 ? CGFloat((overallHigh - day.highTemp) / range) * barWidth : 0

                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .green, .yellow, .orange],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(height: 5)
                                .padding(.leading, leftOffset)
                                .padding(.trailing, rightOffset)
                                .frame(maxHeight: .infinity, alignment: .center)
                        }
                        .frame(height: 18)

                        Text("\(convertTemperature(day.highTemp, to: entry.temperatureUnit))\u{00B0}")
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .frame(width: 32, alignment: .trailing)
                    }
                    .frame(maxHeight: .infinity)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(for: .widget) {
            weatherGradient(for: snapshot.conditionId, icon: snapshot.conditionIcon)
        }
    }
}
