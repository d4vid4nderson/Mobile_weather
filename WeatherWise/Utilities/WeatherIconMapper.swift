import Foundation
import SwiftUI

struct WeatherIconMapper {
    /// Maps OpenWeatherMap condition codes to SF Symbol names
    static func sfSymbol(for conditionId: Int, icon: String = "") -> String {
        let isNight = icon.hasSuffix("n")

        switch conditionId {
        // Thunderstorm
        case 200...202:
            return "cloud.bolt.rain.fill"
        case 210...221:
            return "cloud.bolt.fill"
        case 230...232:
            return "cloud.bolt.rain.fill"

        // Drizzle
        case 300...321:
            return "cloud.drizzle.fill"

        // Rain
        case 500:
            return "cloud.rain.fill"
        case 501:
            return "cloud.rain.fill"
        case 502...504:
            return "cloud.heavyrain.fill"
        case 511:
            return "cloud.sleet.fill"
        case 520...531:
            return "cloud.rain.fill"

        // Snow
        case 600...622:
            return "cloud.snow.fill"

        // Atmosphere
        case 701:
            return "cloud.fog.fill"
        case 711:
            return "smoke.fill"
        case 721:
            return "sun.haze.fill"
        case 731, 761:
            return "sun.dust.fill"
        case 741:
            return "cloud.fog.fill"
        case 751:
            return "sun.dust.fill"
        case 762:
            return "mountain.2.fill"
        case 771:
            return "wind"
        case 781:
            return "tornado"

        // Clear
        case 800:
            return isNight ? "moon.stars.fill" : "sun.max.fill"

        // Clouds
        case 801:
            return isNight ? "cloud.moon.fill" : "cloud.sun.fill"
        case 802:
            return "cloud.fill"
        case 803, 804:
            return "smoke.fill"

        default:
            return isNight ? "moon.fill" : "sun.max.fill"
        }
    }

    /// Returns the primary color for a weather condition
    static func color(for conditionId: Int) -> Color {
        switch conditionId {
        case 200...232: return .purple
        case 300...321: return .cyan
        case 500...531: return .blue
        case 600...622: return .white
        case 700...781: return .gray
        case 800: return .yellow
        case 801...804: return .gray
        default: return .blue
        }
    }
}
