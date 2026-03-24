import SwiftUI

extension Color {
    // MARK: - Custom Weather Colors
    static let weatherBlue = Color(red: 0.2, green: 0.5, blue: 0.9)
    static let weatherDarkBlue = Color(red: 0.1, green: 0.2, blue: 0.5)
    static let weatherNight = Color(red: 0.05, green: 0.05, blue: 0.2)
    static let weatherSunrise = Color(red: 0.95, green: 0.6, blue: 0.3)
    static let weatherSunset = Color(red: 0.9, green: 0.4, blue: 0.3)
    static let weatherCloudy = Color(red: 0.5, green: 0.55, blue: 0.65)
    static let weatherRainy = Color(red: 0.3, green: 0.4, blue: 0.55)
    static let weatherSnowy = Color(red: 0.7, green: 0.75, blue: 0.85)
    static let weatherStormy = Color(red: 0.2, green: 0.2, blue: 0.35)

    // MARK: - Adaptive App Colors
    // Modern iOS-inspired palette — soft tones, no harsh pure black/white

    /// Primary text: warm off-white in dark, charcoal in light
    static let appPrimary = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.93, green: 0.93, blue: 0.95, alpha: 1.0)
            : UIColor(red: 0.13, green: 0.13, blue: 0.15, alpha: 1.0)
    })

    /// Secondary text: muted complement
    static let appSecondary = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.60, green: 0.60, blue: 0.65, alpha: 1.0)
            : UIColor(red: 0.40, green: 0.40, blue: 0.45, alpha: 1.0)
    })

    /// Tertiary text / icons: most muted
    static let appTertiary = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.40, green: 0.40, blue: 0.45, alpha: 1.0)
            : UIColor(red: 0.62, green: 0.62, blue: 0.67, alpha: 1.0)
    })

    /// Page background: soft dark charcoal / warm light gray
    static let appBackground = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.10, green: 0.10, blue: 0.11, alpha: 1.0)
            : UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0)
    })

    /// Card / container surface: elevated dark / near-white
    static let appCardBackground = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.15, green: 0.15, blue: 0.17, alpha: 1.0)
            : UIColor(red: 0.98, green: 0.98, blue: 1.0, alpha: 1.0)
    })

    /// Search bar / tertiary surface
    static let appTertiaryBackground = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.17, green: 0.17, blue: 0.19, alpha: 1.0)
            : UIColor(red: 0.93, green: 0.93, blue: 0.95, alpha: 1.0)
    })

    // MARK: - On-Gradient Colors (Weather Tab)
    // Light mode: white text on bright gradients, frosted-glass cards
    // Dark mode: crisp white text on deep gradients, dark glass cards

    /// Primary text on gradient
    static let onGradientPrimary = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 0.97, alpha: 1.0)
            : UIColor(white: 1.0, alpha: 1.0)
    })

    /// Secondary text / labels on gradient
    static let onGradientSecondary = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 0.70, alpha: 1.0)   // noticeably dimmer on dark
            : UIColor(white: 1.0, alpha: 0.70)   // translucent white on light
    })

    /// Card surface on gradient
    static let onGradientCard = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 0.0, alpha: 0.35)   // dark glass
            : UIColor(white: 1.0, alpha: 0.45)   // frosted white glass — more opaque for contrast
    })

    /// Card border on gradient
    static let onGradientCardBorder = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 1.0, alpha: 0.15)
            : UIColor(white: 1.0, alpha: 0.6)    // stronger border in light mode
    })
}

