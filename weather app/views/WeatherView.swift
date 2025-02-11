
import SwiftUI
import SwiftData

import SwiftUI

struct WeatherView: View {
    @ObservedObject var viewModel: WeatherViewModel
    @Query private var locations: [FavoriteLocation]
    @Environment(\.modelContext) private var modelContext
    @State private var showToast = false
    
    private var backgroundImage: String {
        let condition = viewModel.weatherCondition.lowercased()
        
        if condition.contains("cloud") {
            return "cloudy"
        } else if condition.contains("rain") {
            return "rainy"
        } else if condition.contains("sun") {
            return "sunny"
        } else {
            return "sunny" // Default fallback
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Image(backgroundImage)
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2.5)
                
                VStack(spacing: 20) {
                    Text("Weather in \(viewModel.city)")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.white)
                    
                    if viewModel.currentTemperature == 0 && viewModel.weatherCondition == "Sunny" {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                    } else {
                        VStack(spacing: 5) {
                            Text("\(viewModel.currentTemperature)°")
                                .font(.system(size: 70, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text(viewModel.weatherCondition)
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                        
                        if let url = URL(string: viewModel.weatherIconURL) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .frame(width: 80, height: 80)
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(width: 80, height: 80)
                        }
                    }
                    
                    if !viewModel.forecast.isEmpty {
                        List(viewModel.forecast, id: \.day) { day in
                            HStack {
                                Text(day.day)
                                    .font(.headline)
                                    .foregroundColor(.white)

                                Spacer()
                                
                                if let url = URL(string: day.weatherIconURL) {
                                    AsyncImage(url: url) { image in
                                        image
                                            .resizable()
                                            .renderingMode(.template)
                                            .foregroundColor(.gray)
                                    } placeholder: {
                                        ProgressView()
                                    }
                                    .frame(width: 40, height: 40)
                                }
                                
                                Text("\(day.temperature)°")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            .padding(.vertical, 5)
                        }
                        .frame(height: 250)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                    }
                }
                .padding()
                
                if showToast {
                    VStack {
                        Spacer()
                        Text("✅ Location Saved!")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(10)
                            .padding(.bottom, 50)
                    }
                    .transition(.move(edge: .bottom))
                }
            }
            .navigationTitle("Weather")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button(action: saveLocation) {
                        Label("Save", systemImage: "heart.fill")
                    }
                    .foregroundColor(.red)
                    
                    NavigationLink(destination: FavoriteLocationsView()) {
                        Label("Saved", systemImage: "list.dash")
                    }
                    
                    NavigationLink(destination: MapView(locations: locations, viewModel: viewModel)) {
                        Label("Saved", systemImage: "map")
                    }
                }
            }
        }
    }
    
    private func saveLocation() {
        let newLocation = FavoriteLocation(
            name: viewModel.city,
            latitude: viewModel.latitude,
            longitude: viewModel.longitude,
            temperature: viewModel.currentTemperature,
            dateSaved: Date()
        )
        modelContext.insert(newLocation)
        
        withAnimation {
            showToast = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showToast = false
            }
        }
    }
}



@Model
class FavoriteLocation {
    var name: String
    var latitude: Double
    var longitude: Double
    var temperature: Int
    var dateSaved: Date

    init(name: String, latitude: Double, longitude: Double, temperature: Int, dateSaved: Date) {
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.temperature = temperature
        self.dateSaved = dateSaved
    }
}

