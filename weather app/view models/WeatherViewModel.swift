

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







import SwiftUI
import MapKit

struct MapViewControllerRepresentable: UIViewControllerRepresentable {
    var locations: [FavoriteLocation]
    var currentLocation: CLLocationCoordinate2D?
    var currentTemperature: String?
    var locationTemperatures: [String: String]

    func makeUIViewController(context: Context) -> UIViewController {
        let mapVC = UIViewController()
        let mapView = MKMapView()
        mapView.frame = mapVC.view.bounds
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        
        mapVC.view.addSubview(mapView)
        addAnnotations(to: mapView)
        return mapVC
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        guard let mapView = uiViewController.view.subviews.first as? MKMapView else { return }
        mapView.removeAnnotations(mapView.annotations)
        addAnnotations(to: mapView)
    }

    private func addAnnotations(to mapView: MKMapView) {
        for location in locations {
            let temp = locationTemperatures[location.name] ?? "--°"
            let annotation = WeatherAnnotation(
                title: location.name,
                subtitle: "Temp: \(temp)",
                coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
            )
            mapView.addAnnotation(annotation)
        }

        if let currentLocation = currentLocation {
            let annotation = WeatherAnnotation(
                title: "Current Location",
                subtitle: "Temp: \(currentTemperature ?? "--°")",
                coordinate: currentLocation
            )
            mapView.addAnnotation(annotation)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            let identifier = "WeatherPin"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView

            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
                annotationView?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            } else {
                annotationView?.annotation = annotation
            }

            if let weatherAnnotation = annotation as? WeatherAnnotation {
                annotationView?.markerTintColor = weatherAnnotation.title == "Current Location" ? .blue : .red
            }

            return annotationView
        }
    }
}

class WeatherAnnotation: NSObject, MKAnnotation {
    var title: String?
    var subtitle: String?
    var coordinate: CLLocationCoordinate2D

    init(title: String, subtitle: String, coordinate: CLLocationCoordinate2D) {
        self.title = title
        self.subtitle = subtitle
        self.coordinate = coordinate
    }
}









struct MapView: View {
     var locations: [FavoriteLocation]
    @ObservedObject var viewModel: WeatherViewModel

    var body: some View {
        MapViewControllerRepresentable(
            locations: locations,
            currentLocation: CLLocationCoordinate2D(latitude: viewModel.latitude, longitude: viewModel.longitude),
            currentTemperature: "\(viewModel.currentTemperature)°",
            locationTemperatures: viewModel.savedLocationTemperatures
        )
        .edgesIgnoringSafeArea(.all)
        .navigationTitle("Saved Locations")
        .onAppear {
            viewModel.fetchWeatherForSavedLocations(locations: locations)
        }
    }
}
