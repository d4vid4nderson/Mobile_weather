import SwiftUI
import MapKit
import CoreLocation

// MARK: - Weather Layer Definition

enum WeatherLayer: String, CaseIterable, Identifiable {
    case precipitation = "precipitation_new"
    case clouds = "clouds_new"
    case temperature = "temp_new"
    case wind = "wind_new"
    case humidity = "humidity_new"
    case pressure = "pressure_new"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .precipitation: return "Rain"
        case .clouds: return "Clouds"
        case .temperature: return "Temp"
        case .wind: return "Wind"
        case .humidity: return "Humidity"
        case .pressure: return "Pressure"
        }
    }

    var icon: String {
        switch self {
        case .precipitation: return "drop.fill"
        case .clouds: return "cloud.fill"
        case .temperature: return "thermometer.medium"
        case .wind: return "wind"
        case .humidity: return "humidity.fill"
        case .pressure: return "gauge.medium"
        }
    }

    var legendTitle: String {
        switch self {
        case .precipitation: return "Precipitation Intensity"
        case .clouds: return "Cloud Coverage"
        case .temperature: return "Temperature"
        case .wind: return "Wind Speed"
        case .humidity: return "Relative Humidity"
        case .pressure: return "Atmospheric Pressure"
        }
    }

    var legendItems: [(String, Color)] {
        switch self {
        case .precipitation:
            return [
                ("None", .clear),
                ("Light", Color(red: 0.6, green: 0.8, blue: 1.0)),
                ("Moderate", Color(red: 0.2, green: 0.5, blue: 1.0)),
                ("Heavy", Color(red: 0.0, green: 0.2, blue: 0.8)),
                ("Extreme", Color(red: 0.5, green: 0.0, blue: 0.5))
            ]
        case .clouds:
            return [
                ("Clear", Color(red: 0.95, green: 0.95, blue: 1.0)),
                ("Scattered", Color(red: 0.8, green: 0.8, blue: 0.85)),
                ("Broken", Color(red: 0.6, green: 0.6, blue: 0.65)),
                ("Overcast", Color(red: 0.4, green: 0.4, blue: 0.45)),
                ("Full", Color(red: 0.25, green: 0.25, blue: 0.3))
            ]
        case .temperature:
            return [
                ("Cold", Color(red: 0.2, green: 0.2, blue: 0.9)),
                ("Cool", Color(red: 0.3, green: 0.7, blue: 0.9)),
                ("Mild", Color(red: 0.3, green: 0.9, blue: 0.3)),
                ("Warm", Color(red: 0.95, green: 0.8, blue: 0.2)),
                ("Hot", Color(red: 0.9, green: 0.2, blue: 0.2))
            ]
        case .wind:
            return [
                ("Calm", Color(red: 0.85, green: 0.95, blue: 0.85)),
                ("Light", Color(red: 0.5, green: 0.85, blue: 0.5)),
                ("Moderate", Color(red: 0.95, green: 0.9, blue: 0.3)),
                ("Strong", Color(red: 0.95, green: 0.5, blue: 0.2)),
                ("Severe", Color(red: 0.9, green: 0.15, blue: 0.15))
            ]
        case .humidity:
            return [
                ("Dry", Color(red: 0.95, green: 0.85, blue: 0.6)),
                ("Low", Color(red: 0.7, green: 0.9, blue: 0.5)),
                ("Moderate", Color(red: 0.3, green: 0.8, blue: 0.6)),
                ("High", Color(red: 0.2, green: 0.5, blue: 0.9)),
                ("Saturated", Color(red: 0.1, green: 0.2, blue: 0.7))
            ]
        case .pressure:
            return [
                ("Low", Color(red: 0.6, green: 0.3, blue: 0.9)),
                ("Below Avg", Color(red: 0.3, green: 0.5, blue: 0.9)),
                ("Normal", Color(red: 0.3, green: 0.8, blue: 0.3)),
                ("Above Avg", Color(red: 0.9, green: 0.8, blue: 0.3)),
                ("High", Color(red: 0.9, green: 0.4, blue: 0.2))
            ]
        }
    }
}

