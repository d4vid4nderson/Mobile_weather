import SwiftUI

// MARK: - Detail Types

enum WeatherDetailType: Identifiable {
    case humidity
    case wind
    case pressure
    case visibility
    case sunrise
    case sunset

    var id: String {
        switch self {
        case .humidity: return "humidity"
        case .wind: return "wind"
        case .pressure: return "pressure"
        case .visibility: return "visibility"
        case .sunrise: return "sunrise"
        case .sunset: return "sunset"
        }
    }

    var title: String {
        switch self {
        case .humidity: return "Humidity"
        case .wind: return "Wind"
        case .pressure: return "Pressure"
        case .visibility: return "Visibility"
        case .sunrise: return "Sunrise"
        case .sunset: return "Sunset"
        }
    }

    var icon: String {
        switch self {
        case .humidity: return "humidity.fill"
        case .wind: return "wind"
        case .pressure: return "gauge.medium"
        case .visibility: return "eye.fill"
        case .sunrise: return "sunrise.fill"
        case .sunset: return "sunset.fill"
        }
    }
}

// MARK: - Detail Sheet

struct WeatherDetailSheet: View {
    @EnvironmentObject var viewModel: WeatherViewModel
    @Environment(\.dismiss) private var dismiss
    let detailType: WeatherDetailType

    var body: some View {
        NavigationStack {
            ZStack {
                viewModel.backgroundGradient
                    .ignoresSafeArea()

                // Dripping droplets for high humidity
                if detailType == .humidity,
                   let humidity = viewModel.currentWeather?.main.humidity,
                   humidity >= 75 {
                    DropletsView(humidity: humidity)
                        .ignoresSafeArea()
                }

                // Wind gusts blowing left to right
                if detailType == .wind,
                   let speed = viewModel.currentWeather?.wind.speed {
                    WindGustView(windSpeed: speed)
                        .ignoresSafeArea()
                }

                ScrollView {
                    VStack(spacing: 20) {
                        // Hero value (skip for sun views — arc is the hero)
                        if detailType != .sunrise && detailType != .sunset {
                            heroSection
                        }

                        // Detail rows
                        detailRows
                    }
                    .padding(20)
                    .padding(.top, 8)
                }
            }
            .navigationTitle(detailType.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Color.onGradientSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 8) {
            Image(systemName: detailType.icon)
                .font(.system(size: 44))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.onGradientPrimary)

            Text(heroValue)
                .font(.system(size: 52, weight: .thin, design: .rounded))
                .foregroundStyle(Color.onGradientPrimary)

            Text(heroSubtitle)
                .font(.subheadline)
                .foregroundStyle(Color.onGradientSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private var heroValue: String {
        switch detailType {
        case .humidity: return viewModel.humidityString
        case .wind: return viewModel.windSpeedString
        case .pressure: return viewModel.pressureString
        case .visibility: return viewModel.visibilityString
        case .sunrise: return viewModel.sunriseString
        case .sunset: return viewModel.sunsetString
        }
    }

    private var heroSubtitle: String {
        switch detailType {
        case .humidity: return humidityComfort
        case .wind: return windDescription
        case .pressure: return pressureDescription
        case .visibility: return visibilityDescription
        case .sunrise: return "Local Time"
        case .sunset: return "Local Time"
        }
    }

    // MARK: - Detail Rows

    private var detailRows: some View {
        VStack(spacing: 0) {
            switch detailType {
            case .humidity: humidityDetails
            case .wind: windDetails
            case .pressure: pressureDetails
            case .visibility: visibilityDetails
            case .sunrise: sunriseDetails
            case .sunset: sunsetDetails
            }
        }
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.onGradientCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.onGradientCardBorder, lineWidth: 1)
                )
        }
    }

    // MARK: - Humidity Details

    private var humidityDetails: some View {
        Group {
            detailRow(label: "Relative Humidity", value: viewModel.humidityString)
            detailDivider
            detailRow(label: "Dew Point", value: dewPointString)
            detailDivider
            detailRow(label: "Comfort Level", value: humidityComfort)
            if let aqi = viewModel.airQualityIndex {
                detailDivider
                detailRow(label: "Air Quality Index", value: "\(aqi) - \(viewModel.airQualityLabel)")
            }
            if let components = viewModel.airQuality?.list.first?.components {
                if let pm25 = components.pm2_5 {
                    detailDivider
                    detailRow(label: "PM2.5", value: String(format: "%.1f µg/m³", pm25))
                }
                if let pm10 = components.pm10 {
                    detailDivider
                    detailRow(label: "PM10", value: String(format: "%.1f µg/m³", pm10))
                }
            }
        }
    }

