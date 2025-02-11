
import Foundation
import Combine

class WeatherRepository {
    private let weatherService = WeatherService()

    func getCurrentWeather(lat: Double, lon: Double) -> AnyPublisher<WeatherResponse, Error> {
        if let cached = weatherService.loadCachedWeather() {
            return Just(cached)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        return weatherService.fetchCurrentWeather(lat: lat, lon: lon)
    }

    func getFiveDayForecast(lat: Double, lon: Double) -> AnyPublisher<[ForecastDay], Error> {
        if let cached = weatherService.loadCachedForecast() {
            return Just(cached)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        return weatherService.fetchFiveDayForecast(lat: lat, lon: lon)
    }
}

