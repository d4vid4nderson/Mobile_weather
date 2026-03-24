import SwiftUI

// MARK: - Alert Banner View

/// A compact banner that appears on the main weather screen when alerts are active.
/// Displays the most severe alert's event name, a count, and pulses for critical alerts.
struct AlertBannerView: View {
    @EnvironmentObject var viewModel: WeatherViewModel

    /// Binding to trigger navigation to the full alerts view.
    @Binding var showAlerts: Bool

    @State private var isPulsing = false

    var body: some View {
        if !viewModel.alerts.isEmpty {
            Button {
                showAlerts = true
            } label: {
                bannerContent
            }
            .buttonStyle(.plain)
            .onAppear {
                startPulsingIfNeeded()
            }
            .onChange(of: mostSevereAlert?.properties.severity) { _ in
                startPulsingIfNeeded()
            }
        }
    }

    // MARK: - Banner Content

    private var bannerContent: some View {
        HStack(spacing: 10) {
            // Severity icon
            Image(systemName: severityIconName)
                .font(.body.bold())
                .foregroundStyle(.white)
                .scaleEffect(isPulsing ? 1.2 : 1.0)

            // Alert info
            VStack(alignment: .leading, spacing: 2) {
                Text(mostSevereEventName)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(alertCountLabel)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(bannerBackgroundColor)
                .shadow(color: bannerBackgroundColor.opacity(0.5), radius: 8, y: 2)
        )
        .opacity(isPulsing ? pulsingOpacity : 1.0)
    }

    // MARK: - Pulsing Animation

    @State private var pulsingOpacity: Double = 1.0

    private func startPulsingIfNeeded() {
        guard hasCriticalAlerts else {
            isPulsing = false
            pulsingOpacity = 1.0
            return
        }

        withAnimation(
            .easeInOut(duration: 1.0)
            .repeatForever(autoreverses: true)
        ) {
            isPulsing = true
            pulsingOpacity = 0.75
        }
    }

    // MARK: - Computed Properties

    private var mostSevereAlert: NWSAlertFeature? {
        viewModel.alerts.min { $0.properties.severity < $1.properties.severity }
    }

    private var mostSevereEventName: String {
        mostSevereAlert?.properties.event ?? "Weather Alert"
    }

    private var severityIconName: String {
        mostSevereAlert?.properties.severity.iconName ?? "exclamationmark.triangle"
    }

    private var hasCriticalAlerts: Bool {
        viewModel.alerts.contains { $0.isCritical }
    }

    private var alertCountLabel: String {
        let count = viewModel.alerts.count
        if count == 1 {
            return "1 active alert"
        }
        return "\(count) active alerts"
    }

    private var bannerBackgroundColor: Color {
        guard let severity = mostSevereAlert?.properties.severity else {
            return .orange
        }
        switch severity {
        case .extreme:
            return .red
        case .severe:
            return .orange
        case .moderate:
            return .yellow.opacity(0.85)
        case .minor:
            return .blue
        case .unknown:
            return .gray
        }
    }
}

// MARK: - Preview

#if DEBUG
struct AlertBannerView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            AlertBannerView(showAlerts: .constant(false))
                .padding()
        }
        .preferredColorScheme(.dark)
    }
}
#endif
