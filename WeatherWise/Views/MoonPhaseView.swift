import SwiftUI

/// Draws a realistic moon disc showing the current illumination and phase.
struct MoonPhaseView: View {
    let phase: MoonPhase

    var body: some View {
        Canvas { context, size in
            let diameter = min(size.width, size.height)
            let radius = diameter / 2
            let center = CGPoint(x: size.width / 2, y: size.height / 2)

            // Full moon disc (lit side)
            let moonRect = CGRect(
                x: center.x - radius,
                y: center.y - radius,
                width: diameter,
                height: diameter
            )
            let moonPath = Path(ellipseIn: moonRect)

            // Gradient for the lit surface
            let litGradient = Gradient(colors: [
                Color(red: 0.85, green: 0.83, blue: 0.78),
                Color(red: 0.75, green: 0.73, blue: 0.68)
            ])
            context.fill(
                moonPath,
                with: .linearGradient(
                    litGradient,
                    startPoint: CGPoint(x: center.x - radius, y: center.y - radius),
                    endPoint: CGPoint(x: center.x + radius, y: center.y + radius)
                )
            )

            // Shadow overlay for unlit portion
            let shadowPath = moonShadowPath(center: center, radius: radius)
            context.fill(
                shadowPath,
                with: .color(Color(red: 0.06, green: 0.06, blue: 0.14).opacity(0.92))
            )

            // Subtle crater-like texture dots
            drawCraters(context: &context, center: center, radius: radius)

            // Soft outer glow
            context.stroke(
                moonPath,
                with: .color(.white.opacity(0.08)),
                lineWidth: 2
            )
        }
    }

    /// Build the shadow path that covers the unlit part of the moon.
    private func moonShadowPath(center: CGPoint, radius: CGFloat) -> Path {
        let phaseValue = phase.phase // 0 = new, 0.5 = full, 1 = new again

        // terminatorX: -1 = fully shadowed (new), 0 = half, +1 = fully lit (full)
        let terminatorX: CGFloat
        if phaseValue <= 0.5 {
            // Waxing: shadow shrinks from right to left
            terminatorX = CGFloat(phaseValue * 2.0 - 1.0) // -1 → 0
        } else {
            // Waning: shadow grows from right to left
            terminatorX = CGFloat((1.0 - phaseValue) * 2.0 - 1.0) // 0 → -1
        }

        var path = Path()
        let steps = 64

        if phaseValue <= 0.5 {
            // Waxing: shadow on the LEFT side
            // Left arc of the moon (always in shadow during waxing)
            for i in 0...steps {
                let angle = CGFloat.pi / 2 + CGFloat(i) / CGFloat(steps) * CGFloat.pi
                let x = center.x + radius * cos(angle)
                let y = center.y + radius * sin(angle)
                if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                else { path.addLine(to: CGPoint(x: x, y: y)) }
            }
            // Terminator line (elliptical edge of shadow)
            for i in (0...steps).reversed() {
                let t = CGFloat(i) / CGFloat(steps)
                let angle = CGFloat.pi / 2 + t * CGFloat.pi
                let y = center.y + radius * sin(angle)
                let x = center.x + terminatorX * radius * cos(angle)
                path.addLine(to: CGPoint(x: x, y: y))
            }
            path.closeSubpath()
        } else {
            // Waning: shadow on the RIGHT side
            // Right arc of the moon
            for i in 0...steps {
                let angle = -CGFloat.pi / 2 + CGFloat(i) / CGFloat(steps) * CGFloat.pi
                let x = center.x + radius * cos(angle)
                let y = center.y + radius * sin(angle)
                if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                else { path.addLine(to: CGPoint(x: x, y: y)) }
            }
            // Terminator
            for i in (0...steps).reversed() {
                let t = CGFloat(i) / CGFloat(steps)
                let angle = -CGFloat.pi / 2 + t * CGFloat.pi
                let y = center.y + radius * sin(angle)
                let x = center.x - terminatorX * radius * cos(angle)
                path.addLine(to: CGPoint(x: x, y: y))
            }
            path.closeSubpath()
        }

        // Clip to moon circle
        let clipPath = Path(ellipseIn: CGRect(
            x: center.x - radius,
            y: center.y - radius,
            width: radius * 2,
            height: radius * 2
        ))
        return path.intersection(clipPath)
    }

    /// Draw subtle crater marks for texture.
    private func drawCraters(context: inout GraphicsContext, center: CGPoint, radius: CGFloat) {
        let craters: [(dx: CGFloat, dy: CGFloat, r: CGFloat)] = [
            (-0.25, -0.15, 0.08),
            (0.1, -0.3, 0.06),
            (0.2, 0.15, 0.1),
            (-0.1, 0.25, 0.05),
            (0.3, -0.1, 0.04),
            (-0.3, 0.05, 0.07),
            (0.05, 0.05, 0.12),
        ]

        for crater in craters {
            let cx = center.x + crater.dx * radius
            let cy = center.y + crater.dy * radius
            let cr = crater.r * radius
            let craterPath = Path(ellipseIn: CGRect(
                x: cx - cr, y: cy - cr,
                width: cr * 2, height: cr * 2
            ))
            context.fill(
                craterPath,
                with: .color(.black.opacity(0.08))
            )
        }
    }
}

#Preview {
    ZStack {
        Color(red: 0.06, green: 0.06, blue: 0.14)
            .ignoresSafeArea()

        VStack(spacing: 20) {
            MoonPhaseView(phase: MoonPhaseCalculator.currentPhase())
                .frame(width: 120, height: 120)

            // Show a few phases for testing
            HStack(spacing: 16) {
                ForEach([0.0, 0.125, 0.25, 0.5, 0.75, 0.9], id: \.self) { age in
                    let fakeMoon = MoonPhaseCalculator.phase(for: Date(timeIntervalSince1970: 947182440.0 + age * 29.53059 * 86400))
                    MoonPhaseView(phase: fakeMoon)
                        .frame(width: 50, height: 50)
                }
            }
        }
    }
}