// MARK: - Storm Alert Annotation

struct StormAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let title: String
    let severity: AlertSeverity

    enum AlertSeverity: String {
        case watch = "Watch"
        case warning = "Warning"
        case emergency = "Emergency"

        var color: UIColor {
            switch self {
            case .watch: return .systemYellow
            case .warning: return .systemOrange
            case .emergency: return .systemRed
            }
        }

        var markerTintColor: UIColor {
            switch self {
            case .watch: return .systemGreen
            case .warning: return .systemPurple
            case .emergency: return .systemRed
            }
        }
    }
}

// MARK: - MKPointAnnotation Subclass for Storm Data

final class StormPointAnnotation: MKPointAnnotation {
    var severity: StormAnnotation.AlertSeverity = .watch
    var annotationId: UUID = UUID()
}

// MARK: - Saved Location Pin Annotation

final class SavedLocationAnnotation: MKPointAnnotation {
    var label: String = ""
    var iconName: String = "mappin.circle.fill"
}

// MARK: - WeatherMapView (UIViewRepresentable)

struct WeatherMapView: UIViewRepresentable {
    let selectedLayer: WeatherLayer
    let overlayOpacity: Double
    let apiKey: String
    let stormAnnotations: [StormAnnotation]
    let savedLocations: [SavedLocation]
    let defaultLocationName: String
    let defaultLocationLat: Double
    let defaultLocationLon: Double
    let centerCoordinate: CLLocationCoordinate2D
    let regionSpan: MKCoordinateSpan

    @Binding var mapView: MKMapView?

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView(frame: .zero)
        map.delegate = context.coordinator
        map.preferredConfiguration = MKStandardMapConfiguration(emphasisStyle: .muted)
        map.overrideUserInterfaceStyle = .dark
        map.showsUserLocation = true
        map.showsCompass = true
        map.showsScale = true

        let region = MKCoordinateRegion(
            center: centerCoordinate,
            span: regionSpan
        )
        map.setRegion(region, animated: false)

        addTileOverlay(to: map, layer: selectedLayer, apiKey: apiKey, opacity: overlayOpacity)
        addStormAnnotations(to: map, annotations: stormAnnotations)
        addSavedLocationPins(to: map)

        DispatchQueue.main.async {
            self.mapView = map
        }

        return map
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Remove existing tile overlays
        let existingOverlays = mapView.overlays.filter { $0 is MKTileOverlay }
        mapView.removeOverlays(existingOverlays)

        // Add new tile overlay for selected layer
        addTileOverlay(to: mapView, layer: selectedLayer, apiKey: apiKey, opacity: overlayOpacity)

        // Update storm annotations
        let existingStorm = mapView.annotations.filter { $0 is StormPointAnnotation }
        mapView.removeAnnotations(existingStorm)
        addStormAnnotations(to: mapView, annotations: stormAnnotations)

        // Update saved location pins
        let existingSaved = mapView.annotations.filter { $0 is SavedLocationAnnotation }
        mapView.removeAnnotations(existingSaved)
        addSavedLocationPins(to: mapView)

        // Update coordinator state
        context.coordinator.currentOpacity = overlayOpacity
        context.coordinator.selectedLayer = selectedLayer

