import SwiftUI
import MapKit
import CoreLocation

// MARK: - Weather Layer Definition

enum WeatherLayer: String, CaseIterable, Identifiable {
    case precipitation = "precipitation_new"
    case clouds = "clouds_new"
    case temperature = "temp_new"
    case wind = "wind_new"
    case pressure = "pressure_new"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .precipitation: return "Rain"
        case .clouds: return "Clouds"
        case .temperature: return "Temp"
        case .wind: return "Wind"
        case .pressure: return "Pressure"
        }
    }

    var icon: String {
        switch self {
        case .precipitation: return "drop.fill"
        case .clouds: return "cloud.fill"
        case .temperature: return "thermometer.medium"
        case .wind: return "wind"
        case .pressure: return "gauge.medium"
        }
    }

    var legendTitle: String {
        switch self {
        case .precipitation: return "Precipitation Intensity"
        case .clouds: return "Cloud Coverage"
        case .temperature: return "Temperature"
        case .wind: return "Wind Speed"
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

// MARK: - WeatherMapView (UIViewRepresentable)

struct WeatherMapView: UIViewRepresentable {
    let selectedLayer: WeatherLayer
    let overlayOpacity: Double
    let apiKey: String
    let stormAnnotations: [StormAnnotation]
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
        let existingAnnotations = mapView.annotations.filter { $0 is StormPointAnnotation }
        mapView.removeAnnotations(existingAnnotations)
        addStormAnnotations(to: mapView, annotations: stormAnnotations)

        // Update coordinator state
        context.coordinator.currentOpacity = overlayOpacity
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(overlayOpacity: overlayOpacity)
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

    // MARK: - Coordinator

    final class Coordinator: NSObject, MKMapViewDelegate {
        var currentOpacity: Double

        init(overlayOpacity: Double) {
            self.currentOpacity = overlayOpacity
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

            return nil
        }

        func mapView(_ mapView: MKMapView, didSelect annotation: MKAnnotation) {
            // Allow default callout behavior
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
                centerCoordinate: wiseCountyCenter,
                regionSpan: defaultSpan,
                mapView: $mapView
            )
            .ignoresSafeArea()

            // MARK: - Overlay Controls
            VStack(spacing: 0) {
                // Layer selector
                layerSelectorBar
                    .padding(.top, 8)

                Spacer()

                // Bottom controls
                VStack(spacing: 12) {
                    // Map action buttons
                    actionButtonsRow
                        .padding(.horizontal)

                    // Opacity slider
                    opacitySlider
                        .padding(.horizontal)

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

    // MARK: - Layer Selector Bar

    private var layerSelectorBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(WeatherLayer.allCases) { layer in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedLayer = layer
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: layer.icon)
                                .font(.system(size: 14, weight: .semibold))
                            Text(layer.displayName)
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(selectedLayer == layer ? .white : .white.opacity(0.7))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(selectedLayer == layer
                                      ? Color.blue.opacity(0.8)
                                      : Color.clear)
                        )
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Action Buttons

    private var actionButtonsRow: some View {
        HStack(spacing: 12) {
            Spacer()

            // Wise County button
            Button {
                centerOnWiseCounty()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 16))
                    Text("Wise County")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                )
            }

            // My Location button
            Button {
                centerOnUserLocation()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 16))
                    Text("My Location")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                )
            }

            // Toggle legend
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showLegend.toggle()
                }
            } label: {
                Image(systemName: showLegend ? "info.circle.fill" : "info.circle")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                    )
            }
        }
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

    private func centerOnWiseCounty() {
        guard let map = mapView else { return }
        let region = MKCoordinateRegion(
            center: wiseCountyCenter,
            span: defaultSpan
        )
        map.setRegion(region, animated: true)
    }

    private func centerOnUserLocation() {
        guard let map = mapView else { return }
        if let userLocation = map.userLocation.location {
            let region = MKCoordinateRegion(
                center: userLocation.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
            )
            map.setRegion(region, animated: true)
        } else if let location = viewModel.locationManager.location {
            let region = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
            )
            map.setRegion(region, animated: true)
        }
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
