
import Foundation
import Combine

class WeatherService {
    
    private var apiKey: String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "apiKey") as? String, !key.isEmpty else {
            fatalError("API Key is missing in Info.plist")
        }
        return key
    }
    
    private var baseURL: String {
        guard let url = Bundle.main.object(forInfoDictionaryKey: "baseURL") as? String, !url.isEmpty else {
            fatalError("baseURL is missing in Info.plist")
        }
        return url
    }

    
    private let cacheKeyCurrentWeather = "cachedCurrentWeather"
    private let cacheKeyForecast = "cachedForecast"
    private let cacheExpiryKeyForecast = "cacheExpiryForecast"

    func fetchCurrentWeather(lat: Double, lon: Double) -> AnyPublisher<WeatherResponse, Error> {
        guard let url = URL(string: "\(baseURL)weather?lat=\(lat)&lon=\(lon)&appid=\(apiKey)&units=metric") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher() 
        }

        return URLSession.shared.dataTaskPublisher(for: url)
            .tryMap { try self.validateResponse($0.data, $0.response) }
            .handleEvents(receiveOutput: { data in
                UserDefaults.standard.set(data, forKey: self.cacheKeyCurrentWeather)
            })
            .decode(type: WeatherResponse.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }

    func fetchFiveDayForecast(lat: Double, lon: Double) -> AnyPublisher<[ForecastDay], Error> {
        guard let url = URL(string: "\(baseURL)forecast?lat=\(lat)&lon=\(lon)&appid=\(apiKey)&units=metric") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        return URLSession.shared.dataTaskPublisher(for: url)
            .tryMap { try self.validateResponse($0.data, $0.response) }
            .handleEvents(receiveOutput: { data in
                UserDefaults.standard.set(data, forKey: self.cacheKeyForecast)
                UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: self.cacheExpiryKeyForecast)
            })
            .decode(type: ForecastResponse.self, decoder: JSONDecoder())
            .map { response in
                print("Raw forecast data: \(response.list)")
                return self.processForecast(response.list)
            }
            .eraseToAnyPublisher()
    }

    func loadCachedWeather() -> WeatherResponse? {
        guard let data = UserDefaults.standard.data(forKey: cacheKeyCurrentWeather) else { return nil }
        return try? JSONDecoder().decode(WeatherResponse.self, from: data)
    }

    func loadCachedForecast() -> [ForecastDay]? {
        guard let data = UserDefaults.standard.data(forKey: cacheKeyForecast) else { return nil }
        
        let now = Date().timeIntervalSince1970
        let cacheTime = UserDefaults.standard.double(forKey: cacheExpiryKeyForecast)
        
        if now - cacheTime > 3600 {
            return nil
        }
        
        if let decoded = try? JSONDecoder().decode(ForecastResponse.self, from: data) {
            return self.processForecast(decoded.list)
        }
        
        return nil
    }

    private func processForecast(_ forecastList: [ForecastDay]) -> [ForecastDay] {
        let grouped = Dictionary(grouping: forecastList) { forecast in
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.string(from: Date(timeIntervalSince1970: forecast.dt))
        }
        
        let uniqueForecasts = grouped.compactMap { (_, forecasts) -> ForecastDay? in
            guard let middayForecast = forecasts.first(where: {
                Calendar.current.component(.hour, from: Date(timeIntervalSince1970: $0.dt)) == 12
            }) ?? forecasts.first else { return nil }

            let avgTemp = forecasts.map { $0.temp }.reduce(0, +) / Double(forecasts.count)
            let minTemp = forecasts.map { $0.main.tempMin }.min() ?? avgTemp
            let maxTemp = forecasts.map { $0.main.tempMax }.max() ?? avgTemp

            return ForecastDay(
                dt: middayForecast.dt,
                main: Main(temp: avgTemp, tempMin: minTemp, tempMax: maxTemp),
                weather: middayForecast.weather 
            )
        }
        
        return uniqueForecasts.sorted { $0.dt < $1.dt }
    }

    private func validateResponse(_ data: Data, _ response: URLResponse) throws -> Data {
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return data
    }
}
