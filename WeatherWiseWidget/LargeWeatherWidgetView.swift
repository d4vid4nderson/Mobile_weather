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
        VStack(spacing: 8) {
            // Top: current conditions (matching small widget layout)
            HStack(spacing: 4) {
                Image(systemName: WeatherIconMapper.sfSymbol(for: snapshot.conditionId, icon: snapshot.conditionIcon))
                    .symbolRenderingMode(.multicolor)
                    .font(.system(size: 20))
                Text(snapshot.cityName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .lineLimit(2)
            }

            Text("\(temp)")
                .font(.system(size: 64, weight: .heavy))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.6)

            Text("H: \(highTemp)\u{00B0}  L: \(lowTemp)\u{00B0}")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))

            Divider()
                .overlay(.white.opacity(0.3))

            // Bottom: 5-day forecast
            VStack(spacing: 6) {
                ForEach(snapshot.dailyForecast.prefix(5)) { day in
                    HStack(spacing: 8) {
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
                        .frame(height: 16)

                        Text("\(convertTemperature(day.highTemp, to: entry.temperatureUnit))\u{00B0}")
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .frame(width: 32, alignment: .trailing)
                    }
                }
            }
        }
        .containerBackground(for: .widget) {
            weatherGradient(for: snapshot.conditionId, icon: snapshot.conditionIcon)
        }
    }
}
