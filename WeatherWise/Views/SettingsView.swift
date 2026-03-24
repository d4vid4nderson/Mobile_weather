import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var viewModel: WeatherViewModel
    @State private var showDefaultLocationSearch = false
    @State private var defaultLocationSearchText = ""
    @State private var showSetDefaultConfirmation = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                Text("Settings")
                    .font(.system(size: 28, weight: .medium, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.top, 70)
                    .padding(.bottom, 24)

                VStack(spacing: 16) {
                    locationSection
                    appearanceSection
                    dataSection
                    aboutSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .alert("Set Default Location", isPresented: $showSetDefaultConfirmation) {
            Button("Set to \(viewModel.cityName)", role: nil) {
                viewModel.setCurrentLocationAsDefault()
            }
            Button("Reset to Wise County", role: nil) {
                viewModel.setDefaultLocation(
                    name: "Wise County, TX",
                    lat: WeatherViewModel.wiseCountyLat,
                    lon: WeatherViewModel.wiseCountyLon
                )
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Choose a default location for when GPS is unavailable.")
        }
    }

    // MARK: - Location Section

    private var locationSection: some View {
        settingsSection(title: "LOCATION") {
            // Current Location
            Button {
                viewModel.fetchWeather()
            } label: {
                HStack {
                    Image(systemName: "location.fill")
                        .font(.body)
                        .foregroundStyle(.blue)
                        .frame(width: 28)
                    Text("Current Location")
                        .font(.body)
                        .foregroundStyle(.white)
                    Spacer()
                    Text(viewModel.cityName.isEmpty ? "Tap to detect" : viewModel.cityName)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.5))
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.3))
                }
                .padding(.vertical, 4)
            }

            Divider().overlay(Color.white.opacity(0.15))

            // Default Location
            Button {
                showSetDefaultConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .font(.body)
                        .foregroundStyle(.orange)
                        .frame(width: 28)
                    Text("Default Location")
                        .font(.body)
                        .foregroundStyle(.white)
                    Spacer()
                    Text(viewModel.defaultLocationName)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.5))
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.3))
                }
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Appearance Section

    private var appearanceSection: some View {
        settingsSection(title: "APPEARANCE") {
            HStack {
                Image(systemName: "circle.lefthalf.filled")
                    .font(.body)
                    .foregroundStyle(.purple)
                    .frame(width: 28)
                Text("Theme")
                    .font(.body)
                    .foregroundStyle(.white)
                Spacer()
            }
            .padding(.vertical, 4)

            Picker("", selection: $viewModel.appearance) {
                ForEach(AppAppearance.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.top, 4)
            .padding(.bottom, 4)
        }
    }

    // MARK: - Data Section

    private var dataSection: some View {
        settingsSection(title: "DATA") {
            // Temperature Unit
            HStack {
                Image(systemName: "thermometer.medium")
                    .font(.body)
                    .foregroundStyle(.red)
                    .frame(width: 28)
                Text("Temperature")
                    .font(.body)
                    .foregroundStyle(.white)
                Spacer()
                Menu {
                    ForEach(TemperatureUnit.allCases, id: \.self) { unit in
                        Button {
                            viewModel.temperatureUnit = unit
                        } label: {
                            HStack {
                                Text(unit.rawValue)
                                if viewModel.temperatureUnit == unit {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(viewModel.temperatureUnit.rawValue)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.5))
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                }
            }
            .padding(.vertical, 4)

            Divider().overlay(Color.white.opacity(0.15))

            // Wind Speed Unit
            HStack {
                Image(systemName: "wind")
                    .font(.body)
                    .foregroundStyle(.cyan)
                    .frame(width: 28)
                Text("Wind Speed")
                    .font(.body)
                    .foregroundStyle(.white)
                Spacer()
                Menu {
                    ForEach(WindSpeedUnit.allCases, id: \.self) { unit in
                        Button {
                            viewModel.windSpeedUnit = unit
                        } label: {
                            HStack {
                                Text(unit.rawValue)
                                if viewModel.windSpeedUnit == unit {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(viewModel.windSpeedUnit.rawValue)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.5))
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                }
            }
            .padding(.vertical, 4)

            Divider().overlay(Color.white.opacity(0.15))

            // Auto Refresh
            HStack {
                Image(systemName: "arrow.clockwise")
                    .font(.body)
                    .foregroundStyle(.green)
                    .frame(width: 28)
                Text("Auto Refresh")
                    .font(.body)
                    .foregroundStyle(.white)
                Spacer()
                Menu {
                    ForEach(AutoRefresh.allCases, id: \.self) { option in
                        Button {
                            viewModel.autoRefresh = option
                        } label: {
                            HStack {
                                Text(option.rawValue)
                                if viewModel.autoRefresh == option {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(viewModel.autoRefresh.rawValue)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.5))
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        settingsSection(title: "ABOUT") {
            settingsInfoRow(icon: "info.circle.fill", iconColor: .gray, title: "Version", subtitle: "1.0.0")
            Divider().overlay(Color.white.opacity(0.15))
            settingsInfoRow(icon: "cloud.fill", iconColor: .blue, title: "Weather Data", subtitle: "OpenWeatherMap")
            Divider().overlay(Color.white.opacity(0.15))
            settingsInfoRow(icon: "exclamationmark.triangle.fill", iconColor: .orange, title: "Alerts Data", subtitle: "National Weather Service")
        }
    }

    // MARK: - Helpers

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

    private func settingsInfoRow(icon: String, iconColor: Color, title: String, subtitle: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(iconColor)
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
