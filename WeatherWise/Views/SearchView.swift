import SwiftUI

struct SearchView: View {
    @EnvironmentObject var viewModel: WeatherViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
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

                    if !viewModel.citySuggestions.isEmpty {
                        suggestionsList
                    } else if viewModel.isLoadingSuggestions && searchText.count >= 2 {
                        suggestionsLoading
                    } else if !searchText.isEmpty && !viewModel.isLoadingSuggestions {
                        searchAction
                    }

                    if viewModel.citySuggestions.isEmpty && searchText.isEmpty {
                        recentSearchesList
                    }

                    Spacer()
                }
            }
            .navigationTitle("Search City")
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
        .onDisappear {
            viewModel.citySuggestions = []
        }
        .onChange(of: searchText) { _, newValue in
            viewModel.fetchCitySuggestions(for: newValue)
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.appSecondary)

            TextField("Enter city name...", text: $searchText)
                .textFieldStyle(.plain)
                .focused($isSearchFocused)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .onSubmit {
                    performSearch(searchText)
                }

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    viewModel.citySuggestions = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.appSecondary)
                }
            }
        }
        .padding(12)
        .background(Color.appTertiaryBackground, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Suggestions List

    private var suggestionsList: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.citySuggestions) { city in
                Button {
                    viewModel.selectCity(city)
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

                        Image(systemName: "arrow.up.left")
                            .font(.caption)
                            .foregroundStyle(Color.appTertiary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if city != viewModel.citySuggestions.last {
                    Divider()
                        .padding(.leading, 52)
                }
            }
        }
        .background(Color.appCardBackground, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
    }

    // MARK: - Suggestions Loading

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

    // MARK: - Search Action (fallback)

    private var searchAction: some View {
        Button {
            performSearch(searchText)
        } label: {
            HStack {
                Image(systemName: "magnifyingglass")
                Text("Search for \"\(searchText)\"")
                    .fontWeight(.medium)
                Spacer()
                Image(systemName: "arrow.right")
            }
            .foregroundStyle(.blue)
            .padding(16)
            .background(Color.appCardBackground, in: RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    // MARK: - Recent Searches

    private var recentSearchesList: some View {
        Group {
            if !viewModel.recentSearches.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("Recent Searches")
                            .font(.headline)
                            .foregroundStyle(Color.appPrimary)
                        Spacer()
                        Button("Clear All") {
                            withAnimation {
                                viewModel.clearRecentSearches()
                            }
                        }
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)

                    VStack(spacing: 0) {
                        ForEach(viewModel.recentSearches, id: \.self) { city in
                            recentSearchRow(city)

                            if city != viewModel.recentSearches.last {
                                Divider()
                                    .padding(.leading, 52)
                            }
                        }
                    }
                    .background(Color.appCardBackground, in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 16)
                }
            }
        }
    }

    private func recentSearchRow(_ city: String) -> some View {
        Button {
            performSearch(city)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "clock")
                    .font(.body)
                    .foregroundStyle(Color.appSecondary)
                    .frame(width: 24)

                Text(city)
                    .foregroundStyle(Color.appPrimary)
                    .font(.body)

                Spacer()

                Button {
                    withAnimation {
                        viewModel.removeRecentSearch(city)
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundStyle(Color.appSecondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func performSearch(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        viewModel.searchCity(trimmed)
        dismiss()
    }
}

#Preview {
    SearchView()
        .environmentObject(WeatherViewModel())
}
