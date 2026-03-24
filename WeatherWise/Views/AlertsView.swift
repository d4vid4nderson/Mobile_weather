import SwiftUI

// MARK: - Alerts View

/// Full-screen view displaying all active severe weather alerts for Wise County.
struct AlertsView: View {
    @EnvironmentObject var viewModel: WeatherViewModel

    @State private var expandedAlertID: String?

    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    headerSection
                    alertContent
                }
                .padding()
            }
            .refreshable {
                await viewModel.refreshAlerts()
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Background

    @ViewBuilder
    private var backgroundGradient: some View {
        if hasCriticalAlerts {
            LinearGradient(
                colors: [
                    mostSevereSeverity == .extreme
                        ? Color.red.opacity(0.4)
                        : Color.orange.opacity(0.3),
                    Color.black.opacity(0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.1, blue: 0.2),
                    Color.black.opacity(0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Severe Weather Alerts")
                    .font(.title.bold())
                    .foregroundStyle(.white)

                Text("Wise County, Texas")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()

            alertCountBadge
        }
        .padding(.bottom, 8)
    }

    private var alertCountBadge: some View {
        Group {
            if viewModel.isLoadingAlerts {
                ProgressView()
                    .tint(.white)
            } else {
                Text("\(viewModel.alerts.count)")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(badgeColor)
                    )
            }
        }
    }

    private var badgeColor: Color {
        guard let severity = mostSevereSeverity else {
            return .green
        }
        return severity.color
    }

    // MARK: - Content

    @ViewBuilder
    private var alertContent: some View {
        if viewModel.isLoadingAlerts {
            loadingState
        } else if viewModel.alerts.isEmpty {
            allClearState
        } else {
            alertList
        }
    }

    private var loadingState: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.white)
            Text("Checking for alerts...")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }

    private var allClearState: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            Text("All Clear")
                .font(.title.bold())
                .foregroundStyle(.green)

            Text("No active weather alerts for Wise County.")
                .font(.body)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.green.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Color.green.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private var alertList: some View {
        LazyVStack(spacing: 12) {
            ForEach(sortedAlerts) { alert in
                AlertCardView(
                    alert: alert,
                    isExpanded: expandedAlertID == alert.id
                )
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        if expandedAlertID == alert.id {
                            expandedAlertID = nil
                        } else {
                            expandedAlertID = alert.id
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private var sortedAlerts: [NWSAlertFeature] {
        viewModel.alerts.sorted { $0.properties.severity < $1.properties.severity }
    }

    private var hasCriticalAlerts: Bool {
        viewModel.alerts.contains { $0.isCritical }
    }

    private var mostSevereSeverity: AlertSeverity? {
        viewModel.alerts.map(\.properties.severity).min()
    }
}

// MARK: - Alert Card View

/// An individual alert card with expandable detail.
struct AlertCardView: View {
    let alert: NWSAlertFeature
    let isExpanded: Bool

    var body: some View {
        HStack(spacing: 0) {
            // Severity color bar on left edge
            Rectangle()
                .fill(alert.properties.severity.color)
                .frame(width: 6)

            VStack(alignment: .leading, spacing: 8) {
                // Top row: event name + severity icon
                HStack {
                    Image(systemName: alert.properties.severity.iconName)
                        .foregroundStyle(alert.properties.severity.color)
                        .font(.title3)

                    Text(alert.properties.event)
                        .font(.headline.bold())
                        .foregroundStyle(.white)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.white.opacity(0.5))
                        .font(.caption)
                }

                // Severity label
                Text(alert.properties.severity.displayName)
                    .font(.caption.bold())
                    .foregroundStyle(alert.properties.severity.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(alert.properties.severity.color.opacity(0.2))
                    )

                // Areas affected
                Text(alert.properties.areaDesc)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(isExpanded ? nil : 2)

                // Time range
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                    Text(alert.formattedTimeRange)
                        .font(.caption)
                }
                .foregroundStyle(.white.opacity(0.6))

                // Expanded detail
                if isExpanded {
                    expandedContent
                }
            }
            .padding(12)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            alert.properties.severity.color.opacity(0.3),
                            lineWidth: 1
                        )
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var expandedContent: some View {
        Divider()
            .background(Color.white.opacity(0.2))

        // Headline
        if let headline = alert.properties.headline, !headline.isEmpty {
            Text(headline)
                .font(.subheadline.bold())
                .foregroundStyle(.white)
                .padding(.bottom, 4)
        }

        // Description
        if let description = alert.properties.description, !description.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text("Description")
                    .font(.caption.bold())
                    .foregroundStyle(alert.properties.severity.color)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }

        // Instructions
        if let instruction = alert.properties.instruction, !instruction.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text("Instructions")
                    .font(.caption.bold())
                    .foregroundStyle(.orange)

                Text(instruction)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.orange.opacity(0.1))
            )
        }

        // Source
        if let sender = alert.properties.senderName {
            Text("Source: \(sender)")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.4))
        }
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension AlertsView {
    static var previewAlerts: [NWSAlertFeature] {
        [
            NWSAlertFeature(
                id: "urn:oid:2.49.0.1.840.0.preview1",
                type: "Feature",
                properties: NWSAlertProperties(
                    id: "https://api.weather.gov/alerts/preview1",
                    areaDesc: "Wise County, TX",
                    geocode: nil,
                    affectedZones: ["TXZ091"],
                    sent: nil,
                    effective: ISO8601DateFormatter().string(from: Date()),
                    onset: ISO8601DateFormatter().string(from: Date()),
                    expires: ISO8601DateFormatter().string(from: Date().addingTimeInterval(3600)),
                    ends: nil,
                    status: "Actual",
                    messageType: "Alert",
                    severity: .extreme,
                    certainty: "Observed",
                    urgency: "Immediate",
                    event: "Tornado Warning",
                    senderName: "NWS Fort Worth TX",
                    headline: "Tornado Warning issued for Wise County",
                    description: "A severe thunderstorm capable of producing a tornado was located near Decatur, moving northeast at 45 mph.",
                    instruction: "TAKE COVER NOW! Move to a basement or interior room on the lowest floor of a sturdy building.",
                    response: "Shelter"
                ),
                geometry: nil
            )
        ]
    }
}
#endif
