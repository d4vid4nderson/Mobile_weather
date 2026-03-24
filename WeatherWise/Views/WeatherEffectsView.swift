import SwiftUI

// MARK: - Weather Effect Type

enum WeatherEffect {
    case rain(intensity: Intensity)
    case hail
    case snow(intensity: Intensity)
    case thunderstorm
    case drizzle
    case none

    enum Intensity {
        case light, moderate, heavy
    }

    static func from(conditionId: Int) -> WeatherEffect {
        switch conditionId {
        // Thunderstorm (2xx)
        case 200...232:
            return .thunderstorm
        // Drizzle (3xx)
        case 300...321:
            return .drizzle
        // Rain (5xx)
        case 500:
            return .rain(intensity: .light)
        case 501:
            return .rain(intensity: .moderate)
        case 502...504:
            return .rain(intensity: .heavy)
        case 511:
            return .hail // freezing rain treated as hail
        case 520:
            return .rain(intensity: .light)
        case 521:
            return .rain(intensity: .moderate)
        case 522, 531:
            return .rain(intensity: .heavy)
        // Snow (6xx)
        case 600:
            return .snow(intensity: .light)
        case 601:
            return .snow(intensity: .moderate)
        case 602:
            return .snow(intensity: .heavy)
        case 611...616:
            return .hail // sleet
        case 620:
            return .snow(intensity: .light)
        case 621:
            return .snow(intensity: .moderate)
        case 622:
            return .snow(intensity: .heavy)
        default:
            return .none
        }
    }
}

// MARK: - Weather Effects View

struct WeatherEffectsView: View {
    let conditionId: Int

    private var effect: WeatherEffect {
        WeatherEffect.from(conditionId: conditionId)
    }

    var body: some View {
        switch effect {
        case .rain(let intensity):
            RainEffectCanvas(intensity: intensity)
        case .hail:
            HailEffectCanvas()
        case .snow(let intensity):
            SnowEffectCanvas(intensity: intensity)
        case .thunderstorm:
            ZStack {
                RainEffectCanvas(intensity: .heavy)
                LightningEffectView()
            }
        case .drizzle:
            RainEffectCanvas(intensity: .light)
        case .none:
            Color.clear
        }
    }
}

// MARK: - Rain Effect

private struct RainEffectCanvas: View {
    let intensity: WeatherEffect.Intensity

    private var dropCount: Int {
        switch intensity {
        case .light: return 40
        case .moderate: return 80
        case .heavy: return 140
        }
    }

    private var speedRange: ClosedRange<CGFloat> {
        switch intensity {
        case .light: return 4...8
        case .moderate: return 7...12
        case .heavy: return 10...18
        }
    }

    private var sizeRange: ClosedRange<CGFloat> {
        switch intensity {
        case .light: return 8...18
        case .moderate: return 12...25
        case .heavy: return 15...35
        }
    }

    @State private var drops: [RainDrop] = []

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                Canvas { context, size in
                    let elapsed = timeline.date.timeIntervalSinceReferenceDate

                    for drop in drops {
                        let cycle = Double(h + 60) / Double(drop.speed * 60)
                        guard cycle > 0 else { continue }
                        let raw = (elapsed - drop.delay).truncatingRemainder(dividingBy: cycle)
                        let progress = raw >= 0 ? raw / cycle : (raw + cycle) / cycle

                        let y = -30 + CGFloat(progress) * (h + 60)
                        // Rain falls at slight angle
                        let windOffset = CGFloat(progress) * drop.windAngle
                        let x = drop.x + windOffset

                        // Rain streak
                        let streakLen = drop.length
                        var streakPath = Path()
                        streakPath.move(to: CGPoint(x: x, y: y))
                        streakPath.addLine(to: CGPoint(x: x - drop.windAngle * 0.3, y: y - streakLen))

                        context.opacity = drop.opacity
                        context.stroke(
                            streakPath,
                            with: .linearGradient(
                                Gradient(colors: [
                                    Color(white: 0.8, opacity: 0.0),
                                    Color(white: 0.85, opacity: 0.5)
                                ]),
                                startPoint: CGPoint(x: x, y: y - streakLen),
                                endPoint: CGPoint(x: x, y: y)
                            ),
                            lineWidth: drop.width
                        )

                        // Small splash at bottom
                        if y > h - 40 {
                            let splashProgress = (y - (h - 40)) / 40
                            let splashSize = drop.width * 3 * splashProgress
                            let splashRect = CGRect(
                                x: x - splashSize / 2,
                                y: h - 5 - splashSize * 0.3,
                                width: splashSize,
                                height: splashSize * 0.3
                            )
                            context.opacity = drop.opacity * Double(1.0 - splashProgress)
                            context.fill(
                                Path(ellipseIn: splashRect),
                                with: .color(.white.opacity(0.3))
                            )
                        }
                    }
                }
            }
            .onAppear { generateDrops(width: w, height: h) }
            .onChange(of: geo.size) { _, s in generateDrops(width: s.width, height: s.height) }
        }
        .allowsHitTesting(false)
    }

    private func generateDrops(width: CGFloat, height: CGFloat) {
        guard width > 0 else { return }
        drops = (0..<dropCount).map { _ in
            RainDrop(
                x: CGFloat.random(in: -20...(width + 20)),
                speed: CGFloat.random(in: speedRange),
                length: CGFloat.random(in: sizeRange),
                width: CGFloat.random(in: 0.8...2.0),
                opacity: Double.random(in: 0.15...0.5),
                delay: Double.random(in: 0...6),
                windAngle: CGFloat.random(in: 8...20)
            )
        }
    }
}

