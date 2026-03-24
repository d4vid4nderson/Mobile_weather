import SwiftUI

extension Color {
    // MARK: - Custom Colors
    static let weatherBlue = Color(red: 0.2, green: 0.5, blue: 0.9)
    static let weatherDarkBlue = Color(red: 0.1, green: 0.2, blue: 0.5)
    static let weatherNight = Color(red: 0.05, green: 0.05, blue: 0.2)
    static let weatherSunrise = Color(red: 0.95, green: 0.6, blue: 0.3)
    static let weatherSunset = Color(red: 0.9, green: 0.4, blue: 0.3)
    static let weatherCloudy = Color(red: 0.5, green: 0.55, blue: 0.65)
    static let weatherRainy = Color(red: 0.3, green: 0.4, blue: 0.55)
    static let weatherSnowy = Color(red: 0.7, green: 0.75, blue: 0.85)
    static let weatherStormy = Color(red: 0.2, green: 0.2, blue: 0.35)
}

// MARK: - Weather Gradients
struct WeatherGradients {
    static func background(for conditionId: Int, isDaytime: Bool) -> LinearGradient {
        let colors: [Color]

        if !isDaytime {
            colors = nightColors(for: conditionId)
        } else {
            colors = dayColors(for: conditionId)
        }

        return LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private static func dayColors(for conditionId: Int) -> [Color] {
        switch conditionId {
        case 200...232: // Thunderstorm
            return [.weatherStormy, Color(red: 0.3, green: 0.25, blue: 0.45), Color(red: 0.15, green: 0.15, blue: 0.3)]
        case 300...321: // Drizzle
            return [.weatherCloudy, .weatherRainy, Color(red: 0.35, green: 0.45, blue: 0.6)]
        case 500...531: // Rain
            return [.weatherRainy, Color(red: 0.25, green: 0.35, blue: 0.5), Color(red: 0.2, green: 0.3, blue: 0.45)]
        case 600...622: // Snow
            return [.weatherSnowy, Color(red: 0.6, green: 0.65, blue: 0.8), Color(red: 0.5, green: 0.55, blue: 0.7)]
        case 700...781: // Atmosphere (fog, haze, etc.)
            return [.weatherCloudy, Color(red: 0.55, green: 0.6, blue: 0.65), Color(red: 0.45, green: 0.5, blue: 0.55)]
        case 800: // Clear
            return [Color(red: 0.25, green: 0.55, blue: 0.95), .weatherBlue, Color(red: 0.35, green: 0.65, blue: 0.95)]
        case 801...804: // Clouds
            return [Color(red: 0.4, green: 0.55, blue: 0.75), .weatherCloudy, Color(red: 0.45, green: 0.5, blue: 0.6)]
        default:
            return [.weatherBlue, .weatherDarkBlue]
        }
    }

    private static func nightColors(for conditionId: Int) -> [Color] {
        switch conditionId {
        case 200...232: // Thunderstorm
            return [Color(red: 0.1, green: 0.08, blue: 0.2), Color(red: 0.15, green: 0.1, blue: 0.3), .black]
        case 300...531: // Rain/Drizzle
            return [Color(red: 0.08, green: 0.1, blue: 0.2), Color(red: 0.1, green: 0.12, blue: 0.25), Color(red: 0.05, green: 0.05, blue: 0.15)]
        case 600...622: // Snow
            return [Color(red: 0.15, green: 0.18, blue: 0.3), Color(red: 0.12, green: 0.15, blue: 0.25), Color(red: 0.08, green: 0.1, blue: 0.2)]
        case 800: // Clear night
            return [Color(red: 0.05, green: 0.05, blue: 0.15), .weatherNight, Color(red: 0.08, green: 0.05, blue: 0.2)]
        default:
            return [.weatherNight, Color(red: 0.08, green: 0.08, blue: 0.18), Color(red: 0.05, green: 0.05, blue: 0.12)]
        }
    }

    static let defaultBackground = LinearGradient(
        colors: [.weatherBlue, .weatherDarkBlue],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
