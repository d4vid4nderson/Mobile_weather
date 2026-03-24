import SwiftUI

struct SunArcView: View {
    let sunrise: Int       // Unix timestamp
    let sunset: Int        // Unix timestamp
    let timezoneOffset: Int
    let isDaytime: Bool

    private let currentTime = Date().timeIntervalSince1970

    // Full 24-hour period: midnight to midnight (local time)
    private var dayStart: Double {
        // Midnight of the sunrise day in local time
        let cal = Calendar.current
        var tz = TimeZone(secondsFromGMT: timezoneOffset) ?? .current
        var comps = cal.dateComponents(in: tz, from: Date(timeIntervalSince1970: Double(sunrise)))
        comps.hour = 0
        comps.minute = 0
        comps.second = 0
        return cal.date(from: comps)?.timeIntervalSince1970 ?? Double(sunrise - 21600)
    }

    private var dayEnd: Double {
        dayStart + 86400
    }

    // Normalize a timestamp to 0...1 within the 24h window
    private func normalized(_ timestamp: Double) -> CGFloat {
        CGFloat((timestamp - dayStart) / (dayEnd - dayStart)).clamped(to: 0...1)
    }

    // Sun position on sine curve: rises at sunrise, peaks at solar noon, sets at sunset
    // Below horizon (negative) during night
    private func sunY(at x: CGFloat, in rect: CGRect) -> CGFloat {
        let sunriseX = normalized(Double(sunrise))
        let sunsetX = normalized(Double(sunset))
        let midday = (sunriseX + sunsetX) / 2.0

        // Calculate next day's sunrise (approx same time tomorrow)
        let nextSunrise = normalized(Double(sunrise) + 86400)
        let prevSunset = normalized(Double(sunset) - 86400)

        let horizonY = rect.midY
        let amplitude = rect.height * 0.38

        let y: CGFloat
        if x >= sunriseX && x <= sunsetX {
            // Daytime arc: sine from sunrise to sunset
            let progress = (x - sunriseX) / (sunsetX - sunriseX)
            y = horizonY - amplitude * sin(progress * .pi)
        } else if x > sunsetX {
            // Evening/night: sine dip below horizon
            let nightDuration = nextSunrise - sunsetX
            let progress = nightDuration > 0 ? (x - sunsetX) / nightDuration : 0
            y = horizonY + amplitude * 0.5 * sin(progress * .pi)
        } else {
            // Before sunrise: tail end of previous night
            let nightDuration = sunriseX - max(prevSunset, 0)
            let progress = nightDuration > 0 ? (sunriseX - x) / nightDuration : 0
            y = horizonY + amplitude * 0.5 * sin(progress * .pi)
        }

        return y
    }

    var body: some View {
        VStack(spacing: 16) {
            // Arc graph
            GeometryReader { geo in
                let rect = geo.frame(in: .local)
                let horizonY = rect.midY

                ZStack {
                    // Daytime gradient fill
                    daytimeFill(rect: rect)

                    // Horizon line
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: horizonY))
                        path.addLine(to: CGPoint(x: rect.width, y: horizonY))
                    }
                    .stroke(Color.white.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [6, 4]))

