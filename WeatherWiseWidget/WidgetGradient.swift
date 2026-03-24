import SwiftUI

/// Returns a gradient background matching the weather condition for widget views
func weatherGradient(for conditionId: Int, icon: String) -> LinearGradient {
    let isNight = icon.hasSuffix("n")

    if isNight {
        return LinearGradient(
            colors: [Color(red: 0.1, green: 0.1, blue: 0.3), Color(red: 0.05, green: 0.05, blue: 0.15)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    switch conditionId {
    // Thunderstorm
    case 200...232:
        return LinearGradient(
            colors: [Color(red: 0.3, green: 0.2, blue: 0.5), Color(red: 0.15, green: 0.1, blue: 0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    // Drizzle / Rain
    case 300...531:
        return LinearGradient(
            colors: [Color(red: 0.3, green: 0.4, blue: 0.6), Color(red: 0.2, green: 0.25, blue: 0.4)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    // Snow
    case 600...622:
        return LinearGradient(
            colors: [Color(red: 0.7, green: 0.75, blue: 0.85), Color(red: 0.5, green: 0.55, blue: 0.65)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    // Atmosphere (fog, haze, etc.)
    case 700...781:
        return LinearGradient(
            colors: [Color(red: 0.5, green: 0.5, blue: 0.55), Color(red: 0.35, green: 0.35, blue: 0.4)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    // Clear
    case 800:
        return LinearGradient(
            colors: [Color(red: 0.2, green: 0.5, blue: 0.9), Color(red: 0.1, green: 0.35, blue: 0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    // Clouds
    case 801...804:
        return LinearGradient(
            colors: [Color(red: 0.35, green: 0.5, blue: 0.7), Color(red: 0.25, green: 0.35, blue: 0.5)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    default:
        return LinearGradient(
            colors: [Color(red: 0.2, green: 0.5, blue: 0.9), Color(red: 0.1, green: 0.35, blue: 0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
