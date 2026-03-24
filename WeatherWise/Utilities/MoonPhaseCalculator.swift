import Foundation

/// Moon phase data
struct MoonPhase {
    let name: String
    let icon: String          // SF Symbol
    let illumination: Double  // 0.0 to 1.0
    let age: Double           // days into the lunation cycle (0 = new moon)
    let phase: Double         // 0.0 to 1.0 through the cycle

    enum PhaseType {
        case newMoon
        case waxingCrescent
        case firstQuarter
        case waxingGibbous
        case fullMoon
        case waningGibbous
        case lastQuarter
        case waningCrescent
    }

    var phaseType: PhaseType {
        switch age {
        case 0..<1.85: return .newMoon
        case 1.85..<7.38: return .waxingCrescent
        case 7.38..<9.23: return .firstQuarter
        case 9.23..<14.77: return .waxingGibbous
        case 14.77..<16.61: return .fullMoon
        case 16.61..<22.15: return .waningGibbous
        case 22.15..<24.0: return .lastQuarter
        default: return .waningCrescent
        }
    }
}

/// Calculates moon phase using a simplified astronomical algorithm.
/// Based on the synodic month (29.53059 days) relative to a known new moon.
enum MoonPhaseCalculator {
    // Synodic month length in days
    static let synodicMonth: Double = 29.53059

    // Known new moon: January 6, 2000 18:14 UTC (J2000 epoch reference)
    static let referenceNewMoon: Double = 947182440.0 // Unix timestamp

    /// Calculate current moon phase
    static func currentPhase(date: Date = Date()) -> MoonPhase {
        return phase(for: date)
    }

    /// Convenience for just the name
    static func currentPhaseName(date: Date = Date()) -> String {
        return phase(for: date).name
    }

    /// Calculate moon phase for a given date
    static func phase(for date: Date) -> MoonPhase {
        let timestamp = date.timeIntervalSince1970
        let daysSinceRef = (timestamp - referenceNewMoon) / 86400.0
        let age = daysSinceRef.truncatingRemainder(dividingBy: synodicMonth)
        let normalizedAge = age < 0 ? age + synodicMonth : age
        let phaseValue = normalizedAge / synodicMonth // 0.0 to 1.0

        // Illumination approximation using cosine
        let illumination = (1.0 - cos(phaseValue * 2.0 * .pi)) / 2.0

        let (name, icon) = phaseNameAndIcon(age: normalizedAge)

        return MoonPhase(
            name: name,
            icon: icon,
            illumination: illumination,
            age: normalizedAge,
            phase: phaseValue
        )
    }

    private static func phaseNameAndIcon(age: Double) -> (String, String) {
        switch age {
        case 0..<1.85:
            return ("New Moon", "moon.fill")
        case 1.85..<7.38:
            return ("Waxing Crescent", "moon.stars.fill")
        case 7.38..<9.23:
            return ("First Quarter", "moon.zzz.fill")
        case 9.23..<14.77:
            return ("Waxing Gibbous", "moon.haze.fill")
        case 14.77..<16.61:
            return ("Full Moon", "moon.circle.fill")
        case 16.61..<22.15:
            return ("Waning Gibbous", "moon.haze.fill")
        case 22.15..<24.0:
            return ("Last Quarter", "moon.zzz.fill")
        default:
            return ("Waning Crescent", "moon.stars.fill")
        }
    }

    /// Target phase types for nextPhaseDate
    enum TargetPhase {
        case newMoon       // age ~0
        case firstQuarter  // age ~7.38
        case fullMoon      // age ~14.77
        case lastQuarter   // age ~22.15

        var targetAge: Double {
            switch self {
            case .newMoon: return 0.0
            case .firstQuarter: return 7.38
            case .fullMoon: return 14.77
            case .lastQuarter: return 22.15
            }
        }
    }

    /// Calculate the date string for the next occurrence of a target phase
    static func nextPhaseDate(target: TargetPhase, from date: Date = Date()) -> String {
        let current = phase(for: date)
        var daysUntil = target.targetAge - current.age
        if daysUntil <= 0.5 {
            daysUntil += synodicMonth
        }

        let targetDate = date.addingTimeInterval(daysUntil * 86400)
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: targetDate)
    }

    /// Moonrise/set approximation (simplified — varies by location)
    /// Returns (rise, set) as hours offset from midnight
    static func approximateMoonTimes(phase: MoonPhase) -> (riseHour: Double, setHour: Double) {
        // New moon rises/sets with the sun (~6am/6pm)
        // Full moon rises at sunset, sets at sunrise (~18/6)
        // First quarter rises at noon, sets at midnight (~12/0)
        // Last quarter rises at midnight, sets at noon (~0/12)
        let baseRise = phase.phase * 24.0  // shifts through the day with phase
        let riseHour = baseRise.truncatingRemainder(dividingBy: 24.0)
        let setHour = (riseHour + 12.0).truncatingRemainder(dividingBy: 24.0)
        return (riseHour, setHour)
    }
}
