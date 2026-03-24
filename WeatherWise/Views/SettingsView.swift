import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var viewModel: WeatherViewModel
    @State private var showDefaultLocationPicker = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                Text("Settings")
                    .font(.system(size: 28, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.appPrimary)
                    .padding(.top, 70)
                    .padding(.bottom, 28)

                VStack(spacing: 28) {
                    locationSection
                    appearanceSection
                    dataSection
                    aboutSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showDefaultLocationPicker) {
            DefaultLocationPicker()
                .environmentObject(viewModel)
        }
    }

    // MARK: - Location Section

    private var locationSection: some View {
        SettingsGroup(title: "LOCATION") {
            Button {
                viewModel.fetchWeather()
            } label: {
                SettingsRow(
                    icon: "location.fill",
                    iconBackground: .blue,
                    title: "Current Location",
                    value: viewModel.cityName.isEmpty ? "Tap to detect" : viewModel.cityName,
                    accessory: .reload
                )
            }

            SettingsDivider()

            Button {
                showDefaultLocationPicker = true
            } label: {
                SettingsRow(
                    icon: "mappin.circle.fill",
                    iconBackground: .orange,
                    title: "Default Location",
                    value: viewModel.defaultLocationName,
                    accessory: .chevron
                )
            }
        }
    }

    // MARK: - Appearance Section

    private var appearanceSection: some View {
        SettingsGroup(title: "APPEARANCE") {
            VStack(spacing: 12) {
                HStack {
                    SettingsIconBadge(icon: "circle.lefthalf.filled", color: .purple)
                    Text("Theme")
                        .font(.body)
                        .foregroundStyle(Color.appPrimary)
                    Spacer()
                }

                Picker("", selection: $viewModel.appearance) {
                    ForEach(AppAppearance.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(.vertical, 2)
        }
    }

    // MARK: - Data Section

    private var dataSection: some View {
        SettingsGroup(title: "DATA") {
            SettingsMenuRow(
                icon: "thermometer.medium",
                iconBackground: .red,
                title: "Temperature",
                selection: $viewModel.temperatureUnit,
                options: TemperatureUnit.allCases
            )

            SettingsDivider()

            SettingsMenuRow(
                icon: "wind",
                iconBackground: .cyan,
                title: "Wind Speed",
                selection: $viewModel.windSpeedUnit,
                options: WindSpeedUnit.allCases
            )

            SettingsDivider()

            SettingsMenuRow(
                icon: "arrow.clockwise",
                iconBackground: .green,
                title: "Auto Refresh",
                selection: $viewModel.autoRefresh,
                options: AutoRefresh.allCases
            )
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        SettingsGroup(title: "ABOUT") {
            SettingsRow(icon: "info.circle.fill", iconBackground: .gray, title: "Version", value: "1.0.0")

            SettingsDivider()

            SettingsRow(icon: "cloud.fill", iconBackground: .blue, title: "Weather Data", value: "OpenWeatherMap")

            SettingsDivider()

            SettingsRow(icon: "exclamationmark.triangle.fill", iconBackground: .orange, title: "Alerts Data", value: "NWS")
        }
    }
}

// MARK: - Reusable iOS-style Settings Components

private struct SettingsGroup<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.footnote)
                .foregroundStyle(Color.appSecondary)
                .padding(.leading, 16)

            VStack(spacing: 0) {
                content
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.appCardBackground)
            )
        }
    }
}

private struct SettingsDivider: View {
    var body: some View {
        Divider()
            .padding(.leading, 42)
    }
}

private struct SettingsIconBadge: View {
    let icon: String
    let color: Color

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 28, height: 28)
            .background(color, in: RoundedRectangle(cornerRadius: 6))
    }
}

private enum RowAccessory {
    case none
    case chevron
    case reload
}

private struct SettingsRow: View {
    let icon: String
    let iconBackground: Color
    let title: String
    var value: String = ""
    var accessory: RowAccessory = .none

    var body: some View {
        HStack(spacing: 12) {
            SettingsIconBadge(icon: icon, color: iconBackground)

            Text(title)
                .font(.body)
                .foregroundStyle(Color.appPrimary)

            Spacer()

            if !value.isEmpty {
                Text(value)
                    .font(.body)
                    .foregroundStyle(Color.appSecondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            switch accessory {
            case .chevron:
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.appTertiary)
            case .reload:
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.appTertiary)
            case .none:
                EmptyView()
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

private struct SettingsMenuRow<T: Hashable & RawRepresentable>: View where T.RawValue == String {
    let icon: String
    let iconBackground: Color
    let title: String
    @Binding var selection: T
    let options: [T]

    var body: some View {
        HStack(spacing: 12) {
            SettingsIconBadge(icon: icon, color: iconBackground)

            Text(title)
                .font(.body)
                .foregroundStyle(Color.appPrimary)

            Spacer()

            Menu {
                ForEach(options, id: \.self) { option in
                    Button {
                        selection = option
                    } label: {
                        HStack {
                            Text(option.rawValue)
                            if selection == option {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(selection.rawValue)
                        .font(.body)
                        .foregroundStyle(Color.appSecondary)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.appTertiary)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    SettingsView()
        .environmentObject(WeatherViewModel())
}
