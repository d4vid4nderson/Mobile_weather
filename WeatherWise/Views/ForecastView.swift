import SwiftUI

struct ForecastView: View {
    @EnvironmentObject var viewModel: WeatherViewModel

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 60)

            Text(viewModel.cityName)
                .font(.system(size: 28, weight: .medium, design: .rounded))
                .foregroundStyle(.white)
                .padding(.bottom, 4)

            Text("Forecast")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .padding(.bottom, 24)

            hourlySection
                .padding(.bottom, 24)

            dailySection
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
        }
        .padding(.top, 20)
    }

    // MARK: - Hourly Forecast

    private var hourlySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("HOURLY FORECAST", systemImage: "clock")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.white.opacity(0.6))
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.hourlyForecast) { item in
                        hourlyItemView(item)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 16)
        .background(.ultraThinMaterial.opacity(0.5))
    }

    private func hourlyItemView(_ item: ForecastItem) -> some View {
        let timezone = viewModel.forecast?.city.timezone ?? 0
        let icon = item.weather.first.map {
            WeatherIconMapper.sfSymbol(for: $0.id, icon: $0.icon)
        } ?? "sun.max.fill"

        return VStack(spacing: 10) {
            Text(item.dt.asDate.formattedHour(timezoneOffset: timezone))
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.white.opacity(0.7))

            Image(systemName: icon)
                .font(.title2)
                .symbolRenderingMode(.multicolor)
                .frame(height: 30)

            Text("\(Int(item.main.temp.rounded()))°")
                .font(.headline)
                .foregroundStyle(.white)

            if let pop = item.pop, pop > 0.1 {
                HStack(spacing: 2) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 8))
                    Text("\(Int(pop * 100))%")
                        .font(.caption2)
                }
                .foregroundStyle(.cyan)
            }
        }
        .frame(width: 60)
    }

    // MARK: - Daily Forecast

    private var dailySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("5-DAY FORECAST", systemImage: "calendar")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.white.opacity(0.6))

            VStack(spacing: 0) {
                ForEach(Array(viewModel.dailyForecast.enumerated()), id: \.element.id) { index, day in
                    dailyRow(day)

                    if index < viewModel.dailyForecast.count - 1 {
                        Divider()
                            .overlay(Color.white.opacity(0.15))
                    }
                }
            }
            .padding(16)
            .background(.ultraThinMaterial.opacity(0.5), in: RoundedRectangle(cornerRadius: 16))
        }
    }

    private func dailyRow(_ day: DailyForecast) -> some View {
        let timezone = viewModel.forecast?.city.timezone ?? 0
        let icon = WeatherIconMapper.sfSymbol(for: day.conditionId, icon: day.conditionIcon)

        return HStack {
            Text(day.date.formattedShortDay(timezoneOffset: timezone))
                .font(.body)
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .frame(width: 50, alignment: .leading)

            if day.pop > 0.1 {
                HStack(spacing: 2) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 10))
                    Text("\(Int(day.pop * 100))%")
                        .font(.caption)
                }
                .foregroundStyle(.cyan)
                .frame(width: 50)
            } else {
                Spacer()
                    .frame(width: 50)
            }

            Spacer()

            Image(systemName: icon)
                .font(.title3)
                .symbolRenderingMode(.multicolor)
                .frame(width: 35)

            Spacer()

            HStack(spacing: 8) {
                Text("\(Int(day.lowTemp.rounded()))°")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(width: 35, alignment: .trailing)

                temperatureBar(low: day.lowTemp, high: day.highTemp)
                    .frame(width: 60, height: 4)

                Text("\(Int(day.highTemp.rounded()))°")
                    .font(.body)
                    .foregroundStyle(.white)
                    .frame(width: 35, alignment: .leading)
            }
        }
        .padding(.vertical, 10)
    }

    private func temperatureBar(low: Double, high: Double) -> some View {
        let allLows = viewModel.dailyForecast.map(\.lowTemp)
        let allHighs = viewModel.dailyForecast.map(\.highTemp)
        let minTemp = allLows.min() ?? low
        let maxTemp = allHighs.max() ?? high
        let range = maxTemp - minTemp
        let normalizedLow = range > 0 ? (low - minTemp) / range : 0
        let normalizedHigh = range > 0 ? (high - minTemp) / range : 1

        return GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.15))

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.cyan, .yellow, .orange],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * (normalizedHigh - normalizedLow))
                    .offset(x: geometry.size.width * normalizedLow)
            }
        }
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

        ScrollView {
            ForecastView()
                .environmentObject(WeatherViewModel())
        }
    }
}
