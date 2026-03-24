import SwiftUI

struct SavedLocationPicker: View {
    @EnvironmentObject var viewModel: WeatherViewModel
    @Environment(\.dismiss) private var dismiss

    let editingLocation: SavedLocation?

    @State private var label: String = ""
    @State private var customLabel: String = ""
    @State private var searchText = ""
    @State private var suggestions: [GeocodingResult] = []
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?
    @State private var selectedCity: GeocodingResult?
    @State private var showDeleteConfirm = false
    @FocusState private var isSearchFocused: Bool

    private var isEditing: Bool { editingLocation != nil }

    private var effectiveLabel: String {
        label == "Custom" ? customLabel : label
    }

    private var canSave: Bool {
        !effectiveLabel.trimmingCharacters(in: .whitespaces).isEmpty && selectedCity != nil
    }

    private let labelOptions = ["Home", "Work", "Custom"]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        labelSection
                        locationSection
                    }
                    .padding(16)
                }
            }
            .navigationTitle(isEditing ? "Edit Location" : "Add Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
            .confirmationDialog("Delete Location", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    if let loc = editingLocation {
                        viewModel.removeSavedLocation(loc)
                    }
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to remove this saved location?")
            }
        }
        .onAppear {
            if let loc = editingLocation {
                if SavedLocation.presetLabels.contains(loc.label) {
                    label = loc.label
                } else {
                    label = "Custom"
                    customLabel = loc.label
                }
                // Create a placeholder selected city from saved data
                selectedCity = GeocodingResult(
                    name: loc.cityName.components(separatedBy: ",").first ?? loc.cityName,
                    lat: loc.latitude,
                    lon: loc.longitude,
                    country: nil,
                    state: nil
                )
            }
        }
        .onChange(of: searchText) { _, newValue in
            fetchSuggestions(for: newValue)
        }
    }

    // MARK: - Label Section

    private var labelSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("LABEL")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.appSecondary)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                ForEach(Array(labelOptions.enumerated()), id: \.element) { index, option in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            label = option
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: iconForLabel(option))
                                .font(.body)
                                .foregroundStyle(colorForLabel(option))
                                .frame(width: 24)

                            Text(option)
                                .font(.body)
                                .foregroundStyle(Color.appPrimary)

                            Spacer()

                            if label == option {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.blue)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if index < labelOptions.count - 1 {
                        Divider().padding(.leading, 52)
                    }
                }
            }
            .background(Color.appCardBackground, in: RoundedRectangle(cornerRadius: 12))

            if label == "Custom" {
                TextField("Enter label name...", text: $customLabel)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(Color.appCardBackground, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Location Section

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CITY")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.appSecondary)
                .padding(.leading, 4)

            // Selected city display
            if let city = selectedCity {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)

                    Text(city.displayName)
                        .font(.body)
                        .foregroundStyle(Color.appPrimary)
                        .lineLimit(1)

                    Spacer()

                    Button {
                        selectedCity = nil
                        searchText = ""
                        suggestions = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.appSecondary)
                    }
                }
                .padding(12)
                .background(Color.appCardBackground, in: RoundedRectangle(cornerRadius: 12))
            }

            // Search bar
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

            // Suggestions
            if !suggestions.isEmpty {
                VStack(spacing: 0) {
                    ForEach(suggestions) { city in
                        Button {
                            selectedCity = city
                            searchText = ""
                            suggestions = []
                            isSearchFocused = false
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
                            Divider().padding(.leading, 52)
                        }
                    }
                }
                .background(Color.appCardBackground, in: RoundedRectangle(cornerRadius: 12))
            } else if isSearching && searchText.count >= 2 {
                HStack(spacing: 10) {
                    ProgressView().scaleEffect(0.8)
                    Text("Finding cities...")
                        .font(.subheadline)
                        .foregroundStyle(Color.appSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }

            // Delete button for editing
            if isEditing {
                Button {
                    showDeleteConfirm = true
                } label: {
                    HStack {
                        Spacer()
                        Text("Remove Location")
                            .font(.body)
                            .foregroundStyle(.red)
                        Spacer()
                    }
                    .padding(.vertical, 12)
                    .background(Color.appCardBackground, in: RoundedRectangle(cornerRadius: 12))
                }
                .padding(.top, 8)
            }
        }
    }

    // MARK: - Helpers

    private func save() {
        guard let city = selectedCity else { return }
        let finalLabel = effectiveLabel.trimmingCharacters(in: .whitespaces)
        guard !finalLabel.isEmpty else { return }

        if var existing = editingLocation {
            existing.label = finalLabel
            existing.cityName = city.displayName
            existing.latitude = city.lat
            existing.longitude = city.lon
            viewModel.updateSavedLocation(existing)
        } else {
            viewModel.addSavedLocation(
                label: finalLabel,
                cityName: city.displayName,
                lat: city.lat,
                lon: city.lon
            )
        }
        dismiss()
    }

    private func iconForLabel(_ label: String) -> String {
        switch label {
        case "Home": return "house.fill"
        case "Work": return "briefcase.fill"
        default: return "tag.fill"
        }
    }

    private func colorForLabel(_ label: String) -> Color {
        switch label {
        case "Home": return .blue
        case "Work": return .purple
        default: return .orange
        }
    }

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
    SavedLocationPicker(editingLocation: nil)
        .environmentObject(WeatherViewModel())
}