    private var dewPointString: String {
        guard let temp = viewModel.currentWeather?.main.temp,
              let humidity = viewModel.currentWeather?.main.humidity else { return "--" }
        // Magnus formula approximation (temp in F, convert to C first)
        let tempC = (temp - 32) * 5.0 / 9.0
        let h = Double(humidity)
        let a = 17.27
        let b = 237.7
        let alpha = (a * tempC) / (b + tempC) + log(h / 100.0)
        let dewPointC = (b * alpha) / (a - alpha)
        let dewPoint = viewModel.convertTemp(dewPointC * 9.0 / 5.0 + 32)
        return "\(Int(dewPoint.rounded()))°"
    }

    private var humidityComfort: String {
        guard let humidity = viewModel.currentWeather?.main.humidity else { return "Unknown" }
        switch humidity {
        case 0..<30: return "Dry"
        case 30..<50: return "Comfortable"
        case 50..<70: return "Moderate"
        case 70..<85: return "Humid"
        default: return "Very Humid"
        }
    }

    // MARK: - Wind Details

    private var windDetails: some View {
        Group {
            detailRow(label: "Speed", value: viewModel.windSpeedString)
            if let gust = viewModel.currentWeather?.wind.gust {
                detailDivider
                let gustConverted = viewModel.windSpeedString.contains("mph") ? gust :
                    viewModel.windSpeedString.contains("km/h") ? gust * 1.60934 : gust * 0.44704
                let unit = viewModel.windSpeedUnit.rawValue
                detailRow(label: "Gusts", value: String(format: "%.1f %@", gustConverted, unit))
            }
            if let deg = viewModel.currentWeather?.wind.deg {
                detailDivider
                detailRow(label: "Direction", value: "\(windCompass(deg)) (\(deg)°)")
            }
            detailDivider
            detailRow(label: "Beaufort Scale", value: beaufortScale)
            detailDivider
            detailRow(label: "Description", value: windDescription)
        }
    }

    private func windCompass(_ degrees: Int) -> String {
        let directions = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
                          "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        let index = Int((Double(degrees) + 11.25) / 22.5) % 16
        return directions[index]
    }

    private var beaufortScale: String {
        guard let speed = viewModel.currentWeather?.wind.speed else { return "--" }
        // speed is in mph from API
        switch speed {
        case 0..<1: return "0 - Calm"
        case 1..<4: return "1 - Light Air"
        case 4..<8: return "2 - Light Breeze"
        case 8..<13: return "3 - Gentle Breeze"
        case 13..<19: return "4 - Moderate Breeze"
        case 19..<25: return "5 - Fresh Breeze"
        case 25..<32: return "6 - Strong Breeze"
        case 32..<39: return "7 - Near Gale"
        case 39..<47: return "8 - Gale"
        case 47..<55: return "9 - Strong Gale"
        case 55..<64: return "10 - Storm"
        case 64..<73: return "11 - Violent Storm"
        default: return "12 - Hurricane"
        }
    }

    private var windDescription: String {
        guard let speed = viewModel.currentWeather?.wind.speed else { return "Unknown" }
        switch speed {
        case 0..<4: return "Calm"
        case 4..<13: return "Light"
        case 13..<25: return "Moderate"
        case 25..<39: return "Strong"
        case 39..<55: return "Very Strong"
        default: return "Extreme"
        }
    }

    // MARK: - Pressure Details

    private var pressureDetails: some View {
        Group {
            detailRow(label: "Station Pressure", value: viewModel.pressureString)
            if let seaLevel = viewModel.currentWeather?.main.seaLevel {
                detailDivider
                detailRow(label: "Sea Level", value: "\(seaLevel) hPa")
            }
            if let grndLevel = viewModel.currentWeather?.main.grndLevel {
                detailDivider
                detailRow(label: "Ground Level", value: "\(grndLevel) hPa")
            }
            detailDivider
            detailRow(label: "Condition", value: pressureDescription)
            detailDivider
            detailRow(label: "Inches of Mercury", value: pressureInHg)
        }
    }

    private var pressureDescription: String {
        guard let pressure = viewModel.currentWeather?.main.pressure else { return "Unknown" }
        switch pressure {
        case ..<1000: return "Low Pressure"
        case 1000..<1010: return "Below Average"
        case 1010..<1020: return "Normal"
        case 1020..<1030: return "Above Average"
        default: return "High Pressure"
        }
    }

    private var pressureInHg: String {
        guard let pressure = viewModel.currentWeather?.main.pressure else { return "--" }
        let inHg = Double(pressure) * 0.02953
        return String(format: "%.2f inHg", inHg)
    }

    // MARK: - Visibility Details

