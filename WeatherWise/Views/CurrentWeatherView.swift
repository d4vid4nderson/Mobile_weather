import SwiftUI

struct CurrentWeatherView: View {
    @EnvironmentObject var viewModel: WeatherViewModel

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
                .foregroundStyle(.white)

            if !viewModel.countryCode.isEmpty {
                HStack(spacing: 4) {
                    Text(viewModel.countryCode)
                    if viewModel.cityName.lowercased().contains("decatur") ||
                       viewModel.cityName.lowercased().contains("wise") {
                        Text("- Wise County")
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
            }
        }
    }

    // MARK: - Temperature

    private var temperatureSection: some View {
        Text(viewModel.temperatureString)
            .font(.system(size: 96, weight: .thin, design: .rounded))
            .foregroundStyle(.white)
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
        .foregroundStyle(.white)
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
                .foregroundStyle(.white.opacity(0.7))
        }
        .foregroundStyle(.white)
    }

    // MARK: - Details Grid

    private var detailsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            WeatherDetailCard(
                icon: "humidity.fill",
                title: "HUMIDITY",
                value: viewModel.humidityString
            )

            WeatherDetailCard(
                icon: "wind",
                title: "WIND",
                value: viewModel.windSpeedString
            )

            WeatherDetailCard(
                icon: "gauge.medium",
                title: "PRESSURE",
                value: viewModel.pressureString
            )

            WeatherDetailCard(
                icon: "eye.fill",
                title: "VISIBILITY",
                value: viewModel.visibilityString
            )

            WeatherDetailCard(
                icon: "sunrise.fill",
                title: "SUNRISE",
                value: viewModel.sunriseString
            )

            WeatherDetailCard(
                icon: "sunset.fill",
                title: "SUNSET",
                value: viewModel.sunsetString
            )
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
