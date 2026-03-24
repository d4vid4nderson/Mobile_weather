import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var viewModel: WeatherViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                Text("Settings")
                    .font(.system(size: 28, weight: .medium, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.top, 70)
                    .padding(.bottom, 24)

                VStack(spacing: 16) {
                    // Location Section
                    settingsSection(title: "LOCATION") {
                        settingsRow(icon: "location.fill", title: "Current Location", subtitle: viewModel.cityName.isEmpty ? "Not set" : viewModel.cityName)
                        Divider().overlay(Color.white.opacity(0.15))
                        settingsRow(icon: "mappin.circle.fill", title: "Default Location", subtitle: "Wise County, TX")
                    }

                    // Data Section
                    settingsSection(title: "DATA") {
                        settingsRow(icon: "thermometer.medium", title: "Temperature Unit", subtitle: "Fahrenheit")
                        Divider().overlay(Color.white.opacity(0.15))
                        settingsRow(icon: "wind", title: "Wind Speed Unit", subtitle: "mph")
                        Divider().overlay(Color.white.opacity(0.15))
                        settingsRow(icon: "arrow.clockwise", title: "Auto Refresh", subtitle: "On Launch")
                    }

                    // About Section
                    settingsSection(title: "ABOUT") {
                        settingsRow(icon: "info.circle.fill", title: "Version", subtitle: "1.0.0")
                        Divider().overlay(Color.white.opacity(0.15))
                        settingsRow(icon: "cloud.fill", title: "Weather Data", subtitle: "OpenWeatherMap")
                        Divider().overlay(Color.white.opacity(0.15))
                        settingsRow(icon: "exclamationmark.triangle.fill", title: "Alerts Data", subtitle: "National Weather Service")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Settings Section

    private func settingsSection(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.white.opacity(0.6))

            VStack(spacing: 0) {
                content()
            }
            .padding(16)
            .background(.ultraThinMaterial.opacity(0.5), in: RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Settings Row

    private func settingsRow(icon: String, title: String, subtitle: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 28)

            Text(title)
                .font(.body)
                .foregroundStyle(.white)

            Spacer()

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(.vertical, 4)
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

        SettingsView()
            .environmentObject(WeatherViewModel())
    }
}
