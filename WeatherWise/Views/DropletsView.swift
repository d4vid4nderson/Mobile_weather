import SwiftUI

// MARK: - Combined Steam + Droplets Effect

struct DropletsView: View {
    let humidity: Int

    private var dropletCount: Int {
        switch humidity {
        case 75..<85: return 12
        case 85..<95: return 20
        default: return 30
        }
    }

    private var steamCount: Int {
        switch humidity {
        case 75..<85: return 4
        case 85..<95: return 6
        default: return 8
        }
    }

    @State private var droplets: [WaterDroplet] = []
    @State private var steamPuffs: [SteamPuff] = []

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height

            ZStack {
                // Steam layer (behind droplets)
                steamLayer(width: width, height: height)

                // Droplets layer
                dropletsLayer(width: width, height: height)
            }
            .onAppear {
                generateParticles(width: width, height: height)
            }
            .onChange(of: geo.size) { _, newSize in
                generateParticles(width: newSize.width, height: newSize.height)
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Droplets (falling)

    private func dropletsLayer(width: CGFloat, height: CGFloat) -> some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            Canvas { context, size in
                let elapsed = timeline.date.timeIntervalSinceReferenceDate

                for drop in droplets {
                    let cycle = Double(height + 60) / Double(drop.speed * 60)
                    guard cycle > 0 else { continue }
                    let raw = (elapsed - drop.delay).truncatingRemainder(dividingBy: cycle)
                    let progress = raw >= 0 ? raw / cycle : (raw + cycle) / cycle

                    let currentY = -30 + CGFloat(progress) * (height + 60)
                    let wobbleX = sin(CGFloat(progress) * .pi * 2.5) * drop.wobble
                    let currentX = drop.x + wobbleX

                    // Teardrop shape via two ellipses
                    let bodyW = drop.size * 0.5
                    let bodyH = drop.size * 1.2

                    // Main body
                    let bodyRect = CGRect(
                        x: currentX - bodyW / 2,
                        y: currentY - bodyH / 2,
                        width: bodyW,
                        height: bodyH
                    )

                    let fadeOut = 1.0 - Double(progress) * 0.4
                    context.opacity = drop.opacity * fadeOut

                    // Drop body gradient
                    context.fill(
                        Path(ellipseIn: bodyRect),
                        with: .linearGradient(
                            Gradient(colors: [
                                Color(red: 0.7, green: 0.85, blue: 1.0, opacity: 0.7),
                                Color(red: 0.3, green: 0.6, blue: 0.9, opacity: 0.4)
                            ]),
                            startPoint: CGPoint(x: bodyRect.minX, y: bodyRect.minY),
                            endPoint: CGPoint(x: bodyRect.maxX, y: bodyRect.maxY)
                        )
                    )

                    // Pointed top (teardrop tip)
                    var tipPath = Path()
                    tipPath.move(to: CGPoint(x: currentX, y: currentY - bodyH / 2 - drop.size * 0.3))
                    tipPath.addQuadCurve(
                        to: CGPoint(x: currentX + bodyW / 2, y: currentY - bodyH * 0.1),
                        control: CGPoint(x: currentX + bodyW * 0.1, y: currentY - bodyH / 2)
                    )
                    tipPath.addQuadCurve(
                        to: CGPoint(x: currentX, y: currentY - bodyH / 2 - drop.size * 0.3),
                        control: CGPoint(x: currentX - bodyW * 0.1, y: currentY - bodyH / 2)
                    )
                    context.fill(tipPath, with: .color(Color(red: 0.5, green: 0.75, blue: 1.0, opacity: 0.5)))

                    // Highlight reflection
                    let hlSize = drop.size * 0.18
                    let hlRect = CGRect(
                        x: currentX - bodyW * 0.15,
                        y: currentY - bodyH * 0.2,
                        width: hlSize,
                        height: hlSize * 1.3
                    )
                    context.opacity = drop.opacity * 0.9
                    context.fill(Path(ellipseIn: hlRect), with: .color(.white.opacity(0.7)))
                }
            }
        }
    }

    // MARK: - Steam (rising wisps)

    private func steamLayer(width: CGFloat, height: CGFloat) -> some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { timeline in
            Canvas { context, size in
                let elapsed = timeline.date.timeIntervalSinceReferenceDate

                for puff in steamPuffs {
                    let cycle = puff.riseDuration
                    guard cycle > 0 else { continue }
                    let raw = (elapsed - puff.delay).truncatingRemainder(dividingBy: cycle)
                    let progress = raw >= 0 ? raw / cycle : (raw + cycle) / cycle

                    // Rise from bottom, expanding and fading
                    let startY = height + 20
                    let currentY = startY - CGFloat(progress) * (height * 0.7)
                    let driftX = sin(CGFloat(progress) * .pi * 1.5 + puff.phase) * puff.drift
                    let currentX = puff.x + driftX

                    // Expand as it rises
                    let scale = 1.0 + CGFloat(progress) * 2.0
                    let currentSize = puff.size * scale

                    // Fade out as it rises
                    let fadeIn = min(CGFloat(progress) * 4.0, 1.0)
                    let fadeOut = max(1.0 - CGFloat(progress), 0)
                    let alpha = Double(fadeIn * fadeOut) * puff.opacity

                    guard alpha > 0.01 else { continue }

                    // Soft blurred circle
                    let puffRect = CGRect(
                        x: currentX - currentSize / 2,
                        y: currentY - currentSize / 2,
                        width: currentSize,
                        height: currentSize * 0.7
                    )

                    context.opacity = alpha
                    context.fill(
                        Path(ellipseIn: puffRect),
                        with: .radialGradient(
                            Gradient(colors: [
                                Color.white.opacity(0.15),
                                Color.white.opacity(0.05),
                                Color.white.opacity(0.0)
                            ]),
                            center: CGPoint(x: puffRect.midX, y: puffRect.midY),
                            startRadius: 0,
                            endRadius: currentSize / 2
                        )
                    )

                    // Secondary smaller wisp
                    let smallRect = CGRect(
                        x: currentX - currentSize * 0.3 + driftX * 0.5,
                        y: currentY - currentSize * 0.15,
                        width: currentSize * 0.5,
                        height: currentSize * 0.35
                    )
                    context.opacity = alpha * 0.6
                    context.fill(
                        Path(ellipseIn: smallRect),
                        with: .radialGradient(
                            Gradient(colors: [
                                Color.white.opacity(0.12),
                                Color.white.opacity(0.0)
                            ]),
                            center: CGPoint(x: smallRect.midX, y: smallRect.midY),
                            startRadius: 0,
                            endRadius: currentSize * 0.25
                        )
                    )
                }
            }
        }
    }

    // MARK: - Generation

    private func generateParticles(width: CGFloat, height: CGFloat) {
        guard width > 0 else { return }

        droplets = (0..<dropletCount).map { _ in
            WaterDroplet(
                x: CGFloat.random(in: 10...(width - 10)),
                size: CGFloat.random(in: 6...14),
                opacity: Double.random(in: 0.2...0.5),
                speed: CGFloat.random(in: 1.0...3.5),
                delay: Double.random(in: 0...10),
                wobble: CGFloat.random(in: 1...3)
            )
        }

        steamPuffs = (0..<steamCount).map { _ in
            SteamPuff(
                x: CGFloat.random(in: 20...(width - 20)),
                size: CGFloat.random(in: 40...80),
                opacity: Double.random(in: 0.3...0.6),
                riseDuration: Double.random(in: 6...12),
                delay: Double.random(in: 0...10),
                drift: CGFloat.random(in: 15...40),
                phase: CGFloat.random(in: 0...(2 * .pi))
            )
        }
    }
}

// MARK: - Particle Models

private struct WaterDroplet: Identifiable {
    let id = UUID()
    let x: CGFloat
    let size: CGFloat
    let opacity: Double
    let speed: CGFloat
    let delay: Double
    let wobble: CGFloat
}

private struct SteamPuff: Identifiable {
    let id = UUID()
    let x: CGFloat
    let size: CGFloat
    let opacity: Double
    let riseDuration: Double
    let delay: Double
    let drift: CGFloat
    let phase: CGFloat
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [.blue, .indigo],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        DropletsView(humidity: 90)
    }
}
