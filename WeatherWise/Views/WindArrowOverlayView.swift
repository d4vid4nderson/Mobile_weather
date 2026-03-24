import UIKit
import MapKit

// MARK: - Wind Grid Point Data

struct WindGridPoint {
    let coordinate: CLLocationCoordinate2D
    let windDeg: Double
    let windSpeed: Double  // mph
}

// MARK: - Wind Arrow Annotation

final class WindArrowAnnotation: MKPointAnnotation {
    var windDeg: Double = 0
    var windSpeed: Double = 0
    var gridKey: String = ""
}

// MARK: - Wind Arrow Annotation View

final class WindArrowAnnotationView: MKAnnotationView {
    private let arrowLayer = CAShapeLayer()
    private var displayLink: CADisplayLink?
    private var animationOffset: CGFloat = 0
    private var arrowLength: CGFloat = 20

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        centerOffset = .zero
        backgroundColor = .clear
        isUserInteractionEnabled = false

        arrowLayer.strokeColor = UIColor.white.cgColor
        arrowLayer.fillColor = UIColor.clear.cgColor
        arrowLayer.lineWidth = 2.0
        arrowLayer.lineCap = .round
        arrowLayer.lineJoin = .round
        arrowLayer.shadowColor = UIColor.black.cgColor
        arrowLayer.shadowOffset = CGSize(width: 0.5, height: 0.5)
        arrowLayer.shadowRadius = 1.5
        arrowLayer.shadowOpacity = 0.5
        layer.addSublayer(arrowLayer)

        startAnimation()
    }

    func configure(windDeg: Double, windSpeed: Double) {
        // Wind blows FROM deg, arrow points where wind goes TO
        let toAngle = (windDeg + 180.0).truncatingRemainder(dividingBy: 360.0)
        let radians = toAngle * .pi / 180.0

        // Arrow length scales with wind speed
        arrowLength = arrowLengthForSpeed(windSpeed)

        // Resize frame based on arrow length
        let size = max(arrowLength * 2.2, 50)
        frame = CGRect(x: 0, y: 0, width: size, height: size)

        // Opacity scales with wind speed
        let opacity: Float
        switch windSpeed {
        case 0..<3: opacity = 0.3
        case 3..<8: opacity = 0.5
        case 8..<15: opacity = 0.65
        case 15..<25: opacity = 0.8
        default: opacity = 0.9
        }
        arrowLayer.opacity = opacity

        // Line width scales slightly with speed
        arrowLayer.lineWidth = windSpeed > 20 ? 2.5 : (windSpeed > 10 ? 2.0 : 1.5)

        // Rotate the entire view to wind direction
        transform = CGAffineTransform(rotationAngle: radians)

        updateArrowPath()
    }

    private func arrowLengthForSpeed(_ speed: Double) -> CGFloat {
        switch speed {
        case 0..<3: return 10
        case 3..<8: return 16
        case 8..<15: return 22
        case 15..<25: return 30
        case 25..<40: return 38
        default: return 44
        }
    }

    private func updateArrowPath() {
        let cx = bounds.midX
        let cy = bounds.midY
        let halfLen = arrowLength / 2

        // Shaft pointing up (rotation handles direction)
        let path = UIBezierPath()
        let tailY = cy + halfLen + animationOffset
        let tipY = cy - halfLen + animationOffset

        // Shaft
        path.move(to: CGPoint(x: cx, y: tailY))
        path.addLine(to: CGPoint(x: cx, y: tipY))

        // Chevron head
        let headLen = min(arrowLength * 0.35, 14)
        let headAngle: CGFloat = .pi / 5.5
        let leftX = cx - sin(headAngle) * headLen
        let leftY = tipY + cos(headAngle) * headLen
        let rightX = cx + sin(headAngle) * headLen
        let rightY = leftY

        path.move(to: CGPoint(x: leftX, y: leftY))
        path.addLine(to: CGPoint(x: cx, y: tipY))
        path.addLine(to: CGPoint(x: rightX, y: rightY))

        arrowLayer.path = path.cgPath
    }

    private func startAnimation() {
        displayLink = CADisplayLink(target: self, selector: #selector(tick))
        displayLink?.preferredFrameRateRange = CAFrameRateRange(minimum: 15, maximum: 30)
        displayLink?.add(to: .main, forMode: .common)
    }

    @objc private func tick(_ link: CADisplayLink) {
        // Gentle bob animation
        animationOffset = sin(CGFloat(link.timestamp) * 1.5) * 2.0
        updateArrowPath()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        transform = .identity
    }

    deinit {
        displayLink?.invalidate()
    }
}

