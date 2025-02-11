
import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    
    @Published var city: String = ""
    @Published var latitude: Double = 0.0
    @Published var longitude: Double = 0.0
    private var isRequestingLocation = false

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        checkAuthorizationStatus()
    }

    func checkAuthorizationStatus() {
        let status = locationManager.authorizationStatus

        switch status {
        case .notDetermined:
            print("No Location authorisation.")
        case .authorizedWhenInUse, .authorizedAlways:
            print("Authorised.")
            DispatchQueue.main.async { [weak self] in
                self?.requestLocation()
            }
        case .denied, .restricted:
            print("Location access denied.")
        @unknown default:
            break
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus

        switch status {
        case .notDetermined:
            print(" Requesting location permission...")
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            print("Authorization granted,location updating.")
            DispatchQueue.main.async { [weak self] in
                self?.requestLocation()
            }
        case .denied, .restricted:
            print("Authorization denied")
        @unknown default:
            break
        }
    }

    func requestLocation() {
        guard CLLocationManager.locationServicesEnabled() else {
            print(" Location services disabled.")
            return
        }
        
        guard !isRequestingLocation else { return }
        isRequestingLocation = true

        print("Requesting location update...")
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.locationManager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.latitude = location.coordinate.latitude
            self.longitude = location.coordinate.longitude
            self.isRequestingLocation = false
            self.reverseGeocode(location)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                print("Location access denied. Ask the user to enable it in Settings.")
            case .locationUnknown:
                print(" Location unavailable. Retrying ")
                DispatchQueue.global().asyncAfter(deadline: .now() + 10) { [weak self] in
                    self?.isRequestingLocation = false
                    self?.requestLocation()
                }
            default:
                print("Location error: \(clError.localizedDescription)")
            }
        }
    }

    private func reverseGeocode(_ location: CLLocation) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self else { return }

            if let error = error {
                print("Failed: \(error.localizedDescription)")
                return
            }

            if let city = placemarks?.first?.locality {
                DispatchQueue.main.async {
                    self.city = city
                }
            }
        }
    }
}
