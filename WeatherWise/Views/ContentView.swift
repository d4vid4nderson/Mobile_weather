import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: WeatherViewModel
    @State private var selectedTab = 0
    @State private var showSearch = false
    @State private var showAlerts = false

    var body: some View {
        ZStack {
            viewModel.backgroundGradient
                .ignoresSafeArea()

            if viewModel.isLoading && viewModel.currentWeather == nil {
                loadingView
            } else if let errorMessage = viewModel.errorMessage, viewModel.currentWeather == nil {
                errorView(message: errorMessage)
            } else {
                mainContent
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            viewModel.fetchWeather()
        }
        .sheet(isPresented: $showSearch) {
            SearchView()
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $showAlerts) {
            NavigationStack {
                AlertsView()
                    .environmentObject(viewModel)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") {
                                showAlerts = false
                            }
                            .foregroundStyle(.white)
                        }
                    }
            }
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        TabView(selection: $selectedTab) {
            currentWeatherTab
                .tag(0)

            forecastTab
                .tag(1)

            radarTab
                .tag(2)

            alertsTab
                .tag(3)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .overlay(alignment: .topTrailing) {
            HStack(spacing: 8) {
                alertButton
                searchButton
            }
        }
        .overlay(alignment: .topLeading) {
            HStack(spacing: 8) {
                locationButton
                wiseCountyButton
            }
        }
    }

    private var currentWeatherTab: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Alert banner at top if alerts are active
                if !viewModel.alerts.isEmpty {
                    AlertBannerView(showAlerts: $showAlerts)
                        .environmentObject(viewModel)
                        .padding(.horizontal, 20)
                        .padding(.top, 50)
                }

                CurrentWeatherView()
                    .environmentObject(viewModel)
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    private var forecastTab: some View {
        ScrollView(showsIndicators: false) {
            ForecastView()
                .environmentObject(viewModel)
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    private var radarTab: some View {
        RadarView()
            .environmentObject(viewModel)
    }

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
                .foregroundStyle(.white)
                .padding(12)
                .background(.ultraThinMaterial, in: Circle())
        }
        .padding(.trailing, 20)
        .padding(.top, 8)
    }

    private var alertButton: some View {
        Button {
            showAlerts = true
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(viewModel.alerts.isEmpty ? .white : .orange)
                    .padding(12)
                    .background(.ultraThinMaterial, in: Circle())

                if !viewModel.alerts.isEmpty {
                    Text("\(viewModel.alerts.count)")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .frame(width: 18, height: 18)
                        .background(Color.red, in: Circle())
                        .offset(x: 4, y: -4)
                }
            }
        }
        .padding(.top, 8)
    }

    private var locationButton: some View {
        Button {
            viewModel.fetchWeather()
        } label: {
            Image(systemName: "location.fill")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(12)
                .background(.ultraThinMaterial, in: Circle())
        }
        .padding(.leading, 20)
        .padding(.top, 8)
    }

    private var wiseCountyButton: some View {
        Button {
            viewModel.loadWiseCounty()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "mappin.circle.fill")
                    .font(.caption)
                Text("Wise Co.")
                    .font(.caption2.bold())
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())
        }
        .padding(.top, 8)
    }

    // MARK: - Loading & Error

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.white)
            Text("Loading Weather Wise...")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.8))
            Text("Wise County, Texas")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))
        }
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundStyle(.yellow)

            Text("Unable to Load Weather")
                .font(.title2.bold())
                .foregroundStyle(.white)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                viewModel.fetchWeather()
            } label: {
                Label("Try Again", systemImage: "arrow.clockwise")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial, in: Capsule())
            }

            Button {
                showSearch = true
            } label: {
                Label("Search City", systemImage: "magnifyingglass")
                    .font(.headline)
                    .foregroundStyle(.white)
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
