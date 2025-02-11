


//import XCTest
//import Combine
//@testable import weather_app
//
//final class WeatherServiceTests: XCTestCase {
//    var weatherService: WeatherService!
//    var cancellables: Set<AnyCancellable>!
//
//    override func setUp() {
//        super.setUp()
//        weatherService = WeatherService()
//        cancellables = []
//    }
//
//    override func tearDown() {
//        weatherService = nil
//        cancellables = nil
//        super.tearDown()
//    }
//
//    func testFetchCurrentWeather_Success() {
//        let expectation = XCTestExpectation(description: "Fetch current weather successfully")
//        let lat = 37.7749
//        let lon = -122.4194
//        
//        weatherService.fetchCurrentWeather(lat: lat, lon: lon)
//            .sink(receiveCompletion: { completion in
//                if case .failure(let error) = completion {
//                    XCTFail("Expected success but got failure: \(error)")
//                }
//            }, receiveValue: { weather in
//                XCTAssertNotNil(weather, "Weather response should not be nil")
//                expectation.fulfill()
//            })
//            .store(in: &cancellables)
//
//        wait(for: [expectation], timeout: 5.0)
//    }
//
//    func testFetchFiveDayForecast_Success() {
//        let expectation = XCTestExpectation(description: "Fetch forecast successfully")
//        let lat = 37.7749
//        let lon = -122.4194
//
//        weatherService.fetchFiveDayForecast(lat: lat, lon: lon)
//            .sink(receiveCompletion: { completion in
//                if case .failure(let error) = completion {
//                    XCTFail("Expected success but got failure: \(error)")
//                }
//            }, receiveValue: { forecast in
//                XCTAssertGreaterThan(forecast.count, 0, "Forecast should have at least one entry")
//                expectation.fulfill()
//            })
//            .store(in: &cancellables)
//
//        wait(for: [expectation], timeout: 5.0)
//    }
//
//    func testLoadCachedWeather_WhenDataExists() {
//        let mockWeather = WeatherResponse(currentTemp: 20.0, minTemp: 15.0, maxTemp: 25.0, condition: "Clear", weather: [WeatherDetail(iconURL: "mock_url")])
//        let encodedData = try? JSONEncoder().encode(mockWeather)
//        UserDefaults.standard.set(encodedData, forKey: "cachedCurrentWeather")
//
//        let cachedWeather = weatherService.loadCachedWeather()
//        XCTAssertNotNil(cachedWeather, "Cached weather should not be nil")
//        XCTAssertEqual(cachedWeather?.currentTemp, 20.0, "Cached temperature should match")
//    }
//}
//
//
//import XCTest
//import Combine
//@testable import weather_app
//
//final class WeatherRepositoryTests: XCTestCase {
//    var repository: WeatherRepository!
//    var mockWeatherService: WeatherService!
//    var cancellables: Set<AnyCancellable>!
//
//    override func setUp() {
//        super.setUp()
//        mockWeatherService = WeatherService()
//        repository = WeatherRepository()
//        cancellables = []
//    }
//
//    override func tearDown() {
//        repository = nil
//        mockWeatherService = nil
//        cancellables = nil
//        super.tearDown()
//    }
//
//    func testGetCurrentWeather_UsesCache() {
//        let mockWeather = WeatherResponse(currentTemp: 22.0, minTemp: 18.0, maxTemp: 26.0, condition: "Cloudy", weather: [WeatherDetail(iconURL: "mock_url")])
//        let encodedData = try? JSONEncoder().encode(mockWeather)
//        UserDefaults.standard.set(encodedData, forKey: "cachedCurrentWeather")
//
//        let expectation = XCTestExpectation(description: "Retrieve cached weather")
//
//        repository.getCurrentWeather(lat: 0.0, lon: 0.0)
//            .sink(receiveCompletion: { _ in }, receiveValue: { weather in
//                XCTAssertEqual(weather.currentTemp, 22.0, "Cached temperature should match")
//                expectation.fulfill()
//            })
//            .store(in: &cancellables)
//
//        wait(for: [expectation], timeout: 3.0)
//    }
//}
//
//
//import XCTest
//import Combine
//@testable import weather_app
//@MainActor
//final class WeatherViewModelTests: XCTestCase {
//    var viewModel: WeatherViewModel!
//    var mockRepository: WeatherRepository!
//    var cancellables: Set<AnyCancellable>!
//
//    override func setUp() {
//        super.setUp()
//        mockRepository = WeatherRepository()
//        viewModel = WeatherViewModel()
//        cancellables = []
//    }
//
//    override func tearDown() {
//        viewModel = nil
//        mockRepository = nil
//        cancellables = nil
//        super.tearDown()
//    }
//
//    @MainActor func testFetchWeather_UpdatesTemperature() {
//        let mockWeather = WeatherResponse(currentTemp: 25.0, minTemp: 20.0, maxTemp: 30.0, condition: "Rainy", weather: [WeatherDetail(iconURL: "mock_url")])
//
//        let expectation = XCTestExpectation(description: "Weather view model updates temperature")
//
//        viewModel.$currentTemperature
//            .dropFirst()
//            .sink { newTemp in
//                XCTAssertEqual(newTemp, 25, "Temperature should update to 25")
//                expectation.fulfill()
//            }
//            .store(in: &cancellables)
//
////        viewModel.updateWeather(with: mockWeather)
//
//        wait(for: [expectation], timeout: 3.0)
//    }
//
//    func testFetchWeather_UpdatesWeatherCondition() {
//        let mockWeather = WeatherResponse(currentTemp: 25.0, minTemp: 20.0, maxTemp: 30.0, condition: "Rainy", weather: [WeatherDetail(iconURL: "mock_url")])
//
//        let expectation = XCTestExpectation(description: "Weather view model updates condition")
//
//        viewModel.$weatherCondition
//            .dropFirst()
//            .sink { newCondition in
//                XCTAssertEqual(newCondition, "Rainy", "Weather condition should update to Rainy")
//                expectation.fulfill()
//            }
//            .store(in: &cancellables)
//
////        viewModel.updateWeather(with: mockWeather)
//
//        wait(for: [expectation], timeout: 3.0)
//    }
//
//    func testFetchWeather_UpdatesForecast() {
//        let mockForecast = [
////            ForecastDay(dt: "Monday", main: 18.0, weather: "mock_url"),
////            ForecastDay(dt: "Tuesday", main: 20.0, weather: "mock_url")
//        ]
//
//        let expectation = XCTestExpectation(description: "Weather view model updates forecast")
//
//        viewModel.$forecast
//            .dropFirst()
//            .sink { newForecast in
//                XCTAssertEqual(newForecast.count, 2, "Forecast should contain 2 days")
//                XCTAssertEqual(newForecast.first?.day, "Monday", "First forecast entry should be Monday")
//                expectation.fulfill()
//            }
//            .store(in: &cancellables)
//
////        viewModel.updateForecast(with: mockForecast)
//
//        wait(for: [expectation], timeout: 3.0)
//    }
//}
