import SwiftUI

/// Draws a realistic moon disc showing the current illumination and phase.
struct MoonPhaseView: View {
    let phase: MoonPhase

    var body: some View {
        Canvas { context, size in
            let diameter = min(size.width, size.height)
            let radius = diameter / 2
            let center = CGPoint(x: size.width / 2, y: size.height / 2)

            let moonRect = CGRect(
                x: center.x - radius,
                y: center.y - radius,
                width: diameter,
                height: diameter
            )
            let moonPath = Path(ellipseIn: moonRect)

            // Draw the dark base (unlit moon)
            context.fill(
                moonPath,
                with: .color(Color(red: 0.08, green: 0.08, blue: 0.16))
            )

            // Draw the lit portion
            let litPath = moonLitPath(center: center, radius: radius)
            let litGradient = Gradient(colors: [
                Color(red: 0.9, green: 0.88, blue: 0.82),
                Color(red: 0.78, green: 0.76, blue: 0.70)
            ])
            context.fill(
                litPath,
                with: .linearGradient(
                    litGradient,
                    startPoint: CGPoint(x: center.x - radius, y: center.y - radius),
                    endPoint: CGPoint(x: center.x + radius, y: center.y + radius)
                )
            )

            // Subtle craters on lit portion only
            drawCraters(context: &context, center: center, radius: radius)

            // Soft rim highlight
            context.stroke(
                moonPath,
                with: .color(.white.opacity(0.12)),
                lineWidth: 1.5
            )
        }
    }

    /// Build the lit portion of the moon.
    ///
    /// The lit shape is bounded by the circular edge on one side
    /// and an elliptical terminator on the other. The terminator's
    /// x-radius varies from +radius (full) through 0 (quarter) to
    /// -radius (new).
    private func moonLitPath(center: CGPoint, radius: CGFloat) -> Path {
        let phaseValue = phase.phase // 0.0 = new moon, 0.5 = full, 1.0 = new again

        // Convert phase to a terminator position:
        // terminatorFraction: -1 = new (no lit), 0 = quarter, +1 = full
        let terminatorFraction: CGFloat
        if phaseValue <= 0.5 {
            // Waxing: 0→0.5 maps to -1→+1
            terminatorFraction = CGFloat(phaseValue * 4.0 - 1.0)
        } else {
            // Waning: 0.5→1 maps to +1→-1
            terminatorFraction = CGFloat((1.0 - phaseValue) * 4.0 - 1.0)
        }

        let steps = 90
        var path = Path()

        if phaseValue <= 0.5 {
            // Waxing: lit on the RIGHT side
            // Right circular arc from top to bottom
            for i in 0...steps {
                let t = CGFloat(i) / CGFloat(steps)
                let angle = -CGFloat.pi / 2 + t * CGFloat.pi  // -90° to +90°
                let x = center.x + radius * cos(angle)
                let y = center.y + radius * sin(angle)
                if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                else { path.addLine(to: CGPoint(x: x, y: y)) }
            }
            // Terminator from bottom back to top (elliptical)
            for i in (0...steps).reversed() {
                let t = CGFloat(i) / CGFloat(steps)
                let angle = -CGFloat.pi / 2 + t * CGFloat.pi
                let y = center.y + radius * sin(angle)
                let x = center.x + terminatorFraction * radius * cos(angle)
                path.addLine(to: CGPoint(x: x, y: y))
            }
            path.closeSubpath()
        } else {
            // Waning: lit on the LEFT side
            // Left circular arc from top to bottom
            for i in 0...steps {
                let t = CGFloat(i) / CGFloat(steps)
                let angle = CGFloat.pi / 2 + t * CGFloat.pi  // 90° to 270°
                let x = center.x + radius * cos(angle)
                let y = center.y + radius * sin(angle)
                if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                else { path.addLine(to: CGPoint(x: x, y: y)) }
            }
            // Terminator from bottom back to top
            for i in (0...steps).reversed() {
                let t = CGFloat(i) / CGFloat(steps)
                let angle = CGFloat.pi / 2 + t * CGFloat.pi
                let y = center.y + radius * sin(angle)
                let x = center.x - terminatorFraction * radius * cos(angle)
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
            (-0.22, -0.18, 0.07),
            (0.12, -0.32, 0.05),
            (0.22, 0.12, 0.09),
            (-0.08, 0.28, 0.04),
            (0.32, -0.08, 0.035),
            (-0.28, 0.08, 0.06),
            (0.04, 0.02, 0.11),
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
                with: .color(.black.opacity(0.06))
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
