import SwiftUI

struct DefaultLocationPicker: View {
    @EnvironmentObject var viewModel: WeatherViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var suggestions: [GeocodingResult] = []
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    searchBar
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 16)

                    if !suggestions.isEmpty {
                        suggestionsList
                    } else if isSearching && searchText.count >= 2 {
                        suggestionsLoading
                    } else if searchText.isEmpty {
                        quickOptions
                    }

                    Spacer()
                }
            }
            .navigationTitle("Default Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            isSearchFocused = true
        }
        .onChange(of: searchText) { _, newValue in
            fetchSuggestions(for: newValue)
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.appSecondary)

            TextField("Search for a city...", text: $searchText)
                .textFieldStyle(.plain)
                .focused($isSearchFocused)
                .autocorrectionDisabled()
                .submitLabel(.search)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    suggestions = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.appSecondary)
                }
            }
        }
        .padding(12)
        .background(Color.appTertiaryBackground, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Quick Options

    private var quickOptions: some View {
        VStack(spacing: 0) {
            // Use current location
            if !viewModel.cityName.isEmpty {
                Button {
                    viewModel.setCurrentLocationAsDefault()
                    dismiss()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "location.fill")
                            .font(.body)
                            .foregroundStyle(.blue)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Use Current Location")
                                .font(.body)
                                .foregroundStyle(Color.appPrimary)
                            Text(viewModel.cityName)
                                .font(.caption)
                                .foregroundStyle(Color.appSecondary)
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Divider()
                    .padding(.leading, 52)
            }

            // Reset to Wise County
            Button {
                viewModel.setDefaultLocation(
                    name: "Wise County, TX",
                    lat: WeatherViewModel.wiseCountyLat,
                    lon: WeatherViewModel.wiseCountyLon
                )
                dismiss()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.body)
                        .foregroundStyle(.orange)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Wise County, TX")
                            .font(.body)
                            .foregroundStyle(Color.appPrimary)
                        Text("Default")
                            .font(.caption)
                            .foregroundStyle(Color.appSecondary)
                    }

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .background(Color.appCardBackground, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
    }

    // MARK: - Suggestions List

    private var suggestionsList: some View {
        VStack(spacing: 0) {
            ForEach(suggestions) { city in
                Button {
                    viewModel.setDefaultLocation(
                        name: city.displayName,
                        lat: city.lat,
                        lon: city.lon
                    )
                    dismiss()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.body)
                            .foregroundStyle(.blue)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(city.name)
                                .font(.body)
                                .foregroundStyle(Color.appPrimary)

                            if let state = city.state, !state.isEmpty {
                                Text("\(state), \(city.country ?? "")")
                                    .font(.caption)
                                    .foregroundStyle(Color.appSecondary)
                            } else if let country = city.country {
                                Text(country)
                                    .font(.caption)
                                    .foregroundStyle(Color.appSecondary)
                            }
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if city != suggestions.last {
                    Divider()
                        .padding(.leading, 52)
                }
            }
        }
        .background(Color.appCardBackground, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
    }

    // MARK: - Loading

    private var suggestionsLoading: some View {
        HStack(spacing: 10) {
            ProgressView()
                .scaleEffect(0.8)
            Text("Finding cities...")
                .font(.subheadline)
                .foregroundStyle(Color.appSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }

    // MARK: - Search Logic

    private func fetchSuggestions(for query: String) {
        searchTask?.cancel()

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else {
            suggestions = []
            isSearching = false
            return
        }

        isSearching = true
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }

            do {
                let results = try await WeatherService.shared.fetchCitySuggestions(query: trimmed)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self.suggestions = results
                    self.isSearching = false
                }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self.suggestions = []
                    self.isSearching = false
                }
            }
        }
    }
}

#Preview {
    DefaultLocationPicker()
        .environmentObject(WeatherViewModel())
}