// MARK: - Wind Grid Manager

/// Fetches wind data for a grid of points across the visible map region
/// and manages wind arrow annotations on the map.
final class WindGridManager {
    private let apiKey: String
    private var cachedPoints: [String: WindGridPoint] = [:]
    private var pendingFetches: Set<String> = []
    private var lastGridUpdate = Date.distantPast
    private let gridCols = 5
    private let gridRows = 7
    private let minUpdateInterval: TimeInterval = 2.0 // debounce

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    /// Called when the map region changes. Fetches wind for grid points and updates annotations.
    func updateGrid(for mapView: MKMapView, isWindLayer: Bool) {
        // Remove wind annotations if not wind layer
        if !isWindLayer {
            removeAllWindAnnotations(from: mapView)
            return
        }

        // Debounce
        let now = Date()
        guard now.timeIntervalSince(lastGridUpdate) >= minUpdateInterval else { return }
        lastGridUpdate = now

        let region = mapView.region
        let latStep = region.span.latitudeDelta / Double(gridRows + 1)
        let lonStep = region.span.longitudeDelta / Double(gridCols + 1)
        let baseLat = region.center.latitude - region.span.latitudeDelta / 2
        let baseLon = region.center.longitude - region.span.longitudeDelta / 2

        var neededKeys: Set<String> = []

        for row in 1...gridRows {
            for col in 1...gridCols {
                let lat = baseLat + latStep * Double(row)
                let lon = baseLon + lonStep * Double(col)
                // Round to ~0.5° grid for caching
                let snapLat = (lat * 2).rounded() / 2
                let snapLon = (lon * 2).rounded() / 2
                let key = "\(snapLat),\(snapLon)"
                neededKeys.insert(key)

                if cachedPoints[key] == nil && !pendingFetches.contains(key) {
                    pendingFetches.insert(key)
                    fetchWind(lat: snapLat, lon: snapLon, key: key) { [weak self] point in
                        DispatchQueue.main.async {
                            self?.pendingFetches.remove(key)
                            if let point = point {
                                self?.cachedPoints[key] = point
                                self?.placeAnnotation(for: point, key: key, on: mapView)
                            }
                        }
                    }
                }
            }
        }

        // Remove annotations that are no longer in the visible grid
        removeStaleAnnotations(from: mapView, activeKeys: neededKeys)

        // Place cached points that are in the needed set
        for key in neededKeys {
            if let point = cachedPoints[key] {
                // Only add if not already on map
                let existing = mapView.annotations.contains { ann in
                    (ann as? WindArrowAnnotation)?.gridKey == key
                }
                if !existing {
                    placeAnnotation(for: point, key: key, on: mapView)
                }
            }
        }
    }

    private func placeAnnotation(for point: WindGridPoint, key: String, on mapView: MKMapView) {
        let ann = WindArrowAnnotation()
        ann.coordinate = point.coordinate
        ann.windDeg = point.windDeg
        ann.windSpeed = point.windSpeed
        ann.gridKey = key
        mapView.addAnnotation(ann)
    }

    private func removeStaleAnnotations(from mapView: MKMapView, activeKeys: Set<String>) {
        let stale = mapView.annotations.compactMap { $0 as? WindArrowAnnotation }
            .filter { !activeKeys.contains($0.gridKey) }
        if !stale.isEmpty {
            mapView.removeAnnotations(stale)
        }
    }

    func removeAllWindAnnotations(from mapView: MKMapView) {
        let windAnns = mapView.annotations.filter { $0 is WindArrowAnnotation }
        if !windAnns.isEmpty {
            mapView.removeAnnotations(windAnns)
        }
    }

    private func fetchWind(lat: Double, lon: Double, key: String, completion: @escaping (WindGridPoint?) -> Void) {
        let urlStr = "https://api.openweathermap.org/data/2.5/weather?lat=\(lat)&lon=\(lon)&units=imperial&appid=\(apiKey)"
        guard let url = URL(string: urlStr) else {
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                let wind = json?["wind"] as? [String: Any]
                let deg = wind?["deg"] as? Double ?? 0
                let speed = wind?["speed"] as? Double ?? 0
                completion(WindGridPoint(
                    coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                    windDeg: deg,
                    windSpeed: speed
                ))
            } catch {
                completion(nil)
            }
        }.resume()
    }
}
