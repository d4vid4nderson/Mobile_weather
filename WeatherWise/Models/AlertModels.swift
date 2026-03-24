import Foundation
import SwiftUI

// MARK: - NWS Alert API Response (GeoJSON)

/// Top-level GeoJSON response from the NWS Alerts API.
struct NWSAlertResponse: Codable {
    let type: String
    let features: [NWSAlertFeature]
    let title: String?
    let updated: String?
}

/// A single GeoJSON Feature representing one weather alert.
struct NWSAlertFeature: Codable, Identifiable {
    let id: String
    let type: String
    let properties: NWSAlertProperties

    // Geometry is nullable in the NWS API (some alerts lack geometry)
    let geometry: NWSAlertGeometry?
}

/// GeoJSON geometry for an alert area. The NWS API uses Polygon or null.
struct NWSAlertGeometry: Codable {
    let type: String
    let coordinates: [[[Double]]]?
}

/// The geocode block embedded within alert properties.
struct NWSGeocode: Codable {
    let SAME: [String]?
    let UGC: [String]?
}

/// All properties for a single NWS weather alert.
struct NWSAlertProperties: Codable {
    let id: String
    let areaDesc: String
    let geocode: NWSGeocode?
    let affectedZones: [String]?
    let sent: String?
    let effective: String?
    let onset: String?
    let expires: String?
    let ends: String?
    let status: String?
    let messageType: String?
    let severity: AlertSeverity
    let certainty: String?
    let urgency: String?
    let event: String
    let senderName: String?
    let headline: String?
    let description: String?
    let instruction: String?
    let response: String?

    enum CodingKeys: String, CodingKey {
        case id = "@id"
        case areaDesc
        case geocode
        case affectedZones
        case sent
        case effective
        case onset
        case expires
        case ends
        case status
        case messageType
        case severity
        case certainty
        case urgency
        case event
        case senderName
        case headline
        case description
        case instruction
        case response
    }
}

// MARK: - Alert Severity

/// Severity levels as defined by the NWS CAP standard.
enum AlertSeverity: String, Codable, Comparable, CaseIterable {
    case extreme = "Extreme"
    case severe = "Severe"
    case moderate = "Moderate"
    case minor = "Minor"
    case unknown = "Unknown"

    /// Numeric rank for sorting. Lower numbers are more severe.
    var sortOrder: Int {
        switch self {
        case .extreme:  return 0
        case .severe:   return 1
        case .moderate: return 2
        case .minor:    return 3
        case .unknown:  return 4
        }
    }

    /// The color associated with this severity level.
    var color: Color {
        switch self {
        case .extreme:  return .red
        case .severe:   return .orange
        case .moderate: return .yellow
        case .minor:    return .blue
        case .unknown:  return .gray
        }
    }

    /// An SF Symbol name representing the severity level.
    var iconName: String {
        switch self {
        case .extreme:  return "exclamationmark.triangle.fill"
        case .severe:   return "exclamationmark.triangle"
        case .moderate: return "exclamationmark.circle.fill"
        case .minor:    return "info.circle.fill"
        case .unknown:  return "questionmark.circle"
        }
    }

    /// Display label for the severity.
    var displayName: String {
        rawValue
    }

    // MARK: Comparable

    static func < (lhs: AlertSeverity, rhs: AlertSeverity) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }

    // MARK: Codable

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawString = try container.decode(String.self)
        self = AlertSeverity(rawValue: rawString) ?? .unknown
    }
}

// MARK: - Convenience Extensions

extension NWSAlertFeature {
    /// Returns the onset date parsed from the ISO 8601 string, if available.
    var onsetDate: Date? {
        guard let onset = properties.onset else { return nil }
        return ISO8601DateFormatter().date(from: onset)
    }

    /// Returns the expiration date parsed from the ISO 8601 string, if available.
    /// Falls back to `ends` if `expires` is nil.
    var expiresDate: Date? {
        let dateString = properties.expires ?? properties.ends
        guard let dateString else { return nil }
        return ISO8601DateFormatter().date(from: dateString)
    }

    /// Returns the effective date parsed from the ISO 8601 string, if available.
    var effectiveDate: Date? {
        guard let effective = properties.effective else { return nil }
        return ISO8601DateFormatter().date(from: effective)
    }

    /// A human-readable time range string for display.
    var formattedTimeRange: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short

        let start = onsetDate ?? effectiveDate
        let end = expiresDate

        switch (start, end) {
        case let (.some(s), .some(e)):
            return "\(formatter.string(from: s)) - \(formatter.string(from: e))"
        case let (.some(s), .none):
            return "From \(formatter.string(from: s))"
        case let (.none, .some(e)):
            return "Until \(formatter.string(from: e))"
        case (.none, .none):
            return "Time unavailable"
        }
    }

    /// Whether this alert has extreme or severe severity.
    var isCritical: Bool {
        properties.severity == .extreme || properties.severity == .severe
    }
}