private struct RainDrop {
    let x: CGFloat
    let speed: CGFloat
    let length: CGFloat
    let width: CGFloat
    let opacity: Double
    let delay: Double
    let windAngle: CGFloat
}

// MARK: - Hail Effect

private struct HailEffectCanvas: View {
    @State private var stones: [HailStone] = []

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                Canvas { context, size in
                    let elapsed = timeline.date.timeIntervalSinceReferenceDate

                    for stone in stones {
                        let cycle = Double(h + 40) / Double(stone.speed * 60)
                        guard cycle > 0 else { continue }
                        let raw = (elapsed - stone.delay).truncatingRemainder(dividingBy: cycle)
                        let progress = raw >= 0 ? raw / cycle : (raw + cycle) / cycle

                        let y = -20 + CGFloat(progress) * (h + 40)
                        let windX = CGFloat(progress) * stone.windAngle
                        let x = stone.x + windX

                        // Tumble rotation
                        let rotation = CGFloat(progress) * .pi * stone.tumbleSpeed

                        let s = stone.size

                        // Irregular hail shape (slightly deformed circle)
                        context.opacity = stone.opacity

                        var transform = CGAffineTransform.identity
                            .translatedBy(x: x, y: y)
                            .rotated(by: rotation)

                        // Main body — slightly squashed circle
                        let bodyRect = CGRect(x: -s/2, y: -s * 0.45, width: s, height: s * 0.9)
                        var bodyPath = Path(ellipseIn: bodyRect)
                        bodyPath = bodyPath.applying(transform)

                        context.fill(bodyPath, with: .linearGradient(
                            Gradient(colors: [
                                Color(white: 0.95, opacity: 0.8),
                                Color(white: 0.75, opacity: 0.5),
                                Color(white: 0.6, opacity: 0.3)
                            ]),
                            startPoint: CGPoint(x: x - s/3, y: y - s/3),
                            endPoint: CGPoint(x: x + s/3, y: y + s/3)
                        ))

                        // Inner highlight
                        let hlRect = CGRect(x: -s * 0.2, y: -s * 0.25, width: s * 0.3, height: s * 0.3)
                        var hlPath = Path(ellipseIn: hlRect)
                        hlPath = hlPath.applying(transform)
                        context.opacity = stone.opacity * 0.7
                        context.fill(hlPath, with: .color(.white.opacity(0.8)))

                        // Bounce at bottom
                        if y > h - 30 {
                            let bounceProgress = (y - (h - 30)) / 30
                            let bounceSize = s * 1.5 * bounceProgress
                            let bounceRect = CGRect(
                                x: x - bounceSize / 2,
                                y: h - 4 - bounceSize * 0.15,
                                width: bounceSize,
                                height: bounceSize * 0.15
                            )
                            context.opacity = Double(1.0 - bounceProgress) * 0.3
                            context.fill(Path(ellipseIn: bounceRect), with: .color(.white.opacity(0.4)))
                        }
                    }
                }
            }
            .onAppear { generateStones(width: w, height: h) }
            .onChange(of: geo.size) { _, s in generateStones(width: s.width, height: s.height) }
        }
        .allowsHitTesting(false)
    }

    private func generateStones(width: CGFloat, height: CGFloat) {
        guard width > 0 else { return }
        stones = (0..<35).map { _ in
            HailStone(
                x: CGFloat.random(in: -10...(width + 10)),
                size: CGFloat.random(in: 5...14),
                speed: CGFloat.random(in: 6...14),
                opacity: Double.random(in: 0.3...0.7),
                delay: Double.random(in: 0...5),
                windAngle: CGFloat.random(in: 5...15),
                tumbleSpeed: CGFloat.random(in: 2...6)
            )
        }
    }
}

