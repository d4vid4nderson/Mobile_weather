import SwiftUI

/// Animated directional wind arrows overlaid on the radar map.
/// Shows flowing arrow particles that travel in the wind direction.
struct WindArrowOverlayView: View {
    let windDeg: Double   // meteorological degrees (0=N, 90=E, 180=S, 270=W)
    let windSpeed: Double // mph

    @State private var arrows: [WindArrow] = []

    /// Wind blows FROM this direction, so arrows travel in the opposite heading.
    private var flowAngle: Double {
        // Meteorological convention: deg is where wind comes FROM.
        // Arrows should point in the direction wind is going TO.
        // Convert to radians, screen coords (0=right, clockwise).
        // Wind from 0° (N) → arrows flow south → screen angle = π/2 (down)
        let toRad = Double.pi / 180.0
        return (windDeg + 180.0).truncatingRemainder(dividingBy: 360.0) * toRad
    }

    /// Arrow count scales with wind speed
    private var arrowCount: Int {
        switch windSpeed {
        case 0..<5: return 20
        case 5..<15: return 35
        case 15..<30: return 50
        default: return 65
        }
    }

    /// Animation speed multiplier
    private var speedFactor: CGFloat {
        switch windSpeed {
        case 0..<5: return 0.4
        case 5..<15: return 0.8
        case 15..<30: return 1.3
        default: return 1.8
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
                    // Direction vector (screen: x-right, y-down)
                    let dx = CGFloat(sin(angle))  // sin because 0°=up in met, but we offset +180
                    let dy = CGFloat(-cos(angle))

                    for arrow in arrows {
                        let speed = arrow.speed * speedFactor
                        // Total travel distance (diagonal of screen + buffer)
                        let travel = sqrt(w * w + h * h) + 200
                        let cycleDuration = Double(travel) / Double(speed * 60)
                        guard cycleDuration > 0 else { continue }

                        let raw = (now - arrow.delay).truncatingRemainder(dividingBy: cycleDuration)
                        let progress = CGFloat(raw >= 0 ? raw / cycleDuration : (raw + cycleDuration) / cycleDuration)

                        // Start from upwind edge, travel across screen
                        let startX = arrow.lateralOffset - dx * (travel * 0.5)
                        let startY = arrow.baseY - dy * (travel * 0.5)
                        let x = startX + dx * travel * progress
                        let y = startY + dy * travel * progress

                        // Skip if off screen (with margin)
                        guard x > -40 && x < w + 40 && y > -40 && y < h + 40 else { continue }

                        // Fade at edges for smooth appearance/disappearance
                        let edgeFade: Double
                        if progress < 0.1 {
                            edgeFade = Double(progress / 0.1)
                        } else if progress > 0.9 {
                            edgeFade = Double((1.0 - progress) / 0.1)
                        } else {
                            edgeFade = 1.0
                        }

                        let opacity = arrow.opacity * edgeFade
                        let len = arrow.length

                        // Draw arrow shaft + chevron head
                        drawArrow(
                            in: &context,
                            at: CGPoint(x: x, y: y),
                            angle: angle,
                            length: len,
                            thickness: arrow.thickness,
                            opacity: opacity
                        )
                    }
                }
            }
            .onAppear { generateArrows(width: w, height: h) }
            .onChange(of: geo.size) { _, newSize in generateArrows(width: newSize.width, height: newSize.height) }
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

        // Shaft: line from tail to tip
        let tailX = point.x - dx * length * 0.5
        let tailY = point.y - dy * length * 0.5
        let tipX = point.x + dx * length * 0.5
        let tipY = point.y + dy * length * 0.5

        var shaft = Path()
        shaft.move(to: CGPoint(x: tailX, y: tailY))
        shaft.addLine(to: CGPoint(x: tipX, y: tipY))

        context.opacity = opacity
        context.stroke(
            shaft,
            with: .color(.white),
            lineWidth: thickness
        )

        // Chevron head
        let headLen = length * 0.35
        let headAngle = Double.pi / 6.0 // 30 degrees

        let leftX = tipX - CGFloat(sin(angle + headAngle)) * headLen
        let leftY = tipY + CGFloat(cos(angle + headAngle)) * headLen
        let rightX = tipX - CGFloat(sin(angle - headAngle)) * headLen
        let rightY = tipY + CGFloat(cos(angle - headAngle)) * headLen

        var head = Path()
        head.move(to: CGPoint(x: leftX, y: leftY))
        head.addLine(to: CGPoint(x: tipX, y: tipY))
        head.addLine(to: CGPoint(x: rightX, y: rightY))

        context.stroke(
            head,
            with: .color(.white),
            style: StrokeStyle(lineWidth: thickness * 1.2, lineCap: .round, lineJoin: .round)
        )
    }

    // MARK: - Generation

    private func generateArrows(width: CGFloat, height: CGFloat) {
        guard width > 0, height > 0 else { return }

        arrows = (0..<arrowCount).map { _ in
            WindArrow(
                lateralOffset: CGFloat.random(in: -50...(width + 50)),
                baseY: CGFloat.random(in: -50...(height + 50)),
                length: CGFloat.random(in: 16...32),
                thickness: CGFloat.random(in: 1.0...2.0),
                speed: CGFloat.random(in: 2.5...6.0),
                opacity: Double.random(in: 0.25...0.55),
                delay: Double.random(in: 0...10)
            )
        }
    }
}

// MARK: - Model

private struct WindArrow {
    let lateralOffset: CGFloat
    let baseY: CGFloat
    let length: CGFloat
    let thickness: CGFloat
    let speed: CGFloat
    let opacity: Double
    let delay: Double
}
