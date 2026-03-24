import Foundation

enum WeatherError: LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingError(Error)
    case networkError(Error)
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .apiError(let message):
            return message
        }
    }
}

actor WeatherService {
    static let shared = WeatherService()

    // Replace with your OpenWeatherMap API key
    // Get a free key at https://openweathermap.org/api
    static let apiKey = "39029bf0c1f9bc244377f3e8c16de220"

    private let baseURL = "https://api.openweathermap.org/data/2.5"
    private let geoBaseURL = "https://api.openweathermap.org/geo/1.0"
    private let airQualityBaseURL = "https://api.openweathermap.org/data/2.5/air_pollution"
    // Imperial units: Fahrenheit, mph
    private let units = "imperial"

    private let session: URLSession
    private let decoder: JSONDecoder

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: config)
        self.decoder = JSONDecoder()
    }

    // MARK: - Current Weather

    func fetchCurrentWeather(lat: Double, lon: Double) async throws -> WeatherResponse {
        let urlString = "\(baseURL)/weather?lat=\(lat)&lon=\(lon)&appid=\(WeatherService.apiKey)&units=\(units)"
        return try await performRequest(urlString: urlString)
    }

    func fetchCurrentWeather(city: String) async throws -> WeatherResponse {
        guard let encodedCity = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw WeatherError.invalidURL
        }
        let urlString = "\(baseURL)/weather?q=\(encodedCity)&appid=\(WeatherService.apiKey)&units=\(units)"
        return try await performRequest(urlString: urlString)
    }

    // MARK: - Forecast

    func fetchForecast(lat: Double, lon: Double) async throws -> ForecastResponse {
        let urlString = "\(baseURL)/forecast?lat=\(lat)&lon=\(lon)&appid=\(WeatherService.apiKey)&units=\(units)"
        return try await performRequest(urlString: urlString)
    }

    func fetchForecast(city: String) async throws -> ForecastResponse {
        guard let encodedCity = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw WeatherError.invalidURL
        }
        let urlString = "\(baseURL)/forecast?q=\(encodedCity)&appid=\(WeatherService.apiKey)&units=\(units)"
        return try await performRequest(urlString: urlString)
    }

    // MARK: - Geocoding (City Autocomplete)

    func fetchCitySuggestions(query: String, limit: Int = 5) async throws -> [GeocodingResult] {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw WeatherError.invalidURL
        }
        let urlString = "\(geoBaseURL)/direct?q=\(encodedQuery)&limit=\(limit)&appid=\(WeatherService.apiKey)"
        return try await performRequest(urlString: urlString)
    }

    // MARK: - Reverse Geocoding

    func reverseGeocode(lat: Double, lon: Double) async throws -> GeocodingResult? {
        let urlString = "\(geoBaseURL)/reverse?lat=\(lat)&lon=\(lon)&limit=1&appid=\(WeatherService.apiKey)"
        let results: [GeocodingResult] = try await performRequest(urlString: urlString)
        return results.first
    }

    // MARK: - Air Quality

    func fetchAirQuality(lat: Double, lon: Double) async throws -> AirQualityResponse {
        let urlString = "\(airQualityBaseURL)?lat=\(lat)&lon=\(lon)&appid=\(WeatherService.apiKey)"
        return try await performRequest(urlString: urlString)
    }

    // MARK: - Private

    private func performRequest<T: Decodable>(urlString: String) async throws -> T {
        guard let url = URL(string: urlString) else {
            throw WeatherError.invalidURL
        }

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(from: url)
        } catch {
            throw WeatherError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw WeatherError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorBody = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let message = errorBody["message"] as? String {
                throw WeatherError.apiError(message)
            }
            throw WeatherError.apiError("Server returned status code \(httpResponse.statusCode)")
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw WeatherError.decodingError(error)
        }
    }
}