        // Update wind grid arrows
        context.coordinator.windGridManager.updateGrid(for: mapView, isWindLayer: selectedLayer == .wind)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(overlayOpacity: overlayOpacity, apiKey: apiKey)
    }

    // MARK: - Helpers

    private func addTileOverlay(to mapView: MKMapView, layer: WeatherLayer, apiKey: String, opacity: Double) {
        let template = "https://tile.openweathermap.org/map/\(layer.rawValue)/{z}/{x}/{y}.png?appid=\(apiKey)"
        let tileOverlay = MKTileOverlay(urlTemplate: template)
        tileOverlay.canReplaceMapContent = false
        tileOverlay.tileSize = CGSize(width: 256, height: 256)
        tileOverlay.maximumZ = 18
        tileOverlay.minimumZ = 1
        mapView.addOverlay(tileOverlay, level: .aboveRoads)
    }

    private func addStormAnnotations(to mapView: MKMapView, annotations: [StormAnnotation]) {
        for storm in annotations {
            let annotation = StormPointAnnotation()
            annotation.coordinate = storm.coordinate
            annotation.title = storm.title
            annotation.subtitle = storm.severity.rawValue
            annotation.severity = storm.severity
            annotation.annotationId = storm.id
            mapView.addAnnotation(annotation)
        }
    }

    private func addSavedLocationPins(to mapView: MKMapView) {
        // Default location pin
        let defaultPin = SavedLocationAnnotation()
        defaultPin.coordinate = CLLocationCoordinate2D(latitude: defaultLocationLat, longitude: defaultLocationLon)
        defaultPin.title = defaultLocationName
        defaultPin.label = "Default"
        defaultPin.iconName = "mappin.circle.fill"
        mapView.addAnnotation(defaultPin)

        // Saved location pins
        for location in savedLocations {
            let pin = SavedLocationAnnotation()
            pin.coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
            pin.title = location.cityName
            pin.subtitle = location.label
            pin.label = location.label
            pin.iconName = location.iconName
            mapView.addAnnotation(pin)
        }
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, MKMapViewDelegate {
        var currentOpacity: Double
        var selectedLayer: WeatherLayer = .precipitation
        let windGridManager: WindGridManager

        init(overlayOpacity: Double, apiKey: String) {
            self.currentOpacity = overlayOpacity
            self.windGridManager = WindGridManager(apiKey: apiKey)
            super.init()
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let tileOverlay = overlay as? MKTileOverlay {
                let renderer = MKTileOverlayRenderer(tileOverlay: tileOverlay)
                renderer.alpha = CGFloat(currentOpacity)
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            // Don't customize user location
            guard !(annotation is MKUserLocation) else { return nil }

            if let stormAnnotation = annotation as? StormPointAnnotation {
                let identifier = "StormAnnotation"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView

                if annotationView == nil {
                    annotationView = MKMarkerAnnotationView(annotation: stormAnnotation, reuseIdentifier: identifier)
                    annotationView?.canShowCallout = true
                } else {
                    annotationView?.annotation = stormAnnotation
                }

                switch stormAnnotation.severity {
                case .watch:
                    annotationView?.markerTintColor = .systemYellow
                    annotationView?.glyphImage = UIImage(systemName: "exclamationmark.triangle.fill")
                case .warning:
                    annotationView?.markerTintColor = .systemOrange
                    annotationView?.glyphImage = UIImage(systemName: "exclamationmark.triangle.fill")
                case .emergency:
                    annotationView?.markerTintColor = .systemRed
                    annotationView?.glyphImage = UIImage(systemName: "bolt.fill")
                }

                annotationView?.displayPriority = .required
                annotationView?.titleVisibility = .adaptive
                return annotationView
            }

            if let windAnnotation = annotation as? WindArrowAnnotation {
                let identifier = "WindArrow"
                var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? WindArrowAnnotationView
                if view == nil {
                    view = WindArrowAnnotationView(annotation: windAnnotation, reuseIdentifier: identifier)
                } else {
                    view?.annotation = windAnnotation
                }
                view?.configure(windDeg: windAnnotation.windDeg, windSpeed: windAnnotation.windSpeed)
                view?.canShowCallout = false
                return view
            }

            if let savedAnnotation = annotation as? SavedLocationAnnotation {
                let identifier = "SavedLocationPin"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView

                if annotationView == nil {
                    annotationView = MKMarkerAnnotationView(annotation: savedAnnotation, reuseIdentifier: identifier)
                    annotationView?.canShowCallout = true
                } else {
                    annotationView?.annotation = savedAnnotation
                }

                switch savedAnnotation.label {
                case "Home":
                    annotationView?.markerTintColor = .systemBlue
                    annotationView?.glyphImage = UIImage(systemName: "house.fill")
                case "Work":
                    annotationView?.markerTintColor = .systemPurple
                    annotationView?.glyphImage = UIImage(systemName: "briefcase.fill")
                case "Default":
                    annotationView?.markerTintColor = .systemGreen
                    annotationView?.glyphImage = UIImage(systemName: "mappin.circle.fill")
                default:
                    annotationView?.markerTintColor = .systemOrange
                    annotationView?.glyphImage = UIImage(systemName: "mappin.circle.fill")
                }

                annotationView?.displayPriority = .required
                annotationView?.titleVisibility = .adaptive
                return annotationView
            }

            return nil
        }

        func mapView(_ mapView: MKMapView, didSelect annotation: MKAnnotation) {
            // Allow default callout behavior
        }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            // Update wind arrows when map region changes
            if selectedLayer == .wind {
                windGridManager.updateGrid(for: mapView, isWindLayer: true)
            }
        }

        func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
            // Map finished loading tiles
        }

        func mapViewDidFailLoadingMap(_ mapView: MKMapView, withError error: Error) {
            print("Map failed to load: \(error.localizedDescription)")
        }
    }
}

