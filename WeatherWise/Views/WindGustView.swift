import SwiftUI

struct WindGustView: View {
    let windSpeed: Double // in mph

    private var streakCount: Int {
        switch windSpeed {
        case 0..<8: return 8
        case 8..<20: return 15
        case 20..<40: return 25
        default: return 35
        }
    }

    private var speedMultiplier: CGFloat {
        switch windSpeed {
        case 0..<8: return 0.6
        case 8..<20: return 1.0
        case 20..<40: return 1.5
        default: return 2.0
        }
    }

    @State private var streaks: [WindStreak] = []
    @State private var particles: [WindParticle] = []

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                Canvas { context, size in
                    let elapsed = timeline.date.timeIntervalSinceReferenceDate

                    // Wind streaks (horizontal lines blowing left to right)
                    for streak in streaks {
                        let speed = streak.speed * speedMultiplier
                        let cycle = Double(w + streak.length + 40) / Double(speed * 60)
                        guard cycle > 0 else { continue }
                        let raw = (elapsed - streak.delay).truncatingRemainder(dividingBy: cycle)
                        let progress = raw >= 0 ? raw / cycle : (raw + cycle) / cycle

                        let x = -streak.length - 20 + CGFloat(progress) * (w + streak.length + 40)
                        // Slight vertical wave
                        let waveY = sin(CGFloat(progress) * .pi * 2 + streak.phase) * streak.wave
                        let y = streak.y + waveY

                        // Tapered streak: thin at leading edge, fading at trailing edge
                        var path = Path()
                        path.move(to: CGPoint(x: x, y: y))
                        path.addLine(to: CGPoint(x: x + streak.length, y: y))

                        // Fade: strongest in middle, transparent at ends
                        let midX = x + streak.length / 2
                        context.opacity = streak.opacity
                        context.stroke(
                            path,
                            with: .linearGradient(
                                Gradient(colors: [
                                    Color.white.opacity(0.0),
                                    Color.white.opacity(0.4),
                                    Color.white.opacity(0.5),
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.0)
                                ]),
                                startPoint: CGPoint(x: x, y: y),
                                endPoint: CGPoint(x: x + streak.length, y: y)
                            ),
                            lineWidth: streak.thickness
                        )
                    }

                    // Small dust/leaf particles
                    for particle in particles {
                        let speed = particle.speed * speedMultiplier
                        let cycle = Double(w + 40) / Double(speed * 60)
                        guard cycle > 0 else { continue }
                        let raw = (elapsed - particle.delay).truncatingRemainder(dividingBy: cycle)
                        let progress = raw >= 0 ? raw / cycle : (raw + cycle) / cycle

                        let x = -20 + CGFloat(progress) * (w + 40)
                        let tumble = sin(CGFloat(progress) * .pi * particle.tumbleFreq + particle.phase)
                        let y = particle.y + tumble * particle.drift

                        let s = particle.size
                        let rect = CGRect(x: x - s/2, y: y - s/2, width: s, height: s * 0.6)

                        // Rotation based on tumble
                        var transform = CGAffineTransform.identity
                            .translatedBy(x: rect.midX, y: rect.midY)
                            .rotated(by: tumble * .pi * 0.5)
                            .translatedBy(x: -rect.midX, y: -rect.midY)

                        var rotatedPath = Path(ellipseIn: rect)
                        rotatedPath = rotatedPath.applying(transform)

                        context.opacity = particle.opacity * (1.0 - abs(Double(tumble) * 0.3))
                        context.fill(
                            rotatedPath,
                            with: .color(.white.opacity(0.35))
                        )
                    }
                }
            }
            .onAppear { generate(width: w, height: h) }
            .onChange(of: geo.size) { _, s in generate(width: s.width, height: s.height) }
        }
        .allowsHitTesting(false)
    }

    private func generate(width: CGFloat, height: CGFloat) {
        guard width > 0, height > 0 else { return }

        streaks = (0..<streakCount).map { _ in
            WindStreak(
                y: CGFloat.random(in: 20...(height - 20)),
                length: CGFloat.random(in: 40...120),
                thickness: CGFloat.random(in: 0.5...1.5),
                speed: CGFloat.random(in: 3...8),
                opacity: Double.random(in: 0.1...0.3),
                delay: Double.random(in: 0...6),
                wave: CGFloat.random(in: 2...8),
                phase: CGFloat.random(in: 0...(2 * .pi))
            )
        }

        particles = (0..<(streakCount / 2)).map { _ in
            WindParticle(
                y: CGFloat.random(in: 40...(height - 40)),
                size: CGFloat.random(in: 3...7),
                speed: CGFloat.random(in: 4...10),
                opacity: Double.random(in: 0.15...0.4),
                delay: Double.random(in: 0...8),
                drift: CGFloat.random(in: 10...30),
                tumbleFreq: CGFloat.random(in: 2...5),
                phase: CGFloat.random(in: 0...(2 * .pi))
            )
        }
    }
}

private struct WindStreak {
    let y: CGFloat
    let length: CGFloat
    let thickness: CGFloat
    let speed: CGFloat
    let opacity: Double
    let delay: Double
    let wave: CGFloat
    let phase: CGFloat
}

private struct WindParticle {
    let y: CGFloat
    let size: CGFloat
    let speed: CGFloat
    let opacity: Double
    let delay: Double
    let drift: CGFloat
    let tumbleFreq: CGFloat
    let phase: CGFloat
}

#Preview {
    ZStack {
        LinearGradient(colors: [.blue, .indigo], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
        WindGustView(windSpeed: 25)
    }
}
