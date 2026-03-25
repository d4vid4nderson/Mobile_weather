import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: WeatherViewModel
    @State private var selectedTab = 0
    @State private var showSearch = false

    var body: some View {
        ZStack {
            viewModel.backgroundGradient
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 1.5), value: viewModel.currentWeather?.weather.first?.id)

            if viewModel.isLoading && viewModel.currentWeather == nil {
                loadingView
            } else if let errorMessage = viewModel.errorMessage, viewModel.currentWeather == nil {
                errorView(message: errorMessage)
            } else {
                mainContent
            }
        }
        .preferredColorScheme(viewModel.appearance.colorScheme)
        .onAppear {
            viewModel.fetchWeather()
        }
        .sheet(isPresented: $showSearch) {
            SearchView()
                .environmentObject(viewModel)
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        TabView(selection: $selectedTab) {
            weatherTab
                .environment(\.colorScheme, .dark)
                .background {
                    viewModel.backgroundGradient
                        .ignoresSafeArea()
                        .animation(.easeInOut(duration: 1.5), value: viewModel.currentWeather?.weather.first?.id)
                }
                .tabItem {
                    Image(systemName: "cloud.sun.fill")
                    Text("Weather")
                }
                .tag(0)

            radarTab
                .environment(\.colorScheme, .dark)
                .tabItem {
                    Image(systemName: "map.fill")
                    Text("Radar")
                }
                .tag(1)

            alertsTab
                .background {
                    Color.appBackground
                        .ignoresSafeArea()
                }
                .tabItem {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text("Alerts")
                }
                .tag(2)

            SettingsView()
                .environmentObject(viewModel)
                .background {
                    Color.appBackground
                        .ignoresSafeArea()
                }
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
                .tag(3)
        }
        .overlay(alignment: .topTrailing) {
            if selectedTab == 0 {
                searchButton
            }
        }
        .overlay(alignment: .topLeading) {
            if selectedTab == 0 {
                quickLocationBar
            }
        }
    }

    // MARK: - Weather Tab (Current + Forecast combined)

    private var weatherTab: some View {
        ZStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    if !viewModel.alerts.isEmpty {
                        alertBanner
                    }

                    CurrentWeatherView()
                        .environmentObject(viewModel)

                    ForecastView()
                        .environmentObject(viewModel)
                        .padding(.top, 8)
                }
            }
            .refreshable {
                await viewModel.refresh()
            }

            // Weather particle effects overlay
            if let conditionId = viewModel.currentWeather?.weather.first?.id {
                WeatherEffectsView(conditionId: conditionId)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
    }

    private var alertBanner: some View {
        AlertBannerView(showAlerts: .constant(false))
            .environmentObject(viewModel)
            .padding(.horizontal, 20)
            .padding(.top, 50)
    }

    // MARK: - Radar Tab

    private var radarTab: some View {
        RadarView()
            .environmentObject(viewModel)
    }

    // MARK: - Alerts Tab

    private var alertsTab: some View {
        AlertsView()
            .environmentObject(viewModel)
    }

    // MARK: - Overlay Buttons

    private var searchButton: some View {
        Button {
            showSearch = true
        } label: {
            Image(systemName: "magnifyingglass")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(Color.onGradientPrimary)
                .padding(12)
                .background(.ultraThinMaterial, in: Circle())
        }
        .padding(.trailing, 20)
        .padding(.top, 8)
    }

    private var quickLocationBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Current location button
                Button {
                    viewModel.fetchWeather()
                } label: {
                    Image(systemName: "location.fill")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.onGradientPrimary)
                        .padding(12)
                        .background(.ultraThinMaterial, in: Circle())
                }

                // Default location pill
                Button {
                    viewModel.loadWiseCounty()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.caption)
                        Text(shortName(viewModel.defaultLocationName))
                            .font(.caption2.bold())
                    }
                    .foregroundStyle(Color.onGradientPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
                }

                // Saved location pills
                ForEach(viewModel.savedLocations) { location in
                    Button {
                        viewModel.loadSavedLocationWeather(location)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: location.iconName)
                                .font(.caption)
                            Text(location.label)
                                .font(.caption2.bold())
                        }
                        .foregroundStyle(Color.onGradientPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                    }
                }
            }
            .padding(.leading, 20)
            .padding(.trailing, 8)
        }
        .padding(.top, 8)
    }

    /// Shorten a location name for the pill (e.g. "Wise County, TX" → "Wise Co.")
    private func shortName(_ name: String) -> String {
        let city = name.components(separatedBy: ",").first ?? name
        return city
            .replacingOccurrences(of: "County", with: "Co.")
            .trimmingCharacters(in: .whitespaces)
    }

    // MARK: - Loading & Error

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading Weather Wise...")
                .font(.headline)
                .foregroundStyle(Color.onGradientPrimary.opacity(0.8))
            Text("Wise County, Texas")
                .font(.subheadline)
                .foregroundStyle(Color.onGradientSecondary)
        }
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundStyle(.yellow)

            Text("Unable to Load Weather")
                .font(.title2.bold())
                .foregroundStyle(Color.onGradientPrimary)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(Color.onGradientSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                viewModel.fetchWeather()
            } label: {
                Label("Try Again", systemImage: "arrow.clockwise")
                    .font(.headline)
                    .foregroundStyle(Color.onGradientPrimary)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial, in: Capsule())
            }

            Button {
                showSearch = true
            } label: {
                Label("Search City", systemImage: "magnifyingglass")
                    .font(.headline)
                    .foregroundStyle(Color.onGradientPrimary)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial, in: Capsule())
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(WeatherViewModel())
}
