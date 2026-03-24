import SwiftUI

/// Arc visualization of the moon's phase cycle, similar to SunArcView.
/// Shows the moon's position along its ~29.5-day lunation arc.
struct MoonArcView: View {
    let phase: MoonPhase
    let timezoneOffset: Int

    // Phase positions on the arc (0...1)
    private let newMoonX: CGFloat = 0.0
    private let firstQuarterX: CGFloat = 0.25
    private let fullMoonX: CGFloat = 0.5
    private let lastQuarterX: CGFloat = 0.75
    private let nextNewMoonX: CGFloat = 1.0

    /// Current position along the arc (0...1)
    private var currentX: CGFloat {
        CGFloat(phase.phase).clamped(to: 0...1)
    }

    /// Y position on the arc for a given x (0...1)
    private func arcY(at x: CGFloat, in rect: CGRect) -> CGFloat {
        let horizonY = rect.midY
        let amplitude = rect.height * 0.38
        // Above horizon from new moon to full moon (waxing), below from full to new (waning)
        // Peak at full moon (x=0.5)
        return horizonY - amplitude * sin(x * .pi)
    }

    var body: some View {
        GeometryReader { geo in
            let rect = geo.frame(in: .local)
            let horizonY = rect.midY

            if rect.width > 1 && rect.height > 1 {
                ZStack {
                    // Illumination gradient fill (above horizon during waxing)
                    illuminationFill(rect: rect)

                    // Horizon line
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: horizonY))
                        path.addLine(to: CGPoint(x: rect.width, y: horizonY))
                    }
                    .stroke(Color.onGradientSecondary.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [6, 4]))

                    // Moon arc curve
                    arcPath(rect: rect)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.blue.opacity(0.4),
                                    Color.white.opacity(0.8),
                                    Color.yellow.opacity(0.6),
                                    Color.white.opacity(0.8),
                                    Color.blue.opacity(0.4)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 2.5
                        )

                    // Phase markers
                    phaseMarker(x: newMoonX, rect: rect, label: "New", icon: "moon.fill")
                    phaseMarker(x: firstQuarterX, rect: rect, label: "1st Qtr", icon: "moon.zzz.fill")
                    phaseMarker(x: fullMoonX, rect: rect, label: "Full", icon: "moon.circle.fill")
                    phaseMarker(x: lastQuarterX, rect: rect, label: "3rd Qtr", icon: "moon.zzz.fill")

                    // Current position
                    currentPositionDot(rect: rect)

                    // Labels
                    labels(rect: rect, horizonY: horizonY)
                }
            }
        }
        .frame(height: 200)
        .padding(.horizontal, 4)
    }

    // MARK: - Illumination Fill

    private func illuminationFill(rect: CGRect) -> some View {
        let horizonY = rect.midY

        return Path { path in
            let steps = 60
            path.move(to: CGPoint(x: 0, y: horizonY))

            for i in 0...steps {
                let frac = CGFloat(i) / CGFloat(steps)
                let px = frac * rect.width
                let py = arcY(at: frac, in: rect)
                if py < horizonY {
                    path.addLine(to: CGPoint(x: px, y: py))
                } else {
                    path.addLine(to: CGPoint(x: px, y: horizonY))
                }
            }

            path.addLine(to: CGPoint(x: rect.width, y: horizonY))
            path.closeSubpath()
        }
        .fill(
            LinearGradient(
                colors: [Color.blue.opacity(0.08), Color.white.opacity(0.12)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    // MARK: - Arc Path

    private func arcPath(rect: CGRect) -> Path {
        Path { path in
            let steps = 80
            var started = false
            for i in 0...steps {
                let frac = CGFloat(i) / CGFloat(steps)
                let px = frac * rect.width
                let py = arcY(at: frac, in: rect)
                if !started {
                    path.move(to: CGPoint(x: px, y: py))
                    started = true
                } else {
                    path.addLine(to: CGPoint(x: px, y: py))
                }
            }
        }
    }

    // MARK: - Phase Markers

    private func phaseMarker(x: CGFloat, rect: CGRect, label: String, icon: String) -> some View {
        let px = x * rect.width
        let py = arcY(at: x, in: rect)

        return VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(Color.onGradientSecondary)
            Text(label)
                .font(.system(size: 8, weight: .medium))
                .foregroundStyle(Color.onGradientSecondary)
        }
        .position(x: px.clamped(to: 0...max(rect.width, 1)), y: py + 22)
    }

    // MARK: - Current Position

    private func currentPositionDot(rect: CGRect) -> some View {
        let px = currentX * rect.width
        let py = arcY(at: currentX, in: rect)
        let aboveHorizon = py <= rect.midY

        return ZStack {
            // Glow
            Circle()
                .fill(aboveHorizon ? Color.white.opacity(0.3) : Color.blue.opacity(0.2))
                .frame(width: 24, height: 24)

            // Dot
            Circle()
                .fill(aboveHorizon ? Color.white.opacity(0.9) : Color.blue.opacity(0.5))
                .frame(width: 12, height: 12)

            // Moon icon
            Image(systemName: phase.icon)
                .font(.system(size: 7))
                .foregroundStyle(aboveHorizon ? .yellow : .white)
        }
        .position(x: px, y: py)
    }

    // MARK: - Labels

    private func labels(rect: CGRect, horizonY: CGFloat) -> some View {
        ZStack {
            // Illumination percentage at the top
            Text("\(Int(phase.illumination * 100))%")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color.onGradientPrimary.opacity(0.6))
                .position(x: rect.width / 2, y: horizonY - rect.height * 0.36)

            // "WAXING" / "WANING" labels
            if phase.phase < 0.5 {
                Text("WAXING")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Color.accentNow.opacity(0.7))
                    .position(x: rect.width * 0.25, y: horizonY - rect.height * 0.18)
            } else {
                Text("WANING")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Color.accentRain.opacity(0.6))
                    .position(x: rect.width * 0.75, y: horizonY - rect.height * 0.18)
            }

            // Horizon label
            Text("HORIZON")
                .font(.system(size: 8, weight: .medium))
                .foregroundStyle(Color.onGradientSecondary.opacity(0.5))
                .position(x: rect.width - 30, y: horizonY - 10)
        }
    }
}

// MARK: - Clamping

private extension CGFloat {
    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
