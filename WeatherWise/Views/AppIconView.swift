import SwiftUI

/// A 1024x1024 app icon view: cloud that morphs into a brain.
/// Use Xcode previews to screenshot this for the app icon asset.
struct AppIconView: View {
    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height

            // MARK: - Background gradient
            let bgRect = CGRect(origin: .zero, size: size)
            let gradient = Gradient(colors: [
                Color(red: 0.15, green: 0.40, blue: 0.85),
                Color(red: 0.08, green: 0.20, blue: 0.55),
                Color(red: 0.05, green: 0.12, blue: 0.35)
            ])
            context.fill(
                Path(roundedRect: bgRect, cornerRadius: 0),
                with: .linearGradient(gradient, startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: w, y: h))
            )

            // MARK: - Subtle radial glow behind icon
            let glowCenter = CGPoint(x: w * 0.5, y: h * 0.48)
            let glowGradient = Gradient(colors: [
                Color.white.opacity(0.12),
                Color.white.opacity(0.03),
                Color.clear
            ])
            context.fill(
                Path(ellipseIn: CGRect(x: w * 0.15, y: h * 0.18, width: w * 0.7, height: h * 0.65)),
                with: .radialGradient(glowGradient, center: glowCenter, startRadius: 0, endRadius: w * 0.4)
            )

            // MARK: - Cloud-brain hybrid shape
            // Left side: cloud puffs. Right side: brain folds.
            let shape = cloudBrainPath(in: size)

            // Shadow
            var shadowContext = context
            shadowContext.translateBy(x: 3, y: 5)
            shadowContext.fill(shape, with: .color(Color.black.opacity(0.25)))

            // Main fill - gradient from cloud-blue (left) to brain-pink (right)
            let shapeGradient = Gradient(colors: [
                Color(red: 0.85, green: 0.92, blue: 1.0),
                Color(red: 0.95, green: 0.88, blue: 0.95),
                Color(red: 0.92, green: 0.82, blue: 0.90)
            ])
            context.fill(shape, with: .linearGradient(shapeGradient, startPoint: CGPoint(x: w * 0.15, y: h * 0.5), endPoint: CGPoint(x: w * 0.85, y: h * 0.5)))

            // Highlight on top
            let highlightGradient = Gradient(colors: [
                Color.white.opacity(0.5),
                Color.white.opacity(0.0)
            ])
            context.fill(shape, with: .linearGradient(highlightGradient, startPoint: CGPoint(x: w * 0.5, y: h * 0.2), endPoint: CGPoint(x: w * 0.5, y: h * 0.55)))

            // Outline
            context.stroke(shape, with: .color(Color.white.opacity(0.4)), lineWidth: w * 0.004)

            // MARK: - Brain sulcus lines (right half)
            let sulci = brainSulciPath(in: size)
            context.stroke(sulci, with: .color(Color(red: 0.7, green: 0.6, blue: 0.72).opacity(0.5)), style: StrokeStyle(lineWidth: w * 0.008, lineCap: .round))

            // MARK: - Lightning bolt accent (bottom center)
            let bolt = lightningPath(in: size)
            let boltGradient = Gradient(colors: [
                Color(red: 1.0, green: 0.85, blue: 0.2),
                Color(red: 1.0, green: 0.65, blue: 0.1)
            ])
            context.fill(bolt, with: .linearGradient(boltGradient, startPoint: CGPoint(x: w * 0.47, y: h * 0.58), endPoint: CGPoint(x: w * 0.53, y: h * 0.78)))

            // Bolt outline
            context.stroke(bolt, with: .color(Color.orange.opacity(0.6)), lineWidth: w * 0.003)

        }
        .frame(width: 1024, height: 1024)
    }

    // MARK: - Cloud-Brain hybrid path

    private func cloudBrainPath(in size: CGSize) -> Path {
        let w = size.width
        let h = size.height

        var path = Path()

        // Start at bottom-left of flat base
        let baseY = h * 0.68
        let baseLeft = w * 0.18
        let baseRight = w * 0.82

        path.move(to: CGPoint(x: baseLeft, y: baseY))

        // LEFT SIDE - Cloud puffs (smooth rounded bumps)

        // Bottom-left puff
        path.addCurve(
            to: CGPoint(x: w * 0.14, y: h * 0.52),
            control1: CGPoint(x: w * 0.10, y: baseY),
            control2: CGPoint(x: w * 0.08, y: h * 0.58)
        )

        // Mid-left large puff
        path.addCurve(
            to: CGPoint(x: w * 0.18, y: h * 0.34),
            control1: CGPoint(x: w * 0.10, y: h * 0.44),
            control2: CGPoint(x: w * 0.10, y: h * 0.36)
        )

        // Top-left puff
        path.addCurve(
            to: CGPoint(x: w * 0.32, y: h * 0.24),
            control1: CGPoint(x: w * 0.22, y: h * 0.28),
            control2: CGPoint(x: w * 0.26, y: h * 0.24)
        )

        // TOP - Transition from cloud to brain

        // Top cloud dome transitioning to brain top
        path.addCurve(
            to: CGPoint(x: w * 0.48, y: h * 0.22),
            control1: CGPoint(x: w * 0.38, y: h * 0.22),
            control2: CGPoint(x: w * 0.43, y: h * 0.20)
        )

        // Brain central fissure dip
        path.addCurve(
            to: CGPoint(x: w * 0.52, y: h * 0.23),
            control1: CGPoint(x: w * 0.50, y: h * 0.25),
            control2: CGPoint(x: w * 0.51, y: h * 0.25)
        )

        // RIGHT SIDE - Brain lobes (more organic, wrinkled contour)

        // Right frontal lobe bump
        path.addCurve(
            to: CGPoint(x: w * 0.68, y: h * 0.24),
            control1: CGPoint(x: w * 0.57, y: h * 0.19),
            control2: CGPoint(x: w * 0.63, y: h * 0.20)
        )

        // Right parietal bump
        path.addCurve(
            to: CGPoint(x: w * 0.80, y: h * 0.32),
            control1: CGPoint(x: w * 0.74, y: h * 0.24),
            control2: CGPoint(x: w * 0.80, y: h * 0.26)
        )

        // Small indentation
        path.addCurve(
            to: CGPoint(x: w * 0.82, y: h * 0.40),
            control1: CGPoint(x: w * 0.83, y: h * 0.35),
            control2: CGPoint(x: w * 0.84, y: h * 0.38)
        )

        // Right temporal lobe
        path.addCurve(
            to: CGPoint(x: w * 0.86, y: h * 0.52),
            control1: CGPoint(x: w * 0.86, y: h * 0.44),
            control2: CGPoint(x: w * 0.88, y: h * 0.48)
        )

        // Lower right curve back to base
        path.addCurve(
            to: CGPoint(x: baseRight, y: baseY),
            control1: CGPoint(x: w * 0.88, y: h * 0.60),
            control2: CGPoint(x: w * 0.88, y: baseY)
        )

        // Flat base
        path.addLine(to: CGPoint(x: baseLeft, y: baseY))
        path.closeSubpath()

        return path
    }

    // MARK: - Brain sulci (fold lines on right half)

    private func brainSulciPath(in size: CGSize) -> Path {
        let w = size.width
        let h = size.height

        var path = Path()

        // Central sulcus - vertical divide
        path.move(to: CGPoint(x: w * 0.50, y: h * 0.25))
        path.addCurve(
            to: CGPoint(x: w * 0.52, y: h * 0.62),
            control1: CGPoint(x: w * 0.51, y: h * 0.38),
            control2: CGPoint(x: w * 0.50, y: h * 0.52)
        )

        // Upper horizontal fold
        path.move(to: CGPoint(x: w * 0.54, y: h * 0.32))
        path.addCurve(
            to: CGPoint(x: w * 0.76, y: h * 0.33),
            control1: CGPoint(x: w * 0.62, y: h * 0.28),
            control2: CGPoint(x: w * 0.70, y: h * 0.30)
        )

        // Middle horizontal fold
        path.move(to: CGPoint(x: w * 0.53, y: h * 0.43))
        path.addCurve(
            to: CGPoint(x: w * 0.80, y: h * 0.44),
            control1: CGPoint(x: w * 0.62, y: h * 0.40),
            control2: CGPoint(x: w * 0.74, y: h * 0.40)
        )

        // Lower horizontal fold
        path.move(to: CGPoint(x: w * 0.53, y: h * 0.54))
        path.addCurve(
            to: CGPoint(x: w * 0.82, y: h * 0.55),
            control1: CGPoint(x: w * 0.63, y: h * 0.51),
            control2: CGPoint(x: w * 0.75, y: h * 0.51)
        )

        return path
    }

    // MARK: - Lightning bolt

    private func lightningPath(in size: CGSize) -> Path {
        let w = size.width
        let h = size.height

        var path = Path()
        path.move(to: CGPoint(x: w * 0.50, y: h * 0.60))
        path.addLine(to: CGPoint(x: w * 0.46, y: h * 0.70))
        path.addLine(to: CGPoint(x: w * 0.49, y: h * 0.70))
        path.addLine(to: CGPoint(x: w * 0.46, y: h * 0.80))
        path.addLine(to: CGPoint(x: w * 0.54, y: h * 0.72))
        path.addLine(to: CGPoint(x: w * 0.51, y: h * 0.72))
        path.addLine(to: CGPoint(x: w * 0.55, y: h * 0.60))
        path.closeSubpath()

        return path
    }
}

#Preview("App Icon 1024x1024") {
    AppIconView()
        .frame(width: 1024, height: 1024)
        .previewLayout(.fixed(width: 1024, height: 1024))
}

#Preview("App Icon Preview (200pt)") {
    AppIconView()
        .frame(width: 200, height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 44))
}
