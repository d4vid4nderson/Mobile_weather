import Foundation

// MARK: - Alert Service Errors

enum AlertServiceError: LocalizedError {
    case invalidURL
    case httpError(statusCode: Int)
    case decodingError(underlying: Error)
    case networkError(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid request URL."
        case .httpError(let statusCode):
            return "Server returned HTTP \(statusCode)."
        case .decodingError(let underlying):
            return "Failed to decode alert data: \(underlying.localizedDescription)"
        case .networkError(let underlying):
            return "Network error: \(underlying.localizedDescription)"
        }
    }
}

// MARK: - Alert Service

/// An actor that fetches weather alerts from the National Weather Service API.
///
/// The NWS API is free, requires no key, but mandates a `User-Agent` header
/// identifying the application and a contact address.
actor AlertService {

    // MARK: Singleton

    static let shared = AlertService()

    // MARK: Constants

    private let baseURL = "https://api.weather.gov/alerts/active"
    private let wiseCountyZone = "TXZ091"
    private let userAgent = "(WeatherWise, contact@weatherwise.app)"

    // MARK: URL Session

    private let session: URLSession

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: configuration)
    }

    // MARK: - Public Methods

    /// Fetches all active alerts for Wise County, Texas (zone TXZ091).
    /// - Returns: An array of alert features sorted by severity (most severe first).
    func fetchAlertsForWiseCounty() async throws -> [NWSAlertFeature] {
        guard let url = URL(string: "\(baseURL)?zone=\(wiseCountyZone)") else {
            throw AlertServiceError.invalidURL
        }
        return try await fetchAlerts(from: url)
    }

    /// Fetches all active alerts for a given geographic coordinate.
    /// - Parameters:
    ///   - lat: Latitude of the location.
    ///   - lon: Longitude of the location.
    /// - Returns: An array of alert features sorted by severity (most severe first).
    func fetchAlerts(lat: Double, lon: Double) async throws -> [NWSAlertFeature] {
        let pointParam = String(format: "%.4f,%.4f", lat, lon)
        guard let url = URL(string: "\(baseURL)?point=\(pointParam)") else {
            throw AlertServiceError.invalidURL
        }
        return try await fetchAlerts(from: url)
    }

    // MARK: - Private Helpers

    /// Builds an NWS-compliant request, fetches, decodes, and sorts alerts.
    private func fetchAlerts(from url: URL) async throws -> [NWSAlertFeature] {
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/geo+json", forHTTPHeaderField: "Accept")

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw AlertServiceError.networkError(underlying: error)
        }

        if let httpResponse = response as? HTTPURLResponse,
           !(200...299).contains(httpResponse.statusCode) {
            throw AlertServiceError.httpError(statusCode: httpResponse.statusCode)
        }

        let decoded: NWSAlertResponse
        do {
            let decoder = JSONDecoder()
            decoded = try decoder.decode(NWSAlertResponse.self, from: data)
        } catch {
            throw AlertServiceError.decodingError(underlying: error)
        }

        // Sort by severity: extreme first, then severe, moderate, minor, unknown.
        let sorted = decoded.features.sorted { lhs, rhs in
            lhs.properties.severity < rhs.properties.severity
        }

        return sorted
    }
}