// MARK: - RadarView

struct RadarView: View {
    @EnvironmentObject var viewModel: WeatherViewModel

    @State private var selectedLayer: WeatherLayer = .precipitation
    @State private var overlayOpacity: Double = 0.6
    @State private var showLegend: Bool = true
    @State private var showLayerPicker: Bool = false
    @State private var showDataGraph: Bool = false
    @State private var mapView: MKMapView?
    @State private var stormAnnotations: [StormAnnotation] = []

    // Wise County, Texas center coordinates
    private let wiseCountyCenter = CLLocationCoordinate2D(
        latitude: 33.2343,
        longitude: -97.5892
    )
    private let defaultSpan = MKCoordinateSpan(
        latitudeDelta: 2.0,
        longitudeDelta: 2.0
    )

    // API Key - reads from WeatherService or uses placeholder
    private let apiKey = "39029bf0c1f9bc244377f3e8c16de220"

    var body: some View {
        ZStack(alignment: .top) {
            // MARK: - Map Layer
            WeatherMapView(
                selectedLayer: selectedLayer,
                overlayOpacity: overlayOpacity,
                apiKey: apiKey,
                stormAnnotations: stormAnnotations,
                savedLocations: viewModel.savedLocations,
                defaultLocationName: viewModel.defaultLocationName,
                defaultLocationLat: viewModel.defaultLocationLat,
                defaultLocationLon: viewModel.defaultLocationLon,
                centerCoordinate: wiseCountyCenter,
                regionSpan: defaultSpan,
                mapView: $mapView
            )
            .ignoresSafeArea()

            // MARK: - Overlay Controls
            VStack(spacing: 0) {
                // Quick location bar at top
                radarLocationBar
                    .padding(.top, 8)

                Spacer()

                // Bottom controls
                VStack(spacing: 12) {
                    // Right-aligned buttons: Layers, Reset, Info
                    bottomButtonsRow
                        .padding(.horizontal)

                    // Layer picker sheet
                    if showLayerPicker {
                        layerPickerGrid
                            .padding(.horizontal)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    // Opacity slider
                    opacitySlider
                        .padding(.horizontal)

                    // Data graph
                    if showDataGraph, let forecast = viewModel.forecast {
                        RadarDataGraphView(
                            forecastItems: forecast.list,
                            selectedLayer: selectedLayer,
                            timezoneOffset: forecast.city.timezone ?? 0,
                            convertTemp: viewModel.convertTemp
                        )
                        .padding(.horizontal)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    // Legend
                    if showLegend {
                        legendView
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(.bottom, 16)
            }
        }
        .onAppear {
            loadStormAnnotations()
        }
    }

    // MARK: - Radar Location Bar

    private var radarLocationBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Current location
                Button {
                    centerOnUserLocation()
                } label: {
                    Image(systemName: "location.fill")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(10)
                        .background(.ultraThinMaterial, in: Circle())
                }

                // Default location pill
                Button {
                    centerOnLocation(lat: viewModel.defaultLocationLat, lon: viewModel.defaultLocationLon)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.caption)
                        Text(shortLocationName(viewModel.defaultLocationName))
                            .font(.caption2.bold())
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
                }

                // Saved locations
                ForEach(viewModel.savedLocations) { location in
                    Button {
                        centerOnLocation(lat: location.latitude, lon: location.longitude)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: location.iconName)
                                .font(.caption)
                            Text(location.label)
                                .font(.caption2.bold())
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                    }
                }
            }
            .padding(.leading, 16)
            .padding(.trailing, 8)
        }
    }

    // MARK: - Bottom Buttons

    private var bottomButtonsRow: some View {
        HStack(spacing: 10) {
            // Active layer indicator
            HStack(spacing: 6) {
                Image(systemName: selectedLayer.icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(selectedLayer.displayName)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.6))
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            )

            Spacer()

            // Data graph toggle
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showDataGraph.toggle()
                }
            } label: {
                Image(systemName: showDataGraph ? "chart.bar.fill" : "chart.bar")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Circle().fill(.ultraThinMaterial))
            }

            // Reset map
            Button {
                resetMap()
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Circle().fill(.ultraThinMaterial))
            }

            // Layers button
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showLayerPicker.toggle()
                }
            } label: {
                Image(systemName: "square.3.layers.3d")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Circle().fill(.ultraThinMaterial))
            }

            // Toggle legend / info
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showLegend.toggle()
                }
            } label: {
                Image(systemName: showLegend ? "info.circle.fill" : "info.circle")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Circle().fill(.ultraThinMaterial))
            }
        }
    }

    // MARK: - Layer Picker Grid

    private var layerPickerGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8)
        ], spacing: 8) {
            ForEach(WeatherLayer.allCases) { layer in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedLayer = layer
                        showLayerPicker = false
                    }
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: layer.icon)
                            .font(.system(size: 22))
                        Text(layer.displayName)
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedLayer == layer
                                  ? Color.blue.opacity(0.7)
                                  : Color.white.opacity(0.1))
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }

    // MARK: - Opacity Slider

    private var opacitySlider: some View {
        HStack(spacing: 12) {
            Image(systemName: "eye.slash")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.7))

            Slider(value: $overlayOpacity, in: 0.0...1.0, step: 0.05)
                .tint(.blue)

            Image(systemName: "eye.fill")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.7))

            Text("\(Int(overlayOpacity * 100))%")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 40, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }

    // MARK: - Legend View

    private var legendView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: selectedLayer.icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(selectedLayer.legendTitle)
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
            }
            .foregroundColor(.white)

            // Gradient bar with labels
            VStack(spacing: 4) {
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        ForEach(Array(selectedLayer.legendItems.enumerated()), id: \.offset) { _, item in
                            Rectangle()
                                .fill(item.1)
                                .frame(height: 12)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .frame(height: 12)

                HStack {
                    ForEach(Array(selectedLayer.legendItems.enumerated()), id: \.offset) { index, item in
                        if index == 0 || index == selectedLayer.legendItems.count - 1 ||
                            index == selectedLayer.legendItems.count / 2 {
                            Text(item.0)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        if index < selectedLayer.legendItems.count - 1 {
                            Spacer()
                        }
                    }
                }
            }

            // Wind direction indicator
            if selectedLayer == .wind, let deg = viewModel.currentWeather?.wind.deg {
                Divider()
                    .background(Color.white.opacity(0.3))
                HStack(spacing: 8) {
                    // Animated rotating arrow
                    Image(systemName: "location.north.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(Double(deg) + 180)) // point where wind goes TO
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Wind from \(windCompassLabel(deg))")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                        if viewModel.currentWeather?.wind.speed != nil {
                            Text(viewModel.windSpeedString)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    Spacer()
                }
            }

            // Storm alerts indicator
            if !stormAnnotations.isEmpty {
                Divider()
                    .background(Color.white.opacity(0.3))
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.orange)
                    Text("\(stormAnnotations.count) active alert\(stormAnnotations.count == 1 ? "" : "s") in area")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.orange)
                    Spacer()
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
        )
        .padding(.horizontal, 16)
    }

    // MARK: - Actions

    private func centerOnLocation(lat: Double, lon: Double, span: MKCoordinateSpan? = nil) {
        guard let map = mapView else { return }
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
            span: span ?? MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
        )
        map.setRegion(region, animated: true)
    }

    private func centerOnUserLocation() {
        guard let map = mapView else { return }
        if let userLocation = map.userLocation.location {
            centerOnLocation(lat: userLocation.coordinate.latitude, lon: userLocation.coordinate.longitude)
        } else if let location = viewModel.locationManager.location {
            centerOnLocation(lat: location.coordinate.latitude, lon: location.coordinate.longitude)
        }
    }

    private func resetMap() {
        guard let map = mapView else { return }
        let region = MKCoordinateRegion(
            center: wiseCountyCenter,
            span: defaultSpan
        )
        map.setRegion(region, animated: true)
    }

    private func shortLocationName(_ name: String) -> String {
        let city = name.components(separatedBy: ",").first ?? name
        return city
            .replacingOccurrences(of: "County", with: "Co.")
            .trimmingCharacters(in: .whitespaces)
    }

    private func windCompassLabel(_ degrees: Int) -> String {
        let dirs = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
                    "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        let index = Int((Double(degrees) + 11.25).truncatingRemainder(dividingBy: 360) / 22.5)
        return dirs[index % 16]
    }

    private func loadStormAnnotations() {
        // Check if the current weather data suggests severe conditions
        // and populate storm annotations accordingly.
        // This creates sample annotations based on weather alerts in the Wise County area.
        guard let weather = viewModel.currentWeather else { return }

        var annotations: [StormAnnotation] = []

        // Check for severe weather condition codes
        // Thunderstorm: 2xx, Drizzle: 3xx, Rain: 5xx, Snow: 6xx, Atmosphere: 7xx
        if let condition = weather.weather.first {
            let conditionId = condition.id

            // Thunderstorms (200-232)
            if conditionId >= 200 && conditionId < 300 {
                annotations.append(StormAnnotation(
                    coordinate: CLLocationCoordinate2D(
                        latitude: 33.2343,
                        longitude: -97.5892
                    ),
                    title: "Thunderstorm - \(condition.description.capitalized)",
                    severity: conditionId >= 210 ? .warning : .watch
                ))
            }

            // Heavy rain (502-531)
            if conditionId >= 502 && conditionId <= 531 {
                annotations.append(StormAnnotation(
                    coordinate: CLLocationCoordinate2D(
                        latitude: 33.20,
                        longitude: -97.55
                    ),
                    title: "Heavy Rain - \(condition.description.capitalized)",
                    severity: .watch
                ))
            }

            // Tornado or severe (781)
            if conditionId == 781 {
                annotations.append(StormAnnotation(
                    coordinate: CLLocationCoordinate2D(
                        latitude: 33.25,
                        longitude: -97.60
                    ),
                    title: "Tornado Warning",
                    severity: .emergency
                ))
            }

            // Extreme weather codes (900+)
            if conditionId >= 900 {
                annotations.append(StormAnnotation(
                    coordinate: CLLocationCoordinate2D(
                        latitude: 33.24,
                        longitude: -97.59
                    ),
                    title: "Severe Weather Alert",
                    severity: .emergency
                ))
            }
        }

        withAnimation {
            stormAnnotations = annotations
        }
    }
}

// MARK: - Preview

#Preview {
    RadarView()
        .environmentObject(WeatherViewModel())
}