// MARK: - Weather Gradients
struct WeatherGradients {
    static func background(for conditionId: Int, isDaytime: Bool, darkMode: Bool = false) -> LinearGradient {
        let colors: [Color]

        if !isDaytime {
            colors = nightColors(for: conditionId)
        } else if darkMode {
            colors = dayDarkModeColors(for: conditionId)
        } else {
            colors = dayColors(for: conditionId)
        }

        return LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Light mode day gradients (bright, vivid)
    private static func dayColors(for conditionId: Int) -> [Color] {
        switch conditionId {
        case 200...232: // Thunderstorm
            return [Color(red: 0.15, green: 0.1, blue: 0.25), Color(red: 0.25, green: 0.15, blue: 0.4), Color(red: 0.1, green: 0.08, blue: 0.2)]
        case 300...321: // Drizzle
            return [Color(red: 0.4, green: 0.5, blue: 0.6), .weatherRainy, Color(red: 0.3, green: 0.4, blue: 0.55)]
        case 500...531: // Rain
            return [Color(red: 0.2, green: 0.25, blue: 0.4), Color(red: 0.25, green: 0.3, blue: 0.5), Color(red: 0.15, green: 0.2, blue: 0.35)]
        case 600...622: // Snow
            return [Color(red: 0.75, green: 0.8, blue: 0.9), Color(red: 0.6, green: 0.65, blue: 0.8), Color(red: 0.5, green: 0.55, blue: 0.7)]
        case 700...781: // Atmosphere (fog, haze, etc.)
            return [Color(red: 0.55, green: 0.55, blue: 0.58), Color(red: 0.45, green: 0.48, blue: 0.52), Color(red: 0.38, green: 0.4, blue: 0.45)]
        case 800: // Clear
            return [Color(red: 0.1, green: 0.45, blue: 0.95), Color(red: 0.2, green: 0.55, blue: 0.9), Color(red: 0.4, green: 0.7, blue: 0.95)]
        case 801...802: // Few/Scattered Clouds
            return [Color(red: 0.3, green: 0.5, blue: 0.8), Color(red: 0.45, green: 0.55, blue: 0.7), Color(red: 0.35, green: 0.5, blue: 0.7)]
        case 803...804: // Broken/Overcast Clouds
            return [Color(red: 0.4, green: 0.45, blue: 0.55), .weatherCloudy, Color(red: 0.35, green: 0.4, blue: 0.5)]
        default:
            return [.weatherBlue, .weatherDarkBlue]
        }
    }

    // MARK: - Dark mode day gradients (deeper, moodier versions)
    private static func dayDarkModeColors(for conditionId: Int) -> [Color] {
        switch conditionId {
        case 200...232: // Thunderstorm
            return [Color(red: 0.08, green: 0.05, blue: 0.15), Color(red: 0.14, green: 0.08, blue: 0.25), Color(red: 0.06, green: 0.04, blue: 0.12)]
        case 300...321: // Drizzle
            return [Color(red: 0.18, green: 0.24, blue: 0.32), Color(red: 0.14, green: 0.20, blue: 0.30), Color(red: 0.12, green: 0.18, blue: 0.28)]
        case 500...531: // Rain
            return [Color(red: 0.10, green: 0.13, blue: 0.24), Color(red: 0.13, green: 0.16, blue: 0.30), Color(red: 0.08, green: 0.10, blue: 0.20)]
        case 600...622: // Snow
            return [Color(red: 0.30, green: 0.33, blue: 0.48), Color(red: 0.24, green: 0.27, blue: 0.42), Color(red: 0.20, green: 0.22, blue: 0.36)]
        case 700...781: // Atmosphere
            return [Color(red: 0.24, green: 0.24, blue: 0.30), Color(red: 0.20, green: 0.22, blue: 0.28), Color(red: 0.16, green: 0.18, blue: 0.24)]
        case 800: // Clear
            return [Color(red: 0.04, green: 0.18, blue: 0.52), Color(red: 0.06, green: 0.24, blue: 0.50), Color(red: 0.10, green: 0.30, blue: 0.55)]
        case 801...802: // Few/Scattered Clouds
            return [Color(red: 0.12, green: 0.24, blue: 0.44), Color(red: 0.18, green: 0.26, blue: 0.38), Color(red: 0.14, green: 0.24, blue: 0.38)]
        case 803...804: // Broken/Overcast Clouds
            return [Color(red: 0.18, green: 0.20, blue: 0.28), Color(red: 0.22, green: 0.24, blue: 0.32), Color(red: 0.16, green: 0.18, blue: 0.26)]
        default:
            return [Color(red: 0.06, green: 0.16, blue: 0.40), .weatherDarkBlue]
        }
    }

    private static func nightColors(for conditionId: Int) -> [Color] {
        switch conditionId {
        case 200...232: // Thunderstorm
            return [Color(red: 0.08, green: 0.05, blue: 0.18), Color(red: 0.15, green: 0.08, blue: 0.3), Color(red: 0.02, green: 0.02, blue: 0.08)]
        case 300...531: // Rain/Drizzle
            return [Color(red: 0.06, green: 0.08, blue: 0.18), Color(red: 0.1, green: 0.12, blue: 0.25), Color(red: 0.04, green: 0.04, blue: 0.12)]
        case 600...622: // Snow
            return [Color(red: 0.18, green: 0.2, blue: 0.35), Color(red: 0.14, green: 0.16, blue: 0.28), Color(red: 0.1, green: 0.12, blue: 0.22)]
        case 700...781: // Atmosphere (fog, haze)
            return [Color(red: 0.12, green: 0.12, blue: 0.18), Color(red: 0.15, green: 0.15, blue: 0.2), Color(red: 0.08, green: 0.08, blue: 0.14)]
        case 800: // Clear night
            return [Color(red: 0.02, green: 0.02, blue: 0.12), .weatherNight, Color(red: 0.06, green: 0.03, blue: 0.18)]
        case 801...804: // Cloudy night
            return [Color(red: 0.08, green: 0.08, blue: 0.15), Color(red: 0.12, green: 0.12, blue: 0.2), Color(red: 0.06, green: 0.06, blue: 0.12)]
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
