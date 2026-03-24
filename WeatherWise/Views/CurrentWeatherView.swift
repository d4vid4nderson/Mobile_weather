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
                .padding(.bottom, 32)

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
                        Text(viewModel.stateName)
                        if viewModel.cityName.lowercased().contains("decatur") ||
                           viewModel.cityName.lowercased().contains("wise") {
                            Text("- Wise County")
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

            Button { selectedDetail = .sunrise } label: {
                WeatherDetailCard(
                    icon: "sunrise.fill",
                    title: "SUNRISE",
                    value: viewModel.sunriseString
                )
            }
            .buttonStyle(.plain)

            Button { selectedDetail = .sunset } label: {
                WeatherDetailCard(
                    icon: "sunset.fill",
                    title: "SUNSET",
                    value: viewModel.sunsetString
                )
            }
            .buttonStyle(.plain)
        }
        .sheet(item: $selectedDetail) { detail in
            WeatherDetailSheet(detailType: detail)
                .environmentObject(viewModel)
                .presentationDetents([.medium, .large])
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