    private var visibilityDetails: some View {
        Group {
            detailRow(label: "Distance", value: viewModel.visibilityString)
            if let visibility = viewModel.currentWeather?.visibility {
                detailDivider
                detailRow(label: "Meters", value: "\(visibility) m")
                detailDivider
                let km = Double(visibility) / 1000.0
                detailRow(label: "Kilometers", value: String(format: "%.1f km", km))
            }
            detailDivider
            detailRow(label: "Conditions", value: visibilityDescription)
            if let clouds = viewModel.currentWeather?.clouds?.all {
                detailDivider
                detailRow(label: "Cloud Cover", value: "\(clouds)%")
            }
        }
    }

    private var visibilityDescription: String {
        guard let visibility = viewModel.currentWeather?.visibility else { return "Unknown" }
        let miles = Double(visibility) / 1609.34
        switch miles {
        case 0..<0.5: return "Very Poor"
        case 0.5..<2: return "Poor"
        case 2..<5: return "Moderate"
        case 5..<7: return "Good"
        default: return "Excellent"
        }
    }

    // MARK: - Sunrise Details

    private var sunriseDetails: some View {
        Group {
            sunArcGraph
            detailRow(label: "Sunrise", value: viewModel.sunriseString)
            detailDivider
            detailRow(label: "Sunset", value: viewModel.sunsetString)
            detailDivider
            detailRow(label: "Day Length", value: dayLengthString)
            detailDivider
            detailRow(label: "Night Length", value: nightLengthString)
            detailDivider
            detailRow(label: "Currently", value: viewModel.isDaytime ? "Daytime" : "Nighttime")
            detailDivider
            detailRow(label: "Golden Hour (AM)", value: goldenHourString(isSunrise: true))
            detailDivider
            detailRow(label: "Golden Hour (PM)", value: goldenHourString(isSunrise: false))
        }
    }

    // MARK: - Sunset Details

    private var sunsetDetails: some View {
        Group {
            sunArcGraph
            detailRow(label: "Sunset", value: viewModel.sunsetString)
            detailDivider
            detailRow(label: "Sunrise", value: viewModel.sunriseString)
            detailDivider
            detailRow(label: "Day Length", value: dayLengthString)
            detailDivider
            detailRow(label: "Night Length", value: nightLengthString)
            detailDivider
            detailRow(label: "Currently", value: viewModel.isDaytime ? "Daytime" : "Nighttime")
            detailDivider
            detailRow(label: "Golden Hour (AM)", value: goldenHourString(isSunrise: true))
            detailDivider
            detailRow(label: "Golden Hour (PM)", value: goldenHourString(isSunrise: false))
        }
    }

    // MARK: - Sun Arc Graph

    @ViewBuilder
    private var sunArcGraph: some View {
        if let sunrise = viewModel.currentWeather?.sys.sunrise,
           let sunset = viewModel.currentWeather?.sys.sunset {
            SunArcView(
                sunrise: sunrise,
                sunset: sunset,
                timezoneOffset: viewModel.currentWeather?.timezone ?? 0,
                isDaytime: viewModel.isDaytime
            )
            .padding(.horizontal, 12)
            .padding(.vertical, 16)
        }
    }

    private var dayLengthString: String {
        guard let sunrise = viewModel.currentWeather?.sys.sunrise,
              let sunset = viewModel.currentWeather?.sys.sunset else { return "--" }
        let diff = sunset - sunrise
        let hours = diff / 3600
        let minutes = (diff % 3600) / 60
        return "\(hours)h \(minutes)m"
    }

    private var nightLengthString: String {
        guard let sunrise = viewModel.currentWeather?.sys.sunrise,
              let sunset = viewModel.currentWeather?.sys.sunset else { return "--" }
        let nightSeconds = 86400 - (sunset - sunrise)
        let hours = nightSeconds / 3600
        let minutes = (nightSeconds % 3600) / 60
        return "\(hours)h \(minutes)m"
    }

    private func goldenHourString(isSunrise: Bool) -> String {
        guard let sunrise = viewModel.currentWeather?.sys.sunrise,
              let sunset = viewModel.currentWeather?.sys.sunset else { return "--" }
        let tz = viewModel.currentWeather?.timezone ?? 0
        // Golden hour is ~30 min after sunrise or ~30 min before sunset
        let timestamp = isSunrise ? sunrise + 1800 : sunset - 1800
        return timestamp.asDate.formattedTime(timezoneOffset: tz)
    }

    // MARK: - Row Components

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Color.onGradientSecondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(Color.onGradientPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var detailDivider: some View {
        Divider()
            .background(Color.onGradientSecondary.opacity(0.2))
            .padding(.leading, 16)
    }
}

#Preview {
    WeatherDetailSheet(detailType: .humidity)
        .environmentObject(WeatherViewModel())
}