                    // Sun curve
                    sunCurvePath(rect: rect)
                        .stroke(
                            LinearGradient(
                                colors: [.orange.opacity(0.8), .yellow, .orange.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 2.5
                        )

                    // Night curve (below horizon, dimmer)
                    nightCurvePath(rect: rect)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1.5)

                    // Sunrise marker
                    sunMarker(
                        x: normalized(Double(sunrise)) * rect.width,
                        y: horizonY,
                        label: formatTime(sunrise),
                        icon: "sunrise.fill",
                        color: .orange,
                        rect: rect,
                        above: true
                    )

                    // Sunset marker
                    sunMarker(
                        x: normalized(Double(sunset)) * rect.width,
                        y: horizonY,
                        label: formatTime(sunset),
                        icon: "sunset.fill",
                        color: .orange,
                        rect: rect,
                        above: true
                    )

                    // Current position dot
                    currentPositionDot(rect: rect)

                    // Time labels
                    timeLabels(rect: rect, horizonY: horizonY)
                }
            }
            .frame(height: 200)
            .padding(.horizontal, 4)
        }
    }

    // MARK: - Daytime Fill

    private func daytimeFill(rect: CGRect) -> some View {
        let sunriseX = normalized(Double(sunrise))
        let sunsetX = normalized(Double(sunset))
        let horizonY = rect.midY

        return Path { path in
            let steps = 60
            let startX = sunriseX * rect.width
            let endX = sunsetX * rect.width

            path.move(to: CGPoint(x: startX, y: horizonY))

            for i in 0...steps {
                let frac = CGFloat(i) / CGFloat(steps)
                let x = sunriseX + frac * (sunsetX - sunriseX)
                let px = x * rect.width
                let py = sunY(at: x, in: rect)
                path.addLine(to: CGPoint(x: px, y: py))
            }

            path.addLine(to: CGPoint(x: endX, y: horizonY))
            path.closeSubpath()
        }
        .fill(
            LinearGradient(
                colors: [.yellow.opacity(0.15), .orange.opacity(0.08)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    // MARK: - Sun Curve (above horizon)

    private func sunCurvePath(rect: CGRect) -> Path {
        let sunriseX = normalized(Double(sunrise))
        let sunsetX = normalized(Double(sunset))
        let steps = 60

        return Path { path in
            var started = false
            for i in 0...steps {
                let frac = CGFloat(i) / CGFloat(steps)
                let x = sunriseX + frac * (sunsetX - sunriseX)
                let px = x * rect.width
                let py = sunY(at: x, in: rect)

                if !started {
                    path.move(to: CGPoint(x: px, y: py))
                    started = true
                } else {
                    path.addLine(to: CGPoint(x: px, y: py))
                }
            }
        }
    }

    // MARK: - Night Curve (below horizon)

    private func nightCurvePath(rect: CGRect) -> Path {
        let sunriseX = normalized(Double(sunrise))
        let sunsetX = normalized(Double(sunset))
        let steps = 30

        return Path { path in
            // Before sunrise
            if sunriseX > 0.02 {
                var started = false
                for i in 0...steps {
                    let frac = CGFloat(i) / CGFloat(steps)
                    let x = frac * sunriseX
                    let px = x * rect.width
                    let py = sunY(at: x, in: rect)
                    if !started {
                        path.move(to: CGPoint(x: px, y: py))
                        started = true
                    } else {
                        path.addLine(to: CGPoint(x: px, y: py))
                    }
                }
            }

            // After sunset
            if sunsetX < 0.98 {
                var started = false
                for i in 0...steps {
                    let frac = CGFloat(i) / CGFloat(steps)
                    let x = sunsetX + frac * (1.0 - sunsetX)
                    let px = x * rect.width
                    let py = sunY(at: x, in: rect)
                    if !started {
                        path.move(to: CGPoint(x: px, y: py))
                        started = true
                    } else {
                        path.addLine(to: CGPoint(x: px, y: py))
                    }
                }
            }
        }
    }

    // MARK: - Current Position

    private func currentPositionDot(rect: CGRect) -> some View {
        let x = normalized(currentTime)
        let px = x * rect.width
        let py = sunY(at: x, in: rect)
        let aboveHorizon = py <= rect.midY

        return ZStack {
            // Glow
            Circle()
                .fill(aboveHorizon ? Color.yellow.opacity(0.3) : Color.blue.opacity(0.3))
                .frame(width: 24, height: 24)

            // Dot
            Circle()
                .fill(aboveHorizon ? Color.yellow : Color.blue.opacity(0.7))
                .frame(width: 12, height: 12)

            // Sun/Moon icon
            Image(systemName: aboveHorizon ? "sun.max.fill" : "moon.fill")
                .font(.system(size: 8))
                .foregroundStyle(aboveHorizon ? .orange : .white)
        }
        .position(x: px, y: py)
    }

    // MARK: - Markers

    private func sunMarker(x: CGFloat, y: CGFloat, label: String, icon: String, color: Color, rect: CGRect, above: Bool) -> some View {
        VStack(spacing: 2) {
            if above {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(color)
                Text(label)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.onGradientPrimary)
            }
        }
        .position(x: x.clamped(to: 30...(rect.width - 30)), y: y + 24)
    }

    // MARK: - Time Labels

    private func timeLabels(rect: CGRect, horizonY: CGFloat) -> some View {
        ZStack {
            // "Day" label
            Text("DAY")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(Color.yellow.opacity(0.5))
                .position(x: rect.width / 2, y: horizonY - rect.height * 0.32)

            // "Night" labels
            Text("NIGHT")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(Color.blue.opacity(0.4))
                .position(x: rect.width * 0.12, y: horizonY + rect.height * 0.25)

            Text("NIGHT")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(Color.blue.opacity(0.4))
                .position(x: rect.width * 0.88, y: horizonY + rect.height * 0.25)

            // Horizon label
            Text("HORIZON")
                .font(.system(size: 8, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.25))
                .position(x: rect.width - 30, y: horizonY - 10)
        }
    }

    // MARK: - Helpers

    private func formatTime(_ timestamp: Int) -> String {
        timestamp.asDate.formattedTime(timezoneOffset: timezoneOffset)
    }
}

// MARK: - Clamping

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [.blue, .indigo],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        SunArcView(
            sunrise: Int(Date().timeIntervalSince1970) - 21600,
            sunset: Int(Date().timeIntervalSince1970) + 21600,
            timezoneOffset: -18000,
            isDaytime: true
        )
        .padding()
    }
}