private struct HailStone {
    let x: CGFloat
    let size: CGFloat
    let speed: CGFloat
    let opacity: Double
    let delay: Double
    let windAngle: CGFloat
    let tumbleSpeed: CGFloat
}

// MARK: - Snow Effect

private struct SnowEffectCanvas: View {
    let intensity: WeatherEffect.Intensity

    private var flakeCount: Int {
        switch intensity {
        case .light: return 30
        case .moderate: return 60
        case .heavy: return 100
        }
    }

    @State private var flakes: [SnowFlake] = []

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            TimelineView(.animation(minimumInterval: 1.0 / 24.0)) { timeline in
                Canvas { context, size in
                    let elapsed = timeline.date.timeIntervalSinceReferenceDate

                    for flake in flakes {
                        let cycle = Double(h + 40) / Double(flake.speed * 30)
                        guard cycle > 0 else { continue }
                        let raw = (elapsed - flake.delay).truncatingRemainder(dividingBy: cycle)
                        let progress = raw >= 0 ? raw / cycle : (raw + cycle) / cycle

                        let y = -20 + CGFloat(progress) * (h + 40)
                        // Gentle floating drift
                        let driftX = sin(CGFloat(progress) * .pi * 3 + flake.phase) * flake.drift
                        let x = flake.x + driftX

                        let s = flake.size
                        let flakeRect = CGRect(x: x - s/2, y: y - s/2, width: s, height: s)

                        context.opacity = flake.opacity * (1.0 - Double(progress) * 0.2)
                        context.fill(
                            Path(ellipseIn: flakeRect),
                            with: .radialGradient(
                                Gradient(colors: [
                                    .white.opacity(0.9),
                                    .white.opacity(0.3),
                                    .white.opacity(0.0)
                                ]),
                                center: CGPoint(x: x, y: y),
                                startRadius: 0,
                                endRadius: s / 2
                            )
                        )
                    }
                }
            }
            .onAppear { generateFlakes(width: w, height: h) }
            .onChange(of: geo.size) { _, s in generateFlakes(width: s.width, height: s.height) }
        }
        .allowsHitTesting(false)
    }

    private func generateFlakes(width: CGFloat, height: CGFloat) {
        guard width > 0 else { return }
        flakes = (0..<flakeCount).map { _ in
            SnowFlake(
                x: CGFloat.random(in: 0...width),
                size: CGFloat.random(in: 3...10),
                speed: CGFloat.random(in: 0.8...2.5),
                opacity: Double.random(in: 0.3...0.8),
                delay: Double.random(in: 0...8),
                drift: CGFloat.random(in: 10...30),
                phase: CGFloat.random(in: 0...(2 * .pi))
            )
        }
    }
}

private struct SnowFlake {
    let x: CGFloat
    let size: CGFloat
    let speed: CGFloat
    let opacity: Double
    let delay: Double
    let drift: CGFloat
    let phase: CGFloat
}

// MARK: - Lightning Flash Effect

private struct LightningEffectView: View {
    @State private var flashOpacity: Double = 0

    var body: some View {
        Color.white
            .opacity(flashOpacity)
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .onAppear { startFlashing() }
    }

    private func startFlashing() {
        func scheduleFlash() {
            let nextFlash = Double.random(in: 3...8)
            DispatchQueue.main.asyncAfter(deadline: .now() + nextFlash) {
                // Quick double flash
                withAnimation(.easeIn(duration: 0.05)) {
                    flashOpacity = Double.random(in: 0.15...0.35)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                    withAnimation(.easeOut(duration: 0.1)) {
                        flashOpacity = 0
                    }
                    // Second flash
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(.easeIn(duration: 0.04)) {
                            flashOpacity = Double.random(in: 0.1...0.25)
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
                            withAnimation(.easeOut(duration: 0.2)) {
                                flashOpacity = 0
                            }
                        }
                    }
                }
                scheduleFlash()
            }
        }
        scheduleFlash()
    }
}

// MARK: - Preview

#Preview("Rain") {
    ZStack {
        LinearGradient(colors: [.blue, .indigo], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
        WeatherEffectsView(conditionId: 502)
    }
}

#Preview("Hail") {
    ZStack {
        LinearGradient(colors: [.gray, .blue], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
        WeatherEffectsView(conditionId: 511)
    }
}

#Preview("Snow") {
    ZStack {
        LinearGradient(colors: [.blue.opacity(0.5), .white.opacity(0.3)], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
        WeatherEffectsView(conditionId: 601)
    }
}

#Preview("Thunderstorm") {
    ZStack {
        LinearGradient(colors: [.black, .purple.opacity(0.5)], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
        WeatherEffectsView(conditionId: 211)
    }
}
