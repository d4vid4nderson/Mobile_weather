import Foundation

struct SavedLocation: Identifiable, Codable, Equatable {
    var id: UUID
    var label: String
    var cityName: String
    var latitude: Double
    var longitude: Double

    init(id: UUID = UUID(), label: String, cityName: String, latitude: Double, longitude: Double) {
        self.id = id
        self.label = label
        self.cityName = cityName
        self.latitude = latitude
        self.longitude = longitude
    }

    /// Common preset labels
    static let presetLabels = ["Home", "Work"]

    /// SF Symbol for a given label
    var iconName: String {
        switch label {
        case "Home": return "house.fill"
        case "Work": return "briefcase.fill"
        default: return "mappin.circle.fill"
        }
    }

    var iconColor: String {
        switch label {
        case "Home": return "blue"
        case "Work": return "purple"
        default: return "orange"
        }
    }
}
