import SwiftUI

struct CurrentWeatherView: View {
    @EnvironmentObject var viewModel: WeatherViewModel
    @State private var selectedDetail: WeatherDetailType?

    var body: some View {
        VStack(spacing: 0) {
            headerSection
                .padding(.top, 60)
                .padding(.bottom, 8)

            temperatureSection
                .padding(.bottom, 4)

            conditionSection
                .padding(.bottom, 24)

            tempRangeSection
                .padding(.bottom, 12)

            outlookSection
                .padding(.horizontal, 40)
                .padding(.bottom, 28)

            detailsGrid
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
        }
        .padding(.top, 20)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 4) {
            Text(viewModel.cityName)
                .font(.system(size: 34, weight: .medium, design: .rounded))
                .foregroundStyle(Color.onGradientPrimary)

            if !viewModel.stateName.isEmpty || !viewModel.countryCode.isEmpty {
                HStack(spacing: 4) {
                    if !viewModel.stateName.isEmpty {
                        if !viewModel.countyName.isEmpty {
                            Text("\(viewModel.stateName) - \(viewModel.countyName)")
                        } else {
                            Text(viewModel.stateName)
                        }
                    } else {
                        Text(viewModel.countryCode)
                    }
                }
                .font(.subheadline)
                .foregroundStyle(Color.onGradientSecondary)
            }
        }
    }

    // MARK: - Temperature

    private var temperatureSection: some View {
        Text(viewModel.temperatureString)
            .font(.system(size: 96, weight: .thin, design: .rounded))
            .foregroundStyle(Color.onGradientPrimary)
    }

    // MARK: - Condition

    private var conditionSection: some View {
        HStack(spacing: 8) {
            Image(systemName: viewModel.conditionIcon)
                .font(.title2)
                .symbolRenderingMode(.multicolor)
            Text(viewModel.conditionDescription)
                .font(.title3)
                .fontWeight(.medium)
        }
        .foregroundStyle(Color.onGradientPrimary)
    }

    // MARK: - Temp Range

    private var tempRangeSection: some View {
        HStack(spacing: 16) {
            Text(viewModel.highTempString)
                .font(.headline)
            Text(viewModel.lowTempString)
                .font(.headline)
            Text("Feels like \(viewModel.feelsLikeString)")
                .font(.subheadline)
                .foregroundStyle(Color.onGradientSecondary)
        }
        .foregroundStyle(Color.onGradientPrimary)
    }

    // MARK: - Outlook

    @ViewBuilder
    private var outlookSection: some View {
        if let outlook = viewModel.hourlyOutlook {
            Text(outlook)
                .font(.subheadline)
                .foregroundStyle(Color.onGradientSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Details Grid

    private var detailsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            Button { selectedDetail = .humidity } label: {
                WeatherDetailCard(
                    icon: "humidity.fill",
                    title: "HUMIDITY",
                    value: viewModel.humidityString
                )
            }
            .buttonStyle(.plain)

            Button { selectedDetail = .wind } label: {
                WeatherDetailCard(
                    icon: "wind",
                    title: "WIND",
                    value: viewModel.windSpeedString
                )
            }
            .buttonStyle(.plain)

            Button { selectedDetail = .pressure } label: {
                WeatherDetailCard(
                    icon: "gauge.medium",
                    title: "PRESSURE",
                    value: viewModel.pressureString
                )
            }
            .buttonStyle(.plain)

            Button { selectedDetail = .visibility } label: {
                WeatherDetailCard(
                    icon: "eye.fill",
                    title: "VISIBILITY",
                    value: viewModel.visibilityString
                )
            }
            .buttonStyle(.plain)

            Button { selectedDetail = .sun } label: {
                VStack(alignment: .leading, spacing: 0) {
                    Label {
                        Text("SUNRISE / SUNSET")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.onGradientSecondary)
                    } icon: {
                        Image(systemName: "sun.max.fill")
                            .font(.caption)
                            .foregroundStyle(Color.onGradientSecondary)
                    }

                    Spacer()

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "sunrise.fill")
                                .font(.caption2)
                                .foregroundStyle(.yellow.opacity(0.8))
                            Text(viewModel.sunriseString)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.onGradientPrimary)
                        }
                        HStack(spacing: 4) {
                            Image(systemName: "sunset.fill")
                                .font(.caption2)
                                .foregroundStyle(.orange.opacity(0.8))
                            Text(viewModel.sunsetString)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.onGradientPrimary)
                        }
                    }

                    Spacer()

                    Text(viewModel.daylightDurationString)
                        .font(.caption)
                        .foregroundStyle(Color.onGradientSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
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
            .buttonStyle(.plain)

            Button { selectedDetail = .moonPhase } label: {
                let currentMoon = MoonPhaseCalculator.currentPhase()
                ZStack(alignment: .bottomTrailing) {
                    // Card background
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.onGradientCard)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(Color.onGradientCardBorder, lineWidth: 1)
                        )

                    // Moon image tucked into bottom-trailing corner
                    MoonPhaseView(phase: currentMoon)
                        .frame(width: 64, height: 64)
                        .opacity(0.3)
                        .padding(8)

                    // Text content
                    VStack(alignment: .leading, spacing: 0) {
                        Label {
                            Text("MOON PHASE")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.onGradientSecondary)
                        } icon: {
                            Image(systemName: currentMoon.icon)
                                .font(.caption)
                                .foregroundStyle(Color.onGradientSecondary)
                        }

                        Spacer()

                        Text(currentMoon.name)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.onGradientPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)

                        Spacer()

                        Text("\(Int(currentMoon.illumination * 100))% illuminated")
                            .font(.caption)
                            .foregroundStyle(Color.onGradientSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .padding(16)
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .buttonStyle(.plain)
        }
        .sheet(item: $selectedDetail) { detail in
            WeatherDetailSheet(detailType: detail)
                .environmentObject(viewModel)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
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
            CurrentWeatherView()
                .environmentObject(WeatherViewModel())
        }
    }
}
