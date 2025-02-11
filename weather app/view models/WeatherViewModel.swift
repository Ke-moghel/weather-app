

import Foundation
import Combine
import CoreLocation

@MainActor
class WeatherViewModel: ObservableObject {
    @Published var currentTemperature: Int = 0
    @Published var minTemperature: Int = 0
    @Published var maxTemperature: Int = 0
    @Published var weatherCondition: String = "Sunny"
    @Published var weatherIconURL: String = ""
    @Published var forecast: [WeatherDay] = []
    @Published var city: String = "Loading..."
    
    @Published var latitude: Double = 0.0
    @Published var longitude: Double = 0.0
    @Published var savedLocationTemperatures: [String: String] = [:]
    
    private var cancellables = Set<AnyCancellable>()
    private let repository = WeatherRepository()
    private let locationManager = LocationManager()
    private var timer: Timer?
    
    init() {
        locationManager.$city
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newCity in
                self?.city = newCity
            }
            .store(in: &cancellables)

        locationManager.$latitude
            .combineLatest(locationManager.$longitude)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] lat, lon in
                self?.fetchWeather(latitude: lat, longitude: lon)
            }
            .store(in: &cancellables)

        locationManager.checkAuthorizationStatus()
        startAutoRefresh()
    }
    
    func fetchWeather(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude

        repository.getCurrentWeather(lat: latitude, lon: longitude)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { self.updateWeather(with: $0) })
            .store(in: &cancellables)

        repository.getFiveDayForecast(lat: latitude, lon: longitude)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { self.updateForecast(with: $0) })
            .store(in: &cancellables)
    }

    func fetchWeatherForSavedLocations(locations: [FavoriteLocation]) {
        for location in locations {
            repository.getCurrentWeather(lat: location.latitude, lon: location.longitude)
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { _ in }, receiveValue: { weather in
                    self.savedLocationTemperatures[location.name] = "\(Int(weather.currentTemp))°"
                })
                .store(in: &cancellables)
        }
    }

    private func updateWeather(with weather: WeatherResponse) {
        currentTemperature = Int(weather.currentTemp)
        minTemperature = Int(weather.minTemp)
        maxTemperature = Int(weather.maxTemp)
        weatherCondition = weather.condition
        weatherIconURL = weather.weather.first?.iconURL ?? ""
    }

    private func updateForecast(with forecastData: [ForecastDay]) {
        forecast = forecastData.map {
            WeatherDay(day: $0.date, temperature: Int($0.temp), weatherIconURL: $0.iconURL)
        }
    }
    
    private func startAutoRefresh() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 600, repeats: true) { [weak self] _ in
            self?.fetchWeather(latitude: self?.latitude ?? 0, longitude: self?.longitude ?? 0)
        }
    }

    deinit {
        timer?.invalidate()
    }
}
