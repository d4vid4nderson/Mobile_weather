import Foundation

/// Moon phase data for widget display
struct WidgetMoonPhase {
    let name: String
    let icon: String          // SF Symbol
    let illumination: Double  // 0.0 to 1.0
    let age: Double           // days into the lunation cycle (0 = new moon)
    let phase: Double         // 0.0 to 1.0 through the cycle

    var isWaxing: Bool {
        age < 14.77
    }
}

/// Calculates moon phase for widget display.
/// Mirrors the main app's MoonPhaseCalculator.
enum WidgetMoonCalculator {
    static let synodicMonth: Double = 29.53059
    static let referenceNewMoon: Double = 947182440.0 // Jan 6, 2000 18:14 UTC

    static func currentPhase(date: Date = Date()) -> WidgetMoonPhase {
        let timestamp = date.timeIntervalSince1970
        let daysSinceRef = (timestamp - referenceNewMoon) / 86400.0
        let age = daysSinceRef.truncatingRemainder(dividingBy: synodicMonth)
        let normalizedAge = age < 0 ? age + synodicMonth : age
        let phaseValue = normalizedAge / synodicMonth

        let illumination = (1.0 - cos(phaseValue * 2.0 * .pi)) / 2.0
        let (name, icon) = phaseNameAndIcon(age: normalizedAge)

        return WidgetMoonPhase(
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

    enum TargetPhase {
        case newMoon, firstQuarter, fullMoon, lastQuarter

        var targetAge: Double {
            switch self {
            case .newMoon: return 0.0
            case .firstQuarter: return 7.38
            case .fullMoon: return 14.77
            case .lastQuarter: return 22.15
            }
        }

        var name: String {
            switch self {
            case .newMoon: return "New Moon"
            case .firstQuarter: return "First Quarter"
            case .fullMoon: return "Full Moon"
            case .lastQuarter: return "Last Quarter"
            }
        }

        var icon: String {
            switch self {
            case .newMoon: return "moon.fill"
            case .firstQuarter: return "moon.zzz.fill"
            case .fullMoon: return "moon.circle.fill"
            case .lastQuarter: return "moon.zzz.fill"
            }
        }
    }

    static func nextPhaseDate(target: TargetPhase, from date: Date = Date()) -> Date {
        let current = currentPhase(date: date)
        var daysUntil = target.targetAge - current.age
        if daysUntil <= 0.5 {
            daysUntil += synodicMonth
        }
        return date.addingTimeInterval(daysUntil * 86400)
    }

    static func nextPhaseDateString(target: TargetPhase, from date: Date = Date()) -> String {
        let targetDate = nextPhaseDate(target: target, from: date)
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: targetDate)
    }

    static func daysUntilNextPhase(target: TargetPhase, from date: Date = Date()) -> Int {
        let targetDate = nextPhaseDate(target: target, from: date)
        let days = targetDate.timeIntervalSince(date) / 86400.0
        return max(1, Int(ceil(days)))
    }
}
