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
                        .strokeBorder(Color.onGradientCardBorder, lineWidth: 1)
                )
        }
    }

    // MARK: - Hourly Forecast

    private var hourlySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("HOURLY FORECAST", systemImage: "clock")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.onGradientSecondary)

                Spacer()

                // Legend
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Circle().fill(Color.onGradientPrimary).frame(width: 6, height: 6)
                        Text("Forecast")
                            .font(.system(size: 9))
                            .foregroundStyle(Color.onGradientSecondary)
                    }
                    HStack(spacing: 4) {
                        Circle().fill(Color.accentActual).frame(width: 6, height: 6)
                        Text("Actual")
                            .font(.system(size: 9))
                            .foregroundStyle(Color.onGradientSecondary)
                    }
                }
            }
            .padding(.horizontal, 20)

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(viewModel.fullHourlyTimeline) { item in
                            hourlyTimelineItem(item)
                                .id(item.id)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .onAppear {
                    // Scroll to "Now" on appear
                    if let nowItem = viewModel.fullHourlyTimeline.first(where: { $0.isNow }) {
                        proxy.scrollTo(nowItem.id, anchor: .center)
                    }
                }
            }
        }
        .padding(.vertical, 16)
        .background(Color.onGradientCard)
    }

    private func hourlyTimelineItem(_ item: HourlyDisplayItem) -> some View {
        let timezone = viewModel.forecast?.city.timezone ?? 0

        return VStack(spacing: 6) {
            // Time label
            if item.isNow {
                Text("Now")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.accentNow)
            } else {
                Text(item.timestamp.asDate.formattedHour(timezoneOffset: timezone))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(item.isPast ? Color.onGradientSecondary.opacity(0.6) : Color.onGradientSecondary)
            }

            // Weather icon
            Image(systemName: item.icon)
                .font(.title3)
                .symbolRenderingMode(.multicolor)
                .frame(height: 26)
                .opacity(item.isPast ? 0.6 : 1.0)

            // Forecast temp
            Text("\(Int(viewModel.convertTemp(item.forecastTemp).rounded()))°")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(item.isNow ? Color.accentNow : Color.onGradientPrimary)

            // Actual temp (shown for past items and now)
            if let actual = item.actualTemp {
                let diff = viewModel.convertTemp(actual) - viewModel.convertTemp(item.forecastTemp)
                let diffRounded = Int(diff.rounded())
                VStack(spacing: 2) {
                    Text("\(Int(viewModel.convertTemp(actual).rounded()))°")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.accentActual)

                    if !item.isNow && diffRounded != 0 {
                        Text(diffRounded > 0 ? "+\(diffRounded)°" : "\(diffRounded)°")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(diffRounded > 0 ? Color.accentNow : Color.accentRain)
                    }
                }
            } else {
                // Placeholder to keep alignment
                VStack(spacing: 2) {
                    Text(" ")
                        .font(.caption2)
                    Text(" ")
                        .font(.system(size: 9))
                }
                .hidden()
            }

            // Rain probability
            if let pop = item.pop, pop > 0.1 {
                HStack(spacing: 2) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 7))
                    Text("\(Int(pop * 100))%")
                        .font(.system(size: 9))
                }
                .foregroundStyle(Color.accentRain)
            }
        }
        .frame(width: 56)
        .padding(.vertical, 4)
        .background {
            if item.isNow {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.1))
            }
        }
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
                        .strokeBorder(Color.onGradientCardBorder, lineWidth: 1)
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
                .foregroundStyle(Color.accentRain)
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
