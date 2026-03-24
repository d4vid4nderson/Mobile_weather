import SwiftUI

struct ForecastView: View {
    @EnvironmentObject var viewModel: WeatherViewModel
    @State private var selectedDayRange: ForecastRange = .fiveDay

    enum ForecastRange: String, CaseIterable {
        case fiveDay = "5-Day"
        case tenDay = "10-Day"
    }

    var body: some View {
        VStack(spacing: 0) {
            hourlySection
                .padding(.bottom, 24)

            forecastHeader
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

            if selectedDayRange == .fiveDay {
                dailySection
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
            } else {
                comingSoonView
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Forecast Header with Dropdown

    private var forecastHeader: some View {
        HStack {
            Label("FORECAST", systemImage: "calendar")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.onGradientSecondary)

            Spacer()

            Menu {
                ForEach(ForecastRange.allCases, id: \.self) { range in
                    Button {
                        withAnimation {
                            selectedDayRange = range
                        }
                    } label: {
                        HStack {
                            Text(range.rawValue)
                            if range == selectedDayRange {
                                Image(systemName: "checkmark")
                            }
                            if range == .tenDay {
                                Text("Coming Soon")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(selectedDayRange.rawValue)
                        .font(.caption)
                        .fontWeight(.semibold)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundStyle(Color.onGradientPrimary.opacity(0.8))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial, in: Capsule())
            }
        }
    }

    // MARK: - Coming Soon View

    private var comingSoonView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 40))
                .foregroundStyle(Color.onGradientSecondary)

            Text("10-Day Forecast")
                .font(.headline)
                .foregroundStyle(Color.onGradientPrimary)

            Text("Coming Soon")
                .font(.title2.bold())
                .foregroundStyle(Color.onGradientPrimary.opacity(0.8))

            Text("A 10-day forecast requires a paid API.\nStay tuned for a future update!")
                .font(.subheadline)
                .foregroundStyle(Color.onGradientSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.onGradientCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                )
        }
    }

    // MARK: - Hourly Forecast

    private var hourlySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("HOURLY FORECAST", systemImage: "clock")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.onGradientSecondary)
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
        .background(Color.onGradientCard)
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
                .foregroundStyle(Color.onGradientSecondary)

            Image(systemName: icon)
                .font(.title2)
                .symbolRenderingMode(.multicolor)
                .frame(height: 30)

            Text("\(Int(viewModel.convertTemp(item.main.temp).rounded()))°")
                .font(.headline)
                .foregroundStyle(Color.onGradientPrimary)

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
        VStack(spacing: 0) {
            ForEach(Array(viewModel.dailyForecast.enumerated()), id: \.element.id) { index, day in
                dailyRow(day)

                if index < viewModel.dailyForecast.count - 1 {
                    Divider()
                }
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.onGradientCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                )
        }
    }

    private func dailyRow(_ day: DailyForecast) -> some View {
        let timezone = viewModel.forecast?.city.timezone ?? 0
        let icon = WeatherIconMapper.sfSymbol(for: day.conditionId, icon: day.conditionIcon)

        return HStack {
            Text(day.date.formattedShortDay(timezoneOffset: timezone))
                .font(.body)
                .fontWeight(.medium)
                .foregroundStyle(Color.onGradientPrimary)
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
                Text("\(Int(viewModel.convertTemp(day.lowTemp).rounded()))°")
                    .font(.body)
                    .foregroundStyle(Color.onGradientSecondary)
                    .frame(width: 35, alignment: .trailing)

                temperatureBar(low: day.lowTemp, high: day.highTemp)
                    .frame(width: 60, height: 4)

                Text("\(Int(viewModel.convertTemp(day.highTemp).rounded()))°")
                    .font(.body)
                    .foregroundStyle(Color.onGradientPrimary)
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
                    .fill(Color.onGradientPrimary.opacity(0.15))

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
