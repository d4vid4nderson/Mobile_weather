import Foundation

// MARK: - Current Weather Response
struct WeatherResponse: Codable, Identifiable {
    let id: Int
    let coord: Coordinate
    let weather: [WeatherCondition]
    let base: String?
    let main: MainWeather
    let visibility: Int?
    let wind: Wind
    let clouds: Clouds?
    let dt: Int
    let sys: Sys
    let timezone: Int
    let name: String

    enum CodingKeys: String, CodingKey {
        case id, coord, weather, base, main, visibility, wind, clouds, dt, sys, timezone, name
    }
}

struct Coordinate: Codable {
    let lon: Double
    let lat: Double
}

struct WeatherCondition: Codable, Identifiable {
    let id: Int
    let main: String
    let description: String
    let icon: String
}

struct MainWeather: Codable {
    let temp: Double
    let feelsLike: Double
    let tempMin: Double
    let tempMax: Double
    let pressure: Int
    let humidity: Int
    let seaLevel: Int?
    let grndLevel: Int?

    enum CodingKeys: String, CodingKey {
        case temp
        case feelsLike = "feels_like"
        case tempMin = "temp_min"
        case tempMax = "temp_max"
        case pressure, humidity
        case seaLevel = "sea_level"
        case grndLevel = "grnd_level"
    }
}

struct Wind: Codable {
    let speed: Double
    let deg: Int?
    let gust: Double?
}

struct Clouds: Codable {
    let all: Int?
}

struct Sys: Codable {
    let type: Int?
    let id: Int?
    let country: String?
    let sunrise: Int?
    let sunset: Int?
}

// MARK: - Forecast Response
struct ForecastResponse: Codable {
    let cod: String
    let message: Int?
    let cnt: Int?
    let list: [ForecastItem]
    let city: ForecastCity
}

struct ForecastItem: Codable, Identifiable {
    var id: Int { dt }
    let dt: Int
    let main: MainWeather
    let weather: [WeatherCondition]
    let wind: Wind
    let clouds: Clouds?
    let visibility: Int?
    let pop: Double?
    let dtTxt: String

    enum CodingKeys: String, CodingKey {
        case dt, main, weather, wind, clouds, visibility, pop
        case dtTxt = "dt_txt"
    }
}

struct ForecastCity: Codable {
    let id: Int?
    let name: String
    let coord: Coordinate?
    let country: String?
    let population: Int?
    let timezone: Int?
    let sunrise: Int?
    let sunset: Int?
}

// MARK: - Air Quality Response
struct AirQualityResponse: Codable {
    let coord: Coordinate?
    let list: [AirQualityItem]
}

struct AirQualityItem: Codable {
    let dt: Int
    let main: AirQualityMain
    let components: AirQualityComponents
}

struct AirQualityMain: Codable {
    let aqi: Int
}

struct AirQualityComponents: Codable {
    let co: Double?
    let no: Double?
    let no2: Double?
    let o3: Double?
    let so2: Double?
    let pm2_5: Double?
    let pm10: Double?
    let nh3: Double?

    enum CodingKeys: String, CodingKey {
        case co, no, no2, o3, so2
        case pm2_5 = "pm2_5"
        case pm10, nh3
    }
}
