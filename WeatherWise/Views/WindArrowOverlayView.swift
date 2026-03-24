import SwiftUI

/// Animated directional wind arrows overlaid on the radar map.
/// Shows flowing arrow particles that travel in the wind direction.
struct WindArrowOverlayView: View {
    let windDeg: Double   // meteorological degrees (0=N, 90=E, 180=S, 270=W)
    let windSpeed: Double // mph

    @State private var arrows: [WindArrow] = []

    /// Wind blows FROM this direction, so arrows travel in the opposite heading.
    private var flowAngle: Double {
        let toRad = Double.pi / 180.0
        return (windDeg + 180.0).truncatingRemainder(dividingBy: 360.0) * toRad
    }

    /// Arrow count scales with wind speed
    private var arrowCount: Int {
        switch windSpeed {
        case 0..<5: return 25
        case 5..<15: return 40
        case 15..<30: return 55
        default: return 70
        }
    }

    /// Animation speed multiplier
    private var speedFactor: CGFloat {
        switch windSpeed {
        case 0..<5: return 0.5
        case 5..<15: return 1.0
        case 15..<30: return 1.5
        default: return 2.0
        }
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                Canvas { context, size in
                    let now = timeline.date.timeIntervalSinceReferenceDate
                    let angle = flowAngle
                    let dx = CGFloat(sin(angle))
                    let dy = CGFloat(-cos(angle))

                    for arrow in arrows {
                        let speed = arrow.speed * speedFactor
                        let travel = sqrt(w * w + h * h) + 300
                        let cycleDuration = Double(travel) / Double(speed * 60)
                        guard cycleDuration > 0 else { continue }

                        let raw = (now - arrow.delay).truncatingRemainder(dividingBy: cycleDuration)
                        let progress = CGFloat(raw >= 0 ? raw / cycleDuration : (raw + cycleDuration) / cycleDuration)

                        // Perpendicular offset so arrows spread across screen width
                        let perpDx = -dy  // perpendicular to wind direction
                        let perpDy = dx
                        let startX = w * 0.5 + perpDx * arrow.lateralSpread - dx * (travel * 0.5)
                        let startY = h * 0.5 + perpDy * arrow.lateralSpread - dy * (travel * 0.5)
                        let x = startX + dx * travel * progress
                        let y = startY + dy * travel * progress

                        // Skip if off screen
                        guard x > -60 && x < w + 60 && y > -60 && y < h + 60 else { continue }

                        // Fade at edges
                        let edgeFade: Double
                        if progress < 0.12 {
                            edgeFade = Double(progress / 0.12)
                        } else if progress > 0.88 {
                            edgeFade = Double((1.0 - progress) / 0.12)
                        } else {
                            edgeFade = 1.0
                        }

                        let opacity = arrow.opacity * edgeFade

                        drawArrow(
                            in: &context,
                            at: CGPoint(x: x, y: y),
                            angle: angle,
                            length: arrow.length,
                            thickness: arrow.thickness,
                            opacity: opacity
                        )
                    }
                }
            }
            .onAppear { generateArrows(width: w, height: h) }
            .onChange(of: geo.size) { _, s in generateArrows(width: s.width, height: s.height) }
            .onChange(of: windDeg) { _, _ in generateArrows(width: w, height: h) }
            .onChange(of: windSpeed) { _, _ in generateArrows(width: w, height: h) }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Arrow Drawing

    private func drawArrow(
        in context: inout GraphicsContext,
        at point: CGPoint,
        angle: Double,
        length: CGFloat,
        thickness: CGFloat,
        opacity: Double
    ) {
        let dx = CGFloat(sin(angle))
        let dy = CGFloat(-cos(angle))

        let tailX = point.x - dx * length * 0.5
        let tailY = point.y - dy * length * 0.5
        let tipX = point.x + dx * length * 0.5
        let tipY = point.y + dy * length * 0.5

        // Draw shadow for contrast
        let shadowOffset: CGFloat = 1.0
        var shadowShaft = Path()
        shadowShaft.move(to: CGPoint(x: tailX + shadowOffset, y: tailY + shadowOffset))
        shadowShaft.addLine(to: CGPoint(x: tipX + shadowOffset, y: tipY + shadowOffset))
        context.opacity = opacity * 0.4
        context.stroke(shadowShaft, with: .color(.black), lineWidth: thickness + 1.5)

        // Main shaft
        var shaft = Path()
        shaft.move(to: CGPoint(x: tailX, y: tailY))
        shaft.addLine(to: CGPoint(x: tipX, y: tipY))
        context.opacity = opacity
        context.stroke(shaft, with: .color(.white), lineWidth: thickness)

        // Chevron head
        let headLen = length * 0.4
        let headAngle = Double.pi / 5.5

        let leftX = tipX - CGFloat(sin(angle + headAngle)) * headLen
        let leftY = tipY + CGFloat(cos(angle + headAngle)) * headLen
        let rightX = tipX - CGFloat(sin(angle - headAngle)) * headLen
        let rightY = tipY + CGFloat(cos(angle - headAngle)) * headLen

        // Shadow for head
        var shadowHead = Path()
        shadowHead.move(to: CGPoint(x: leftX + shadowOffset, y: leftY + shadowOffset))
        shadowHead.addLine(to: CGPoint(x: tipX + shadowOffset, y: tipY + shadowOffset))
        shadowHead.addLine(to: CGPoint(x: rightX + shadowOffset, y: rightY + shadowOffset))
        context.opacity = opacity * 0.4
        context.stroke(
            shadowHead,
            with: .color(.black),
            style: StrokeStyle(lineWidth: thickness + 1.0, lineCap: .round, lineJoin: .round)
        )

        // Main head
        var head = Path()
        head.move(to: CGPoint(x: leftX, y: leftY))
        head.addLine(to: CGPoint(x: tipX, y: tipY))
        head.addLine(to: CGPoint(x: rightX, y: rightY))
        context.opacity = opacity
        context.stroke(
            head,
            with: .color(.white),
            style: StrokeStyle(lineWidth: thickness * 1.3, lineCap: .round, lineJoin: .round)
        )
    }

    // MARK: - Generation

    private func generateArrows(width: CGFloat, height: CGFloat) {
        guard width > 0, height > 0 else { return }
        let maxSpread = sqrt(width * width + height * height) * 0.6

        arrows = (0..<arrowCount).map { _ in
            WindArrow(
                lateralSpread: CGFloat.random(in: -maxSpread...maxSpread),
                length: CGFloat.random(in: 22...40),
                thickness: CGFloat.random(in: 1.5...2.8),
                speed: CGFloat.random(in: 2.0...5.5),
                opacity: Double.random(in: 0.5...0.85),
                delay: Double.random(in: 0...10)
            )
        }
    }
}

// MARK: - Model

private struct WindArrow {
    let lateralSpread: CGFloat  // perpendicular offset from center
    let length: CGFloat
    let thickness: CGFloat
    let speed: CGFloat
    let opacity: Double
    let delay: Double
}
