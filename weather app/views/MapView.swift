
import SwiftUI
import MapKit

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
