
import XCTest
import Combine
@testable import weather_app

class WeatherServiceTests: XCTestCase {
    var weatherService: WeatherService!
    var cancellables: Set<AnyCancellable> = []
    
    override func setUp() {
        super.setUp()
        weatherService = WeatherService()
    }
    
    override func tearDown() {
        weatherService = nil
        cancellables.removeAll()
        super.tearDown()
    }
    
    func testLoadCachedWeather_NoData() {
        UserDefaults.standard.removeObject(forKey: "cachedCurrentWeather")
        let result = weatherService.loadCachedWeather()
        XCTAssertNil(result, "Cached weather should be nil when no data is stored.")
    }
    
    func testLoadCachedWeather_WithValidData() {
        let mockWeather = WeatherResponse(
            name: "Test City",
            main: Main(temp: 25.0, tempMin: 20.0, tempMax: 30.0),
            weather: [Weather(description: "Sunny", icon: "sun")]
        )
        let encodedData = try! JSONEncoder().encode(mockWeather)
        UserDefaults.standard.set(encodedData, forKey: "cachedCurrentWeather")
        
        let result = weatherService.loadCachedWeather()
        XCTAssertNotNil(result, "Cached weather should not be nil when valid data is stored.")
        XCTAssertEqual(result?.currentTemp, 25.0, "Expected 25.0°C current temperature.")
    }
}

class WeatherRepositoryTests: XCTestCase {
    var repository: WeatherRepository!
    var cancellables: Set<AnyCancellable> = []
    
    override func setUp() {
        super.setUp()
        repository = WeatherRepository()
    }
    
    override func tearDown() {
        repository = nil
        cancellables.removeAll()
        super.tearDown()
    }
    
    func testGetCurrentWeather_ReturnsCachedData() {
        let mockWeather = WeatherResponse(
            name: "Cape Town",
            main: Main(temp: 25.0, tempMin: 20.0, tempMax: 30.0),
            weather: [Weather(description: "Clear", icon: "sun")]
        )
        let encodedData = try! JSONEncoder().encode(mockWeather)
        UserDefaults.standard.set(encodedData, forKey: "cachedCurrentWeather")
        
        let expectation = self.expectation(description: "Returns cached weather")
        
        repository.getCurrentWeather(lat: 0.0, lon: 0.0)
            .sink(receiveCompletion: { _ in }, receiveValue: { weather in
                XCTAssertEqual(weather.currentTemp, 25.0, "Expected cached temperature to be 25.0°C")
                expectation.fulfill()
            })
            .store(in: &cancellables)
        
        waitForExpectations(timeout: 2, handler: nil)
    }
}

class WeatherViewModelTests: XCTestCase {
    var viewModel: WeatherViewModel!
    var cancellables: Set<AnyCancellable> = []
   
    @MainActor
    override func setUp() {
        super.setUp()
        viewModel = WeatherViewModel()
    }
    
    override func tearDown() {
        viewModel = nil
        cancellables.removeAll()
        super.tearDown()
    }
    
    @MainActor func testFetchWeather_UpdatesTemperature() {
        let mockWeather = WeatherResponse(
            name: "Test City",
            main: Main(temp: 24.0, tempMin: 19.0, tempMax: 29.0),
            weather: [Weather(description: "Rainy", icon: "sunny")]
        )
        let encodedData = try! JSONEncoder().encode(mockWeather)
        UserDefaults.standard.set(encodedData, forKey: "cachedCurrentWeather")
        
        let expectation = self.expectation(description: "Weather updated")
        
        viewModel.fetchWeather(latitude: 0.0, longitude: 0.0)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            XCTAssertEqual(self.viewModel.currentTemperature, 24, "Expected updated temperature to be 24°C")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2, handler: nil)
    }
}
